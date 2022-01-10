package com.toombs.backend.identity.services

import com.toombs.backend.identity.entities.*
import com.toombs.backend.identity.repositories.IdentityMapHistoryRepository
import com.toombs.backend.identity.repositories.IdentityMapRepository
import com.toombs.backend.identity.repositories.IdentityRepository
import org.apache.commons.csv.CSVFormat
import org.apache.commons.csv.CSVParser
import org.springframework.stereotype.Service
import java.io.InputStream
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*
import javax.transaction.Transactional


@Service
class IdentityService(
    private val identityRepository: IdentityRepository,
    private val identityMapRepository: IdentityMapRepository,
    private val identityMapHistoryRepository: IdentityMapHistoryRepository,
    private val identityHubService: IdentityHubService,
) {
    private val DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    private val TRX_ID_COLUMN = "TrxId"
    private val UPI_COLUMN = "Upi"

    private val TRX_ID = "TRX-"
    private val USER = "rtoombs@shieldsrx.com"
    private val UPI_REFRESH = "UPI REFRESH"
    private val MERGE = "MERGE"
    private val UPDATE = "UPDATE"
    private val CREATE = "CREATE"

    fun getIdentities(): List<Identity> {
        return identityRepository.findAllByOrderByIdAsc()
    }

    fun getActiveIdentities(): List<Identity> {
        return identityRepository.findByActiveIsTrueOrderByPatientLastAsc()
    }

    fun refreshUPIs(): Boolean {
        val ioStream: InputStream? = this.javaClass
            .classLoader
            .getResourceAsStream("upi_refresh.csv")

        val csvParser = CSVParser(
            ioStream?.bufferedReader(),
            CSVFormat.Builder.create()
                .setHeader()
                .setDelimiter(',')
                .setRecordSeparator("\r\n")
                .build()
        )

        for (record in csvParser) {
            val trxId = record.get(TRX_ID_COLUMN)
            val newUpi = record.get(UPI_COLUMN)

            val optional = identityRepository.findFirstByActiveIsTrueAndTrxId(trxId)
            if(optional.isPresent) {
                val existingIdentity = optional.get()

                val now = LocalDateTime.now()

                retireExistingIdentity(existingIdentity, now, UPI_REFRESH)
                val newIdentity = createNewIdentity(existingIdentity, newUpi, existingIdentity.trxId, UPI_REFRESH)
                val activeIdentity : Identity = save(newIdentity)

                updateIdentityMaps(activeIdentity, existingIdentity.id!!, now)
            }
        }

        return true
    }

    fun updateIdentity(updatedIdentity: Identity) : Boolean {
        if(updatedIdentity.id == null || !identityRepository.existsByIdAndActiveIsTrue(updatedIdentity.id!!)) {
            return false
        }

        val existingIdentity = identityRepository.findById(updatedIdentity.id!!).get()

        if (existingIdentity.patientFirst != updatedIdentity.patientFirst
            || existingIdentity.patientLast != updatedIdentity.patientLast
            || existingIdentity.mrn != updatedIdentity.mrn
            || existingIdentity.gender != updatedIdentity.gender
            || existingIdentity.dateOfBirth != updatedIdentity.dateOfBirth
            || anyPhoneNumbersUpdated(existingIdentity, updatedIdentity)
        ) {
            val now = LocalDateTime.now()

            retireExistingIdentity(existingIdentity, now, USER)
            val newIdentity = createNewIdentity(updatedIdentity, existingIdentity.upi, existingIdentity.trxId, USER)
            val activeIdentity : Identity = save(newIdentity)

            updateIdentityMaps(activeIdentity, existingIdentity.id!!, now)

            return true
        }

        return false
    }

    // TODO If logic is added to add/delete phone numbers, this method would need to be updated
    private fun anyPhoneNumbersUpdated(existingIdentity: Identity, updatedIdentity: Identity): Boolean {
        for (i in 0..existingIdentity.phones.size) {
            val existing = existingIdentity.phones[i]
            val updated = updatedIdentity.phones[i]

            if(existing != updated) {
                return true
            }
        }
        return false
    }

    fun getIdentityMaps(): List<IdentityMap> {
        return identityMapRepository.findAllByOrderByIdAsc()
    }

    fun updateIdentityMap(id: Long, newIdentityId: Long): Boolean {
        if(!identityRepository.existsByIdAndActiveIsTrue(newIdentityId)) {
            return false
        }

        if(!identityMapRepository.existsById(id)) {
            return false
        }

        val newIdentity = identityRepository.findByIdAndActiveIsTrue(newIdentityId)
        val identityMap = identityMapRepository.findById(id).get()

        val now = LocalDateTime.now()

        retireExistingIdentity(identityMap.identity!!, now, USER)
        createIdentityMapHistoryEntry(identityMap.id, identityMap.identity?.id, newIdentity.id, now, MERGE)

        identityMap.identity = newIdentity

        save(identityMap)

        return true
    }

    fun getIdentityMapHistories(): List<IdentityMapHistory> {
        return identityMapHistoryRepository.findAll().toList()
    }

    fun findOrCreateActiveIdentityMap(identityMap : IdentityMap?): IdentityMap? {
        var result: IdentityMap? = null

        if(identityMap != null) {
            val mapId = identityMap.id

            if (mapId == null) {
                val identity = findActiveOrCreateNewIdentity(identityMap.identity)
                result = createActiveIdentityMap(identity)
            }
            else if(identityMapRepository.existsById(mapId)) {
                result = identityMapRepository.findById(mapId).get()
            }
        }

        return result
    }

    fun findActiveOrCreateNewIdentity(identity : Identity?): Identity? {
        var result: Identity? = null

        if(identity != null) {
            val id = identity.id
            if (id == null) {
                val upi = generateUPI(identity)
                val trx = generateTrxId()

                // TODO Search for existing UPI?
                result = createAndSaveNewIdentity(identity, upi, trx, USER)
            }
            else if(identityRepository.existsByIdAndActiveIsTrue(id)) {
                result = identityRepository.findById(id).get()
            }
        }

        return result
    }

    fun addIdentity(identity: Identity): Identity? {
        val upi = generateUPI(identity)
        val trxId = generateTrxId()

        // TODO search for existing UPI?
        val newIdentity = createAndSaveNewIdentity(identity, upi, trxId, USER)
        createActiveIdentityMap(newIdentity)
        return newIdentity
    }

    fun activateIdentity(id: Long): Boolean {
        val exists = identityRepository.existsByIdAndActiveIsFalseAndEndDateIsNull(id)
        if(exists) {
            val existingIdentity = identityRepository.findByIdAndActiveIsFalseAndEndDateIsNull(id)
            val now = LocalDateTime.now()

            retireExistingIdentity(existingIdentity, now, USER)

            val newIdentity = createNewIdentity(existingIdentity, existingIdentity.upi, existingIdentity.trxId, USER)
            val activeIdentity : Identity = save(newIdentity)

            val activatedMaps = updateIdentityMaps(activeIdentity, existingIdentity.id!!, now)

            identityHubService.activateMappedActivities(activatedMaps)

            return true
        }

        return false
    }

    fun deactivateIdentity(id: Long): Boolean {
        val exists = identityRepository.existsByIdAndActiveIsTrue(id)
        if(exists) {
            val existingIdentity = identityRepository.findByIdAndActiveIsTrue(id)
            val now = LocalDateTime.now()

            retireExistingIdentity(existingIdentity, now, USER)

            val newIdentity = createNewIdentity(existingIdentity, false)
            val activeIdentity : Identity = save(newIdentity)

            val deactivatedMaps = updateIdentityMaps(activeIdentity, existingIdentity.id!!, now)

            identityHubService.deactivateMappedActivities(deactivatedMaps)

            return true
        }

        return false
    }

    private fun generateUPI(identity: Identity): String {
        val lastName = identity.patientLast
        val dob = identity.dateOfBirth
        val gender = identity.gender

        val combination = lastName + "/" + dob?.format(DATE_FORMATTER) + "/" + gender
        return combination.hashCode().toString()
    }

    private fun generateTrxId(): String {
        return TRX_ID + UUID.randomUUID().toString().substring(0, 10)
    }

    @Transactional
    fun save(identityMap : IdentityMap): IdentityMap {
        return identityMapRepository.save(identityMap)
    }

    @Transactional
    fun saveAll(identityMaps : List<IdentityMap>): List<IdentityMap> {
        return identityMapRepository.saveAll(identityMaps).toList()
    }

    @Transactional
    fun save(identity : Identity): Identity {
        return identityRepository.save(identity)
    }

    @Transactional
    fun save(identityMapHistory : IdentityMapHistory) {
        identityMapHistoryRepository.save(identityMapHistory)
    }

    private fun createAndSaveNewIdentity(identity: Identity, upi: String, trxId: String, user: String): Identity {
        val newIdentity = createNewIdentity(identity, upi, trxId, user)
        return save(newIdentity)
    }

    private fun createNewIdentity(identity: Identity, active: Boolean): Identity {
        val newIdentity = createNewIdentity(identity, identity.upi, identity.trxId, USER)
        newIdentity.active = active
        return newIdentity
    }

    private fun createNewIdentity(identity: Identity, upi: String, trxId: String, user: String): Identity {
        val newIdentity = Identity()
        newIdentity.gender = identity.gender
        newIdentity.patientLast = identity.patientLast
        newIdentity.patientFirst = identity.patientFirst
        newIdentity.dateOfBirth = identity.dateOfBirth
        newIdentity.trxId = trxId
        newIdentity.upi = upi
        newIdentity.mrn = identity.mrn
        newIdentity.active = true
        newIdentity.createdBy = user
        newIdentity.endDate = null
        newIdentity.modifiedBy = ""
        newIdentity.createDate = LocalDateTime.now()

        for(phone in identity.phones) {
            val newPhone = Phone()
            newPhone.number = phone.number
            newPhone.type = phone.type
            newIdentity.addPhone(newPhone)
        }

        for(mrnOverflow in identity.mrnOverflow) {
            val overflow = MrnOverflow()
            overflow.mrn = mrnOverflow.mrn
            newIdentity.addMrnOverflow(overflow)
        }

        return newIdentity
    }

    private fun retireExistingIdentity(existingIdentity: Identity, now: LocalDateTime?, user: String) {
        existingIdentity.endDate = now
        existingIdentity.modifiedBy = user
        existingIdentity.active = false

        save(existingIdentity)
    }

    private fun createActiveIdentityMap(identity: Identity?): IdentityMap? {
        var result: IdentityMap? = null

        if (identity != null) {
            if (identityMapRepository.existsByIdentityId(identity.id!!)) {
                result = identityMapRepository.findFirstByIdentityId(identity.id!!)
            } else {
                val newMapping = IdentityMap()
                newMapping.identity = identity
                result = save(newMapping)
                createIdentityMapHistoryEntry(result.id, null, result.identity?.id, LocalDateTime.now(), CREATE)
            }
        }

        return result
    }

    private fun updateIdentityMaps(activeIdentity: Identity, previousId: Long, eventTime: LocalDateTime): List<IdentityMap> {
        val identityMaps = identityMapRepository.findAllByIdentityId(previousId)

        for(identityMap in identityMaps) {
            createIdentityMapHistoryEntry(identityMap.id, identityMap.identity?.id, activeIdentity.id, eventTime, UPDATE)

            identityMap.identity = activeIdentity
        }

        return saveAll(identityMaps)
    }

    private fun createIdentityMapHistoryEntry(identityMapId: Long?, oldIdentityId: Long?, newIdentityId: Long?, eventTime: LocalDateTime?, event: String) {
        val history = IdentityMapHistory()
        history.identityMapId = identityMapId
        history.oldIdentityId = oldIdentityId
        history.newIdentityId = newIdentityId
        history.createDate = eventTime
        history.event = event

        save(history)
    }
}
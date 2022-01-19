package com.toombs.backend.identity.services

import com.toombs.backend.etl.APPOINTMENT_ETL
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

const val USER = "rtoombs@shieldsrx.com"

val AUDIT_GENERATOR = AuditGenerator()

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
    private val UPI_REFRESH = "UPI REFRESH"
    private val MERGE = "MERGE"
    private val UPDATE = "UPDATE"
    private val CREATE = "CREATE"

    fun getIdentities(): List<Identity> {
        return identityRepository.findAllByOrderByIdAsc()
    }

    fun getCurrentIdentities(): List<Identity> {
        return identityRepository.findAllByDoneIsFalseOrderByPatientLastAsc()
    }

    fun getActiveIdentities(): List<Identity> {
        return identityRepository.findByActiveIsTrueAndDoneIsFalseOrderByPatientLastAsc()
    }

    fun getAuditTrail(id: Long): List<Audit> {
        val optional = identityRepository.findById(id)
        if(optional.isPresent) {
            val identities = identityRepository.findAllByTrxIdOrderByCreateDateAsc(optional.get().trxId)
            return AUDIT_GENERATOR.generateAuditTrail(identities)
        }

        return emptyList()
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

            val optional = identityRepository.findFirstByActiveIsTrueAndDoneIsFalseAndTrxId(trxId)
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
        if(updatedIdentity.id == null || !identityRepository.existsByIdAndActiveIsTrueAndDoneIsFalse(updatedIdentity.id!!)) {
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
        if(!identityRepository.existsByIdAndActiveIsTrueAndDoneIsFalse(newIdentityId)) {
            return false
        }

        if(!identityMapRepository.existsById(id)) {
            return false
        }

        val destinationIdentity = identityRepository.findByIdAndActiveIsTrueAndDoneIsFalse(newIdentityId)
        val identityMap = identityMapRepository.findById(id).get()

        val now = LocalDateTime.now()

        // Retire the existing identity + create a new history of the merge
        retireExistingIdentity(identityMap.identity!!, now, USER)
        createIdentityMapHistoryEntry(identityMap.id, identityMap.identity?.id, destinationIdentity.id, now, MERGE)

        // Create the new "in-active" identity
        val newIdentity = createNewIdentity(identityMap.identity!!, false)
        save(newIdentity)

        // Update the mapping to point to the selected destination identity + save the mapping
        identityMap.identity = destinationIdentity
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

                result = createAndSaveNewIdentity(identity, upi, trx, USER)
            }
            else if(identityRepository.existsByIdAndActiveIsTrueAndDoneIsFalse(id)) {
                result = identityRepository.findById(id).get()
            }
        }

        return result
    }

    fun addIdentity(identity: Identity, user: String): IdentityMap? {
        val upi = if (identity.upi == "") generateUPI(identity) else identity.upi
        val trxId = if (identity.trxId == "") generateTrxId() else identity.trxId

        val newIdentity = createAndSaveNewIdentity(identity, upi, trxId, user)
        return createActiveIdentityMap(newIdentity)
    }

    fun reactivateIdentityFromEtl(upi: String, etlIdentity: Identity): List<IdentityMap> {
        val exists = identityRepository.findByActiveIsFalseAndDoneIsFalseAndUpi(upi)
        if(exists.isPresent) {
            val existingIdentity = exists.get()
            return reactiveIdentity(existingIdentity, APPOINTMENT_ETL)
        }

        return emptyList()
    }

    fun reactivateIdentityFromApp(id: Long): Boolean {
        val exists = identityRepository.existsByIdAndActiveIsFalseAndDoneIsFalse(id)
        if(exists) {
            val existingIdentity = identityRepository.findByIdAndActiveIsFalseAndEndDateIsNull(id)
            val activatedMaps = reactiveIdentity(existingIdentity, USER)

            identityHubService.activateMappedActivities(activatedMaps)

            return true
        }

        return false
    }

    private fun reactiveIdentity(existingIdentity: Identity, user: String): List<IdentityMap> {
        val now = LocalDateTime.now()

        retireExistingIdentity(existingIdentity, now, user)

        val newIdentity = createNewIdentity(existingIdentity, existingIdentity.upi, existingIdentity.trxId, user)
        val activeIdentity: Identity = save(newIdentity)

        return updateIdentityMaps(activeIdentity, existingIdentity.id!!, now)
    }

    fun deactivateIdentity(id: Long): Boolean {
        val exists = identityRepository.existsByIdAndActiveIsTrueAndDoneIsFalse(id)
        if(exists) {
            val existingIdentity = identityRepository.findByIdAndActiveIsTrueAndDoneIsFalse(id)
            val now = LocalDateTime.now()

            retireExistingIdentity(existingIdentity, now, USER)

            val newIdentity = createNewIdentity(existingIdentity, false)
            val inactiveIdentity : Identity = save(newIdentity)

            val deactivatedMaps = updateIdentityMaps(inactiveIdentity, existingIdentity.id!!, now)

            identityHubService.deactivateMappedActivities(deactivatedMaps)

            return true
        }

        return false
    }

    fun findFirstIdentityMapByUpi(upi: String): IdentityMap? {
        val result = identityRepository.findFirstByActiveIsTrueAndDoneIsFalseAndUpi(upi)
        if(result.isPresent) {
            val identity = result.get()
            if(identityMapRepository.existsByIdentityId(identity.id!!)) {
                return identityMapRepository.findFirstByIdentityId(identity.id!!)
            }
        }

        return null
    }

    fun createActiveIdentityMap(identity: Identity?): IdentityMap? {
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
        existingIdentity.done = true

        save(existingIdentity)
    }

    private fun updateIdentityMaps(activeIdentity: Identity, previousId: Long, eventTime: LocalDateTime): List<IdentityMap> {
        val identityMaps = identityMapRepository.findAllByIdentityId(previousId)

        // If a mapping does not exist for this identity, create one
        if(identityMaps.isEmpty()) {
            return listOfNotNull(createActiveIdentityMap(activeIdentity))
        }
        // If a mapping does exist for this identity, update all of them to point to the new active identity
        else {
            for (identityMap in identityMaps) {
                createIdentityMapHistoryEntry(
                    identityMap.id,
                    identityMap.identity?.id,
                    activeIdentity.id,
                    eventTime,
                    UPDATE
                )

                identityMap.identity = activeIdentity
            }

            return saveAll(identityMaps)
        }
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
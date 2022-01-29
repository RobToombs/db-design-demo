package com.toombs.backend.identity.services

import com.toombs.backend.etl.APPOINTMENT_ETL
import com.toombs.backend.identity.entities.active.Identity
import com.toombs.backend.identity.entities.active.IdentityMap
import com.toombs.backend.identity.entities.active.MrnOverflow
import com.toombs.backend.identity.entities.active.Phone
import com.toombs.backend.identity.entities.audit.Audit
import com.toombs.backend.identity.entities.history.IdentityHistory
import com.toombs.backend.identity.entities.history.IdentityMapHistory
import com.toombs.backend.identity.repositories.history.IdentityMapHistoryRepository
import com.toombs.backend.identity.repositories.active.IdentityMapRepository
import com.toombs.backend.identity.repositories.active.IdentityRepository
import org.apache.commons.csv.CSVFormat
import org.apache.commons.csv.CSVParser
import org.springframework.stereotype.Service
import java.io.InputStream
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*
import javax.transaction.Transactional

const val USER = "rtoombs@shieldsrx.com"
const val TRX_ID_COLUMN = "TrxId"
const val UPI_COLUMN = "Upi"

const val TRX_ID = "TRX-"
const val UPI_REFRESH = "UPI REFRESH"
const val MERGE = "MERGE"
const val UPDATE = "UPDATE"
const val CREATE = "CREATE"

val DATE_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
val AUDIT_GENERATOR = AuditGenerator()

@Service
class IdentityService(
    private val identityRepository: IdentityRepository,
    private val identityMapRepository: IdentityMapRepository,
    private val identityMapHistoryRepository: IdentityMapHistoryRepository,
    private val identityHubService: IdentityHubService,
    private val identityHistoryService: IdentityHistoryService
) {
    fun getCurrentIdentities(): List<Identity> {
        return identityRepository.findAllByOrderByIdAsc()
    }

    fun getActiveIdentities(): List<Identity> {
        return identityRepository.findByActiveIsTrueOrderByPatientLastAsc()
    }

    fun getAuditTrail(id: Long): List<Audit> {
        val optional = identityRepository.findById(id)
        if(optional.isPresent) {
            val active = identityRepository.findByTrxId(optional.get().trxId)
            val historical = identityHistoryService.findByTrxId(optional.get().trxId)
            return AUDIT_GENERATOR.generateAuditTrail(active, historical)
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

            val optional = identityRepository.findFirstByTrxId(trxId)
            if(optional.isPresent) {
                val existingIdentity = optional.get()

                val now = LocalDateTime.now()
                retireExistingIdentity(existingIdentity, now, UPI_REFRESH, false)
                existingIdentity.upi = newUpi
                existingIdentity.createDate = now
                existingIdentity.endDate = null
                existingIdentity.createdBy = UPI_REFRESH

                save(existingIdentity)
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
            retireExistingIdentity(existingIdentity, now, USER, false)
            updateIdentity(existingIdentity, updatedIdentity, USER, now)
            save(existingIdentity)

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

        val destinationIdentity = identityRepository.findByIdAndActiveIsTrue(newIdentityId)
        val identityMap = identityMapRepository.findById(id).get()

        val existingIdentity = identityMap.identity!!

        val now = LocalDateTime.now()

        // Retire the existing identity + create a new history of the merge
        retireExistingIdentity(existingIdentity, now, USER, false)
        createIdentityMapHistoryEntry(identityMap.id, existingIdentity.id, destinationIdentity.id, now, MERGE)

        // Create the new "inactive" identity
        existingIdentity.active = false
        save(existingIdentity)

        // Update the mapping and all other mappings currently pointed at the source identity
        // to point to the selected destination identity + save the mapping
        identityMap.identity = destinationIdentity
        save(identityMap)

        val additionalSourceMappings = identityMapRepository.findAllByIdentityId(existingIdentity.id!!)
        for(mapping in additionalSourceMappings) {
            mapping.identity = destinationIdentity
        }
        saveAll(additionalSourceMappings)

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

                val newIdentity = createNewIdentity(identity, upi, trx, USER)
                result = save(newIdentity)
            }
            else if(identityRepository.existsByIdAndActiveIsTrue(id)) {
                result = identityRepository.findById(id).get()
            }
        }

        return result
    }

    fun addIdentity(identity: Identity, user: String): IdentityMap? {
        val upi = if (identity.upi == "") generateUPI(identity) else identity.upi
        val trxId = if (identity.trxId == "") generateTrxId() else identity.trxId

        val newIdentity = createNewIdentity(identity, upi, trxId, user)
        val savedIdentity = save(newIdentity)

        return createActiveIdentityMap(savedIdentity)
    }

    fun reactivateIdentityFromEtl(upi: String, etlIdentity: Identity): List<IdentityMap> {
        val exists = identityRepository.findByActiveIsFalseAndUpi(upi)
        if(exists.isPresent) {
            val existingIdentity = exists.get()
            return reactiveIdentity(existingIdentity, APPOINTMENT_ETL)
        }

        return emptyList()
    }

    fun reactivateIdentityFromApp(id: Long): Boolean {
        val exists = identityRepository.existsByIdAndActiveIsFalse(id)
        if(exists) {
            val existingIdentity = identityRepository.findByIdAndActiveIsFalseAndEndDateIsNull(id)
            reactiveIdentity(existingIdentity, USER)

            return true
        }

        return false
    }

    fun deactivateIdentity(id: Long): Boolean {
        val exists = identityRepository.existsByIdAndActiveIsTrue(id)
        if(exists) {
            val existingIdentity = identityRepository.findByIdAndActiveIsTrue(id)

            val now = LocalDateTime.now()

            retireExistingIdentity(existingIdentity, now, USER, true)
            existingIdentity.active = false
            existingIdentity.createDate = now
            existingIdentity.endDate = null
            existingIdentity.createdBy = USER

            save(existingIdentity)

            return true
        }

        return false
    }

    fun findFirstIdentityMapByUpi(upi: String): IdentityMap? {
        val result = identityRepository.findFirstByActiveIsTrueAndUpi(upi)
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

    private fun reactiveIdentity(existingIdentity: Identity, user: String): List<IdentityMap> {
        val now = LocalDateTime.now()

        retireExistingIdentity(existingIdentity, now, user, false)
        existingIdentity.active = true
        existingIdentity.createDate = now
        existingIdentity.endDate = null
        existingIdentity.createdBy = user

        save(existingIdentity)

        return getAffectedIdentityMaps(existingIdentity)
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

    fun updateIdentity(existing: Identity, updated: Identity, user: String, created: LocalDateTime) {
        existing.gender = updated.gender
        existing.patientLast = updated.patientLast
        existing.patientFirst = updated.patientFirst
        existing.dateOfBirth = updated.dateOfBirth
        existing.mrn = updated.mrn
        existing.createdBy = user
        existing.endDate = null
        existing.modifiedBy = ""
        existing.createDate = created

        updatePhones(existing, updated)
        updateMrns(existing, updated)
    }

    private fun updatePhones(existing: Identity, updated: Identity) {
        val deletedPhones = mutableListOf<Phone>()

        // Update existing phones
        for(phone in existing.phones) {
            val updatedPhone = updated.phones.firstOrNull { it.id == phone.id }

            if(updatedPhone != null) {
                phone.type = updatedPhone.type
                phone.number = updatedPhone.number

                if(updatedPhone.delete) {
                    deletedPhones.add(phone)
                }
            }
        }

        // Add new phones
        for(newPhone in updated.phones.filter { it.id == null }) {
            val phone = Phone()

            phone.type = newPhone.type
            phone.number = newPhone.number

            existing.addPhone(phone)
        }

        // Remove deleted phones
        existing.phones.removeAll(deletedPhones)
    }

    private fun updateMrns(existing: Identity, updated: Identity) {
        val deletedMrns = mutableListOf<MrnOverflow>()

        // Update existing mrns
        for(mrn in existing.mrnOverflow) {
            val updatedMrn = updated.mrnOverflow.firstOrNull { it.id == mrn.id }

            if(updatedMrn != null) {
                mrn.mrn = updatedMrn.mrn

                if(updatedMrn.delete) {
                    deletedMrns.add(mrn)
                }
            }
        }

        // Add new mrns
        for(newMrn in updated.mrnOverflow.filter { it.id == null }) {
            val mrn = MrnOverflow()

            mrn.mrn = newMrn.mrn

            existing.addMrnOverflow(mrn)
        }

        // Remove deleted overflow mrns
        existing.mrnOverflow.removeAll(deletedMrns)
    }

    private fun retireExistingIdentity(existingIdentity: Identity, now: LocalDateTime, user: String, isIdentityDeactivated: Boolean){
        val identityHistory = identityHistoryService.retireIdentity(existingIdentity, now, user)

        existingIdentity.createdBy = user
        save(existingIdentity)

        // Update any finished activities referencing the previous identity to reference the newly created history
        val affectedMaps = getAffectedIdentityMaps(existingIdentity)
        identityHubService.initializeIdentityHistories(affectedMaps, identityHistory)

        if(isIdentityDeactivated) {
            identityHubService.deactivateMappedActivities(affectedMaps, identityHistory)
        }
    }

    private fun getAffectedIdentityMaps(identity: Identity): List<IdentityMap> {
        val identityMaps = identityMapRepository.findAllByIdentityId(identity.id!!)

        // If the activity is active and a mapping does not exist for this identity, create one
        return if(identity.active && identityMaps.isEmpty()) {
            listOfNotNull(createActiveIdentityMap(identity))
        }
        // If a mapping does exist for this identity, return them
        else {
            identityMaps
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
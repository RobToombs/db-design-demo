package com.toombs.backend.identity

import org.springframework.stereotype.Service
import java.time.LocalDateTime
import javax.transaction.Transactional


@Service
class IdentityService(
    private val identityRepository: IdentityRepository,
    private val identityMapRepository: IdentityMapRepository,
    private val identityMapHistoryRepository: IdentityMapHistoryRepository,
) {
    private val USER = "rtoombs@shieldsrx.com"
    private val MERGE = "MERGE"
    private val UPDATE = "UPDATE"
    private val CREATE = "CREATE"

    fun getIdentities(): List<Identity> {
        return identityRepository.findAllByOrderByIdAsc()
    }

    fun getActiveIdentities(): List<Identity> {
        return identityRepository.findByActiveIsTrueOrderByPatientLastAsc()
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
        ) {
            val now = LocalDateTime.now()

            existingIdentity.endDate = now
            existingIdentity.modifiedBy = USER
            existingIdentity.active = false

            save(existingIdentity)

            val newIdentity = createNewIdentity(updatedIdentity)
            val activeIdentity : Identity = save(newIdentity)

            updateIdentityMaps(activeIdentity, updatedIdentity.id!!, now)

            return true
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

        createIdentityMapHistoryEntry(identityMap.id, identityMap.identity?.id, newIdentity.id, LocalDateTime.now(), MERGE)

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

                if(identity != null) {
                    if(identityMapRepository.existsByIdentityId(identity.id!!)) {
                        result = identityMapRepository.findFirstByIdentityId(identity.id!!)
                    }
                    else {
                        val newMapping = IdentityMap()
                        newMapping.identity = identity
                        result = save(newMapping)
                        createIdentityMapHistoryEntry(result.id, null, result.identity?.id, LocalDateTime.now(), CREATE)
                    }
                }
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
                result = createNewIdentity(identity)
            }
            else if(identityRepository.existsByIdAndActiveIsTrue(id)) {
                result = identityRepository.findById(id).get()
            }
        }

        return result
    }

    private fun createNewIdentity(identity: Identity): Identity {
        val newIdentity = Identity()
        newIdentity.gender = identity.gender
        newIdentity.patientLast = identity.patientLast
        newIdentity.patientFirst = identity.patientFirst
        newIdentity.dateOfBirth = identity.dateOfBirth
        newIdentity.mrn = identity.mrn
        newIdentity.active = true
        newIdentity.createdBy = USER
        newIdentity.endDate = null
        newIdentity.modifiedBy = ""
        newIdentity.createDate = LocalDateTime.now()

        return save(identity)
    }

    @Transactional
    fun save(identityMap : IdentityMap): IdentityMap {
        return identityMapRepository.save(identityMap)
    }

    @Transactional
    fun saveAll(identityMaps : List<IdentityMap>) {
        identityMapRepository.saveAll(identityMaps)
    }

    @Transactional
    fun save(identity : Identity): Identity {
        return identityRepository.save(identity)
    }

    @Transactional
    fun save(identityMapHistory : IdentityMapHistory) {
        identityMapHistoryRepository.save(identityMapHistory)
    }

    private fun updateIdentityMaps(activeIdentity: Identity, previousId: Long, eventTime: LocalDateTime) {
        val identityMaps = identityMapRepository.findAllByIdentityId(previousId)

        for(identityMap in identityMaps) {
            createIdentityMapHistoryEntry(identityMap.id, identityMap.identity?.id, activeIdentity.id, eventTime, UPDATE)

            identityMap.identity = activeIdentity
        }

        saveAll(identityMaps)
    }

    private fun createIdentityMapHistoryEntry(identityMapId: Long?, oldIdentityId: Long?, newIdentityId: Long?, eventTime: LocalDateTime?, event: String) {
        val history = IdentityMapHistory()
        history.identityMapId = identityMapId
        history.oldIdentityId = oldIdentityId
        history.newIdentityId = newIdentityId
        history.createDate = eventTime
        history.createdBy = USER
        history.event = event

        save(history)
    }
}
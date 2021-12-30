package com.toombs.backend.identity

import org.springframework.stereotype.Service
import java.time.LocalDateTime
import javax.persistence.EntityManager
import javax.persistence.PersistenceContext
import javax.transaction.Transactional


@Service
class IdentityService(
    private val identityRepository: IdentityRepository,
    private val identityMapRepository: IdentityMapRepository,
    private val identityMapHistoryRepository: IdentityMapHistoryRepository,
) {
    @PersistenceContext
    var entityManager: EntityManager? = null

    private val USER = "rtoombs@shieldsrx.com"
    private val MERGE = "MERGE"
    private val UPDATE = "UPDATE"
    private val CREATE = "CREATE"

    fun getIdentities(): List<Identity> {
        return identityRepository.findAllByOrderByIdAsc()
    }

    fun updateIdentity(updatedIdentity: Identity) : Boolean {
        if(updatedIdentity.id == null || !identityRepository.existsById(updatedIdentity.id!!)) {
            return false
        }

        val existingIdentity = identityRepository.findById(updatedIdentity.id!!).get()

        if (existingIdentity.patientFirst != updatedIdentity.patientFirst
            || existingIdentity.patientLast != updatedIdentity.patientLast
            || existingIdentity.mrn != updatedIdentity.mrn
            || existingIdentity.gender != updatedIdentity.gender
            || existingIdentity.dateOfBirth != updatedIdentity.dateOfBirth
        ) {
            val now = LocalDateTime.now();

            existingIdentity.endDate = now
            existingIdentity.modifiedBy = USER
            existingIdentity.active = false

            save(existingIdentity)

            entityManager?.detach(existingIdentity)

            existingIdentity.patientFirst = updatedIdentity.patientFirst
            existingIdentity.patientLast = updatedIdentity.patientLast
            existingIdentity.mrn = updatedIdentity.mrn
            existingIdentity.gender = updatedIdentity.gender
            existingIdentity.dateOfBirth = updatedIdentity.dateOfBirth
            existingIdentity.active = true
            existingIdentity.createdBy = USER
            existingIdentity.endDate = null
            existingIdentity.modifiedBy = ""
            existingIdentity.createDate = now
            existingIdentity.id = null

            val activeIdentity : Identity = save(existingIdentity)

            updateIdentityMaps(activeIdentity, updatedIdentity.id!!, now)

            return true
        }

        return false
    }

    fun getIdentityMaps(): List<IdentityMap> {
        return identityMapRepository.findAllByOrderByIdAsc()
    }

    fun updateIdentityMap(id: Long, newIdentityId: Long): Boolean {
        if(!identityRepository.existsById(newIdentityId)) {
            return false
        }

        if(!identityMapRepository.existsById(id)) {
            return false
        }

        val newIdentity = identityRepository.findById(newIdentityId).get()
        val identityMap = identityMapRepository.findById(id).get()

        createIdentityMapHistoryEntry(identityMap.id, identityMap.identity?.id, newIdentity.id, LocalDateTime.now(), MERGE)

        identityMap.identity = newIdentity

        save(identityMap)

        return true
    }

    fun getIdentityMapHistories(): List<IdentityMapHistory> {
        return identityMapHistoryRepository.findAll().toList()
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
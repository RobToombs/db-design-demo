package com.toombs.backend.identity.services

import com.toombs.backend.identity.entities.active.Identity
import com.toombs.backend.identity.repositories.history.IdentityHistoryRepository
import org.springframework.stereotype.Service

@Service
class IdentityHistoryService(
    private val identityHistoryRepository: IdentityHistoryRepository,
) {

    fun retireIdentity(identity: Identity) {

    }

}
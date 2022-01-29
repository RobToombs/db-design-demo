package com.toombs.backend.identity.repositories.history

import com.toombs.backend.identity.entities.history.IdentityHistory
import org.springframework.data.repository.CrudRepository

interface IdentityHistoryRepository : CrudRepository<IdentityHistory, Long> {
    fun findAllByOrderByIdAsc(): List<IdentityHistory>
    fun findAllByTrxIdOrderByCreateDateAsc(trxId: String): List<IdentityHistory>
}
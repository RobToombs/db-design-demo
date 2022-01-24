package com.toombs.backend.identity.repositories.active

import com.toombs.backend.identity.entities.active.Identity
import org.springframework.data.repository.CrudRepository
import java.util.*

interface IdentityRepository : CrudRepository<Identity, Long> {
    fun existsByIdAndActiveIsTrue(id: Long) : Boolean
    fun findByIdAndActiveIsTrue(id: Long) : Identity
    fun findAllByOrderByIdAsc() : List<Identity>
    fun findAllByOrderByPatientLastAsc(): List<Identity>
    fun findByActiveIsTrueOrderByPatientLastAsc(): List<Identity>
    fun existsByIdAndActiveIsFalse(id: Long) : Boolean
    fun findByIdAndActiveIsFalseAndEndDateIsNull(id: Long) : Identity
    fun findFirstByTrxId(trxId: String): Optional<Identity>
    fun findFirstByActiveIsTrueAndUpi(upi: String): Optional<Identity>
    fun findByActiveIsFalseAndUpi(upi: String): Optional<Identity>
    fun findByTrxId(trxId: String): Identity
}
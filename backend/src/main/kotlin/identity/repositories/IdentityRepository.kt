package com.toombs.backend.identity.repositories

import com.toombs.backend.identity.entities.Identity
import org.springframework.data.repository.CrudRepository
import java.util.*

interface IdentityRepository : CrudRepository<Identity, Long> {
    fun existsByIdAndActiveIsTrue(id: Long) : Boolean
    fun findByIdAndActiveIsTrue(id: Long) : Identity
    fun findAllByOrderByIdAsc() : List<Identity>
    fun findByActiveIsTrueOrderByPatientLastAsc(): List<Identity>
    fun existsByIdAndActiveIsFalseAndEndDateIsNull(id: Long) : Boolean
    fun findByIdAndActiveIsFalseAndEndDateIsNull(id: Long) : Identity
    fun findFirstByActiveIsTrueAndTrxId(trxId: String): Optional<Identity>
    fun findFirstByActiveIsTrueAndUpi(upi: String): Optional<Identity>
    fun findByActiveIsFalseAndUpiAndEndDateIsNull(upi: String): Optional<Identity>
}
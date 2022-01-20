package com.toombs.backend.identity.repositories.active

import com.toombs.backend.identity.entities.active.Identity
import org.springframework.data.repository.CrudRepository
import java.util.*

interface IdentityRepository : CrudRepository<Identity, Long> {
    fun existsByIdAndActiveIsTrueAndDoneIsFalse(id: Long) : Boolean
    fun findByIdAndActiveIsTrueAndDoneIsFalse(id: Long) : Identity
    fun findAllByOrderByIdAsc() : List<Identity>
    fun findAllByDoneIsFalseOrderByPatientLastAsc(): List<Identity>
    fun findByActiveIsTrueAndDoneIsFalseOrderByPatientLastAsc(): List<Identity>
    fun existsByIdAndActiveIsFalseAndDoneIsFalse(id: Long) : Boolean
    fun findByIdAndActiveIsFalseAndEndDateIsNull(id: Long) : Identity
    fun findFirstByActiveIsTrueAndDoneIsFalseAndTrxId(trxId: String): Optional<Identity>
    fun findFirstByActiveIsTrueAndDoneIsFalseAndUpi(upi: String): Optional<Identity>
    fun findByActiveIsFalseAndDoneIsFalseAndUpi(upi: String): Optional<Identity>
    fun findAllByTrxIdOrderByCreateDateAsc(trxId: String): List<Identity>
}
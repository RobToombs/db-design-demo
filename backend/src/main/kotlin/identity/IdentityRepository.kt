package com.toombs.backend.identity

import org.springframework.data.repository.CrudRepository

interface IdentityRepository : CrudRepository<Identity, Long> {
    fun existsByIdAndActiveIsTrue(id: Long) : Boolean
    fun findByIdAndActiveIsTrue(id: Long) : Identity
    fun findAllByOrderByIdAsc() : List<Identity>
    fun findByActiveIsTrueOrderByPatientLastAsc(): List<Identity>
    fun existsByIdAndActiveIsFalseAndEndDateIsNull(id: Long) : Boolean
    fun findByIdAndActiveIsFalseAndEndDateIsNull(id: Long) : Identity
}
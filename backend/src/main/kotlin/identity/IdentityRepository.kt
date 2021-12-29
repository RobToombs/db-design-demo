package com.toombs.backend.identity

import org.springframework.data.repository.CrudRepository

interface IdentityRepository : CrudRepository<Identity, Long> {
    fun findAllByOrderByIdAsc() : List<Identity>
}
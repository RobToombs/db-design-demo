package com.toombs.backend.identity

import org.springframework.data.repository.CrudRepository

interface IdentityMapRepository : CrudRepository<IdentityMap, Long> {
    fun findAllByOrderByIdAsc() : List<IdentityMap>
    fun findAllByIdentityId(identityId : Long) : List<IdentityMap>
}
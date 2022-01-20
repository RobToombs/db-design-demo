package com.toombs.backend.identity.repositories.active

import com.toombs.backend.identity.entities.active.IdentityMap
import org.springframework.data.repository.CrudRepository

interface IdentityMapRepository : CrudRepository<IdentityMap, Long> {
    fun findAllByOrderByIdAsc() : List<IdentityMap>
    fun findAllByIdentityId(identityId : Long) : List<IdentityMap>
    fun findFirstByIdentityId(identityId: Long) : IdentityMap
    fun existsByIdentityId(identityId: Long) : Boolean
}
package com.toombs.backend.refill

import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.CrudRepository

interface RefillRepository : CrudRepository<Refill, Long> {
    fun findAllByOrderByIdAsc() : List<Refill>

    @Modifying
    @Query(value = "UPDATE refill r " +
            "SET active = true, identity_id = null " +
            "FROM identity_map im " +
            "WHERE r.identity_map_id in :mapIds",
        nativeQuery = true)
    fun activate(mapIds: List<Long>)

    @Modifying
    @Query(value = "UPDATE refill r " +
            "SET active = false, identity_id = i.id " +
            "FROM identity_map im " +
            "JOIN identity i ON im.identity_id = i.id " +
            "WHERE r.identity_map_id in :mapIds",
        nativeQuery = true)
    fun deactivate(mapIds: List<Long>)
}
package com.toombs.backend.refill

import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.CrudRepository

interface RefillRepository : CrudRepository<Refill, Long> {
    fun findAllByOrderByIdAsc() : List<Refill>

    @Query("SELECT * FROM refill r " +
            "JOIN identity_map im ON r.identity_map_id = im.id " +
            "WHERE r.active = FALSE AND r.identity_history_id IS NULL AND im.id IN :mapIds",
        nativeQuery = true)
    fun findFinishedWithoutHistorical(mapIds: List<Long>): List<Refill>

    @Query("SELECT * FROM refill r " +
            "JOIN identity_map im ON r.identity_map_id = im.id " +
            "WHERE r.active = TRUE AND im.id IN :mapIds",
        nativeQuery = true)
    fun findActive(mapIds: List<Long>): List<Refill>
}
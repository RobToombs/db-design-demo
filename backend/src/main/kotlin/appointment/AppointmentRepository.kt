package com.toombs.backend.appointment

import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.CrudRepository


interface AppointmentRepository : CrudRepository<Appointment, Long> {
    fun findAllByOrderByIdAsc() : List<Appointment>

    @Query("SELECT * FROM appointment a " +
            "JOIN identity_map im ON a.identity_map_id = im.id " +
            "WHERE a.active = FALSE AND a.identity_history_id IS NULL AND im.id IN :mapIds",
        nativeQuery = true)
    fun findFinishedWithoutHistorical(mapIds: List<Long>): List<Appointment>

    @Query("SELECT * FROM appointment a " +
            "JOIN identity_map im ON a.identity_map_id = im.id " +
            "WHERE a.active = TRUE AND im.id IN :mapIds",
        nativeQuery = true)
    fun findActive(mapIds: List<Long>): List<Appointment>
}
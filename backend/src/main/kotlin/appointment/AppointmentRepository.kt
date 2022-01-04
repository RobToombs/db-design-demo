package com.toombs.backend.appointment

import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.CrudRepository


interface AppointmentRepository : CrudRepository<Appointment, Long> {
    fun findAllByOrderByIdAsc() : List<Appointment>

    @Query("SELECT * FROM appointment a " +
            "JOIN identity_map im ON a.identity_map_id = im.id " +
            "WHERE a.active = FALSE AND im.id IN :mapIds AND a.identity_id IN :identityIds",
        nativeQuery = true)
    fun findDeactive(mapIds: List<Long>, identityIds: List<Long>): List<Appointment>

    @Query("SELECT * FROM appointment a " +
            "JOIN identity_map im ON a.identity_map_id = im.id " +
            "WHERE a.active = TRUE AND im.id IN :mapIds",
        nativeQuery = true)
    fun findActive(mapIds: List<Long>): List<Appointment>
}
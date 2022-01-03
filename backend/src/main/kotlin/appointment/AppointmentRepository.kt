package com.toombs.backend.appointment

import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.CrudRepository


interface AppointmentRepository : CrudRepository<Appointment, Long> {
    fun findAllByOrderByIdAsc() : List<Appointment>

    @Modifying
    @Query(value = "UPDATE appointment a " +
            "SET active = true, identity_id = null " +
            "FROM identity_map im " +
            "WHERE a.identity_map_id in :mapIds",
        nativeQuery = true)
    fun activate(mapIds: List<Long>)

    @Modifying
    @Query(value = "UPDATE appointment a " +
            "SET active = false, identity_id = i.id " +
            "FROM identity_map im " +
            "JOIN identity i ON im.identity_id = i.id " +
            "WHERE a.identity_map_id in :mapIds",
        nativeQuery = true)
    fun deactivate(mapIds: List<Long>)
}
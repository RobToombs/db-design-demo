package com.toombs.backend.appointment

import org.springframework.data.repository.CrudRepository

interface AppointmentRepository : CrudRepository<Appointment, Long> {
    fun findAllByOrderByIdAsc() : List<Appointment>
}
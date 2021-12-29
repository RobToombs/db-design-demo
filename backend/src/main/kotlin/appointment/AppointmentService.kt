package com.toombs.backend.appointment

import org.springframework.stereotype.Service

@Service
class AppointmentService(
    private val appointmentRepository: AppointmentRepository
) {
    fun getAppointments() : List<Appointment> {
        return appointmentRepository.findAll().toList()
    }
}
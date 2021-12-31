package com.toombs.backend.appointment

import com.toombs.backend.identity.IdentityService
import org.springframework.stereotype.Service
import javax.transaction.Transactional

@Service
class AppointmentService(
    private val appointmentRepository: AppointmentRepository,
    private val identityService: IdentityService,
) {
    fun getAppointments() : List<Appointment> {
        return appointmentRepository.findAll().toList()
    }

    fun addAppointment(newAppt: Appointment) : Appointment {
        val identityMap = identityService.findOrCreateActiveIdentityMap(newAppt.identityMap)

        val appt = Appointment()
        appt.date = newAppt.date
        appt.medication = newAppt.medication
        appt.identityMap = identityMap

        return save(appt)
    }

    @Transactional
    fun save(appointment: Appointment): Appointment {
        return appointmentRepository.save(appointment)
    }
}
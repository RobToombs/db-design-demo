package com.toombs.backend.appointment

import com.toombs.backend.identity.entities.Identity
import com.toombs.backend.identity.entities.IdentityMap
import org.springframework.stereotype.Service
import javax.transaction.Transactional

@Service
class AppointmentService(
    private val appointmentRepository: AppointmentRepository
) {
    fun getAppointments() : List<Appointment> {
        return appointmentRepository.findAllByOrderByIdAsc()
    }

    fun addAppointment(newAppt: Appointment, identityMap: IdentityMap?) : Appointment {
        val appt = Appointment()
        appt.date = newAppt.date
        appt.medication = newAppt.medication
        appt.identityMap = identityMap

        return save(appt)
    }

    fun finishAppointment(id: Long): Boolean {
        val exists = appointmentRepository.existsById(id)
        if(exists) {
            val appt = appointmentRepository.findById(id).get()
            if(appt.active) {
                appt.active = false
                appt.finalIdentity = appt.identityMap?.identity
                save(appt)

                return true
            }
        }

        return false
    }

    fun deactivate(identityMaps: List<IdentityMap>, finalId: Identity) {
        val mapIds = identityMaps
            .mapNotNull { it.id }
            .toList()

        val appts = appointmentRepository.findActive(mapIds)
        for(appt in appts) {
            appt.active = false
            appt.finalIdentity = finalId
        }
        save(appts)
    }

    @Transactional
    fun save(appointment: Appointment): Appointment {
        return appointmentRepository.save(appointment)
    }

    @Transactional
    fun save(appointments: List<Appointment>): List<Appointment> {
        return appointmentRepository.saveAll(appointments).toList()
    }
}
package com.toombs.backend.appointment

import com.toombs.backend.identity.IdentityMap
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

    @Transactional
    fun activate(mapIds: List<Long>) {
        appointmentRepository.activate(mapIds)
    }

    @Transactional
    fun deactivate(mapIds: List<Long>) {
        appointmentRepository.deactivate(mapIds)
    }

    @Transactional
    fun save(appointment: Appointment): Appointment {
        return appointmentRepository.save(appointment)
    }
}
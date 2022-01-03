package com.toombs.backend.appointment

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api")
class AppointmentController (
    private val appointmentService: AppointmentService
) {

    @GetMapping("/appointments")
    fun appointments(): ResponseEntity<List<Appointment>> {
        val appointments = appointmentService.getAppointments()
        return ResponseEntity(appointments, HttpStatus.OK)
    }

    @PutMapping("/appointments/add")
    fun addAppointment(@RequestBody appointment: Appointment): ResponseEntity<Boolean> {
        appointmentService.addAppointment(appointment)
        return ResponseEntity(true, HttpStatus.CREATED)
    }

    @PutMapping("/appointments/finish/{id}")
    fun finishAppointment(@PathVariable id: Long): ResponseEntity<Boolean> {
        val finished = appointmentService.finishAppointment(id)
        return ResponseEntity(finished, HttpStatus.OK)
    }
}
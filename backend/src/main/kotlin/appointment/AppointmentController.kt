package com.toombs.backend.appointment

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

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

    @GetMapping("/appointments/add")
    fun addAppointment(@RequestBody appointment: Appointment): ResponseEntity<Boolean> {
        val updated = appointmentService.addAppointment(appointment)
        return ResponseEntity(updated, HttpStatus.CREATED)
    }
}
package com.toombs.backend.etl

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api")
class EtlController(
    private val etlService: EtlService,
) {

    @PutMapping("/reset")
    fun resetDatabase(): ResponseEntity<Boolean> {
        val reset = etlService.resetDatabase();
        return ResponseEntity(reset, HttpStatus.OK)
    }

    @PutMapping("/etl")
    fun processAppointmentEtl(): ResponseEntity<Boolean> {
        val processed = etlService.processAppointmentEtl();
        return ResponseEntity(processed, HttpStatus.OK)
    }

}
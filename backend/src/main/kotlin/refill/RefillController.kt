package com.toombs.backend.refill

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api")
class RefillController(
    private val refillService: RefillService
) {

    @GetMapping("/refills")
    fun refills(): ResponseEntity<List<Refill>> {
        val refills = refillService.getRefills()
        return ResponseEntity(refills, HttpStatus.OK)
    }

}
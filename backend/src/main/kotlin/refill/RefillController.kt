package com.toombs.backend.refill

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

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

    @PutMapping("/refills/add")
    fun addRefill(@RequestBody refill: Refill): ResponseEntity<Boolean> {
        refillService.addRefill(refill)
        return ResponseEntity(true, HttpStatus.CREATED)
    }

}
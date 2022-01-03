package com.toombs.backend.refill

import com.toombs.backend.identity.IdentityService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api")
class RefillController(
    private val refillService: RefillService,
    private val identityService: IdentityService
) {

    @GetMapping("/refills")
    fun refills(): ResponseEntity<List<Refill>> {
        val refills = refillService.getRefills()
        return ResponseEntity(refills, HttpStatus.OK)
    }

    @PutMapping("/refills/add")
    fun addRefill(@RequestBody refill: Refill): ResponseEntity<Boolean> {
        val identityMap = identityService.findOrCreateActiveIdentityMap(refill.identityMap)
        refillService.addRefill(refill, identityMap)
        return ResponseEntity(true, HttpStatus.CREATED)
    }

    @PutMapping("/refills/finish/{id}")
    fun finishRefill(@PathVariable id: Long): ResponseEntity<Boolean> {
        val finished = refillService.finishRefill(id)
        return ResponseEntity(finished, HttpStatus.OK)
    }
}
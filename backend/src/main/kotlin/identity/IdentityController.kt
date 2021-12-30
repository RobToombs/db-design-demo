package com.toombs.backend.identity

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api")
class IdentityController(
    private val identityService: IdentityService
) {
    @GetMapping("/identities")
    fun identities(): ResponseEntity<List<Identity>> {
        val identities = identityService.getIdentities()
        return ResponseEntity(identities, HttpStatus.OK)
    }

    @GetMapping("/identities/active")
    fun activeIdentities(): ResponseEntity<List<Identity>> {
        val identities = identityService.getActiveIdentities()
        return ResponseEntity(identities, HttpStatus.OK)
    }

    @PutMapping("/identities/update")
    fun updateIdentity(@RequestBody identity: Identity): ResponseEntity<Boolean> {
        val updated = identityService.updateIdentity(identity)
        return ResponseEntity(updated, HttpStatus.CREATED)
    }

    @GetMapping("/identity-maps")
    fun identityMaps(): ResponseEntity<List<IdentityMap>> {
        val identityMaps = identityService.getIdentityMaps()
        return ResponseEntity(identityMaps, HttpStatus.OK)
    }

    @PutMapping("/identity-maps/update/{id}")
    fun updateIdentityMap(@PathVariable id : Long, @RequestBody newIdentityId: Long): ResponseEntity<Boolean> {
        val updated = identityService.updateIdentityMap(id, newIdentityId)
        return ResponseEntity(updated, HttpStatus.CREATED)
    }

    @GetMapping("/identity-map-histories")
    fun identityMapHistories(): ResponseEntity<List<IdentityMapHistory>> {
        val identityMapHistories = identityService.getIdentityMapHistories()
        return ResponseEntity(identityMapHistories, HttpStatus.OK)
    }
}
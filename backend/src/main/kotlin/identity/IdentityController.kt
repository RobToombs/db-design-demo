package com.toombs.backend.identity

import com.toombs.backend.identity.entities.Identity
import com.toombs.backend.identity.entities.IdentityMap
import com.toombs.backend.identity.entities.IdentityMapHistory
import com.toombs.backend.identity.services.IdentityService
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

    @PutMapping("/identities/activate/{id}")
    fun activateIdentity(@PathVariable id: Long): ResponseEntity<Boolean> {
        val activated = identityService.activateIdentity(id)
        return ResponseEntity(activated, HttpStatus.OK)
    }

    @PutMapping("/identities/deactivate/{id}")
    fun deactivateIdentity(@PathVariable id: Long): ResponseEntity<Boolean> {
        val deactivated = identityService.deactivateIdentity(id)
        return ResponseEntity(deactivated, HttpStatus.OK)
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

    @PutMapping("/identities/add")
    fun addIdentity(@RequestBody identity: Identity): ResponseEntity<Boolean> {
        val result = identityService.addIdentity(identity)
        return ResponseEntity(result != null, HttpStatus.CREATED)
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
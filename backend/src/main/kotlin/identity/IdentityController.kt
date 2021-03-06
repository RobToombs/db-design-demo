package com.toombs.backend.identity

import com.toombs.backend.identity.entities.active.Identity
import com.toombs.backend.identity.entities.active.IdentityMap
import com.toombs.backend.identity.entities.audit.Audit
import com.toombs.backend.identity.entities.history.IdentityHistory
import com.toombs.backend.identity.entities.history.IdentityMapHistory
import com.toombs.backend.identity.services.IdentityHistoryService
import com.toombs.backend.identity.services.IdentityService
import com.toombs.backend.identity.services.randomUser
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import org.springframework.web.servlet.support.ServletUriComponentsBuilder
import java.net.URI


@RestController
@RequestMapping("/api")
class IdentityController(
    private val identityService: IdentityService,
    private val identityHistoryService: IdentityHistoryService,
) {
    @GetMapping("/identities/current")
    fun currentIdentities(): ResponseEntity<List<Identity>> {
        val identities = identityService.getCurrentIdentities()
        return ResponseEntity(identities, HttpStatus.OK)
    }

    @GetMapping("/identities/audit/{id}")
    fun identityAudit(@PathVariable id: Long): ResponseEntity<List<Audit>> {
        val auditTrail = identityService.getAuditTrail(id)
        return ResponseEntity(auditTrail, HttpStatus.OK)
    }

    @PutMapping("/identities/activate/{id}")
    fun activateIdentity(@PathVariable id: Long): ResponseEntity<Boolean> {
        val activated = identityService.reactivateIdentityFromApp(id)
        return ResponseEntity(activated, HttpStatus.OK)
    }

    @PutMapping("/identities/deactivate/{id}")
    fun deactivateIdentity(@PathVariable id: Long): ResponseEntity<Boolean> {
        val deactivated = identityService.deactivateIdentity(id)
        return ResponseEntity(deactivated, HttpStatus.OK)
    }

    @GetMapping("/identities/historical")
    fun historicalIdentities(): ResponseEntity<List<IdentityHistory>> {
        val identities = identityHistoryService.getHistoricalIdentities()
        return ResponseEntity(identities, HttpStatus.OK)
    }

    @GetMapping("/identities/active")
    fun activeIdentities(): ResponseEntity<List<Identity>> {
        val identities = identityService.getActiveIdentities()
        return ResponseEntity(identities, HttpStatus.OK)
    }

    @PutMapping("/identities/update")
    fun updateIdentity(@RequestBody identity: Identity): ResponseEntity<Void> {
        val updated = identityService.updateIdentity(identity)
        return if(updated) {
            ResponseEntity.ok().build()
        } else {
            ResponseEntity.noContent().build()
        }
    }

    @PutMapping("/identities/refresh")
    fun refreshIdentityUpis(): ResponseEntity<Boolean> {
        val updated = identityService.refreshUPIs()
        return ResponseEntity(updated, HttpStatus.OK)
    }

    @PostMapping("/identities/add")
    fun addIdentity(@RequestBody identity: Identity): ResponseEntity<Identity> {
        val user = randomUser()
        val result = identityService.addIdentity(identity, user)

        val location: URI = ServletUriComponentsBuilder
            .fromCurrentRequest()
            .path("/{id}")
            .buildAndExpand(result?.identity?.id ?: -1)
            .toUri()

        return if (result != null) {
            ResponseEntity.created(location).body(result.identity)
        } else {
            ResponseEntity.badRequest().build()
        }
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
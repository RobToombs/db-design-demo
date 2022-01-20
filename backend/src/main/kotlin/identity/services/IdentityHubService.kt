package com.toombs.backend.identity.services

import com.toombs.backend.appointment.AppointmentService
import com.toombs.backend.identity.entities.Identity
import com.toombs.backend.identity.entities.IdentityMap
import com.toombs.backend.refill.RefillService
import org.springframework.stereotype.Service

@Service
class IdentityHubService(
    private val appointmentService: AppointmentService,
    private val refillService: RefillService,
) {

    fun deactivateMappedActivities(mappings: List<IdentityMap>, finalId: Identity) {
        appointmentService.deactivate(mappings, finalId)
        refillService.deactivate(mappings, finalId)
    }

}
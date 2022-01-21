package com.toombs.backend.identity.services

import com.toombs.backend.appointment.AppointmentService
import com.toombs.backend.identity.entities.active.Identity
import com.toombs.backend.identity.entities.active.IdentityMap
import com.toombs.backend.identity.entities.history.IdentityHistory
import com.toombs.backend.refill.RefillService
import org.springframework.stereotype.Service

@Service
class IdentityHubService(
    private val appointmentService: AppointmentService,
    private val refillService: RefillService,
) {
    fun initializeIdentityHistories(mappings: List<IdentityMap>, finalId: IdentityHistory) {
        appointmentService.initializeIdentityHistories(mappings, finalId)
        refillService.initializeIdentityHistories(mappings, finalId)
    }

    fun deactivateMappedActivities(mappings: List<IdentityMap>, finalId: IdentityHistory) {
        appointmentService.deactivate(mappings, finalId)
        refillService.deactivate(mappings, finalId)
    }
}
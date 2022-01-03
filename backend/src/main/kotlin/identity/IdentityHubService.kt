package com.toombs.backend.identity

import com.toombs.backend.appointment.AppointmentService
import com.toombs.backend.refill.RefillService
import org.springframework.stereotype.Service

@Service
class IdentityHubService(
    private val appointmentService: AppointmentService,
    private val refillService: RefillService,
) {

    fun activateMappedActivities(mappings: List<IdentityMap>) {
        val mapIds: List<Long> = mappings
            .mapNotNull { it.id }
            .toList()

        appointmentService.activate(mapIds)
        refillService.activate(mapIds)
    }

    fun deactivateMappedActivities(mappings: List<IdentityMap>) {
        val mapIds: List<Long> = mappings
            .mapNotNull { it.id }
            .toList()

        appointmentService.deactivate(mapIds)
        refillService.deactivate(mapIds)
    }

}
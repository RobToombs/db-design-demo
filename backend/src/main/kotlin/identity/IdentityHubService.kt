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
        appointmentService.activate(mappings)
        refillService.activate(mappings)
    }

    fun deactivateMappedActivities(mappings: List<IdentityMap>) {
        appointmentService.deactivate(mappings)
        refillService.deactivate(mappings)
    }

}
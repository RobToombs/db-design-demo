package com.toombs.backend.refill

import com.toombs.backend.appointment.Appointment
import com.toombs.backend.identity.IdentityService
import org.springframework.stereotype.Service

@Service
class RefillService(
    private val refillRepository: RefillRepository,
    private val identityService: IdentityService,
) {
    fun getRefills() : List<Refill> {
        return refillRepository.findAll().toList()
    }

    fun addRefill(newRefill: Refill) : Refill {
        val identityMap = identityService.findOrCreateActiveIdentityMap(newRefill.identityMap)

        val refill = Refill()
        refill.date = newRefill.date
        refill.medication = newRefill.medication
        refill.callAttempts = newRefill.callAttempts
        refill.identityMap = identityMap

        return save(refill)
    }

    private fun save(refill: Refill): Refill {
        return refillRepository.save(refill)
    }
}
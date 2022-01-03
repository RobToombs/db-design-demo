package com.toombs.backend.refill

import com.toombs.backend.identity.IdentityMap
import org.springframework.stereotype.Service
import javax.transaction.Transactional

@Service
class RefillService(
    private val refillRepository: RefillRepository
) {
    fun getRefills() : List<Refill> {
        return refillRepository.findAllByOrderByIdAsc()
    }

    fun addRefill(newRefill: Refill, identityMap: IdentityMap?) : Refill {
        val refill = Refill()
        refill.date = newRefill.date
        refill.medication = newRefill.medication
        refill.callAttempts = newRefill.callAttempts
        refill.identityMap = identityMap

        return save(refill)
    }

    fun finishRefill(id: Long): Boolean {
        val exists = refillRepository.existsById(id)
        if(exists) {
            val refill = refillRepository.findById(id).get()
            if(refill.active) {
                refill.active = false
                refill.finalIdentity = refill.identityMap?.identity
                save(refill)

                return true
            }
        }

        return false
    }

    @Transactional
    fun activate(mapIds: List<Long>) {
        refillRepository.activate(mapIds)
    }

    @Transactional
    fun deactivate(mapIds: List<Long>) {
        refillRepository.deactivate(mapIds)
    }

    @Transactional
    fun save(refill: Refill): Refill {
        return refillRepository.save(refill)
    }
}
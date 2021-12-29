package com.toombs.backend.refill

import org.springframework.stereotype.Service

@Service
class RefillService(
    private val refillRepository: RefillRepository
) {
    fun getRefills() : List<Refill> {
        return refillRepository.findAll().toList()
    }
}
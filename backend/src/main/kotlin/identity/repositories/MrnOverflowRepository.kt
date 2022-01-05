package com.toombs.backend.identity.repositories

import com.toombs.backend.identity.entities.MrnOverflow
import org.springframework.data.repository.CrudRepository

interface MrnOverflowRepository : CrudRepository<MrnOverflow, Long> {
}
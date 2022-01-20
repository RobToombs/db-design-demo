package com.toombs.backend.identity.repositories.active

import com.toombs.backend.identity.entities.active.MrnOverflow
import org.springframework.data.repository.CrudRepository

interface MrnOverflowRepository : CrudRepository<MrnOverflow, Long> {
}
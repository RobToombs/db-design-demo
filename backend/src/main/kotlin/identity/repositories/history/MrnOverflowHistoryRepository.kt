package com.toombs.backend.identity.repositories.history

import com.toombs.backend.identity.entities.history.MrnOverflowHistory
import org.springframework.data.repository.CrudRepository

interface MrnOverflowHistoryRepository : CrudRepository<MrnOverflowHistory, Long> {
}
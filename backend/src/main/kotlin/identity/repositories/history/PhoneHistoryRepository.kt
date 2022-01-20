package com.toombs.backend.identity.repositories.history

import com.toombs.backend.identity.entities.history.PhoneHistory
import org.springframework.data.repository.CrudRepository

interface PhoneHistoryRepository : CrudRepository<PhoneHistory, Long> {
}
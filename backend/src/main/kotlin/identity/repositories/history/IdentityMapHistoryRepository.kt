package com.toombs.backend.identity.repositories.history

import com.toombs.backend.identity.entities.history.IdentityMapHistory
import org.springframework.data.repository.CrudRepository

interface IdentityMapHistoryRepository : CrudRepository<IdentityMapHistory, Long>
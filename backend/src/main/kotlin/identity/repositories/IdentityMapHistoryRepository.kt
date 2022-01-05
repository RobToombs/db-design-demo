package com.toombs.backend.identity.repositories

import com.toombs.backend.identity.entities.IdentityMapHistory
import org.springframework.data.repository.CrudRepository

interface IdentityMapHistoryRepository : CrudRepository<IdentityMapHistory, Long>
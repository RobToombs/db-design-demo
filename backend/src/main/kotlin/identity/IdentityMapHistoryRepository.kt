package com.toombs.backend.identity

import org.springframework.data.repository.CrudRepository

interface IdentityMapHistoryRepository : CrudRepository<IdentityMapHistory, Long>
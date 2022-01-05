package com.toombs.backend.identity.repositories

import com.toombs.backend.identity.entities.Phone
import org.springframework.data.repository.CrudRepository

interface PhoneRepository : CrudRepository<Phone, Long> {
}
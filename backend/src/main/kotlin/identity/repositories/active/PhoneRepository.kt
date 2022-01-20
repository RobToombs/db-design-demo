package com.toombs.backend.identity.repositories.active

import com.toombs.backend.identity.entities.active.Phone
import org.springframework.data.repository.CrudRepository

interface PhoneRepository : CrudRepository<Phone, Long> {
}
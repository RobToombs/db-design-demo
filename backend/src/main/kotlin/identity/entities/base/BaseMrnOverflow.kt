package com.toombs.backend.identity.entities.base

import javax.persistence.*

@MappedSuperclass
abstract class BaseMrnOverflow(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    var mrn: String = "",
)

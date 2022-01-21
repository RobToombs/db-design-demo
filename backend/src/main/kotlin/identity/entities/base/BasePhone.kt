package com.toombs.backend.identity.entities.base

import javax.persistence.*

@MappedSuperclass
abstract class BasePhone (
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    var number: String = "",

    var type: String = "",
)
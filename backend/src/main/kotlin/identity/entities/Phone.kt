package com.toombs.backend.identity.entities

import javax.persistence.*


@Entity
class Phone (
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    var identityId: Long? = null,

    var number: String = "",

    var type: String = "",
)
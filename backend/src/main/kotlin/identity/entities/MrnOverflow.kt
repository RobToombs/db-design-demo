package com.toombs.backend.identity.entities

import javax.persistence.*

@Entity
class MrnOverflow (
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    var identityId: Long? = null,

    var mrn: String = "",
)
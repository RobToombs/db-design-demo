package com.toombs.backend.identity.entities

import javax.persistence.*

@Entity
class MrnOverflow (
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "identity_id")
    var identity: Identity? = null,

    var mrn: String = "",
)
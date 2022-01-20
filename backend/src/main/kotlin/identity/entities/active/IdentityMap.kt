package com.toombs.backend.identity.entities.active

import javax.persistence.*

@Entity
data class IdentityMap(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.EAGER, cascade = [CascadeType.ALL], optional = false)
    @JoinColumn(name = "identity_id")
    var identity: Identity? = null,
)

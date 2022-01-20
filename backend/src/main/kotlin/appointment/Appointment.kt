package com.toombs.backend.appointment

import com.fasterxml.jackson.annotation.JsonFormat
import com.toombs.backend.identity.entities.active.Identity
import com.toombs.backend.identity.entities.active.IdentityMap
import java.time.LocalDate
import javax.persistence.*

@Entity
data class Appointment(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.EAGER, cascade = [CascadeType.ALL], optional = true)
    @JoinColumn(name = "identity_id")
    var finalIdentity: Identity? = null,

    @ManyToOne(fetch = FetchType.EAGER, cascade = [CascadeType.ALL], optional = false)
    @JoinColumn(name = "identity_map_id")
    var identityMap: IdentityMap? = null,

    @JsonFormat(pattern="yyyy-MM-dd")
    var date: LocalDate? = null,

    var medication: String = "",

    var active: Boolean = true,
)

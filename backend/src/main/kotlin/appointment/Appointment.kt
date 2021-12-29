package com.toombs.backend.appointment

import com.fasterxml.jackson.annotation.JsonFormat
import com.toombs.backend.identity.IdentityMap
import java.time.LocalDate
import javax.persistence.*

@Entity
data class Appointment(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.EAGER, cascade = [CascadeType.ALL], optional = false)
    @JoinColumn(name = "identity_map_id")
    val IdentityMap: IdentityMap? = null,

    @JsonFormat(pattern="yyyy-MM-dd")
    val date: LocalDate? = null,

    val medication: String = "",
)

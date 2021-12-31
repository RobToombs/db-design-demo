package com.toombs.backend.refill

import com.fasterxml.jackson.annotation.JsonFormat
import com.toombs.backend.identity.IdentityMap
import java.time.LocalDate
import javax.persistence.*

@Entity
data class Refill(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.EAGER, cascade = [CascadeType.ALL], optional = false)
    @JoinColumn(name = "identity_map_id")
    var identityMap: IdentityMap? = null,

    @JsonFormat(pattern="yyyy-MM-dd")
    var date: LocalDate? = null,

    var callAttempts: Int = 0,

    var medication: String = "",
)

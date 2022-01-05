package com.toombs.backend.identity.entities

import com.fasterxml.jackson.annotation.JsonFormat
import java.time.LocalDate
import java.time.LocalDateTime
import javax.persistence.*

@Entity
data class Identity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    var upi: String = "",

    var mrn: String = "",

    var patientLast: String = "",

    var patientFirst: String = "",

    @JsonFormat(pattern="yyyy-MM-dd")
    var dateOfBirth: LocalDate? = null,

    var gender: String = "",

    var active: Boolean = false,

    @JsonFormat(pattern="yyyy-MM-dd HH:mm:ss")
    var createDate: LocalDateTime? = null,

    @JsonFormat(pattern="yyyy-MM-dd HH:mm:ss")
    var endDate: LocalDateTime? = null,

    var createdBy: String = "",

    var modifiedBy: String = "",

    @OneToMany(mappedBy = "identity", fetch = FetchType.LAZY, cascade = [CascadeType.ALL], orphanRemoval = true)
    var phones: List<Phone> = ArrayList(),

    @OneToMany(mappedBy = "identity", fetch = FetchType.LAZY, cascade = [CascadeType.ALL], orphanRemoval = true)
    var mrnOverflow: List<MrnOverflow> = ArrayList(),
)

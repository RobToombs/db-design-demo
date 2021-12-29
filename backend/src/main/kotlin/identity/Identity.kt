package com.toombs.backend.identity

import com.fasterxml.jackson.annotation.JsonFormat
import java.time.LocalDate
import java.time.LocalDateTime
import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.GenerationType
import javax.persistence.Id

@Entity
data class Identity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    val upi: String = "",

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
)

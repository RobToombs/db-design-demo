package com.toombs.backend.identity.entities.base

import com.fasterxml.jackson.annotation.JsonFormat
import java.time.LocalDate
import java.time.LocalDateTime
import javax.persistence.*

@MappedSuperclass
abstract class BaseIdentity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    var trxId: String = "",

    var upi: String = "",

    var mrn: String = "",

    var patientLast: String = "",

    var patientFirst: String = "",

    @get:JsonFormat(pattern="yyyy-MM-dd", shape = JsonFormat.Shape.STRING)
    var dateOfBirth: LocalDate? = null,

    var gender: String = "",

    var active: Boolean = false,

    @get:JsonFormat(pattern="yyyy-MM-dd HH:mm:ss", shape = JsonFormat.Shape.STRING)
    var createDate: LocalDateTime? = null,

    @get:JsonFormat(pattern="yyyy-MM-dd HH:mm:ss", shape = JsonFormat.Shape.STRING)
    var endDate: LocalDateTime? = null,

    var createdBy: String = "",

    var modifiedBy: String = "",
) {
    abstract fun phones(): List<BasePhone>
    abstract fun mrnOverflow(): List<BaseMrnOverflow>
}

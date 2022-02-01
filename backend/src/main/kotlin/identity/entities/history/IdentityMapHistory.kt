package com.toombs.backend.identity.entities.history

import com.fasterxml.jackson.annotation.JsonFormat
import org.springframework.data.annotation.Immutable
import java.time.LocalDateTime
import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.GenerationType
import javax.persistence.Id

@Entity
@Immutable
data class IdentityMapHistory(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @JsonFormat(pattern="yyyy-MM-dd HH:mm:ss")
    var createDate: LocalDateTime? = null,

    var identityMapId: Long? = null,

    var oldIdentityId: Long? = null,

    var newIdentityId: Long? = null,

    var event: String = "",
)

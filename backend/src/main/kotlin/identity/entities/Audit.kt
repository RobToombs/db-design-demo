package com.toombs.backend.identity.entities

import com.fasterxml.jackson.annotation.JsonFormat
import java.time.LocalDateTime

data class Audit(
    var createdBy: String,

    @JsonFormat(pattern="yyyy-MM-dd HH:mm:ss")
    var createDate: LocalDateTime,

    var event: DeltaEvent,

    var deltas: List<Delta>
)

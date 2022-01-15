package com.toombs.backend.identity.entities

data class Delta(
    var field: String,
    var old: String,
    var new: String,
    var event: DeltaEvent
)

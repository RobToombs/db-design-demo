package com.toombs.backend.identity.entities

data class UpiRefresh(
    val trxId: String,
    val upi: String,
)

package com.toombs.backend.identity.entities.etl

data class UpiRefresh(
    val trxId: String,
    val upi: String,
)

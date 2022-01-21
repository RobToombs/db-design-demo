package com.toombs.backend.identity.entities.active

import com.fasterxml.jackson.annotation.JsonIdentityInfo
import com.fasterxml.jackson.annotation.JsonIdentityReference
import com.fasterxml.jackson.annotation.ObjectIdGenerators
import com.toombs.backend.identity.entities.base.BaseMrnOverflow
import javax.persistence.*
import kotlin.jvm.Transient

@Entity
class MrnOverflow (
    @JsonIdentityInfo(generator = ObjectIdGenerators.PropertyGenerator::class, property = "id")
    @JsonIdentityReference(alwaysAsId = true)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "identity_id")
    var identity: Identity? = null,

    @Transient
    var delete: Boolean = false,
): BaseMrnOverflow()
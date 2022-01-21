package com.toombs.backend.identity.entities.history

import com.fasterxml.jackson.annotation.JsonIdentityInfo
import com.fasterxml.jackson.annotation.JsonIdentityReference
import com.fasterxml.jackson.annotation.ObjectIdGenerators
import com.toombs.backend.identity.entities.base.BaseMrnOverflow
import javax.persistence.*

@Entity
class MrnOverflowHistory(
    @JsonIdentityInfo(generator = ObjectIdGenerators.PropertyGenerator::class, property = "id")
    @JsonIdentityReference(alwaysAsId = true)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "identity_id")
    var identity: IdentityHistory? = null,
) : BaseMrnOverflow()
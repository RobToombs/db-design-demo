package com.toombs.backend.identity.entities.history

import com.fasterxml.jackson.annotation.*
import com.toombs.backend.identity.entities.base.BasePhone
import org.springframework.data.annotation.Immutable
import javax.persistence.*


@Entity
@Immutable
class PhoneHistory (
    @get:JsonProperty("identity")
    @JsonIdentityInfo(generator = ObjectIdGenerators.PropertyGenerator::class, property = "id")
    @JsonIdentityReference(alwaysAsId = true)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "identity_history_id")
    var identityHistory: IdentityHistory? = null,
) : BasePhone()
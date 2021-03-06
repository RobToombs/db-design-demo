package com.toombs.backend.identity.entities.history

import com.toombs.backend.identity.entities.base.BaseIdentity
import com.toombs.backend.identity.entities.base.BaseMrnOverflow
import com.toombs.backend.identity.entities.base.BasePhone
import org.springframework.data.annotation.Immutable
import javax.persistence.*

@Entity
@Immutable
class IdentityHistory (
    @OneToMany(mappedBy = "identityHistory", fetch = FetchType.LAZY, cascade = [CascadeType.ALL], orphanRemoval = true)
    var phones: MutableList<PhoneHistory> = mutableListOf(),

    @OneToMany(mappedBy = "identityHistory", fetch = FetchType.LAZY, cascade = [CascadeType.ALL], orphanRemoval = true)
    var mrnOverflow: MutableList<MrnOverflowHistory> = mutableListOf(),
): BaseIdentity() {
    fun addPhone(phone: PhoneHistory) {
        phone.identityHistory = this
        phones.add(phone)
    }

    fun addMrnOverflow(mrn: MrnOverflowHistory) {
        mrn.identityHistory = this
        mrnOverflow.add(mrn)
    }

    override fun phones(): List<BasePhone> {
        return phones
    }

    override fun mrnOverflow(): List<BaseMrnOverflow> {
        return mrnOverflow
    }
}

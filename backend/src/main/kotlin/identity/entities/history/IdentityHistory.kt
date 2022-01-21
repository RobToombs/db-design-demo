package com.toombs.backend.identity.entities.history

import com.toombs.backend.identity.entities.base.BaseIdentity
import com.toombs.backend.identity.entities.base.BaseMrnOverflow
import com.toombs.backend.identity.entities.base.BasePhone
import javax.persistence.*

@Entity
class IdentityHistory (
    @OneToMany(mappedBy = "identity", fetch = FetchType.LAZY, cascade = [CascadeType.ALL], orphanRemoval = true)
    var phones: MutableList<PhoneHistory> = mutableListOf(),

    @OneToMany(mappedBy = "identity", fetch = FetchType.LAZY, cascade = [CascadeType.ALL], orphanRemoval = true)
    var mrnOverflow: MutableList<MrnOverflowHistory> = mutableListOf(),
): BaseIdentity() {
    fun addPhone(phone: PhoneHistory) {
        phone.identity = this
        phones.add(phone)
    }

    fun addMrnOverflow(mrn: MrnOverflowHistory) {
        mrn.identity = this
        mrnOverflow.add(mrn)
    }

    override fun phones(): List<BasePhone> {
        return phones
    }

    override fun mrnOverflow(): List<BaseMrnOverflow> {
        return mrnOverflow
    }
}

package com.toombs.backend.identity.entities.active

import com.toombs.backend.identity.entities.base.BaseIdentity
import com.toombs.backend.identity.entities.base.BaseMrnOverflow
import com.toombs.backend.identity.entities.base.BasePhone
import javax.persistence.*

@Entity
class Identity(
    @OneToMany(mappedBy = "identity", fetch = FetchType.LAZY, cascade = [CascadeType.ALL], orphanRemoval = true)
    var phones: MutableList<Phone> = mutableListOf(),

    @OneToMany(mappedBy = "identity", fetch = FetchType.LAZY, cascade = [CascadeType.ALL], orphanRemoval = true)
    var mrnOverflow: MutableList<MrnOverflow> = mutableListOf(),
): BaseIdentity() {
    fun addPhone(phone: Phone) {
        phone.identity = this
        phones.add(phone)
    }

    fun addMrnOverflow(mrn: MrnOverflow) {
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

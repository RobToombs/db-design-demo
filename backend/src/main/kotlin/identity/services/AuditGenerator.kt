package com.toombs.backend.identity.services

import com.toombs.backend.identity.entities.audit.Audit
import com.toombs.backend.identity.entities.audit.Delta
import com.toombs.backend.identity.entities.audit.DeltaEvent
import com.toombs.backend.identity.entities.active.Identity
import com.toombs.backend.identity.entities.base.BaseIdentity
import com.toombs.backend.identity.entities.history.IdentityHistory
import java.util.*

const val PRIMARY_MRN: String = "Primary Mrn"
const val SECONDARY_MRN: String = "Overflow Mrn"
const val LAST: String  = "Last"
const val FIRST: String  = "First"
const val DOB: String  = "DOB"
const val GENDER: String  = "Gender"
const val PHONE: String  = "Phone"
const val UPI: String  = "Upi"

class AuditGenerator {

    fun generateAuditTrail(active: Identity, historical: List<IdentityHistory>): List<Audit> {
        val result = mutableListOf<Audit>()

        if(historical.isNotEmpty()) {
            val createdIdentity = historical.first()

            val creationDeltas: List<Delta> = creationDelta(createdIdentity)

            val creation = Audit(
                createDate = createdIdentity.createDate!!,
                createdBy = createdIdentity.createdBy,
                event = DeltaEvent.CREATE,
                deltas = creationDeltas
            )

            result.add(creation)

            for (i in 1 until historical.size) {
                val old = historical[i-1]
                val new = historical[i]

                val audit = createAuditEntry(old, new)
                result.add(audit)
            }

            val lastHistorical = historical[historical.size - 1]
            val audit = createAuditEntry(lastHistorical, active)
            result.add(audit)
        }
        else {
            val creationDeltas: List<Delta> = creationDelta(active)

            val creation = Audit(
                createDate = active.createDate!!,
                createdBy = active.createdBy,
                event = DeltaEvent.CREATE,
                deltas = creationDeltas
            )

            result.add(creation)
        }

        return result
    }

    private fun creationDelta(identity: BaseIdentity): List<Delta> {
        val result = mutableListOf<Delta>()

        result.add(Delta(PRIMARY_MRN, "", identity.mrn))
        result.add(Delta(LAST, "", identity.patientLast))
        result.add(Delta(FIRST, "", identity.patientFirst))
        result.add(Delta(DOB, "", identity.dateOfBirth.toString()))
        result.add(Delta(GENDER, "", identity.gender))

        for(phone in identity.phones()) {
            result.add(Delta(PHONE, "", phone.number))
        }

        for(mrn in identity.mrnOverflow()) {
            result.add(Delta(SECONDARY_MRN, "", mrn.mrn))
        }

        return result
    }

    private fun createAuditEntry(old: BaseIdentity, new: BaseIdentity): Audit {
        val deltas = mutableListOf<Delta>()

        addDeltaIfUpdated(old.mrn, new.mrn, PRIMARY_MRN, deltas)
        addDeltaIfUpdated(old.patientLast, new.patientLast, LAST, deltas)
        addDeltaIfUpdated(old.patientFirst, new.patientFirst, FIRST, deltas)
        addDeltaIfUpdated(old.dateOfBirth, new.dateOfBirth, DOB, deltas)
        addDeltaIfUpdated(old.gender, new.gender, GENDER, deltas)
        addDeltaIfUpdated(old.upi, new.upi, UPI, deltas)

        for(i in 0 until old.phones().size) {
            val oldPhone = old.phones()[i].number
            val newPhone = new.phones()[i].number
            addDeltaIfUpdated(oldPhone, newPhone, PHONE, deltas)
        }

        val deltaEvent = determineEvent(old, new, deltas)

        return Audit(
            createDate = new.createDate!!,
            createdBy = new.createdBy,
            event = deltaEvent,
            deltas = deltas
        )
    }

    private fun determineEvent(old: BaseIdentity, new: BaseIdentity, deltas: MutableList<Delta>): DeltaEvent {
        return if (deltas.isNotEmpty()) {
            DeltaEvent.UPDATE
        } else if (new.active && !old.active) {
            DeltaEvent.ACTIVATE
        } else {
            DeltaEvent.DEACTIVATE
        }
    }

    private fun addDeltaIfUpdated(old: Any?, new: Any?, field: String, deltas: MutableList<Delta>) {
        if(!Objects.equals(old, new)) {
            deltas.add(Delta(field, old.toString(), new.toString()))
        }
    }

}
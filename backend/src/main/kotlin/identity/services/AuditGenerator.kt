package com.toombs.backend.identity.services

import com.toombs.backend.identity.entities.audit.Audit
import com.toombs.backend.identity.entities.audit.Delta
import com.toombs.backend.identity.entities.audit.DeltaEvent
import com.toombs.backend.identity.entities.active.Identity
import com.toombs.backend.identity.entities.base.BaseIdentity
import com.toombs.backend.identity.entities.base.BasePhone
import com.toombs.backend.identity.entities.history.IdentityHistory
import java.util.*

const val PRIMARY_MRN: String = "Primary Mrn"
const val SECONDARY_MRN: String = "Overflow Mrn"
const val LAST: String  = "Last"
const val FIRST: String  = "First"
const val DOB: String  = "DOB"
const val GENDER: String  = "Gender"
const val PHONE: String  = "Phone"
const val PHONE_TYPE: String  = "Phone Type"
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

        createDelta(identity.mrn, PRIMARY_MRN, result)
        createDelta(identity.patientLast, LAST, result)
        createDelta(identity.patientFirst, FIRST, result)
        createDelta(identity.dateOfBirth.toString(), DOB, result)
        createDelta(identity.gender, GENDER, result)

        for(phone in identity.phones()) {
            createDelta(phone.number, PHONE, result)
        }

        for(mrn in identity.mrnOverflow()) {
            createDelta(mrn.mrn, SECONDARY_MRN, result)
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

        comparePhones(old.phones(), new.phones(), deltas)

        val deltaEvent = determineEvent(old, new, deltas)

        return Audit(
            createDate = new.createDate!!,
            createdBy = new.createdBy,
            event = deltaEvent,
            deltas = deltas
        )
    }

    private fun comparePhones(old: List<BasePhone>, new: List<BasePhone>, deltas: MutableList<Delta>) {
        for(i in old.indices) {
            val oldPhone = old[i]
            val newPhone = new.firstOrNull { phone -> phone.number == oldPhone.number }

            // if new phone == null, then oldPhone was deleted
            if(newPhone == null) {
                deleteDelta(oldPhone.number , PHONE, deltas)
            }

            // if new phone != null, the number is the same so compare additional attributes
            if(newPhone != null) {
                addDeltaIfUpdated(oldPhone.number + " - " + oldPhone.type, newPhone.number + " - " + newPhone.type, PHONE_TYPE, deltas)
            }
        }

        val added = new.filter { phone -> old.map { oldPhone -> oldPhone.number }.contains(phone.number).not() }
        added.forEach { phone -> createDelta(phone.number, PHONE, deltas) }
    }

    private fun deleteDelta(deleted: String, field: String, deltas: MutableList<Delta>) {
        deltas.add(Delta(field, deleted, "", DeltaEvent.DELETE))
    }

    private fun createDelta(added: String, field: String, deltas: MutableList<Delta>) {
        deltas.add(Delta(field, "", added, DeltaEvent.CREATE))
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
            deltas.add(Delta(field, old.toString(), new.toString(), DeltaEvent.UPDATE))
        }
    }

}
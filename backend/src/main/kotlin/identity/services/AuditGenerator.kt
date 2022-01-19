package com.toombs.backend.identity.services

import com.toombs.backend.identity.entities.Audit
import com.toombs.backend.identity.entities.Delta
import com.toombs.backend.identity.entities.DeltaEvent
import com.toombs.backend.identity.entities.Identity
import java.util.*

const val PRIMARY_MRN: String = "Primary Mrn"
const val SECONDARY_MRN: String = "Overflow Mrn"
const val LAST: String  = "Last"
const val FIRST: String  = "First"
const val DOB: String  = "DOB"
const val GENDER: String  = "Gender"
const val ACTIVE: String  = "Active"
const val PHONE: String  = "Phone"

class AuditGenerator {

    fun generateAuditTrail(identities: List<Identity>): List<Audit> {
        val result = mutableListOf<Audit>()

        if(identities.isNotEmpty()) {
            val createdIdentity = identities.first()

            val creationDeltas: List<Delta> = creationDelta(createdIdentity)

            val creation = Audit(
                createDate = createdIdentity.createDate!!,
                createdBy = createdIdentity.createdBy,
                event = DeltaEvent.CREATE,
                deltas = creationDeltas
            )

            result.add(creation)

            for (i in 1 until identities.size) {
                val old = identities[i-1]
                val new = identities[i]

                val audit = createAuditEntry(old, new)
                result.add(audit)
            }

        }

        return result
    }

    private fun creationDelta(identity: Identity): List<Delta> {
        val result = mutableListOf<Delta>()

        result.add(Delta(PRIMARY_MRN, "", identity.mrn))
        result.add(Delta(LAST, "", identity.patientLast))
        result.add(Delta(FIRST, "", identity.patientFirst))
        result.add(Delta(DOB, "", identity.dateOfBirth.toString()))
        result.add(Delta(GENDER, "", identity.gender))

        return result
    }

    private fun createAuditEntry(old: Identity, new: Identity): Audit {
        val deltas = mutableListOf<Delta>()

        addDeltaIfUpdated(old.mrn, new.mrn, PRIMARY_MRN, deltas)
        addDeltaIfUpdated(old.patientLast, new.patientLast, LAST, deltas)
        addDeltaIfUpdated(old.patientFirst, new.patientFirst, FIRST, deltas)
        addDeltaIfUpdated(old.dateOfBirth, new.dateOfBirth, DOB, deltas)
        addDeltaIfUpdated(old.gender, new.gender, GENDER, deltas)

        val deltaEvent = determineEvent(old, new, deltas)

        return Audit(
            createDate = new.createDate!!,
            createdBy = new.createdBy,
            event = deltaEvent,
            deltas = deltas
        )
    }

    private fun determineEvent(old: Identity, new: Identity, deltas: MutableList<Delta>): DeltaEvent {
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
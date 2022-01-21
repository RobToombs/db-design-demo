package com.toombs.backend.identity.services

import com.toombs.backend.identity.entities.active.Identity
import com.toombs.backend.identity.entities.history.IdentityHistory
import com.toombs.backend.identity.entities.history.MrnOverflowHistory
import com.toombs.backend.identity.entities.history.PhoneHistory
import com.toombs.backend.identity.repositories.history.IdentityHistoryRepository
import org.springframework.stereotype.Service
import java.time.LocalDateTime
import javax.transaction.Transactional

@Service
class IdentityHistoryService(
    private val identityHistoryRepository: IdentityHistoryRepository,
) {

    fun retireIdentity(identity: Identity, time: LocalDateTime, user: String): IdentityHistory {
        val history = createHistoryEntry(identity, time, user)
        return save(history)
    }

    @Transactional
    fun save(history: IdentityHistory): IdentityHistory {
        return identityHistoryRepository.save(history)
    }

    private fun createHistoryEntry(identity: Identity, endDate: LocalDateTime, user: String): IdentityHistory {
        val ih = IdentityHistory()
        ih.endDate = endDate
        ih.modifiedBy = user
        ih.active = identity.active
        ih.trxId = identity.trxId
        ih.upi = identity.upi
        ih.mrn = identity.mrn
        ih.patientFirst = identity.patientFirst
        ih.patientLast = identity.patientLast
        ih.dateOfBirth = identity.dateOfBirth
        ih.gender = identity.gender
        ih.createDate = identity.createDate
        ih.createdBy = identity.createdBy

        createPhoneHistory(ih)
        createMrnOverflowHistory(ih)

        return ih
    }

    private fun createPhoneHistory(ih: IdentityHistory) {
        for(phone in ih.phones) {
            val phoneHistory = PhoneHistory()
            phoneHistory.number = phone.number
            phoneHistory.type = phone.type

            ih.addPhone(phoneHistory)
        }
    }

    private fun createMrnOverflowHistory(ih: IdentityHistory) {
        for(mrn in ih.mrnOverflow) {
            val mrnOverflowHistory = MrnOverflowHistory()
            mrnOverflowHistory.mrn = mrn.mrn

            ih.addMrnOverflow(mrnOverflowHistory)
        }
    }
}
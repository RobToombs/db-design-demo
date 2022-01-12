package com.toombs.backend.etl

import com.toombs.backend.appointment.Appointment
import com.toombs.backend.appointment.AppointmentService
import com.toombs.backend.identity.entities.Identity
import com.toombs.backend.identity.entities.IdentityMap
import com.toombs.backend.identity.entities.Phone
import com.toombs.backend.identity.services.IdentityService
import org.apache.commons.csv.CSVFormat
import org.apache.commons.csv.CSVParser
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.core.io.ClassPathResource
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator
import org.springframework.stereotype.Service
import java.io.InputStream
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import javax.sql.DataSource

@Service
class EtlService(
    private val appointmentService: AppointmentService,
    private val identityService: IdentityService,
) {
    @Autowired
    private val dataSource: DataSource? = null

    private val APPOINTMENT_ETL = "APPOINTMENT ETL"

    private val UPI_COLUMN = "Upi"
    private val MRN_COLUMN = "Mrn"
    private val DOB_COLUMN = "DateOfBirth"
    private val LAST_COLUMN = "Last"
    private val FIRST_COLUMN = "First"
    private val GENDER_COLUMN = "Gender"
    private val PHONE_COLUMN = "Phone"
    private val DATE_COLUMN = "Date"
    private val MED_COLUMN = "Medication"

    fun resetDatabase(): Boolean {
        val populator = ResourceDatabasePopulator(
            false,
            false,
            "UTF-8",
            ClassPathResource("import.sql")
        )
        populator.execute(dataSource!!)

        return true
    }

    fun processAppointmentEtl(): Boolean {
        val ioStream: InputStream? = this.javaClass
            .classLoader
            .getResourceAsStream("upi_refresh.csv")

        val csvParser = CSVParser(
            ioStream?.bufferedReader(),
            CSVFormat.Builder.create()
                .setHeader()
                .setDelimiter(',')
                .setRecordSeparator("\r\n")
                .build()
        )

        for (record in csvParser) {
            val upi = record.get(UPI_COLUMN)
            val mrn = record.get(MRN_COLUMN)
            val dob = record.get(DOB_COLUMN)
            val last = record.get(LAST_COLUMN)
            val first = record.get(FIRST_COLUMN)
            val gender = record.get(GENDER_COLUMN)
            val phoneNumber = record.get(PHONE_COLUMN)
            val date = record.get(DATE_COLUMN)
            val medication = record.get(MED_COLUMN)

            val appointment = Appointment()
            appointment.date = LocalDate.parse(date, DateTimeFormatter.ISO_DATE)
            appointment.medication = medication

            // Do we already have an active identity for this appointment?
            val existingMapping: IdentityMap? = identityService.findFirstIdentityMapByUpi(upi)
            if(existingMapping != null) {
                appointmentService.addAppointment(appointment, existingMapping)
            }
            else {
                // Do we have a matching inactive identity for this appointment?
                val existingInactiveIdentity = identityService.findByUpiAndInactive(upi)
                if(existingInactiveIdentity.isPresent) {
                    // Create new mapping with CREATE
                    // Create new mapping history
                    // Link new mapping to activity
                }
                else {
                    // No active/inactive identity exists
                    val phone = Phone()
                    phone.number = phoneNumber

                    val identity = Identity()
                    identity.upi = upi
                    identity.mrn = mrn
                    identity.dateOfBirth = LocalDate.parse(dob, DateTimeFormatter.ISO_DATE)
                    identity.patientLast = last
                    identity.patientFirst = first
                    identity.gender = gender
                    identity.addPhone(phone)

                    val identityMap = identityService.addIdentity(identity, APPOINTMENT_ETL)
                    appointmentService.addAppointment(appointment, identityMap)
                }
            }
        }

        return true
    }
}
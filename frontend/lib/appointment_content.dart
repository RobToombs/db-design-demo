import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';
import 'models.dart';

class AppointmentContent extends StatelessWidget {
  const AppointmentContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AppointmentTable();
  }
}

class AppointmentTable extends StatefulWidget {
  const AppointmentTable({Key? key}) : super(key: key);

  @override
  _AppointmentTableState createState() => _AppointmentTableState();
}

class _AppointmentTableState extends State<AppointmentTable> {
  late Future<List<Appointment>> _futureAppointments;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Appointment>>(
        future: _futureAppointments,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _appointmentTable(snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else {
            return circularProgressIndicatorWidget();
          }
        });
  }

  Widget _appointmentTable(List<Appointment> appointments) {
    List<TableRow> appointmentRows =
        appointments.map<TableRow>((Appointment appointment) {
      return TableRow(children: <Widget>[
        createCell(appointment.id.toString()),
        createCell(formatDate(appointment.date)),
        createCell(appointment.medication),
        createCell(appointment.identityMap.identity.upi),
        createCell(appointment.identityMap.identity.mrn),
        createCell(appointment.identityMap.identity.patientLast),
        createCell(appointment.identityMap.identity.patientFirst),
        createCell(formatDate(appointment.identityMap.identity.dateOfBirth)),
        createCell(appointment.identityMap.identity.gender),
      ]);
    }).toList();

    List<TableRow> tableContent = [_appointmentHeaders()];
    tableContent.addAll(appointmentRows);

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(50),
        1: FixedColumnWidth(120),
        7: FixedColumnWidth(120),
        8: FixedColumnWidth(70),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableContent,
    );
  }

  TableRow _appointmentHeaders() {
    return TableRow(
      children: <Widget>[
        createHeader("Id"),
        createHeader("Date"),
        createHeader("Medication"),
        createHeader("UPI"),
        createHeader("MRN"),
        createHeader("Last"),
        createHeader("First"),
        createHeader("DOB"),
        createHeader("Gender"),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _futureAppointments = _fetchAppointments();
  }

  Future<List<Appointment>> _fetchAppointments() async {
    http.Response response =
        await http.get(Uri.http('localhost:8080', 'api/appointments'));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List)
          .map((appointment) => Appointment.fromJson(appointment))
          .toList();
    } else {
      throw Exception('Failed to load appointments');
    }
  }
}

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
  late Future<List<Identity>> _futureActiveIdentities;

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
    List<TableRow> appointmentRows = appointments.map<TableRow>((Appointment appointment) {
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

    Table table = Table(
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

    Scaffold content = Scaffold(
      body: table,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _futureActiveIdentities = _fetchActiveIdentities();
          });
          _showAddModal(context);
        },
        child: const Icon(Icons.add),
      ),
    );

    return content;
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

  _showAddModal(context) {
    DateTime? date;
    String? medication;
    Identity? selectedIdentity;

    String idMrn = "";
    String idLast = "";
    String idFirst = "";
    DateTime idDob = DateTime.now();
    String idGender = "";

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              constraints: const BoxConstraints(minHeight: 500, minWidth: 600, maxHeight: 500, maxWidth: 600),
              child: Column(
                children: [
                  const Text(
                    "Add Appointment",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      filled: false,
                      labelText: 'Medication:',
                    ),
                    onChanged: (value) {
                      setState(() {
                        medication = value;
                      });
                    },
                  ),
                  InputDatePickerFormField(
                    fieldLabelText: 'Date:',
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2200),
                    onDateSubmitted: (value) {
                      setState(() {
                        date = value;
                      });
                    },
                  ),
                  Container(
                      margin: const EdgeInsets.only(top: 15.0, bottom: 10.0),
                      child: const Text(
                        "Active Identities",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      )),
                  FutureBuilder<List<Identity>>(
                      future: _futureActiveIdentities,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return _createIdentityList(snapshot.data!);
                        } else if (snapshot.hasError) {
                          return Text("${snapshot.error}");
                        } else {
                          return circularProgressIndicatorWidget();
                        }
                      }),
                  Container(
                      margin: const EdgeInsets.only(top: 40.0),
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 20),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: ElevatedButton(
                            child: const Text(
                              'Save',
                              style: TextStyle(fontSize: 20),
                            ),
                            onPressed: () {
                              Identity ident = selectedIdentity ??
                                  Identity(
                                      id: null,
                                      upi: "",
                                      mrn: idMrn,
                                      patientLast: idLast,
                                      patientFirst: idFirst,
                                      dateOfBirth: idDob,
                                      gender: idGender,
                                      active: true,
                                      createDate: null,
                                      endDate: null,
                                      createdBy: "",
                                      modifiedBy: "");

                              IdentityMap identMap = IdentityMap(id: null, identity: ident);

                              Appointment appt = Appointment(
                                id: null,
                                identityMap: identMap,
                                date: date!,
                                medication: medication!,
                              );

                              _addAppointment(appt).then((updated) {
                                Navigator.pop(context);
                                setState(() {
                                  _futureAppointments = _fetchAppointments();
                                });
                              });
                            },
                          ),
                        ),
                      ])),
                ],
              ),
            ),
          );
        });
  }

  Widget _createIdentityList(List<Identity> identities) {
    ListView identityList = ListView.builder(
      itemCount: identities.length,
      itemBuilder: (context, index) {
        Identity identity = identities[index];

        String text = identity.patientLast +
            ", " +
            identity.patientFirst +
            " (" +
            identity.gender +
            ")   -    " +
            formatDate(identity.dateOfBirth) +
            "    -    " +
            identity.mrn;

        return Card(child: ListTile(title: Text(text)));
      },
    );

    return SizedBox(height: 230, width: 600, child: identityList);
  }

  Future<List<Appointment>> _fetchAppointments() async {
    http.Response response = await http.get(Uri.http('localhost:8080', 'api/appointments'));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List).map((appointment) => Appointment.fromJson(appointment)).toList();
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  Future<List<Identity>> _fetchActiveIdentities() async {
    http.Response response = await http.get(Uri.http('localhost:8080', 'api/identities/active'));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List).map((identity) => Identity.fromJson(identity)).toList();
    } else {
      throw Exception('Failed to load identities');
    }
  }

  Future<bool> _addAppointment(Appointment appointment) async {
    http.Response response = await http.put(
      Uri.http('localhost:8080', 'api/appointments/add'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(appointment.toJson()),
    );

    if (response.statusCode == HttpStatus.created) {
      return true;
    } else {
      throw Exception('Failed to create appointment');
    }
  }
}

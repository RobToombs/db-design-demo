import 'dart:convert';
import 'dart:html' as html;

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
    List<TableRow> appointmentRows = appointments.map<TableRow>((Appointment appointment) {
      String _upi = appointment.finalIdentity == null ? appointment.identityMap.identity.upi : appointment.finalIdentity!.upi;
      String _mrn = appointment.finalIdentity == null ? appointment.identityMap.identity.mrn : appointment.finalIdentity!.mrn;
      String _patientLast = appointment.finalIdentity == null ? appointment.identityMap.identity.patientLast : appointment.finalIdentity!.patientLast;
      String _patientFirst = appointment.finalIdentity == null ? appointment.identityMap.identity.patientFirst : appointment.finalIdentity!.patientFirst;
      DateTime _dob = appointment.finalIdentity == null ? appointment.identityMap.identity.dateOfBirth : appointment.finalIdentity!.dateOfBirth;
      String _gender = appointment.finalIdentity == null ? appointment.identityMap.identity.gender : appointment.finalIdentity!.gender;

      return TableRow(children: <Widget>[
        createCell(appointment.id.toString()),
        createCell(formatDate(appointment.date)),
        createCell(appointment.medication),
        createCell(_upi),
        createCell(_mrn),
        createCell(_patientLast),
        createCell(_patientFirst),
        createCell(formatDate(_dob)),
        createCell(_gender),
        createCell(appointment.active.toString()),
        createCell(appointment.identityMap.id.toString()),
        createCell(appointment.finalIdentity == null ? "" : appointment.finalIdentity!.id.toString()),
        _createFinishCell(appointment),
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
        9: FixedColumnWidth(60),
        10: FixedColumnWidth(80),
        11: FixedColumnWidth(120),
        12: FixedColumnWidth(50),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableContent,
    );

    Scaffold content = Scaffold(
      body: table,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
        createHeader("Active"),
        createHeader("Map Id"),
        createHeader("Final Identity Id"),
        createHeader("Save"),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _futureAppointments = _fetchAppointments();
  }

  // TODO make this generic w/ Refill content
  TableCell _createFinishCell(Appointment appointment) {
    return TableCell(
      child: SizedBox(
        height: 24,
        child: Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              child: appointment.active
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 22.0,
                    )
                  : const Text(""),
              onTap: appointment.active
                  ? () {
                      _finishAppointment(appointment).then((success) {
                        if (success) {
                          _refresh();
                        }
                      });
                    }
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddModal(context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)), child: AddAppointmentDialogContent(refreshAppointment: _refresh));
        });
  }

  void _refresh() {
    setState(() {
      _futureAppointments = _fetchAppointments();
    });
  }

  Future<bool> _finishAppointment(Appointment appointment) async {
    http.Response response = await http.put(Uri.http('localhost:8080', 'api/appointments/finish/' + appointment.id.toString()), headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });

    if (response.statusCode == html.HttpStatus.ok) {
      return true;
    } else {
      throw Exception('Failed to finish appointment');
    }
  }

  Future<List<Appointment>> _fetchAppointments() async {
    http.Response response = await http.get(Uri.http('localhost:8080', 'api/appointments'));

    if (response.statusCode == html.HttpStatus.ok) {
      return (jsonDecode(response.body) as List).map((appointment) => Appointment.fromJson(appointment)).toList();
    } else {
      throw Exception('Failed to load appointments');
    }
  }
}

class AddAppointmentDialogContent extends StatefulWidget {
  final VoidCallback refreshAppointment;
  const AddAppointmentDialogContent({Key? key, required this.refreshAppointment}) : super(key: key);

  @override
  _AddAppointmentDialogContentState createState() => _AddAppointmentDialogContentState();
}

class _AddAppointmentDialogContentState extends State<AddAppointmentDialogContent> {
  late Future<List<Identity>> _futureActiveIdentities;

  DateTime? _date;
  String _medication = "";
  Identity? _selectedIdentity;

  @override
  void initState() {
    super.initState();
    _futureActiveIdentities = _fetchActiveIdentities();
  }

  Widget _createIdentityList(List<Identity> identities) {
    ListView identityList = ListView.builder(
      itemCount: identities.length,
      itemBuilder: (context, index) {
        Identity identity = identities[index];

        Row title = Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Text(identity.patientLast + ", " + identity.patientFirst)]);
        Row subtitle = Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [Text("Gender: " + identity.gender), Text("DOB: " + formatDate(identity.dateOfBirth)), Text("MRN: " + identity.mrn)]);

        return Card(
            child: ListTile(
                title: title,
                subtitle: subtitle,
                selectedColor: Colors.white,
                selectedTileColor: Colors.blue,
                selected: _selectedIdentity == identity,
                onTap: () {
                  setState(() {
                    _selectedIdentity = identity;
                  });
                }));
      },
    );

    return SizedBox(height: 230, width: 600, child: identityList);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      constraints: const BoxConstraints(minHeight: 500, minWidth: 600, maxHeight: 500, maxWidth: 600),
      child: Column(
        children: [
          const Text(
            "Add Appointment",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
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
          TextFormField(
            decoration: const InputDecoration(
              filled: false,
              labelText: 'Medication:',
            ),
            onChanged: (value) {
              setState(() {
                _medication = value;
              });
            },
          ),
          InputDatePickerFormField(
            fieldLabelText: 'Date:',
            firstDate: DateTime(1900),
            lastDate: DateTime(2200),
            onDateSubmitted: (value) {
              setState(() {
                _date = value;
              });
            },
          ),
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
                      IdentityMap identMap = IdentityMap(id: null, identity: _selectedIdentity!);

                      Appointment appt = Appointment(
                        id: null,
                        finalIdentity: null,
                        identityMap: identMap,
                        active: true,
                        date: _date!,
                        medication: _medication,
                      );

                      _addAppointment(appt).then((updated) {
                        Navigator.pop(context);
                        widget.refreshAppointment();
                      });
                    },
                  ),
                ),
              ])),
        ],
      ),
    );
  }

  Future<List<Identity>> _fetchActiveIdentities() async {
    http.Response response = await http.get(Uri.http('localhost:8080', 'api/identities/active'));

    if (response.statusCode == html.HttpStatus.ok) {
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

    if (response.statusCode == html.HttpStatus.created) {
      return true;
    } else {
      throw Exception('Failed to create appointment');
    }
  }
}

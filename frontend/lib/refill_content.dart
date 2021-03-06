import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';
import 'models.dart';

class RefillContent extends StatelessWidget {
  const RefillContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const RefillTable();
  }
}

class RefillTable extends StatefulWidget {
  const RefillTable({Key? key}) : super(key: key);

  @override
  _RefillTableState createState() => _RefillTableState();
}

class _RefillTableState extends State<RefillTable> {
  late Future<List<Refill>> _futureRefills;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Refill>>(
        future: _futureRefills,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _refillTable(snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else {
            return circularProgressIndicatorWidget();
          }
        });
  }

  Widget _refillTable(List<Refill> refills) {
    List<TableRow> refillRows = refills.map<TableRow>((Refill refill) {
      String _upi = refill.finalIdentity == null ? refill.identityMap.identity.upi : refill.finalIdentity!.upi;
      String _mrn = refill.finalIdentity == null ? refill.identityMap.identity.mrn : refill.finalIdentity!.mrn;
      String _patientLast = refill.finalIdentity == null ? refill.identityMap.identity.patientLast : refill.finalIdentity!.patientLast;
      String _patientFirst = refill.finalIdentity == null ? refill.identityMap.identity.patientFirst : refill.finalIdentity!.patientFirst;
      DateTime _dob = refill.finalIdentity == null ? refill.identityMap.identity.dateOfBirth : refill.finalIdentity!.dateOfBirth;
      String _gender = refill.finalIdentity == null ? refill.identityMap.identity.gender : refill.finalIdentity!.gender;

      return TableRow(children: <Widget>[
        createCell(refill.id.toString()),
        createCell(formatDate(refill.date)),
        createCell(refill.medication),
        createCell(refill.callAttempts.toString()),
        createCell(_upi),
        createCell(_mrn),
        createCell(_patientLast),
        createCell(_patientFirst),
        createCell(formatDate(_dob)),
        createCell(_gender),
        createCell(refill.active.toString()),
        createCell(refill.identityMap.id.toString()),
        createCell(refill.finalIdentity == null ? "" : refill.finalIdentity!.id.toString()),
        _createFinishCell(refill),
      ]);
    }).toList();

    List<TableRow> tableContent = [_refillHeaders()];
    tableContent.addAll(refillRows);

    Table table = Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(50),
        1: FixedColumnWidth(120),
        3: FixedColumnWidth(110),
        8: FixedColumnWidth(120),
        9: FixedColumnWidth(120),
        10: FixedColumnWidth(60),
        11: FixedColumnWidth(80),
        12: FixedColumnWidth(100),
        13: FixedColumnWidth(50),
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

  TableRow _refillHeaders() {
    return TableRow(
      children: <Widget>[
        createHeader("Id"),
        createHeader("Date"),
        createHeader("Medication"),
        createHeader("Call Attempts"),
        createHeader("Identity UPI"),
        createHeader("Identity MRN"),
        createHeader("Identity Last"),
        createHeader("Identity First"),
        createHeader("Identity DOB"),
        createHeader("Identity Gender"),
        createHeader("Active"),
        createHeader("Map Id"),
        createHeader("History Id"),
        createHeader("Save")
      ],
    );
  }

  // TODO make this generic w/ Appointment content
  TableCell _createFinishCell(Refill refill) {
    return TableCell(
      child: SizedBox(
        height: 24,
        child: Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              child: refill.active
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 22.0,
                    )
                  : const Text(""),
              onTap: refill.active
                  ? () {
                      _finishRefill(refill).then((success) {
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

  @override
  void initState() {
    super.initState();
    _futureRefills = _fetchRefills();
  }

  void _showAddModal(context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)), child: AddRefillDialogContent(refreshRefill: _refresh));
        });
  }

  void _refresh() {
    setState(() {
      _futureRefills = _fetchRefills();
    });
  }

  Future<bool> _finishRefill(Refill refill) async {
    http.Response response = await http.put(Uri.http('localhost:8080', 'api/refills/finish/' + refill.id.toString()), headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });

    if (response.statusCode == html.HttpStatus.ok) {
      return true;
    } else {
      throw Exception('Failed to finish refill');
    }
  }

  Future<List<Refill>> _fetchRefills() async {
    http.Response response = await http.get(Uri.http('localhost:8080', 'api/refills'));

    if (response.statusCode == html.HttpStatus.ok) {
      return (jsonDecode(response.body) as List).map((refill) => Refill.fromJson(refill)).toList();
    } else {
      throw Exception('Failed to load refills');
    }
  }
}

class AddRefillDialogContent extends StatefulWidget {
  final VoidCallback refreshRefill;
  const AddRefillDialogContent({Key? key, required this.refreshRefill}) : super(key: key);

  @override
  _AddRefillDialogContentState createState() => _AddRefillDialogContentState();
}

// TODO - REFACTOR THIS INTO A SINGLE DIALOG WITH APPOINTMENT
class _AddRefillDialogContentState extends State<AddRefillDialogContent> {
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
            "Add Refill",
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

                      Refill refill = Refill(
                        id: null,
                        finalIdentity: null,
                        identityMap: identMap,
                        active: true,
                        date: _date!,
                        medication: _medication,
                        callAttempts: 0,
                      );

                      _addRefill(refill).then((updated) {
                        Navigator.pop(context);
                        widget.refreshRefill();
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

  Future<bool> _addRefill(Refill refill) async {
    http.Response response = await http.put(
      Uri.http('localhost:8080', 'api/refills/add'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(refill.toJson()),
    );

    if (response.statusCode == html.HttpStatus.created) {
      return true;
    } else {
      throw Exception('Failed to create refill');
    }
  }
}

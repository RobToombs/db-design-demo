import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'helpers.dart';
import 'models.dart';

class IdentityTable extends StatefulWidget {
  final VoidCallback refreshIdentity;
  const IdentityTable({Key? key, required this.refreshIdentity}) : super(key: key);

  @override
  IdentityTableState createState() => IdentityTableState();
}

class IdentityTableState extends State<IdentityTable> {
  late Future<List<Identity>> _futureIdentities;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [_resetDB(), _refreshUpiButton(), _processETL()],
          ),
          const Padding(padding: EdgeInsets.all(10.0), child: Text("Identity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          FutureBuilder<List<Identity>>(
              future: _futureIdentities,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _identityContent(snapshot.data!);
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  return circularProgressIndicatorWidget();
                }
              })
        ],
      ),
    );
  }

  Padding _refreshUpiButton() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        child: const Text(
          'Apply UPI Refresh',
          style: TextStyle(fontSize: 16),
        ),
        onPressed: () {
          _applyUpiRefresh().then((updated) {
            widget.refreshIdentity();
          });
        },
      ),
    );
  }

  Padding _processETL() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        child: const Text(
          'Process Appointment ETL',
          style: TextStyle(fontSize: 16),
        ),
        onPressed: () {
          _appointmentETL().then((updated) {
            widget.refreshIdentity();
          });
        },
      ),
    );
  }

  Padding _resetDB() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        child: const Text(
          'Reset DB',
          style: TextStyle(fontSize: 16),
        ),
        onPressed: () {
          _resetDatabase().then((updated) {
            widget.refreshIdentity();
          });
        },
      ),
    );
  }

  Column _identityContent(List<Identity> identities) {
    return Column(
      children: [
        _identityTable(identities),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_phoneTable(identities), _mrnTable(identities)],
        )
      ],
    );
  }

  Center _phoneTable(List<Identity> identities) {
    TableRow _phoneHeaders() {
      return TableRow(
        children: <Widget>[
          createHeader("Id"),
          createHeader("Identity Id"),
          createHeader("Phone Number"),
          createHeader("Type"),
        ],
      );
    }

    TableRow _createPhoneRow(Phone phone) {
      return TableRow(children: <Widget>[
        createCell(phone.id.toString()),
        createCell(phone.identityId.toString()),
        createCell(phone.number),
        createCell(phone.type),
      ]);
    }

    List<TableRow> phoneRows = identities.expand((identity) => identity.phones).map((phone) => _createPhoneRow(phone)).toList();
    List<TableRow> tableContent = [_phoneHeaders()];
    tableContent.addAll(phoneRows);

    Table _content = Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(50),
        1: FixedColumnWidth(80),
        2: FixedColumnWidth(120),
        3: FixedColumnWidth(100),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableContent,
    );

    return Center(
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(10.0), child: Text("Phone Numbers", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        _content
      ]),
    );
  }

  Center _mrnTable(List<Identity> identities) {
    TableRow _mrnHeaders() {
      return TableRow(
        children: <Widget>[
          createHeader("Id"),
          createHeader("Identity Id"),
          createHeader("MRN"),
        ],
      );
    }

    List<TableRow> _createMrnRows(Identity identity) {
      return identity.mrnOverflow
          .map((phone) => TableRow(children: <Widget>[
                createCell(phone.id.toString()),
                createCell(phone.identityId.toString()),
                createCell(phone.mrn),
              ]))
          .toList();
    }

    List<TableRow> mrnRows = identities.map((identity) => _createMrnRows(identity)).expand((rows) => rows).toList();
    List<TableRow> tableContent = [_mrnHeaders()];
    tableContent.addAll(mrnRows);

    Table _content = Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(50),
        1: FixedColumnWidth(80),
        2: FixedColumnWidth(120),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableContent,
    );

    return Center(
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(10.0), child: Text("MRN Overflow", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        _content
      ]),
    );
  }

  Table _identityTable(List<Identity> identities) {
    List<TableRow> identityRows = identities.map<TableRow>((Identity identity) {
      return TableRow(children: <Widget>[
        createCell(identity.id.toString()),
        createCell(identity.trxId),
        createCell(identity.upi),
        createCell(identity.mrn),
        createCell(identity.patientLast),
        createCell(identity.patientFirst),
        createCell(formatDate(identity.dateOfBirth)),
        createCell(identity.gender),
        createCell(identity.active.toString()),
        createCell(formatDateTime(identity.createDate)),
        createCell(formatDateTime(identity.endDate)),
        createCell(identity.createdBy),
        createCell(identity.modifiedBy),
        _createEditCell(identity),
        _createActivateCell(identity),
      ]);
    }).toList();

    List<TableRow> tableContent = [_identityHeaders()];
    tableContent.addAll(identityRows);

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(50),
        1: FixedColumnWidth(140),
        6: FixedColumnWidth(120),
        7: FixedColumnWidth(70),
        8: FixedColumnWidth(60),
        9: FixedColumnWidth(160),
        10: FixedColumnWidth(160),
        11: FixedColumnWidth(160),
        12: FixedColumnWidth(160),
        13: FixedColumnWidth(40),
        14: FixedColumnWidth(40),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableContent,
    );
  }

  TableRow _identityHeaders() {
    return TableRow(
      children: <Widget>[
        createHeader("Id"),
        createHeader("TRX Id"),
        createHeader("UPI"),
        createHeader("MRN"),
        createHeader("Last"),
        createHeader("First"),
        createHeader("DOB"),
        createHeader("Gender"),
        createHeader("Active"),
        createHeader("Create Date"),
        createHeader("End Date"),
        createHeader("Created By"),
        createHeader("Modified By"),
        createHeader("Edit"),
        createHeader("")
      ],
    );
  }

  TableCell _createEditCell(Identity identity) {
    return TableCell(
      child: SizedBox(
        height: 24,
        child: Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              child: identity.active
                  ? const Icon(
                      Icons.edit,
                      color: Colors.blue,
                      size: 22.0,
                    )
                  : const Text(""),
              onTap: identity.active
                  ? () {
                      _showEditModal(context, identity);
                    }
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  TableCell _createActivateCell(Identity identity) {
    Widget _icon = const Text("");
    if (identity.active) {
      _icon = const Icon(Icons.cancel, color: Colors.red, size: 22.0);
    } else if (!identity.active) {
      _icon = const Icon(Icons.check_circle, color: Colors.green, size: 22.0);
    }

    GestureTapCallback? _callback;
    if (identity.active) {
      _callback = () {
        _deactivateIdentity(identity).then((success) {
          if (success) {
            widget.refreshIdentity();
          }
        });
      };
    } else if (!identity.active) {
      _callback = () {
        _activateIdentity(identity).then((success) {
          if (success) {
            widget.refreshIdentity();
          }
        });
      };
    }

    return TableCell(
      child: SizedBox(
        height: 24,
        child: Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              child: _icon,
              onTap: _callback,
            ),
          ),
        ),
      ),
    );
  }

  _showEditModal(context, Identity identity) {
    String _updatedMrn = identity.mrn;
    String _updatedLast = identity.patientLast;
    String _updatedFirst = identity.patientFirst;
    DateTime _updatedDob = identity.dateOfBirth;
    String _updatedGender = identity.gender;
    List<String> _updatedNumbers = identity.phones.map((phone) => phone.number).toList();

    List<TextFormField> _phoneNumbers = identity.phones
        .asMap()
        .entries
        .map((entry) => {
              TextFormField(
                decoration: InputDecoration(
                  filled: false,
                  labelText: 'Phone Number :' + entry.value.number,
                ),
                initialValue: entry.value.number,
                onChanged: (value) {
                  setState(() {
                    _updatedNumbers[entry.key] = value;
                  });
                },
              )
            })
        .expand((phoneNumberField) => phoneNumberField)
        .toList();

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
                    "Edit Identity",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: false,
                      labelText: 'MRN:' + identity.mrn,
                    ),
                    initialValue: identity.mrn,
                    onChanged: (value) {
                      setState(() {
                        _updatedMrn = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: false,
                      labelText: 'Last Name:' + identity.patientLast,
                    ),
                    initialValue: identity.patientLast,
                    onChanged: (value) {
                      setState(() {
                        _updatedLast = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: false,
                      labelText: 'First Name:' + identity.patientFirst,
                    ),
                    initialValue: identity.patientFirst,
                    onChanged: (value) {
                      setState(() {
                        _updatedFirst = value;
                      });
                    },
                  ),
                  InputDatePickerFormField(
                    fieldLabelText: 'DOB:' + DateFormat('dd/MM/yyyy').format(identity.dateOfBirth),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    initialDate: identity.dateOfBirth,
                    onDateSubmitted: (value) {
                      setState(() {
                        _updatedDob = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: false,
                      labelText: 'Gender:' + identity.gender,
                    ),
                    initialValue: identity.gender,
                    onChanged: (value) {
                      setState(() {
                        _updatedGender = value;
                      });
                    },
                  ),
                  SingleChildScrollView(
                      child: Column(
                    children: _phoneNumbers,
                  )),
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
                              identity.mrn = _updatedMrn;
                              identity.patientFirst = _updatedFirst;
                              identity.patientLast = _updatedLast;
                              identity.gender = _updatedGender;
                              identity.dateOfBirth = _updatedDob;

                              for (var i = 0; i < identity.phones.length; i++) {
                                identity.phones[i].number = _updatedNumbers[i];
                              }

                              _updateIdentity(identity).then((updated) {
                                Navigator.pop(context);
                                widget.refreshIdentity();
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

  @override
  void initState() {
    super.initState();
    updateIdentities();
  }

  void updateIdentities() {
    setState(() {
      _futureIdentities = _fetchIdentities();
    });
  }

  Future<bool> _deactivateIdentity(Identity identity) async {
    http.Response response = await http.put(Uri.http('localhost:8080', 'api/identities/deactivate/' + identity.id.toString()), headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });

    if (response.statusCode == HttpStatus.ok) {
      return true;
    } else {
      throw Exception('Failed to deactivate identity');
    }
  }

  Future<bool> _activateIdentity(Identity identity) async {
    http.Response response = await http.put(Uri.http('localhost:8080', 'api/identities/activate/' + identity.id.toString()), headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });

    if (response.statusCode == HttpStatus.ok) {
      return true;
    } else {
      throw Exception('Failed to activate identity');
    }
  }

  Future<List<Identity>> _fetchIdentities() async {
    http.Response response = await http.get(Uri.http('localhost:8080', 'api/identities/current'));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List).map((identity) => Identity.fromJson(identity)).toList();
    } else {
      throw Exception('Failed to load identities');
    }
  }

  Future<bool> _updateIdentity(Identity identity) async {
    http.Response response = await http.put(
      Uri.http('localhost:8080', 'api/identities/update'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(identity.toJson()),
    );

    if (response.statusCode == HttpStatus.ok) {
      return true;
    } else {
      throw Exception('Failed to update identity');
    }
  }

  Future<bool> _appointmentETL() async {
    http.Response response = await http.put(
      Uri.http('localhost:8080', 'api/etl'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      return true;
    } else {
      throw Exception('Failed to process ETL');
    }
  }

  Future<bool> _resetDatabase() async {
    http.Response response = await http.put(
      Uri.http('localhost:8080', 'api/reset'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      return true;
    } else {
      throw Exception('Failed to reset DB');
    }
  }

  Future<bool> _applyUpiRefresh() async {
    http.Response response = await http.put(
      Uri.http('localhost:8080', 'api/identities/refresh'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      return true;
    } else {
      throw Exception('Failed to refresh upis');
    }
  }
}

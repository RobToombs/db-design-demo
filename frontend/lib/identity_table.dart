import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'helpers.dart';
import 'models.dart';

class IdentityTable extends StatefulWidget {
  final VoidCallback refreshIdentity;
  const IdentityTable({Key? key, required this.refreshIdentity})
      : super(key: key);

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
          const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text("Identity",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          FutureBuilder<List<Identity>>(
              future: _futureIdentities,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _identityTable(snapshot.data!);
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

  Widget _identityTable(List<Identity> identities) {
    List<TableRow> identityRows = identities.map<TableRow>((Identity identity) {
      return TableRow(children: <Widget>[
        createCell(identity.id.toString()),
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
      ]);
    }).toList();

    List<TableRow> tableContent = [_identityHeaders()];
    tableContent.addAll(identityRows);

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(50),
        5: FixedColumnWidth(120),
        6: FixedColumnWidth(70),
        7: FixedColumnWidth(60),
        12: FixedColumnWidth(40)
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableContent,
    );
  }

  TableRow _identityHeaders() {
    return TableRow(
      children: <Widget>[
        createHeader("Id"),
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

  _showEditModal(context, Identity identity) {
    String updatedMrn = identity.mrn;
    String updatedLast = identity.patientLast;
    String updatedFirst = identity.patientFirst;
    DateTime updatedDob = identity.dateOfBirth;
    String updatedGender = identity.gender;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              constraints: const BoxConstraints(
                  minHeight: 385, minWidth: 600, maxHeight: 385, maxWidth: 600),
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
                      labelText: 'MRN: ' + identity.mrn,
                    ),
                    initialValue: identity.mrn,
                    onChanged: (value) {
                      setState(() {
                        updatedMrn = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: false,
                      labelText: 'Last Name: ' + identity.patientLast,
                    ),
                    initialValue: identity.patientLast,
                    onChanged: (value) {
                      setState(() {
                        updatedLast = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: false,
                      labelText: 'First Name: ' + identity.patientFirst,
                    ),
                    initialValue: identity.patientFirst,
                    onChanged: (value) {
                      setState(() {
                        updatedFirst = value;
                      });
                    },
                  ),
                  InputDatePickerFormField(
                    fieldLabelText: 'DOB: ' +
                        DateFormat('dd/MM/yyyy').format(identity.dateOfBirth),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    initialDate: identity.dateOfBirth,
                    onDateSubmitted: (value) {
                      setState(() {
                        updatedDob = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: false,
                      labelText: 'Gender: ' + identity.gender,
                    ),
                    initialValue: identity.gender,
                    onChanged: (value) {
                      setState(() {
                        updatedGender = value;
                      });
                    },
                  ),
                  Container(
                      margin: const EdgeInsets.only(top: 40.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                                  identity.mrn = updatedMrn;
                                  identity.patientFirst = updatedFirst;
                                  identity.patientLast = updatedLast;
                                  identity.gender = updatedGender;
                                  identity.dateOfBirth = updatedDob;
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

  Future<List<Identity>> _fetchIdentities() async {
    http.Response response =
        await http.get(Uri.http('localhost:8080', 'api/identities'));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List)
          .map((identity) => Identity.fromJson(identity))
          .toList();
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

    if (response.statusCode == HttpStatus.created) {
      return true;
    } else {
      throw Exception('Failed to update identity');
    }
  }
}

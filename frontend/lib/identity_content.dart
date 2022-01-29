import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'identity_map_history_table.dart';
import 'identity_map_table.dart';
import 'identity_table.dart';
import 'models.dart';

class IdentityContent extends StatelessWidget {
  IdentityContent({Key? key}) : super(key: key);

  final GlobalKey<IdentityTableState> _identityTable = GlobalKey();
  final GlobalKey<IdentityMapTableState> _identityMapTable = GlobalKey();
  final GlobalKey<IdentityMapHistoryTableState> _identityMapHistoryTable = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Center tables = Center(
      child: Column(
        children: [
          IdentityTable(key: _identityTable, refreshIdentity: _active),
          IdentityMapTable(key: _identityMapTable, refreshIdentity: _active),
          IdentityMapHistoryTable(key: _identityMapHistoryTable),
        ],
      ),
    );

    ListView listView = ListView(
      children: [tables],
    );

    Scaffold content = Scaffold(
      body: listView,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddModal(context);
        },
        child: const Icon(Icons.add),
      ),
    );

    return content;
  }

  void _showAddModal(context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)), child: AddIdentificationDialogContent(refreshIdentities: _active));
        });
  }

  void _active() {
    _identityTable.currentState?.updateIdentities();
    _identityMapTable.currentState?.updateIdentityMaps();
    _identityMapHistoryTable.currentState?.updateIdentityMapHistories();
  }

  void _historical() {}
}

class AddIdentificationDialogContent extends StatefulWidget {
  final VoidCallback refreshIdentities;
  const AddIdentificationDialogContent({Key? key, required this.refreshIdentities}) : super(key: key);

  @override
  _AddIdentificationDialogContentState createState() => _AddIdentificationDialogContentState();
}

class _AddIdentificationDialogContentState extends State<AddIdentificationDialogContent> {
  String _mrn = "";
  String _patientLast = "";
  String _patientFirst = "";
  DateTime? _dateOfBirth;
  String _gender = "";
  String _phone = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      constraints: const BoxConstraints(minHeight: 450, minWidth: 600, maxHeight: 450, maxWidth: 600),
      child: Column(
        children: [
          const Text(
            "Add Identity",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          TextFormField(
            decoration: const InputDecoration(
              filled: false,
              labelText: 'MRN:',
            ),
            onChanged: (value) {
              setState(() {
                _mrn = value;
              });
            },
          ),
          TextFormField(
            decoration: const InputDecoration(
              filled: false,
              labelText: 'Last Name:',
            ),
            onChanged: (value) {
              setState(() {
                _patientLast = value;
              });
            },
          ),
          TextFormField(
            decoration: const InputDecoration(
              filled: false,
              labelText: 'First Name:',
            ),
            onChanged: (value) {
              setState(() {
                _patientFirst = value;
              });
            },
          ),
          InputDatePickerFormField(
            fieldLabelText: 'DOB:',
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            onDateSubmitted: (value) {
              setState(() {
                _dateOfBirth = value;
              });
            },
          ),
          TextFormField(
            decoration: const InputDecoration(
              filled: false,
              labelText: 'Gender:',
            ),
            onChanged: (value) {
              setState(() {
                _gender = value;
              });
            },
          ),
          TextFormField(
            decoration: const InputDecoration(
              filled: false,
              labelText: 'Phone:',
            ),
            onChanged: (value) {
              setState(() {
                _phone = value;
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
                      List<Phone> _phones = [Phone(id: null, identityId: null, number: _phone, type: "MOBILE")];

                      Identity identity = Identity(
                        id: null,
                        trxId: "",
                        upi: "",
                        mrn: _mrn,
                        patientLast: _patientLast,
                        patientFirst: _patientFirst,
                        dateOfBirth: _dateOfBirth!,
                        gender: _gender,
                        phones: _phones,
                        mrnOverflow: List.empty(),
                        active: true,
                        createDate: null,
                        endDate: null,
                        createdBy: "",
                        modifiedBy: "",
                      );

                      _addIdentity(identity).then((updated) {
                        Navigator.pop(context);
                        widget.refreshIdentities();
                      });
                    },
                  ),
                ),
              ])),
        ],
      ),
    );
  }

  Future<bool> _addIdentity(Identity identity) async {
    http.Response response = await http.post(
      Uri.http('localhost:8080', 'api/identities/add'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(identity.toJson()),
    );

    if (response.statusCode == html.HttpStatus.created) {
      return true;
    } else {
      throw Exception('Failed to create identity');
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

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
  bool _isHistorical = false;
  String _buttonText = "Active";
  String _identityText = "Identity";
  String _phoneText = "Phone Numbers";
  String _mrnText = "MRN Overflow";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [_resetDB(), _refreshUpiButton(), _processETL(), _showHistory()],
          ),
          Padding(padding: const EdgeInsets.all(10.0), child: Text(_identityText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
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

  Padding _showHistory() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: OutlinedButton(
        child: Text(
          _buttonText,
          style: const TextStyle(fontSize: 16),
        ),
        onPressed: () {
          if (_isHistorical) {
            updateIdentities();
          } else {
            updateHistorical();
          }
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
        Padding(padding: const EdgeInsets.all(10.0), child: Text(_phoneText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
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
        Padding(padding: const EdgeInsets.all(10.0), child: Text(_mrnText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
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
    if (_isHistorical) {
      return const TableCell(child: SizedBox(height: 24, child: Center()));
    } else {
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
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                                  child: EditIdentityDialogContent(identity: identity, refresh: widget.refreshIdentity));
                            });
                      }
                    : null,
              ),
            ),
          ),
        ),
      );
    }
  }

  TableCell _createActivateCell(Identity identity) {
    if (_isHistorical) {
      return const TableCell(child: SizedBox(height: 24, child: Center()));
    } else {
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
  }

  @override
  void initState() {
    super.initState();
    updateIdentities();
  }

  void updateIdentities() {
    setState(() {
      _futureIdentities = _fetchIdentities();
      _isHistorical = false;
      _buttonText = "Historical";
      _identityText = "Identity";
      _phoneText = "Phone Numbers";
      _mrnText = "MRN Overflow";
    });
  }

  void updateHistorical() {
    setState(() {
      _futureIdentities = _fetchHistorical();
      _isHistorical = true;
      _buttonText = "Active";
      _identityText = "Identity History";
      _phoneText = "Phone Numbers History";
      _mrnText = "MRN Overflow History";
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

  Future<List<Identity>> _fetchHistorical() async {
    http.Response response = await http.get(Uri.http('localhost:8080', 'api/identities/historical'));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List).map((identity) => Identity.fromJson(identity)).toList();
    } else {
      throw Exception('Failed to load historical identities');
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

class EditIdentityDialogContent extends StatefulWidget {
  final VoidCallback refresh;
  final Identity identity;

  const EditIdentityDialogContent({Key? key, required this.identity, required this.refresh}) : super(key: key);

  @override
  _EditIdentityDialogContentState createState() => _EditIdentityDialogContentState();
}

class _EditIdentityDialogContentState extends State<EditIdentityDialogContent> {
  late String _updatedMrn;
  late String _updatedLast;
  late String _updatedFirst;
  late DateTime _updatedDob;
  late String _updatedGender;
  late List<Tuple2<String, bool>> _updatedNumbers;
  Tuple2<String, bool>? _newNumber;

  @override
  void initState() {
    super.initState();
    _updatedMrn = widget.identity.mrn;
    _updatedLast = widget.identity.patientLast;
    _updatedFirst = widget.identity.patientFirst;
    _updatedDob = widget.identity.dateOfBirth;
    _updatedGender = widget.identity.gender;
    _updatedNumbers = widget.identity.phones.map((phone) => Tuple2(phone.number, phone.delete)).toList();
  }

  @override
  Widget build(BuildContext context) {
    Widget _addPhone = TextButton(
      onPressed: () {
        setState(() {
          _newNumber = const Tuple2("", false);
        });
      },
      child: const Text('Add Phone Number'),
    );

    List<Widget> _phoneNumbers = widget.identity.phones
        .asMap()
        .entries
        .map((entry) => {
              TextFormField(
                style: TextStyle(color: getColor(_updatedNumbers[entry.key].item2)),
                decoration: InputDecoration(
                  filled: false,
                  labelText: 'Phone Number :' + entry.value.number,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _updatedNumbers[entry.key] = _updatedNumbers[entry.key].withItem2(!_updatedNumbers[entry.key].item2);
                      });
                    },
                    icon: getIcon(_updatedNumbers[entry.key].item2),
                  ),
                ),
                initialValue: entry.value.number,
                onChanged: (value) {
                  setState(() {
                    _updatedNumbers[entry.key] = _updatedNumbers[entry.key].withItem1(value);
                  });
                },
              )
            })
        .expand((phoneNumberField) => phoneNumberField)
        .toList();

    if (_newNumber != null) {
      Widget _newPhoneNumber = TextFormField(
        style: TextStyle(color: getColor(_newNumber!.item2)),
        decoration: InputDecoration(
          filled: false,
          labelText: 'New Phone Number :',
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _newNumber = _newNumber!.withItem2(!_newNumber!.item2);
              });
            },
            icon: getIcon(_newNumber!.item2),
          ),
        ),
        initialValue: "",
        onChanged: (value) {
          setState(() {
            _newNumber = _newNumber!.withItem1(value);
          });
        },
      );

      _phoneNumbers.add(_newPhoneNumber);
    }

    Column _phoneContent;
    if (_newNumber == null) {
      _phoneContent = Column(children: [Column(children: _phoneNumbers), _addPhone]);
    } else {
      _phoneContent = Column(children: _phoneNumbers);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      constraints: const BoxConstraints(minHeight: 550, minWidth: 600, maxHeight: 550, maxWidth: 600),
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
              labelText: 'MRN:' + widget.identity.mrn,
            ),
            initialValue: widget.identity.mrn,
            onChanged: (value) {
              setState(() {
                _updatedMrn = value;
              });
            },
          ),
          TextFormField(
            decoration: InputDecoration(
              filled: false,
              labelText: 'Last Name:' + widget.identity.patientLast,
            ),
            initialValue: widget.identity.patientLast,
            onChanged: (value) {
              setState(() {
                _updatedLast = value;
              });
            },
          ),
          TextFormField(
            decoration: InputDecoration(
              filled: false,
              labelText: 'First Name:' + widget.identity.patientFirst,
            ),
            initialValue: widget.identity.patientFirst,
            onChanged: (value) {
              setState(() {
                _updatedFirst = value;
              });
            },
          ),
          InputDatePickerFormField(
            fieldLabelText: 'DOB:' + DateFormat('dd/MM/yyyy').format(widget.identity.dateOfBirth),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            initialDate: widget.identity.dateOfBirth,
            onDateSubmitted: (value) {
              setState(() {
                _updatedDob = value;
              });
            },
          ),
          TextFormField(
            decoration: InputDecoration(
              filled: false,
              labelText: 'Gender:' + widget.identity.gender,
            ),
            initialValue: widget.identity.gender,
            onChanged: (value) {
              setState(() {
                _updatedGender = value;
              });
            },
          ),
          SingleChildScrollView(
            child: _phoneContent,
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
                      widget.identity.mrn = _updatedMrn;
                      widget.identity.patientFirst = _updatedFirst;
                      widget.identity.patientLast = _updatedLast;
                      widget.identity.gender = _updatedGender;
                      widget.identity.dateOfBirth = _updatedDob;

                      for (var i = 0; i < widget.identity.phones.length; i++) {
                        widget.identity.phones[i].number = _updatedNumbers[i].item1;
                        widget.identity.phones[i].delete = _updatedNumbers[i].item2;
                      }

                      if (_newNumber != null) {
                        Phone newPhone = Phone(id: null, identityId: null, number: _newNumber!.item1, type: "");
                        newPhone.delete = _newNumber!.item2;

                        widget.identity.phones.add(newPhone);
                      }

                      _updateIdentity(widget.identity).then((updated) {
                        Navigator.pop(context);
                        widget.refresh();
                      });
                    },
                  ),
                ),
              ])),
        ],
      ),
    );
  }

  Icon getIcon(bool delete) {
    if (delete) {
      return const Icon(
        Icons.delete,
        color: Colors.redAccent,
      );
    } else {
      return const Icon(
        Icons.delete,
      );
    }
  }

  Color? getColor(bool delete) {
    if (delete) {
      return Colors.redAccent;
    } else {
      return null;
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
}

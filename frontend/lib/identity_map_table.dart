import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';
import 'models.dart';

class IdentityMapTable extends StatefulWidget {
  const IdentityMapTable({Key? key}) : super(key: key);

  @override
  _IdentityMapTableState createState() => _IdentityMapTableState();
}

class _IdentityMapTableState extends State<IdentityMapTable> {
  late Future<List<IdentityMap>> _futureIdentityMaps;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Padding(
              padding: EdgeInsets.only(top: 40.0, bottom: 10.0),
              child: Text("Identity Map",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          FutureBuilder<List<IdentityMap>>(
              future: _futureIdentityMaps,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _identityMapTable(snapshot.data!);
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

  Widget _identityMapTable(List<IdentityMap> identityMaps) {
    List<TableRow> identityRows =
        identityMaps.map<TableRow>((IdentityMap identityMap) {
      return TableRow(children: <Widget>[
        createCell(identityMap.id.toString()),
        createCell(identityMap.identity.id.toString()),
        _createEditCell(identityMap),
      ]);
    }).toList();

    List<TableRow> tableContent = [_identityMapHeaders()];
    tableContent.addAll(identityRows);

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(100),
        1: FixedColumnWidth(100),
        2: FixedColumnWidth(40),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableContent,
    );
  }

  TableRow _identityMapHeaders() {
    return TableRow(
      children: <Widget>[
        createHeader("Id"),
        createHeader("Identity Id"),
        createHeader("Edit"),
      ],
    );
  }

  TableCell _createEditCell(IdentityMap identityMap) {
    return TableCell(
      child: SizedBox(
        height: 24,
        child: Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              child: const Icon(
                Icons.edit,
                color: Colors.blue,
                size: 22.0,
              ),
              onTap: () {
                _showEditModal(context, identityMap);
              },
            ),
          ),
        ),
      ),
    );
  }

  _showEditModal(context, IdentityMap identityMap) {
    int newIdentityId = identityMap.identity.id;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              constraints: const BoxConstraints(
                  minHeight: 300, minWidth: 600, maxHeight: 300, maxWidth: 600),
              child: Column(
                children: [
                  const Text(
                    "Edit Identity Mapping",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: false,
                      labelText:
                          'Identity Id: ' + identityMap.identity.id.toString(),
                    ),
                    initialValue: identityMap.identity.id.toString(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      setState(() {
                        int? parsedVal = int.tryParse(value);
                        newIdentityId = parsedVal ?? newIdentityId;
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
                                  _updateIdentityMap(identityMap, newIdentityId)
                                      .then((updated) {
                                    Navigator.pop(context);
                                    setState(() {
                                      _futureIdentityMaps =
                                          _fetchIdentityMaps();
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

  @override
  void initState() {
    super.initState();
    _futureIdentityMaps = _fetchIdentityMaps();
  }

  Future<List<IdentityMap>> _fetchIdentityMaps() async {
    http.Response response =
        await http.get(Uri.http('localhost:8080', 'api/identity-maps'));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List)
          .map((identityMap) => IdentityMap.fromJson(identityMap))
          .toList();
    } else {
      throw Exception('Failed to load identity maps');
    }
  }

  Future<bool> _updateIdentityMap(
      IdentityMap identityMap, int newIdentityId) async {
    String url = 'api/identity-maps/update/' + identityMap.id.toString();
    http.Response response = await http.put(Uri.http('localhost:8080', url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
          json.encode(newIdentityId),
        ));

    if (response.statusCode == HttpStatus.created) {
      return true;
    } else {
      throw Exception('Failed to update identity');
    }
  }
}

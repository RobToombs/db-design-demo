import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';
import 'models.dart';

class IdentityMapHistoryTable extends StatefulWidget {
  const IdentityMapHistoryTable({Key? key}) : super(key: key);

  @override
  IdentityMapHistoryTableState createState() => IdentityMapHistoryTableState();
}

class IdentityMapHistoryTableState extends State<IdentityMapHistoryTable> {
  late Future<List<IdentityMapHistory>> _futureIdentityMapHistories;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.only(top: 40.0, bottom: 10.0), child: Text("Identity Map History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          FutureBuilder<List<IdentityMapHistory>>(
              future: _futureIdentityMapHistories,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _identityMapHistoryTable(snapshot.data!);
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

  Widget _identityMapHistoryTable(List<IdentityMapHistory> identityMapHistories) {
    List<TableRow> identityRows = identityMapHistories.map<TableRow>((IdentityMapHistory identityMapHistory) {
      return TableRow(children: <Widget>[
        createCell(identityMapHistory.id.toString()),
        createCell(formatDateTime(identityMapHistory.createDate)),
        createCell(identityMapHistory.identityMapId.toString()),
        createCell(identityMapHistory.oldIdentityId.toString()),
        createCell(identityMapHistory.newIdentityId.toString()),
        createCell(identityMapHistory.createdBy),
        createCell(identityMapHistory.event),
      ]);
    }).toList();

    List<TableRow> tableContent = [_identityHeaders()];
    tableContent.addAll(identityRows);

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(100),
        1: FixedColumnWidth(160),
        2: FixedColumnWidth(120),
        3: FixedColumnWidth(120),
        4: FixedColumnWidth(120),
        5: FixedColumnWidth(200),
        6: FixedColumnWidth(120),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableContent,
    );
  }

  TableRow _identityHeaders() {
    return TableRow(
      children: <Widget>[
        createHeader("Id"),
        createHeader("Create Date"),
        createHeader("Identity Map Id"),
        createHeader("Old Identity Id"),
        createHeader("New Identity Id"),
        createHeader("Created By"),
        createHeader("Event"),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    updateIdentityMapHistories();
  }

  void updateIdentityMapHistories() {
    setState(() {
      _futureIdentityMapHistories = _fetchIdentityMapHistories();
    });
  }

  Future<List<IdentityMapHistory>> _fetchIdentityMapHistories() async {
    http.Response response = await http.get(Uri.http('localhost:8080', 'api/identity-map-histories'));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List).map((identityMapHistory) => IdentityMapHistory.fromJson(identityMapHistory)).toList();
    } else {
      throw Exception('Failed to load identity map histories');
    }
  }
}

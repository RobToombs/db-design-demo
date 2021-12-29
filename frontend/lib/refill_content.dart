import 'dart:convert';
import 'dart:html';

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
      return TableRow(children: <Widget>[
        createCell(refill.id.toString()),
        createCell(formatDate(refill.date)),
        createCell(refill.medication),
        createCell(refill.callAttempts.toString()),
        createCell(refill.identityMap.identity.upi),
        createCell(refill.identityMap.identity.mrn),
        createCell(refill.identityMap.identity.patientLast),
        createCell(refill.identityMap.identity.patientFirst),
        createCell(formatDate(refill.identityMap.identity.dateOfBirth)),
        createCell(refill.identityMap.identity.gender),
      ]);
    }).toList();

    List<TableRow> tableContent = [_refillHeaders()];
    tableContent.addAll(refillRows);

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(50),
        1: FixedColumnWidth(120),
        3: FixedColumnWidth(110),
        8: FixedColumnWidth(120),
        9: FixedColumnWidth(70),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableContent,
    );
  }

  TableRow _refillHeaders() {
    return TableRow(
      children: <Widget>[
        createHeader("Id"),
        createHeader("Date"),
        createHeader("Medication"),
        createHeader("Call Attempts"),
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
    _futureRefills = _fetchRefills();
  }

  Future<List<Refill>> _fetchRefills() async {
    http.Response response =
        await http.get(Uri.http('localhost:8080', 'api/refills'));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List)
          .map((refill) => Refill.fromJson(refill))
          .toList();
    } else {
      throw Exception('Failed to load refills');
    }
  }
}

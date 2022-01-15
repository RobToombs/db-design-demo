import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';
import 'models.dart';

class AuditContent extends StatelessWidget {
  const AuditContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AuditTable();
  }
}

class AuditTable extends StatefulWidget {
  const AuditTable({Key? key}) : super(key: key);

  @override
  _AuditTableState createState() => _AuditTableState();
}

class _AuditTableState extends State<AuditTable> {
  late Future<List<Identity>> _futureUniqueIdentities;
  Future<List<Audit>>? _futureAuditList;
  Identity? _selectedIdentity;

  @override
  void initState() {
    super.initState();
    _futureUniqueIdentities = _fetchUniqueIdentities();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [_identityListView(), _auditListView()],
        )
      ],
    );
  }

  Widget _auditListView() {
    return FutureBuilder<List<Audit>>(
        future: _futureAuditList,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _createAuditListView(snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else {
            return Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Text("Select an identity")]);
          }
        });
  }

  Widget _createAuditListView(List<Audit> auditTrail) {
    ListView auditList = ListView.builder(
      itemCount: auditTrail.length,
      itemBuilder: (context, index) {
        Audit audit = auditTrail[index];

        return Text(audit.createdBy);
      },
    );

    return SizedBox(height: 885, width: 1000, child: auditList);
  }

  Widget _identityListView() {
    return FutureBuilder<List<Identity>>(
        future: _futureUniqueIdentities,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _createIdentityList(snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else {
            return circularProgressIndicatorWidget();
          }
        });
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
                    _futureAuditList = _auditTrail(identity);
                  });
                }));
      },
    );

    return Container(
        margin: const EdgeInsets.only(right: 10.0),
        decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.grey))),
        height: 885,
        width: 400,
        child: identityList);
  }

  Future<List<Identity>> _fetchUniqueIdentities() async {
    http.Response response = await http.get(Uri.http('localhost:8080', 'api/identities/current'));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List).map((identity) => Identity.fromJson(identity)).toList();
    } else {
      throw Exception('Failed to load identities');
    }
  }

  Future<List<Audit>> _auditTrail(Identity identity) async {
    http.Response response = await http.get(Uri.http('localhost:8080', 'api/identities/audit/' + identity.id.toString()));

    if (response.statusCode == HttpStatus.ok) {
      return (jsonDecode(response.body) as List).map((audit) => Audit.fromJson(audit)).toList();
    } else {
      throw Exception('Failed to load identities');
    }
  }
}

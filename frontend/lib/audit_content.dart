import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timelines/timelines.dart';

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
    return SizedBox(
      height: 850,
      width: 800,
      child: SingleChildScrollView(
        child: Flexible(
          child: _AuditList(audits: auditTrail),
        ),
      ),
    );
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

class _AuditList extends StatelessWidget {
  const _AuditList({Key? key, required this.audits}) : super(key: key);

  final List<Audit> audits;

  @override
  Widget build(BuildContext context) {
    String space(String event) {
      if (event == 'CREATE') {
        return 'CREATE          ';
      } else if (event == 'ACTIVATE') {
        return 'ACTIVATE        ';
      } else if (event == 'DEACTIVATE') {
        return 'DEACTIVATE   ';
      } else {
        return 'UPDATE            ';
      }
    }

    Color determineColor(String event) {
      if (event == 'CREATE') {
        return const Color(0xff565cfd);
      } else if (event == 'ACTIVATE') {
        return const Color(0xff66c97f);
      } else if (event == 'DEACTIVATE') {
        return const Color(0xffff678a);
      } else {
        return const Color(0xff2cffe0);
      }
    }

    return DefaultTextStyle(
      style: const TextStyle(
        color: Color(0xff9b9b9b),
        fontSize: 12.5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FixedTimeline.tileBuilder(
          theme: TimelineThemeData(
            nodePosition: 0,
            color: const Color(0xff989898),
            indicatorTheme: const IndicatorThemeData(
              position: 0,
              size: 20.0,
            ),
            connectorTheme: const ConnectorThemeData(
              thickness: 2.5,
            ),
          ),
          builder: TimelineTileBuilder.connected(
            connectionDirection: ConnectionDirection.before,
            itemCount: audits.length,
            contentsBuilder: (_, index) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      space(audits[index].event) + audits[index].createdBy + " - " + audits[index].createDate,
                      style: DefaultTextStyle.of(context).style.copyWith(
                            fontSize: 18.0,
                          ),
                    ),
                    _ChangeLog(event: audits[index].event, deltas: audits[index].deltas),
                  ],
                ),
              );
            },
            indicatorBuilder: (_, index) {
              return const OutlinedDotIndicator(
                borderWidth: 2.5,
              );
            },
            connectorBuilder: (_, index, ___) => SolidLineConnector(
              color: determineColor(audits[index - 1].event),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangeLog extends StatelessWidget {
  const _ChangeLog({
    required this.event,
    required this.deltas,
  });

  final String event;
  final List<Delta> deltas;

  @override
  Widget build(BuildContext context) {
    bool isEdgeIndex(int index) {
      return index == 0 || index == deltas.length + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FixedTimeline.tileBuilder(
        theme: TimelineTheme.of(context).copyWith(
          nodePosition: 0,
          connectorTheme: TimelineTheme.of(context).connectorTheme.copyWith(
                thickness: 1.0,
              ),
          indicatorTheme: TimelineTheme.of(context).indicatorTheme.copyWith(
                size: 10.0,
                position: 0.5,
              ),
        ),
        builder: TimelineTileBuilder(
          indicatorBuilder: (_, index) => !isEdgeIndex(index) ? Indicator.outlined(borderWidth: 1.0) : null,
          startConnectorBuilder: (_, index) => Connector.solidLine(),
          endConnectorBuilder: (_, index) => Connector.solidLine(),
          contentsBuilder: (_, index) {
            if (isEdgeIndex(index)) {
              return null;
            }

            if (event == 'CREATE') {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(children: [
                  Text(
                    deltas[index - 1].field,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff66c97f)),
                  ),
                  Text(" - " + deltas[index - 1].current),
                ]),
              );
            } else if (deltas[index - 1].event == 'CREATE') {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(children: [
                  Text(
                    deltas[index - 1].field,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff66c97f)),
                  ),
                  Text("      Added:  " + deltas[index - 1].current),
                ]),
              );
            } else if (deltas[index - 1].event == 'DELETE') {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(children: [
                  Text(
                    deltas[index - 1].field,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xffff678a)),
                  ),
                  Text("      Deleted:  " + deltas[index - 1].old),
                ]),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(children: [
                  Text(
                    deltas[index - 1].field,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff565cfd)),
                  ),
                  Text("      Old:  " + deltas[index - 1].old),
                  Text("      New:  " + deltas[index - 1].current),
                ]),
              );
            }
          },
          itemExtentBuilder: (_, index) => isEdgeIndex(index) ? 10.0 : 30.0,
          nodeItemOverlapBuilder: (_, index) => isEdgeIndex(index) ? true : null,
          itemCount: deltas.length + 2,
        ),
      ),
    );
  }
}

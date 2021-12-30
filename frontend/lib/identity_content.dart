import 'package:flutter/material.dart';

import 'identity_map_history_table.dart';
import 'identity_map_table.dart';
import 'identity_table.dart';

class IdentityContent extends StatelessWidget {
  IdentityContent({Key? key}) : super(key: key);

  final GlobalKey<IdentityTableState> _identityTable = GlobalKey();
  final GlobalKey<IdentityMapTableState> _identityMapTable = GlobalKey();
  final GlobalKey<IdentityMapHistoryTableState> _identityMapHistoryTable =
      GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          IdentityTable(key: _identityTable, refreshIdentity: refresh),
          IdentityMapTable(key: _identityMapTable, refreshIdentity: refresh),
          IdentityMapHistoryTable(key: _identityMapHistoryTable),
        ],
      ),
    );
  }

  refresh() {
    _identityTable.currentState?.updateIdentities();
    _identityMapTable.currentState?.updateIdentityMaps();
    _identityMapHistoryTable.currentState?.updateIdentityMapHistories();
  }
}

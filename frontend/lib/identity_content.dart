import 'package:flutter/material.dart';

import 'identity_map_history_table.dart';
import 'identity_map_table.dart';
import 'identity_table.dart';

class IdentityContent extends StatelessWidget {
  const IdentityContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: const [
          IdentityTable(),
          IdentityMapTable(),
          IdentityMapHistoryTable(),
        ],
      ),
    );
  }
}

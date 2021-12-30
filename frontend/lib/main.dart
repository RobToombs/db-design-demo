import 'package:flutter/material.dart';
import 'package:frontend/refill_content.dart';

import 'appointment_content.dart';
import 'identity_content.dart';

void main() {
  runApp(const PatientCentricApp());
}

class PatientCentricApp extends StatelessWidget {
  const PatientCentricApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Patient Centric Demo',
      home: PatientCentricPage(),
    );
  }
}

class PatientCentricPage extends StatefulWidget {
  const PatientCentricPage({Key? key}) : super(key: key);

  @override
  State<PatientCentricPage> createState() => _PatientCentricPageState();
}

class _PatientCentricPageState extends State<PatientCentricPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: Colors.blue,
            elevation: 0,
            bottom: const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.white,
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                  color: Colors.white),
              tabs: [
                Tab(text: "Appointments"),
                Tab(text: "Refills"),
                Tab(text: "Identity"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            const AppointmentContent(),
            const RefillContent(),
            IdentityContent(),
          ],
        ),
      ),
    );
  }
}

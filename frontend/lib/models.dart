import 'package:intl/intl.dart';

class Identity {
  int? id;
  String upi;
  String mrn;
  String patientLast;
  String patientFirst;
  DateTime dateOfBirth;
  String gender;
  bool active;
  DateTime? createDate;
  DateTime? endDate;
  String createdBy;
  String modifiedBy;

  Identity({
    required this.id,
    required this.upi,
    required this.mrn,
    required this.patientLast,
    required this.patientFirst,
    required this.dateOfBirth,
    required this.gender,
    required this.active,
    required this.createDate,
    required this.endDate,
    required this.createdBy,
    required this.modifiedBy,
  });

  factory Identity.fromJson(Map<String, dynamic> json) {
    return Identity(
      id: json['id'] as int,
      upi: json['upi'] as String,
      mrn: json['mrn'] as String,
      patientLast: json['patientLast'] as String,
      patientFirst: json['patientFirst'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      gender: json['gender'] as String,
      active: json['active'] as bool,
      createDate: DateTime.parse(json['createDate']),
      endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate']),
      createdBy: json['createdBy'] as String,
      modifiedBy: json['modifiedBy'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'upi': upi,
        'mrn': mrn,
        'patientLast': patientLast,
        'patientFirst': patientFirst,
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(dateOfBirth),
        'gender': gender,
        'active': active,
        'createDate': createDate == null
            ? null
            : DateFormat('yyyy-MM-dd hh:mm:ss').format(createDate!),
        'endDate': endDate == null
            ? null
            : DateFormat('yyyy-MM-dd hh:mm:ss').format(endDate!),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
      };
}

class IdentityMap {
  int? id;
  Identity identity;

  IdentityMap({
    required this.id,
    required this.identity,
  });

  factory IdentityMap.fromJson(Map<String, dynamic> json) {
    return IdentityMap(
      id: json['id'] as int,
      identity: Identity.fromJson(json['identity']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identity': identity.toJson(),
      };
}

class IdentityMapHistory {
  int id;
  DateTime createDate;
  int identityMapId;
  int oldIdentityId;
  int newIdentityId;
  String createdBy;
  String event;

  IdentityMapHistory({
    required this.id,
    required this.createDate,
    required this.identityMapId,
    required this.oldIdentityId,
    required this.newIdentityId,
    required this.createdBy,
    required this.event,
  });

  factory IdentityMapHistory.fromJson(Map<String, dynamic> json) {
    return IdentityMapHistory(
      id: json['id'] as int,
      createDate: DateTime.parse(json['createDate']),
      identityMapId: json['identityMapId'] as int,
      oldIdentityId: json['oldIdentityId'] as int,
      newIdentityId: json['newIdentityId'] as int,
      createdBy: json['createdBy'] as String,
      event: json['event'] as String,
    );
  }
}

class Appointment {
  int? id;
  IdentityMap identityMap;
  DateTime date;
  String medication;

  Appointment({
    required this.id,
    required this.identityMap,
    required this.date,
    required this.medication,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      identityMap: IdentityMap.fromJson(json['identityMap']),
      date: DateTime.parse(json['date']),
      medication: json['medication'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identityMap': identityMap.toJson(),
        'date': DateFormat('yyyy-MM-dd').format(date),
        'medication': medication,
      };
}

class Refill {
  int id;
  IdentityMap identityMap;
  DateTime date;
  int callAttempts;
  String medication;

  Refill({
    required this.id,
    required this.identityMap,
    required this.date,
    required this.callAttempts,
    required this.medication,
  });

  factory Refill.fromJson(Map<String, dynamic> json) {
    return Refill(
      id: json['id'] as int,
      identityMap: IdentityMap.fromJson(json['identityMap']),
      date: DateTime.parse(json['date']),
      callAttempts: json['callAttempts'] as int,
      medication: json['medication'] as String,
    );
  }
}

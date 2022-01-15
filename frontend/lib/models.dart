import 'package:intl/intl.dart';

class Identity {
  int? id;
  String trxId;
  String upi;
  String mrn;
  String patientLast;
  String patientFirst;
  DateTime dateOfBirth;
  String gender;
  List<Phone> phones;
  List<MrnOverflow> mrnOverflow;
  bool active;
  DateTime? createDate;
  DateTime? endDate;
  String createdBy;
  String modifiedBy;

  Identity({
    required this.id,
    required this.trxId,
    required this.upi,
    required this.mrn,
    required this.patientLast,
    required this.patientFirst,
    required this.dateOfBirth,
    required this.gender,
    required this.phones,
    required this.mrnOverflow,
    required this.active,
    required this.createDate,
    required this.endDate,
    required this.createdBy,
    required this.modifiedBy,
  });

  factory Identity.fromJson(Map<String, dynamic> json) {
    var phones = json['phones'] as List;
    List<Phone> _phones = phones.map((phone) => Phone.fromJson(phone)).toList();

    var mrnOverflow = json['mrnOverflow'] as List;
    List<MrnOverflow> _mrnOverflow = mrnOverflow.map((mrn) => MrnOverflow.fromJson(mrn)).toList();

    return Identity(
      id: json['id'] as int,
      trxId: json['trxId'] as String,
      upi: json['upi'] as String,
      mrn: json['mrn'] as String,
      patientLast: json['patientLast'] as String,
      patientFirst: json['patientFirst'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      gender: json['gender'] as String,
      phones: _phones,
      mrnOverflow: _mrnOverflow,
      active: json['active'] as bool,
      createDate: DateTime.parse(json['createDate']),
      endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate']),
      createdBy: json['createdBy'] as String,
      modifiedBy: json['modifiedBy'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trxId': trxId,
        'upi': upi,
        'mrn': mrn,
        'patientLast': patientLast,
        'patientFirst': patientFirst,
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(dateOfBirth),
        'gender': gender,
        'phones': phones.map((phone) => phone.toJson()).toList(),
        'mrnOverflow': mrnOverflow.map((mrn) => mrn.toJson()).toList(),
        'active': active,
        'createDate': createDate == null ? null : DateFormat('yyyy-MM-dd hh:mm:ss').format(createDate!),
        'endDate': endDate == null ? null : DateFormat('yyyy-MM-dd hh:mm:ss').format(endDate!),
        'modifiedBy': modifiedBy,
      };
}

class Phone {
  int? id;
  int? identityId;
  String number;
  String type;

  Phone({
    required this.id,
    required this.identityId,
    required this.number,
    required this.type,
  });

  factory Phone.fromJson(Map<String, dynamic> json) {
    return Phone(
      id: json['id'] as int,
      identityId: json['identity'] as int,
      number: json['number'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number.toString(),
        'type': type.toString(),
      };
}

class MrnOverflow {
  int? id;
  int? identityId;
  String mrn;

  MrnOverflow({
    required this.id,
    required this.identityId,
    required this.mrn,
  });

  factory MrnOverflow.fromJson(Map<String, dynamic> json) {
    return MrnOverflow(
      id: json['id'] as int,
      identityId: json['identity'] as int,
      mrn: json['mrn'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mrn': mrn.toString(),
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
  int? oldIdentityId;
  int newIdentityId;
  String event;

  IdentityMapHistory({
    required this.id,
    required this.createDate,
    required this.identityMapId,
    required this.oldIdentityId,
    required this.newIdentityId,
    required this.event,
  });

  factory IdentityMapHistory.fromJson(Map<String, dynamic> json) {
    return IdentityMapHistory(
      id: json['id'] as int,
      createDate: DateTime.parse(json['createDate']),
      identityMapId: json['identityMapId'] as int,
      oldIdentityId: json['oldIdentityId'] == null ? null : json['oldIdentityId'] as int,
      newIdentityId: json['newIdentityId'] as int,
      event: json['event'] as String,
    );
  }
}

class Appointment {
  int? id;
  Identity? finalIdentity;
  IdentityMap identityMap;
  bool active;
  DateTime date;
  String medication;

  Appointment({
    required this.id,
    required this.finalIdentity,
    required this.identityMap,
    required this.active,
    required this.date,
    required this.medication,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      finalIdentity: json['finalIdentity'] == null ? null : Identity.fromJson(json['finalIdentity']),
      identityMap: IdentityMap.fromJson(json['identityMap']),
      active: json['active'] as bool,
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
  int? id;
  Identity? finalIdentity;
  IdentityMap identityMap;
  bool active;
  DateTime date;
  int callAttempts;
  String medication;

  Refill({
    required this.id,
    required this.finalIdentity,
    required this.identityMap,
    required this.active,
    required this.date,
    required this.callAttempts,
    required this.medication,
  });

  factory Refill.fromJson(Map<String, dynamic> json) {
    return Refill(
      id: json['id'] as int,
      finalIdentity: json['finalIdentity'] == null ? null : Identity.fromJson(json['finalIdentity']),
      identityMap: IdentityMap.fromJson(json['identityMap']),
      active: json['active'] as bool,
      date: DateTime.parse(json['date']),
      callAttempts: json['callAttempts'] as int,
      medication: json['medication'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identityMap': identityMap.toJson(),
        'date': DateFormat('yyyy-MM-dd').format(date),
        'medication': medication,
        'callAttempts': callAttempts,
      };
}

class Audit {
  String createdBy;
  String createDate;
  String event;
  List<Delta> deltas;

  Audit({
    required this.createdBy,
    required this.createDate,
    required this.event,
    required this.deltas,
  });

  factory Audit.fromJson(Map<String, dynamic> json) {
    var deltas = json['deltas'] as List;
    List<Delta> _deltas = deltas.map((delta) => Delta.fromJson(delta)).toList();

    return Audit(
      createdBy: json['createdBy'],
      createDate: DateTime.parse(json['createDate']).toString(),
      event: json['event'],
      deltas: _deltas,
    );
  }
}

class Delta {
  String field;
  String old;
  String current;
  String event;

  Delta({
    required this.field,
    required this.old,
    required this.current,
    required this.event,
  });

  factory Delta.fromJson(Map<String, dynamic> json) {
    return Delta(
      field: json['field'],
      old: json['old'],
      current: json['new'],
      event: json['event'],
    );
  }
}

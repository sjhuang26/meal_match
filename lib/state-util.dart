import 'state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DbWrite {
  Map<String, dynamic> m = Map();
  void s(String? x, String field) {
    m[field] = x;
  }

  void i(int? x, String field) {
    if (x != null) m[field] = x;
  }

  void b(bool? x, String field) {
    if (x != null) m[field] = x;
  }

  void n(num? x, String field) {
    // Firebase should store this as a double
    if (x != null) m[field] = x as double;
  }

  void u(UserType? x, String field) {
    if (x != null) {
      if (x == UserType.REQUESTER) m[field] = 'REQUESTER';
      if (x == UserType.DONATOR) m[field] = 'DONATOR';
    }
  }

  void st(Status? x, String field) {
    if (x != null) {
      if (x == Status.PENDING) m[field] = 'PENDING';
      if (x == Status.CANCELLED) m[field] = 'CANCELLED';
      if (x == Status.COMPLETED) m[field] = 'COMPLETED';
    }
  }

  void r(String? id, String field, String collection) {
    m[field] = id == null
        ? "NULL"
        : FirebaseFirestore.instance.collection(collection).doc(id);
  }

  void d(DateTime? x, String field) {
    if (x != null) {
      m[field] = x;
    }
  }
}

class DbRead {
  DbRead(this.documentSnapshot)
      : x = (documentSnapshot.data() as dynamic) ?? Map<String, dynamic>() {
    if (x.isEmpty) {
      // This is an error. We shouldn't be reading documents with no data.
      throw 'Reading document with no data';

      // Notice that even though there is an error, the DbRead is still usable afterwards.
    }
  }
  final DocumentSnapshot documentSnapshot;
  final Map<String, dynamic> x;

  String? s(String field) {
    return x[field];
  }

  int? i(String field) {
    return x[field];
  }

  bool? b(String field) {
    return x[field];
  }

  num? n(String field) {
    return x[field];
  }

  UserType? u(String field) {
    if (x[field] == 'REQUESTER') return UserType.REQUESTER;
    if (x[field] == 'DONATOR') return UserType.DONATOR;
    return null;
  }

  Status? st(String field) {
    if (x[field] == 'PENDING') return Status.PENDING;
    if (x[field] == 'CANCELLED') return Status.CANCELLED;
    if (x[field] == 'COMPLETED') return Status.COMPLETED;
    return null;
  }

  String? r(String field) {
    if ((x[field] is String && x[field] == "NULL") || x[field] == null)
      return null;
    return (x[field] as DocumentReference).id;
  }

  DateTime? d(String field) {
    // you have to do this conversion
    // https://github.com/flutter/flutter/issues/31182
    if (x[field] is Timestamp) {
      return (x[field] as Timestamp).toDate();
    } else {
      return x[field];
    }
  }

  String id() {
    return documentSnapshot.id;
  }
}

class FormWrite {
  Map<String, dynamic> m = Map();
  void s(String? x, String field) {
    m[field] = x;
  }

  void i(int? x, String field) {
    m[field] = x.toString();
  }

  void b(bool? x, String field) {
    m[field] = x;
  }

  void addressInfo(String? x, num? y, num? z) {
    m['addressInfo'] = AddressInfo()
      ..address = x
      ..latCoord = y
      ..lngCoord = z;
  }

  void date(int? x, String field) {
    m[field] = x == null ? null : DateTime.fromMillisecondsSinceEpoch(x);
  }
}

class FormRead {
  FormRead(this.x);
  final Map<String, dynamic> x;
  String? s(String field) {
    return x[field];
  }

  int? i(String field) {
    return x[field];
  }

  bool? b(String field) {
    return x[field];
  }

  AddressInfo? addressInfo() {
    return x['addressInfo'];
  }
}

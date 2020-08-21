import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserType { REQUESTER, DONATOR }
enum Status { ACTIVE, CANCELLED, COMPLETED }

class DbWrite {
  Map<String, dynamic> m = Map();
  void s(String x, String field) {
    m[field] = x;
  }

  void i(int x, String field) {
    m[field] = x;
  }

  void b(bool x, String field) {
    m[field] = x;
  }

  void u(UserType x, String field) {
    m[field] = null;
    if (x == UserType.REQUESTER) m[field] = 'REQUESTER';
    if (x == UserType.DONATOR) m[field] = 'DONATOR';
  }

  void st(Status x, String field) {
    m[field] = null;
    if (x == Status.ACTIVE) m[field] = 'ACTIVE';
    if (x == Status.CANCELLED) m[field] = 'CANCELLED';
    if (x == Status.COMPLETED) m[field] = 'COMPLETED';
  }

  void r(String id, String field, String collection) {
    m[field] = id == null
        ? "NULL"
        : Firestore.instance.collection(collection).document(id);
  }
}

class DbRead {
  DbRead(this.x);
  final DocumentSnapshot x;

  String s(String field) {
    return x.data[field];
  }

  int i(String field) {
    return x.data[field];
  }

  bool b(String field) {
    return x.data[field];
  }

  UserType u(String field) {
    if (x.data[field] == 'REQUESTER') return UserType.REQUESTER;
    if (x.data[field] == 'DONATOR') return UserType.DONATOR;
    return null;
  }

  Status st(String field) {
    if (x.data[field] == 'ACTIVE') return Status.ACTIVE;
    if (x.data[field] == 'CANCELLED') return Status.CANCELLED;
    if (x.data[field] == 'COMPLETED') return Status.COMPLETED;
  }

  String r(String field) {
    if (x.data[field] is String && x.data[field] == "NULL") return null;
    return (x.data[field] as DocumentReference).documentID;
  }

  String id() {
    return x.documentID;
  }
}

class FormWrite {
  Map<String, dynamic> m = Map();
  void s(String x, String field) {
    m[field] = x;
  }

  void i(int x, String field) {
    m[field] = x.toString();
  }

  void b(bool x, String field) {
    m[field] = x;
  }
}

class FormRead {
  FormRead(this.x);
  final Map<String, dynamic> x;
  String s(String field) {
    return x[field];
  }

  int i(String field) {
    return x[field];
  }

  bool b(String field) {
    return x[field];
  }
}

class AuthenticationModel extends ChangeNotifier {
  static final FirebaseAnalytics analytics = FirebaseAnalytics();
  static final FirebaseAuth auth = FirebaseAuth.instance;

  bool _isLoggedIn;
  UserType _userType;
  String _requesterId;
  String _donatorId;
  String _email;

  bool get isLoggedIn => _isLoggedIn;
  UserType get userType => _userType;
  String get requesterId => _requesterId;
  String get donatorId => _donatorId;

  AuthenticationModel() {
    _update(null);
    auth.onAuthStateChanged.listen((user) {
      _update(user);
    });
    _initialize();
  }

  Future<void> _initialize() async {
    _update(await FirebaseAuth.instance.currentUser());
  }

  Future<void> _update(FirebaseUser user) async {
    _userType = null;
    _requesterId = null;
    _donatorId = null;
    _email = null;
    if (user == null) {
      _isLoggedIn = false;
    } else {
      final userObject = await Api.getUserWithUid(user.uid);
      if (userObject != null) {
        _isLoggedIn = true;
        _userType = userObject.userType;
        _email = user.email;
        if (_userType == UserType.REQUESTER) _requesterId = user.uid;
        if (_userType == UserType.DONATOR) _donatorId = user.uid;
      }
    }
    notifyListeners();
  }

  Future<void> attemptLogin(String email, String password) async {
    analytics.logEvent(name: 'test_event');
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  Future<void> signUpDonator(
      BaseUser user, BasePrivateUser privateUser, SignUpData data) async {
    final result = await auth.createUserWithEmailAndPassword(
        email: data.email, password: data.password);
    await Api.signUpDonator(user, privateUser, data, result.user);
    _update(result.user);
  }

  Future<void> signUpRequester(
      BaseUser user, BasePrivateUser privateUser, SignUpData data) async {
    final result = await auth.createUserWithEmailAndPassword(
        email: data.email, password: data.password);
    await Api.signUpRequester(user, privateUser, data, result.user);
    _update(result.user);
  }

  Future<void> userChangePassword(UserChangePasswordData data) async {
    final user = await auth.currentUser();
    await user.reauthenticateWithCredential(EmailAuthProvider.getCredential(
        email: _email, password: data.oldPassword));
    await user.updatePassword(data.newPassword);
  }

  Future<void> userChangeEmail(UserChangeEmailData data) async {
    final user = await auth.currentUser();
    await user.reauthenticateWithCredential(EmailAuthProvider.getCredential(
        email: _email, password: data.oldPassword));
    await user.updateEmail(data.email);
    _email = data.email;
  }
}

class ChatMessage {
  String id;
  String donatorId;
  String requesterId;
  String message;
  UserType speaker;
  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..r(donatorId, 'donator', 'donators')
          ..r(requesterId, 'requester', 'requesters')
          ..s(message, 'message')
          ..u(speaker, 'speaker'))
        .m;
  }

  void dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    id = o.id();
    donatorId = o.r('donator');
    requesterId = o.r('requester');
    message = o.s('message');
    speaker = o.u('speaker');
  }

  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    message = o.s('message');
  }
}

class Interest {
  String id;
  String donationId;
  String requesterId;
  Status status;
  int numAdultMeals;
  int numChildMeals;
  String requestedPickupLocation;
  String requestedPickupDateAndTime;

  Map<String, dynamic> dbWrite() {
    return (DbWrite()..r(donationId, 'donation', 'donations')..r(requesterId, 'requester', 'requesters')..st(status, 'status')..i(numAdultMeals, 'numAdultMeals')..i(numChildMeals, 'numChildMeals')..s(requestedPickupLocation, 'requestedPickupLocation')..s(requestedPickupDateAndTime, 'requestedPickupDateAndTime')).m;
  }

  void dbRead(DocumentSnapshot x) {
    final o = DbRead(x);
    id = o.id();
    donationId = o.r('donation');
    requesterId = o.r('requester');
    status = o.st('status');
    numAdultMeals = o.i('numAdultMeals');
    numChildMeals = o.i('numChildMeals');
    requestedPickupLocation = o.s('requestedPickupLocation');
    requestedPickupDateAndTime = o.s('requestedPickupDateAndTime');
  }
}

class LeaderboardEntry {
  String name;
  int numMeals;
}

class BaseUser {
  String id;
  String name;
  String zipCode;
  DbRead _dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    id = o.id();
    name = o.s('name');
    zipCode = o.s('zipCode');
    return o;
  }

  FormRead _formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    name = o.s('name');
    zipCode = o.s('zipCode');
    return o;
  }

  FormWrite _formWrite() {
    return FormWrite()..s(name, 'name')..s(zipCode, 'zipCode');
  }

  DbWrite _dbWrite(String privateCollection) {
    return DbWrite()..s(name, 'name')..s(zipCode, 'zipCode');
  }
}

class Donator extends BaseUser {
  int numMeals;
  bool isRestaurant;
  String restaurantName;
  String foodDescription;

  void dbRead(DocumentSnapshot x) {
    var o = _dbRead(x);
    numMeals = o.i('numMeals');
    isRestaurant = o.b('isRestaurant');
    restaurantName = o.s('restaurantName');
    foodDescription = o.s('foodDescription');
  }

  Map<String, dynamic> dbWrite() {
    return (_dbWrite('privateDonators')
          ..i(numMeals, 'numMeals')
          ..b(isRestaurant, 'isRestaurant')
          ..s(restaurantName, 'restaurantName')
          ..s(foodDescription, 'foodDescription'))
        .m;
  }

  void formRead(Map<String, dynamic> x) {
    final o = super._formRead(x);
    isRestaurant = o.b('isRestaurant');
    restaurantName = o.s('restaurantName');
    foodDescription = o.s('foodDescription');
  }

  Map<String, dynamic> formWrite() {
    return (_formWrite()..b(isRestaurant, 'isRestaurant')
      ..s(restaurantName, 'restaurantName')
      ..s(foodDescription, 'foodDescription')).m;
  }
}

class Requester extends BaseUser {
  void dbRead(DocumentSnapshot x) {
    _dbRead(x);
  }

  Map<String, dynamic> dbWrite() {
    return _dbWrite('privateRequesters').m;
  }

  void formRead(Map<String, dynamic> x) {
    _formRead(x);
  }

  Map<String, dynamic> formWrite() {
    return _formWrite().m;
  }
}

class BasePrivateUser {
  String id;
  String phone;
  bool newsletter;
  void dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    id = o.id();
    phone = o.s('phone');
    newsletter = o.b('newsletter');
  }

  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    phone = o.s('phone');
    newsletter = o.b('newsletter');
  }

  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..s(phone, 'phone')
          ..b(newsletter, 'newsletter'))
        .m;
  }

  Map<String, dynamic> formWrite() {
    return (FormWrite()
          ..s(phone, 'phone')
          ..b(newsletter, 'newsletter'))
        .m;
  }
}

class PrivateDonator extends BasePrivateUser {}

class PrivateRequester extends BasePrivateUser {}

class UserChangePasswordData {
  String oldPassword;
  String newPassword;
  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    oldPassword = o.s('oldPassword');
    newPassword = o.s('password');
  }
}

class UserChangeEmailData {
  String oldPassword;
  String email;
  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    oldPassword = o.s('oldPassword');
    email = o.s('email');
  }
}

class UserData {
  String name;
  String streetAddress;
  String zipCode;
  String bio;
  String email;
  String phoneNumber;
  bool newsletter;
}

class SignUpData {
  String email;
  String password;
  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    email = o.s('email');
    password = o.s('password');
  }
}

class User {
  UserType userType;
  Map<String, dynamic> dbWrite() {
    return (DbWrite()..u(userType, 'userType')).m;
  }

  void dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    userType = o.u('userType');
  }
}

class Api {
  static final Firestore fire = Firestore.instance;

  static dynamic fireRefNullable(String collection, String id) {
    return id == null ? "NULL" : fire.collection(collection).document(id);
  }

  static DocumentReference fireRef(String collection, String id) {
    return fire.collection(collection).document(id);
  }

  static Future<DocumentSnapshot> fireGet(String collection, String id) {
    return fire.collection(collection).document(id).get();
  }

  static Future<void> fireUpdate(
      String collection, String id, Map<String, dynamic> data) {
    return fire.collection(collection).document(id).updateData(data);
  }

  static Future<void> fireAdd(String collection, Map<String, dynamic> data) {
    return fire.collection(collection).add(data);
  }

  static Future<void> fireDelete(String collection, String id) {
    return fire.collection(collection).document(id).delete();
  }

  static Future<void> editPrivateDonator(PrivateDonator x) {
    return fireUpdate('privateDonators', x.id, x.dbWrite());
  }

  static Future<void> editPrivateRequester(PrivateRequester x) {
    return fireUpdate('privateRequesters', x.id, x.dbWrite());
  }

  static Future<void> editDonator(Donator x) {
    return fireUpdate('donators', x.id, x.dbWrite());
  }

  static Future<void> editRequester(Requester x) {
    return fireUpdate('requesters', x.id, x.dbWrite());
  }

  static Future<void> editDonation(Donation x) {
    return fire.runTransaction((transaction) async {
      var result = Donator()
        ..dbRead(await transaction.get(fireRef('donators', x.donatorId)));
      result.numMeals -= x.initialNumMeals;
      result.numMeals += x.numMeals;
      await transaction.set(fireRef('donators', result.id), result.dbWrite());
      await transaction.set(fireRef('donations', x.id), x.dbWrite());
    });
  }

  static Future<void> newPublicRequest(PublicRequest x) {
    return fireAdd('publicRequests', x.dbWrite());
  }

  static Future<void> newDonation(Donation x) {
    return fire.runTransaction((transaction) async {
      var result = Donator()
        ..dbRead(await transaction.get(fireRef('donators', x.donatorId)));
      result.numMeals += x.numMeals;
      await transaction.set(fireRef('donators', result.id), result.dbWrite());
      await transaction.set(fireRef('donations', x.id), x.dbWrite());
    });
  }

  static Future<void> newChatMessage(ChatMessage x) {
    return fireAdd('chatMessages', x.dbWrite());
  }

  static Future<void> signUpDonator(Donator user, PrivateDonator privateUser,
      SignUpData data, FirebaseUser firebaseUser) async {
    final batch = fire.batch();
    batch.setData(
        fireRef('privateDonators', firebaseUser.uid), privateUser.dbWrite());
    batch.setData(fireRef('donators', firebaseUser.uid), user.dbWrite());
    batch.setData(fireRef('users', firebaseUser.uid),
        (User()..userType = UserType.DONATOR).dbWrite());
    return batch.commit();
  }

  static Future<void> signUpRequester(
      Requester user,
      PrivateRequester privateUser,
      SignUpData data,
      FirebaseUser firebaseUser) async {
    final batch = fire.batch();
    batch.setData(
        fireRef('privateRequesters', firebaseUser.uid), privateUser.dbWrite());
    batch.setData(fireRef('requesters', firebaseUser.uid), user.dbWrite());
    batch.setData(fireRef('users', firebaseUser.uid),
        (User()..userType = UserType.REQUESTER).dbWrite());
    return batch.commit();
  }

  static Future<PrivateDonator> getPrivateDonator(String id) async {
    return PrivateDonator()..dbRead(await fireGet('privateDonators', id));
  }

  static Future<PrivateRequester> getPrivateRequester(String id) async {
    return PrivateRequester()..dbRead(await fireGet('privateRequesters', id));
  }

  static Future<List<PublicRequest>> getPublicRequestsByDonationId(
      String id) async {
    final QuerySnapshot results = await fire
        .collection('publicRequests')
        .where('donation', isEqualTo: fireRefNullable('donations', id))
        .getDocuments();
    return results.documents.map((x) => PublicRequest()..dbRead(x)).toList();
  }

  static Future<List<PublicRequest>> getRequesterPublicRequests(
      String id) async {
    final QuerySnapshot results = await fire
        .collection('publicRequests')
        .where('requester', isEqualTo: fireRefNullable('requesters', id))
        .getDocuments();
    return results.documents.map((x) => PublicRequest()..dbRead(x)).toList();
  }

  static Future<List<ChatMessage>> getChatMessagesByUsers(
      ChatUsers users) async {
    final QuerySnapshot results = await fire
        .collection('chatMessages')
        .where('donator',
            isEqualTo: fireRefNullable('donators', users.donatorId))
        .where('requester',
            isEqualTo: fireRefNullable('requesters', users.requesterId))
        .getDocuments();
    return results.documents.map((x) => ChatMessage()..dbRead(x)).toList();
  }

  static Future<Donator> getDonator(String id) async {
    return Donator()..dbRead(await fireGet('donators', id));
  }

  static Future<Requester> getRequester(String id) async {
    return Requester()..dbRead(await fireGet('requesters', id));
  }

  static Future<User> getUserWithUid(String uid) async {
    final user = await fireGet('users', uid);
    if (user == null) return null;
    return User()..dbRead(user);
  }

  static Future<PublicRequest> getPublicRequest(String id) async {
    return PublicRequest()..dbRead(await fireGet('publicRequests', id));
  }

  static Future<List<Donation>> getAllDonations() async {
    final QuerySnapshot results =
        await fire.collection('donations').getDocuments();
    return results.documents.map((x) => Donation()..dbRead(x)).toList();
  }

  static Future<Donation> getDonationById(String id) async {
    return Donation()..dbRead(await fireGet('donations', id));
  }

  static Future<List<Donation>> getDonatorDonations(String id) async {
    final QuerySnapshot results = await fire
        .collection('donations')
        .where('donator', isEqualTo: fireRefNullable('donators', id))
        .getDocuments();
    return results.documents.map((x) => Donation()..dbRead(x)).toList();
  }

  static Future<void> deletePublicRequest(String id) {
    return fireDelete('publicRequests', id);
  }

  static Future<void> deleteDonation(Donation x) {
    return fire.runTransaction((transaction) async {
      var result = Donator()
        ..dbRead(await transaction.get(fireRef('donators', x.donatorId)));
      result.numMeals -= x.initialNumMeals;
      await transaction.set(fireRef('donators', result.id), result.dbWrite());
      await transaction.delete(fireRef('donations', x.id));
    });
  }

  static Future<void> editPublicRequestCommitting(
      {@required PublicRequest publicRequest,
      @required Donation donation,
      @required UserType committer}) {
    return fire.runTransaction((transaction) async {
      debugPrint(publicRequest.donationId);
      debugPrint(donation?.id);
      if (publicRequest.donationId != null && donation?.id == null) {
        var result = Donation()
          ..dbRead(await transaction
              .get(fireRef('donations', publicRequest.donationId)));
        result.numMealsRequested -= publicRequest.numMeals;
        await transaction.update(
            fireRef('donations', result.id), result.dbWrite());
      } else if (publicRequest.donationId == null && donation?.id != null) {
        var result = Donation()
          ..dbRead(await transaction.get(fireRef('donations', donation.id)));
        result.numMealsRequested += publicRequest.numMeals;
        await transaction.update(
            fireRef('donations', result.id), result.dbWrite());
      }
      await transaction.update(
          fireRef('publicRequests', publicRequest.id),
          (publicRequest
                ..donationId = donation?.id
                ..committer = committer)
              .dbWrite());
    });
  }

  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    final QuerySnapshot results =
        await fire.collection('donators').orderBy('numMeals').getDocuments();
    return results.documents.map((x) {
      var y = Donator()..dbRead(x);
      return LeaderboardEntry()
        ..name = y.name
        ..numMeals = y.numMeals;
    }).toList();
  }

  static Future<List<Requester>> getRequestersWithChats(String id) async {
    final QuerySnapshot results = await fire
        .collection('chatMessages')
        .where('donator', isEqualTo: fireRef('donators', id))
        .getDocuments();
    final Set<String> requesterIdSet = {};
    for (DocumentSnapshot x in results.documents) {
      requesterIdSet.add((ChatMessage()..dbRead(x)).requesterId);
    }
    final List<String> requesterIds = requesterIdSet.toList();
    final List<Requester> results2 = [];
    for (String id in requesterIds) {
      results2.add(Requester()
        ..dbRead(await fire.collection('requesters').document(id).get()));
    }
    return results2;
  }

  static Future<List<Donator>> getDonatorsWithChats(String id) async {
    final QuerySnapshot results = await fire
        .collection('chatMessages')
        .where('requester', isEqualTo: fireRef('requesters', id))
        .getDocuments();
    final Set<String> donatorIdSet = {};
    for (DocumentSnapshot x in results.documents) {
      donatorIdSet.add((ChatMessage()..dbRead(x)).donatorId);
    }
    final List<String> donatorIds = donatorIdSet.toList();
    final List<Donator> results2 = [];
    for (String id in donatorIds) {
      results2.add(Donator()
        ..dbRead(await fire.collection('donators').document(id).get()));
    }
    return results2;
  }

  static Future<void> newInterest(Interest x) {
    return fireAdd('interests', x.dbWrite());
  }

  static Future<List<Interest>> getInterestsByDonation(String donationId) async {
    final QuerySnapshot results = await fire
        .collection('interests')
        .where('donation', isEqualTo: fireRef('donations', donationId))
        .getDocuments();
    return results.documents.map((x) => Interest()..dbRead(x)).toList();
  }

  static Future<List<Interest>> getInterestsByRequesterId(String requesterId) async {
    final QuerySnapshot results = await fire
        .collection('interests')
        .where('requester', isEqualTo: fireRef('requesters', requesterId))
        .getDocuments();
    return results.documents.map((x) => Interest()..dbRead(x)).toList();
  }
}

class ChatUsers {
  const ChatUsers({@required this.donatorId, @required this.requesterId});
  final String donatorId;
  final String requesterId;
}

class Donation {
  String id;
  String donatorId;
  int numMeals;
  int initialNumMeals;
  String dateAndTime;
  String description;
  int numMealsRequested;
  String streetAddress;
  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..r(donatorId, 'donator', 'donators')
          ..i(numMeals, 'numMeals')
          ..s(dateAndTime, 'dateAndTime')
          ..s(description, 'description')
          ..i(numMealsRequested, 'numMealsRequested')
          ..s(streetAddress, 'streetAddress'))
        .m;
  }

  void dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    id = o.id();
    donatorId = o.r('donator');
    numMeals = o.i('numMeals');
    initialNumMeals = o.i('numMeals');
    dateAndTime = o.s('dateAndTime');
    description = o.s('description');
    numMealsRequested = o.i('numMealsRequested');
    streetAddress = o.s('streetAddress');
  }

  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    numMeals = o.i('numMeals');
    dateAndTime = o.s('dateAndTime');
    description = o.s('description');
    streetAddress = o.s('streetAddress');
  }

  Map<String, dynamic> formWrite() {
    return (FormWrite()
          ..i(numMeals, 'numMeals')
          ..s(dateAndTime, 'dateAndTime')
          ..s(description, 'description')
          ..s(streetAddress, 'streetAddress'))
        .m;
  }
}

class PublicRequest {
  String id;
  String description;
  String dateAndTime;
  int numMeals;
  String requesterId;
  String donationId;
  UserType committer;
  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..s(description, 'description')
          ..s(dateAndTime, 'dateAndTime')
          ..i(numMeals, 'numMeals')
          ..r(requesterId, 'requester', 'requesters')
          ..r(donationId, 'donation', 'donations')
          ..u(committer, 'committer'))
        .m;
  }

  void dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    id = o.id();
    description = o.s('description');
    dateAndTime = o.s('dateAndTime');
    numMeals = o.i('numMeals');
    requesterId = o.r('requester');
    donationId = o.r('donation');
    committer = o.u('committer');
  }

  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    description =
        'Address: ${o.s('address')}\nNumber of meals (adult): ${o.i('numMealsAdult')}\nNumber of meals (kid): ${o.i('numMealsKid')}\nDietary restrictions: ${o.s('dietaryRestrictions').trim() == '' ? 'None' : o.s('dietaryRestrictions')}';
    dateAndTime = o.s('dateAndTime');
    numMeals = o.i('numMealsAdult') + o.i('numMealsKid');
  }
}

class PublicRequestAndDonation {
  PublicRequestAndDonation(this.publicRequest, this.donation);
  PublicRequest publicRequest;
  Donation donation;
}

class PublicRequestAndDonationId {
  PublicRequestAndDonationId(this.publicRequest, this.donationId);
  PublicRequest publicRequest;
  String donationId;
}

class DonationAndDonator {
  DonationAndDonator(this.donation, this.donator);
  Donation donation;
  Donator donator;
}

class DonationIdAndRequesterId{
  DonationIdAndRequesterId(this.donationId, this.requesterId);
  String donationId;
  String requesterId;
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;

Future<void> firebaseInitializeApp() {
  return Firebase.initializeApp();
}

enum UserType { REQUESTER, DONATOR }
enum Status { PENDING, CANCELLED, COMPLETED }

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
    if (x == Status.PENDING) m[field] = 'PENDING';
    if (x == Status.CANCELLED) m[field] = 'CANCELLED';
    if (x == Status.COMPLETED) m[field] = 'COMPLETED';
  }

  void r(String id, String field, String collection) {
    m[field] = id == null
        ? "NULL"
        : FirebaseFirestore.instance.collection(collection).doc(id);
  }

  void d(DateTime x, String field) {
    m[field] = x;
  }
}

class DbRead {
  DbRead(this.documentSnapshot) : x = documentSnapshot.data();
  final DocumentSnapshot documentSnapshot;
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

  UserType u(String field) {
    if (x[field] == 'REQUESTER') return UserType.REQUESTER;
    if (x[field] == 'DONATOR') return UserType.DONATOR;
    return null;
  }

  Status st(String field) {
    if (x[field] == 'PENDING') return Status.PENDING;
    if (x[field] == 'CANCELLED') return Status.CANCELLED;
    if (x[field] == 'COMPLETED') return Status.COMPLETED;
    return null;
  }

  String r(String field) {
    if ((x[field] is String && x[field] == "NULL") || x[field] == null)
      return null;
    return (x[field] as DocumentReference).id;
  }

  DateTime d(String field) {
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

enum AuthenticationModelState {
  NOT_LOGGED_IN,
  LOADING_LOGIN_DB,
  LOADING_LOGIN_DB_FAILED,
  LOGGED_IN
}

class AuthenticationModel extends ChangeNotifier {
  static final FirebaseAnalytics analytics = FirebaseAnalytics();
  static final firebaseAuth.FirebaseAuth auth =
      firebaseAuth.FirebaseAuth.instance;

  AuthenticationModelState _state = AuthenticationModelState.NOT_LOGGED_IN;
  UserType _userType;
  String _uid;
  String _email;
  Exception _error;

  AuthenticationModelState get state => _state;
  UserType get userType => _userType;
  String get uid => _uid;
  String get email => _email;
  Exception get error => _error;

  AuthenticationModel() {
    auth.authStateChanges().listen((user) {
      _update(user);
    });
  }

  void _nullUserInfo() {
    _userType = null;
    _uid = null;
    _email = null;
  }

  Future<void> _update(firebaseAuth.User user) async {
    print(_state);
    print(user);
    switch (_state) {
      case AuthenticationModelState.NOT_LOGGED_IN:
        if (user == null) {
          // ignore
        } else {
          _state = AuthenticationModelState.LOADING_LOGIN_DB;
          _nullUserInfo();
          notifyListeners();
          try {
            final userObject = await Api.getUserWithUid(user.uid);
            print(userObject);
            if (userObject != null) {
              _state = AuthenticationModelState.LOGGED_IN;
              _userType = userObject.userType;
              _email = user.email;
              _uid = user.uid;
              notifyListeners();
            }
          } catch (e) {
            _state = AuthenticationModelState.LOADING_LOGIN_DB_FAILED;
            _nullUserInfo();
            _error = e;
            notifyListeners();
          }
        }
        break;
      case AuthenticationModelState.LOADING_LOGIN_DB:
        // ignore
        break;
      case AuthenticationModelState.LOADING_LOGIN_DB_FAILED:
        if (user == null) {
          _state = AuthenticationModelState.NOT_LOGGED_IN;
          _nullUserInfo();
          notifyListeners();
        } else {
          // ignore
        }
        break;
      case AuthenticationModelState.LOGGED_IN:
        if (user == null) {
          _state = AuthenticationModelState.NOT_LOGGED_IN;
          _nullUserInfo();
          notifyListeners();
        } else {
          // ignore
        }
        break;
    }
  }

  Future<void> attemptLogin(String email, String password) async {
    analytics.logEvent(name: 'test_event');
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on firebaseAuth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'Wrong password';
      } else if (e.code == 'user-not-found') {
        throw 'Wrong email';
      }
      throw e;
    }
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
    final user = auth.currentUser;
    await user.reauthenticateWithCredential(
        firebaseAuth.EmailAuthProvider.credential(
            email: _email, password: data.oldPassword));
    await user.updatePassword(data.newPassword);
  }

  Future<void> userChangeEmail(UserChangeEmailData data) async {
    final user = auth.currentUser;
    await user.reauthenticateWithCredential(
        firebaseAuth.EmailAuthProvider.credential(
            email: _email, password: data.oldPassword));
    await user.updateEmail(data.email);
    _email = data.email;
  }
}

class ProfilePageInfo {
  // user type
  UserType userType;

  // for base user
  String name;

  // for Donator
  int numMeals;
  bool isRestaurant;
  String restaurantName;
  String foodDescription;

  // for BasePrivateUser
  String phone;
  bool newsletter;

  // email and password
  String email;
  String newPassword;

  // current password
  String currentPassword;

  Map<String, dynamic> formWrite() {
    return (FormWrite()
          ..s(name, 'name')
          ..b(isRestaurant, 'isRestaurant')
          ..s(restaurantName, 'restaurantName')
          ..s(foodDescription, 'foodDescription')
          ..s(phone, 'phone')
          ..b(newsletter, 'newsletter')
          ..s(email, 'email'))
        .m;
  }

  void formRead(Map<String, dynamic> x) {
    final o = FormRead(x);
    name = o.s('name');
    isRestaurant = o.b('isRestaurant');
    restaurantName = o.s('restaurantName');
    foodDescription = o.s('foodDescription');
    phone = o.s('phone');
    newsletter = o.b('newsletter');
    email = o.s('email');
    newPassword = o.s('newPassword');
    currentPassword = o.s('currentPassword');
  }
}

/*

NEW: ALL MESSAGES MUST HAVE donatorId AND requesterId FOR PERMISSIONS

TabBar for donor

Donations || Offers

chatMessages
- CASE 1 {interest, message, speakerUid, timestamp}
- CASE 2 {request, donator, message, speakerUid, timestamp}

{interest?, request?, donator?, message, speakerUid, timestamp}

*/

class ChatMessage {
  String id;

  // these are optional
  String interestId;
  String publicRequestId;

  // these are required
  String message;
  String speakerUid;
  DateTime timestamp;
  String donatorId;
  String requesterId;

  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..r(interestId, 'interest', 'interests')
          ..r(publicRequestId, 'publicRequest', 'publicRequests')
          ..r(donatorId, 'donator', 'donators')
          ..r(requesterId, 'requester', 'requesters')
          ..s(message, 'message')
          ..s(speakerUid, 'speakerUid')
          ..d(timestamp, 'timestamp'))
        .m;
  }

  void dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    id = o.id();

    interestId = o.r('interest');
    publicRequestId = o.r('publicRequest');
    donatorId = o.r('donator');
    requesterId = o.r('requester');
    message = o.s('message');
    speakerUid = o.s('speakerUid');
    timestamp = o.d('timestamp');
  }
}

class Interest {
  String id;
  String donationId;
  String donatorId;
  String requesterId;
  Status status;
  int numAdultMeals;
  int numChildMeals;
  String requestedPickupLocation;
  String requestedPickupDateAndTime;

  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..r(donationId, 'donation', 'donations')
          ..r(donatorId, 'donator', 'donators')
          ..r(requesterId, 'requester', 'requesters')
          ..st(status, 'status')
          ..i(numAdultMeals, 'numAdultMeals')
          ..i(numChildMeals, 'numChildMeals')
          ..s(requestedPickupLocation, 'requestedPickupLocation')
          ..s(requestedPickupDateAndTime, 'requestedPickupDateAndTime'))
        .m;
  }

  void dbRead(DocumentSnapshot x) {
    final o = DbRead(x);
    id = o.id();
    donationId = o.r('donation');
    donatorId = o.r('donator');
    requesterId = o.r('requester');
    status = o.st('status');
    numAdultMeals = o.i('numAdultMeals');
    numChildMeals = o.i('numChildMeals');
    requestedPickupLocation = o.s('requestedPickupLocation');
    requestedPickupDateAndTime = o.s('requestedPickupDateAndTime');
  }

  void formRead(Map<String, dynamic> x) {
    final o = FormRead(x);
    numAdultMeals = o.i('numAdultMeals');
    numChildMeals = o.i('numChildMeals');
    requestedPickupLocation = o.s('requestedPickupLocation');
    requestedPickupDateAndTime = o.s('requestedPickupDateAndTime');
    status = Status.PENDING;
  }
}

class DonatorPendingDonationsListInfo {
  List<Donation> donations;
  List<Interest> interests;
}

class RequesterDonationListInfo {
  List<Donation> donations;
  List<Interest> interests;
}

class RequesterViewInterestInfo {
  Interest interest;
  Donation donation;
  Donator donator;
  List<ChatMessage> messages;
}

class DonatorViewInterestInfo {
  Interest interest;
  Donation donation;
  Requester requester;
  List<ChatMessage> messages;
}

class RequesterViewPublicRequestInfo {
  PublicRequest publicRequest;
  Donator donator;
  List<ChatMessage> messages;
}

class DonatorViewPublicRequestInfo {
  PublicRequest publicRequest;
  List<ChatMessage> messages;
}

class LeaderboardEntry {
  String name;
  int numMeals;
  String id;
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
    return (_formWrite()
          ..b(isRestaurant, 'isRestaurant')
          ..s(restaurantName, 'restaurantName')
          ..s(foodDescription, 'foodDescription'))
        .m;
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
  // TODO for testing only
  static Future<void> editPublicRequestCommitting(
      {publicRequest, donation, committer}) async {}

  static final FirebaseFirestore fire = FirebaseFirestore.instance;

  static dynamic fireRefNullable(String collection, String id) {
    return id == null ? "NULL" : fireRef(collection, id);
  }

  static DocumentReference fireRef(String collection, String id) {
    return fire.collection(collection).doc(id);
  }

  static Future<DocumentSnapshot> fireGet(String collection, String id) {
    return fire.collection(collection).doc(id).get();
  }

  static Future<void> fireUpdate(
      String collection, String id, Map<String, dynamic> data) {
    return fire.collection(collection).doc(id).update(data);
  }

  static Future<void> fireAdd(String collection, Map<String, dynamic> data) {
    return fire.collection(collection).add(data);
  }

  static Future<void> fireDelete(String collection, String id) {
    return fire.collection(collection).doc(id).delete();
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
      transaction.update(fireRef('donators', result.id), result.dbWrite());
      transaction.update(fireRef('donations', x.id), x.dbWrite());
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
      transaction.update(fireRef('donators', result.id), result.dbWrite());
      transaction.update(fireRef('donations', x.id), x.dbWrite());
    });
  }

  static Future<void> newChatMessage(ChatMessage x) {
    return fireAdd('chatMessages', x.dbWrite());
  }

  static Future<void> signUpDonator(Donator user, PrivateDonator privateUser,
      SignUpData data, firebaseAuth.User firebaseUser) async {
    final batch = fire.batch();
    // ALl three should be batch.set because they are creating new documents.
    batch.set(
        fireRef('privateDonators', firebaseUser.uid), privateUser.dbWrite());
    batch.set(fireRef('donators', firebaseUser.uid), user.dbWrite());
    batch.set(fireRef('users', firebaseUser.uid),
        (User()..userType = UserType.DONATOR).dbWrite());
    return batch.commit();
  }

  static Future<void> signUpRequester(
      Requester user,
      PrivateRequester privateUser,
      SignUpData data,
      firebaseAuth.User firebaseUser) async {
    final batch = fire.batch();
    batch.set(
        fireRef('privateRequesters', firebaseUser.uid), privateUser.dbWrite());
    batch.set(fireRef('requesters', firebaseUser.uid), user.dbWrite());
    batch.set(fireRef('users', firebaseUser.uid),
        (User()..userType = UserType.REQUESTER).dbWrite());
    return batch.commit();
  }

  static Future<PrivateDonator> getPrivateDonator(String id) async {
    return PrivateDonator()..dbRead(await fireGet('privateDonators', id));
  }

  static Future<PrivateRequester> getPrivateRequester(String id) async {
    return PrivateRequester()..dbRead(await fireGet('privateRequesters', id));
  }

  static Future<List<PublicRequest>> getPublicRequestsByDonatorId(
      String id) async {
    final QuerySnapshot results = await fire
        .collection('publicRequests')
        .where('donator', isEqualTo: fireRef('donators', id))
        .get();
    return results.docs.map((x) => PublicRequest()..dbRead(x)).toList();
  }

  static Future<List<PublicRequest>> getRequesterPublicRequests(
      String id) async {
    final QuerySnapshot results = await fire
        .collection('publicRequests')
        .where('requester', isEqualTo: fireRefNullable('requesters', id))
        .get();
    return results.docs.map((x) => PublicRequest()..dbRead(x)).toList();
  }

  static Future<List<ChatMessage>> getChatMessagesByUsers(
      ChatUsers users) async {
    final QuerySnapshot results = await fire
        .collection('chatMessages')
        .where('donator',
            isEqualTo: fireRefNullable('donators', users.donatorId))
        .where('requester',
            isEqualTo: fireRefNullable('requesters', users.requesterId))
        .get();
    return results.docs.map((x) => ChatMessage()..dbRead(x)).toList();
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

  static Future<RequesterDonationListInfo> getRequesterDonationListInfo(
      String uid) async {
    List<Donation> donations;
    List<Interest> interests;
    await Future.wait([
      fire.collection('donations').get().then(
          (x) => donations = x.docs.map((x) => Donation()..dbRead(x)).toList()),
      fire
          .collection('interests')
          .where('requester', isEqualTo: fireRef('requesters', uid))
          .get()
          .then((x) =>
              interests = x.docs.map((x) => Interest()..dbRead(x)).toList())
    ]);
    return RequesterDonationListInfo()
      ..donations = donations
      ..interests = interests;
  }

  static Future<List<PublicRequest>> getOpenPublicRequests() async {
    final QuerySnapshot results = await fire
        .collection('publicRequests')
        .where('donator', isEqualTo: fireRefNullable('donators', null))
        .get();
    return results.docs.map((x) => PublicRequest()..dbRead(x)).toList();
  }

  static Future<Donation> getDonationById(String id) async {
    return Donation()..dbRead(await fireGet('donations', id));
  }

  static Future<DonatorPendingDonationsListInfo>
      getDonatorPendingDonationsListInfo(String uid) async {
    List<Donation> donations;
    List<Interest> interests;
    await Future.wait([
      fire
          .collection('donations')
          .where('donator', isEqualTo: fireRef('donators', uid))
          .get()
          .then((x) =>
              donations = x.docs.map((x) => Donation()..dbRead(x)).toList()),
      fire
          .collection('interests')
          .where('donator', isEqualTo: fireRef('donators', uid))
          .get()
          .then((x) =>
              interests = x.docs.map((x) => Interest()..dbRead(x)).toList())
    ]);
    return DonatorPendingDonationsListInfo()
      ..donations = donations
      ..interests = interests;
  }

  static Future<DonatorViewPublicRequestInfo> getDonatorViewPublicRequestInfo(
      PublicRequest publicRequest, String uid) async {
    return DonatorViewPublicRequestInfo()
      ..publicRequest = publicRequest
      ..messages = publicRequest.donatorId == null
          ? null
          : ((await fire
                  .collection('chatMessages')
                  .where('donator', isEqualTo: fireRef('donators', uid))
                  .where('publicRequest',
                      isEqualTo: fireRef('publicRequests', publicRequest.id))
                  .get())
              .docs
              .map((x) => ChatMessage()..dbRead(x))
              .toList());
  }

  static Future<void> deletePublicRequest(PublicRequest x) {
    return fire.runTransaction((transaction) async {
      if (x.initialDonatorId != null) {
        final result = Donator()
          ..dbRead(await transaction.get(fireRef('donators', x.donatorId)));
        result.numMeals -= x.initialNumMeals;
        transaction.update(fireRef('donators', result.id), result.dbWrite());
      }
      transaction.delete(fireRef('publicRequests', x.id));
    });
  }

  static Future<void> deleteInterest(Interest x) {
    return fireDelete('interests', x.id);
  }

  static Future<void> deleteDonation(Donation x) {
    return fire.runTransaction((transaction) async {
      var result = Donator()
        ..dbRead(await transaction.get(fireRef('donators', x.donatorId)));
      result.numMeals -= x.initialNumMeals;
      transaction.update(fireRef('donators', result.id), result.dbWrite());
      transaction.delete(fireRef('donations', x.id));
    });
  }

  static Future<void> editPublicRequest(PublicRequest x) {
    return fire.runTransaction((transaction) async {
      // This is since all writes must come after all reads.
      final List<Function> updatesToRun = [
        () => transaction.update(fireRef('publicRequests', x.id), x.dbWrite())
      ];
      final currentNumMeals = x.numMealsChild + x.numMealsAdult;
      if (x.initialDonatorId != null && currentNumMeals != x.initialNumMeals) {
        final donator = Donator()
          ..dbRead(
              await transaction.get(fireRef('donators', x.initialDonatorId)));
        donator.numMeals -= x.initialNumMeals;
        donator.numMeals += currentNumMeals;
        updatesToRun.add(() => transaction.update(
            fireRef('donators', x.donatorId), donator.dbWrite()));
      }
      if (x.initialDonatorId != null && x.donatorId == null) {
        final donator = Donator()
          ..dbRead(
              await transaction.get(fireRef('donators', x.initialDonatorId)));
        donator.numMeals -= currentNumMeals;
        updatesToRun.add(() => transaction.update(
            fireRef('donators', x.initialDonatorId), donator.dbWrite()));
      }
      if (x.initialDonatorId == null && x.donatorId != null) {
        final donator = Donator()
          ..dbRead(await transaction.get(fireRef('donators', x.donatorId)));
        donator.numMeals += currentNumMeals;
        updatesToRun.add(() => transaction.update(
            fireRef('donators', x.donatorId), donator.dbWrite()));
      }
      updatesToRun.forEach((f) => f());
    });
  }

  static Future<void> editInterest(Interest x) {
    return fireUpdate('interests', x.id, x.dbWrite());
  }

  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    final QuerySnapshot results =
        await fire.collection('donators').orderBy('numMeals').get();
    return results.docs.map((x) {
      var y = Donator()..dbRead(x);
      return LeaderboardEntry()
        ..name = y.name
        ..numMeals = y.numMeals
        ..id = y.id;
    }).toList();
  }

  static Future<void> newInterest(Interest x) {
    return fireAdd('interests', x.dbWrite());
  }

  static Future<List<Interest>> getInterestsByDonation(
      String donationId) async {
    final QuerySnapshot results = await fire
        .collection('interests')
        .where('donation', isEqualTo: fireRef('donations', donationId))
        .get();
    return results.docs.map((x) => Interest()..dbRead(x)).toList();
  }

  static Future<List<Interest>> getInterestsByRequesterId(
      String requesterId) async {
    final QuerySnapshot results = await fire
        .collection('interests')
        .where('requester', isEqualTo: fireRef('requesters', requesterId))
        .get();
    return results.docs.map((x) => Interest()..dbRead(x)).toList();
  }

  static Future<List<ChatMessage>> getChatMessagesByInterest(
      String interestId) async {
    final QuerySnapshot results = await fire
        .collection('chatMessages')
        .where('interest', isEqualTo: fireRef('interests', interestId))
        .orderBy('timestamp')
        .get();
    return results.docs.map((x) => ChatMessage()..dbRead(x)).toList();
  }

  static Future<List<ChatMessage>> getChatMessagesByRequestAndDonator(
      String publicRequestId, String donatorId) async {
    final QuerySnapshot results = await fire
        .collection('chatMessages')
        .where('', isEqualTo: fireRef('publicRequests', publicRequestId))
        .where('', isEqualTo: fireRef('donators', donatorId))
        .orderBy('timestamp')
        .get();
    return results.docs.map((x) => ChatMessage()..dbRead(x)).toList();
  }

  static Future<RequesterViewInterestInfo> getRequesterViewInterestInfo(
      Interest interest, String uid) async {
    final donation = Donation()
      ..dbRead(await fireGet('donations', interest.donationId));
    final donator = Donator()
      ..dbRead(await fireGet('donators', donation.donatorId));
    final messages = (await fire
            .collection('chatMessages')
            .where('requester', isEqualTo: fireRef('requesters', uid))
            .where('interest', isEqualTo: fireRef('interests', interest.id))
            .get())
        .docs
        .map((x) => ChatMessage()..dbRead(x))
        .toList();
    return RequesterViewInterestInfo()
      ..interest = interest
      ..donation = donation
      ..donator = donator
      ..messages = messages;
  }

  static Future<DonatorViewInterestInfo> getDonatorViewInterestInfo(
      String uid, DonationInterestAndRequester val) async {
    final messages = (await fire
            .collection('chatMessages')
            .where('donator', isEqualTo: fireRef('donators', uid))
            .where('interest', isEqualTo: fireRef('interests', val.interest.id))
            .get())
        .docs
        .map((x) => ChatMessage()..dbRead(x))
        .toList();
    return DonatorViewInterestInfo()
      ..interest = val.interest
      ..donation = val.donation
      ..requester = val.requester
      ..messages = messages;
  }

  static Future<RequesterViewPublicRequestInfo>
      getRequesterViewPublicRequestInfo(
          PublicRequest publicRequest, String uid) async {
    final result = RequesterViewPublicRequestInfo()
      ..publicRequest = publicRequest;
    if (publicRequest.donatorId != null) {
      result.donator = Donator()
        ..dbRead(await fireGet('donators', publicRequest.donatorId));
      result.messages = (await fire
              .collection('chatMessages')
              .where('requester', isEqualTo: fireRef('requesters', uid))
              .where('interest',
                  isEqualTo: fireRef('publicRequest', publicRequest.id))
              .where('donator',
                  isEqualTo: fireRef('donators', result.donator.id))
              .get())
          .docs
          .map((x) => ChatMessage()..dbRead(x))
          .toList();
    }
    return result;
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
  String description; // TODO add dietary restrictions
  int numMealsRequested;
  String streetAddress; // TODO get rid of this

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
    dateAndTime = o.s('dateAndTime');
    description = o.s('description');
    numMealsRequested = o.i('numMealsRequested');
    streetAddress = o.s('streetAddress');

    initialNumMeals = numMeals;
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
  String dateAndTime;
  int numMealsAdult;
  int numMealsChild;
  String dietaryRestrictions;
  String requesterId;
  String donatorId;
  Status status;

  // TODO for testing only
  String description;
  int numMeals;
  UserType committer;
  String donationId;

  int initialNumMeals;
  String initialDonatorId;

  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..s(dateAndTime, 'dateAndTime')
          ..i(numMealsAdult, 'numMealsAdult')
          ..i(numMealsChild, 'numMealsChild')
          ..s(dietaryRestrictions, 'dietaryRestrictions')
          ..r(requesterId, 'requester', 'requesters')
          ..r(donatorId, 'donator', 'donators')
          ..st(status, 'status'))
        .m;
  }

  void dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    id = o.id();
    dateAndTime = o.s('dateAndTime');
    numMealsAdult = o.i('numMealsAdult');
    numMealsChild = o.i('numMealsChild');
    dietaryRestrictions = o.s('dietaryRestrictions');
    requesterId = o.r('requester');
    donatorId = o.r('donator');
    status = o.st('status');

    initialNumMeals = numMealsAdult + numMealsChild;
    initialDonatorId = donatorId;
  }

  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    dateAndTime = o.s('dateAndTime');
    numMealsAdult = o.i('numMealsAdult');
    numMealsChild = o.i('numMealsChild');
    dietaryRestrictions = o.s('dietaryRestrictions');
    status = Status.PENDING;
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

class DonationIdAndRequesterId {
  DonationIdAndRequesterId(this.donationId, this.requesterId);
  String donationId;
  String requesterId;
}

class DonationAndInterests {
  DonationAndInterests(this.donation, this.interests);
  Donation donation;
  List<Interest> interests;
}

class DonationInterestAndRequester {
  DonationInterestAndRequester(this.donation, this.interest, this.requester);
  Donation donation;
  Interest interest;
  Requester requester;
}

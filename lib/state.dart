import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:firebase_storage/firebase_storage.dart' as firebaseStorage;
import 'package:shared_preferences/shared_preferences.dart'
    as sharedPreferences;
import 'package:firebase_messaging/firebase_messaging.dart'
    as firebaseMessaging;

dynamic firebaseInitializeApp() async {
  return await Firebase.initializeApp();
}

enum UserType { REQUESTER, DONATOR }
enum Status { PENDING, CANCELLED, COMPLETED }

String statusToString(Status x) {
  switch (x) {
    case Status.PENDING:
      return 'Pending';
    case Status.CANCELLED:
      return 'Cancelled';
    case Status.COMPLETED:
      return 'Completed';
    default:
      return 'NULL';
  }
}

class DbWrite {
  Map<String, dynamic> m = Map();
  void s(String x, String field) {
    m[field] = x;
  }

  void i(int x, String field) {
    if (x != null) m[field] = x;
  }

  void b(bool x, String field) {
    if (x != null) m[field] = x;
  }

  void n(num x, String field) {
    // Firebase should store this as a double
    if (x != null) m[field] = x as double;
  }

  void u(UserType x, String field) {
    if (x != null) {
      if (x == UserType.REQUESTER) m[field] = 'REQUESTER';
      if (x == UserType.DONATOR) m[field] = 'DONATOR';
    }
  }

  void st(Status x, String field) {
    if (x != null) {
      if (x == Status.PENDING) m[field] = 'PENDING';
      if (x == Status.CANCELLED) m[field] = 'CANCELLED';
      if (x == Status.COMPLETED) m[field] = 'COMPLETED';
    }
  }

  void r(String id, String field, String collection) {
    m[field] = id == null
        ? "NULL"
        : FirebaseFirestore.instance.collection(collection).doc(id);
  }

  void d(DateTime x, String field) {
    if (x != null) {
      m[field] = x;
    }
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

  num n(String field) {
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

  void addressInfo(String x, num y, num z) {
    m['addressInfo'] = AddressInfo()
      ..address = x
      ..latCoord = y
      ..lngCoord = z;
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

  AddressInfo addressInfo() {
    return x['addressInfo'];
  }
}

class AddressInfo {
  String address;
  num latCoord;
  num lngCoord;
}

enum AuthenticationModelState {
  FIRST_TIME_ENTRY,
  GUEST,
  SIGNED_IN,
  LOADING_DB,
  LOADING_INIT,
  ERROR_DB,
  ERROR_SIGNOUT,
  LOADING_SIGNOUT
}

class AuthenticationModel extends ChangeNotifier {
  static final FirebaseAnalytics analytics = FirebaseAnalytics();
  static final firebaseAuth.FirebaseAuth auth =
      firebaseAuth.FirebaseAuth.instance;

  AuthenticationModelState _state = AuthenticationModelState.LOADING_INIT;
  UserType _userType;
  String _uid;
  String _email;
  Donator _donator;
  Requester _requester;
  PrivateDonator _privateDonator;
  PrivateRequester _privateRequester;
  String _err;

  AuthenticationModelState get state => _state;
  UserType get userType => _userType;
  String get uid => _uid;
  String get email => _email;
  Donator get donator => _donator;
  Requester get requester => _requester;
  String get err => _err;
  PrivateDonator get privateDonator => _privateDonator;
  PrivateRequester get privateRequester => _privateRequester;

  bool _initFirstAuthUpdateWaiting = true;
  firebaseAuth.User _initFirstAuthUpdateValue;
  bool _initSharedPreferencesUpdate;
  bool _initDbUpdated = false;

  bool _errSignoutIsEarlyExitCase;
  firebaseAuth.User _errDbUser;

  AuthenticationModel() {
    auth.authStateChanges().listen((user) async {
      if (_initFirstAuthUpdateWaiting) {
        _initFirstAuthUpdateWaiting = false;
        _initFirstAuthUpdateValue = user;
        _handleInitOperation(authUpdated: true);
      }
    });
    sharedPreferences.SharedPreferences.getInstance().then((x) {
      // I'm not sure if we should be prefixing our keys -- just to be safe ...
      // If the key exists, then the user has completed their first time entry
      onInitSharedPreferencesFinished(
          x.containsKey('mealmatch::1::firstTimeEntryCompleted'));
    });
  }

  void onFirstTimeEntryNavigateToGuest(UserType userType) {
    _userType = userType;
    _state = AuthenticationModelState.GUEST;
    sharedPreferences.SharedPreferences.getInstance().then((x) {
      // do this in the background; do NOT hang the app until this write finishes
      x.setBool('mealmatch::1::firstTimeEntryCompleted', true);
    });
    notifyListeners();
  }

  void guestChangeUserType(UserType userType) {
    _userType = userType;
    notifyListeners();
  }

  void _handleInitOperation(
      {bool authUpdated = false,
      bool sharedPreferencesUpdated = false,
      bool dbUpdated = false,
      String dbError}) {
    if (dbUpdated || authUpdated || sharedPreferencesUpdated) {
      if (_initFirstAuthUpdateWaiting == false &&
          _initSharedPreferencesUpdate != null) {
        // Both Shared Preferences and Auth are done; let's see what to do...
        if (_initFirstAuthUpdateValue != null &&
            _initSharedPreferencesUpdate == false) {
          // We KNOW that this is the early exit case.
          // In the case of dbUpdated, we return early to prevent the state from becoming SIGNED_IN,
          // but we don't call signOut, because that would result in a double call
          if (!dbUpdated) {
            signOut(isEarlyExitCase: true);
          }
          return;
        }
        if (_initFirstAuthUpdateValue == null &&
            _initSharedPreferencesUpdate == false) {
          _state = AuthenticationModelState.FIRST_TIME_ENTRY;
          notifyListeners();
          return;
        }
        if (_initFirstAuthUpdateValue == null &&
            _initSharedPreferencesUpdate == true) {
          _state = AuthenticationModelState.GUEST;
          notifyListeners();
          return;
        }
      }
    }
    // We DON'T KNOW if the early exit case applies
    if (authUpdated && _initFirstAuthUpdateValue != null) {
      _doDbQueriesReturningErrors(_initFirstAuthUpdateValue).then((err) {
        _initDbUpdated = true;
        _handleInitOperation(dbUpdated: true, dbError: err);
      });
      return;
    }
    if (dbUpdated || sharedPreferencesUpdated) {
      if (_initDbUpdated && _initSharedPreferencesUpdate == true) {
        if (dbError == null) {
          _state = AuthenticationModelState.SIGNED_IN;
          notifyListeners();
          return;
        } else {
          _state = AuthenticationModelState.ERROR_DB;
          _err = dbError;
          notifyListeners();
          return;
        }
      }
    }
  }

  void _updateForSignUp(firebaseAuth.User user) async {
    final err = await _doDbQueriesReturningErrors(user);
    if (err == null) {
      _state = AuthenticationModelState.SIGNED_IN;
    } else {
      _err = err;
      _state = AuthenticationModelState.ERROR_DB;
    }
    notifyListeners();
  }

  onInitSharedPreferencesFinished(bool firstTimeEntryCompleted) {
    _initSharedPreferencesUpdate = firstTimeEntryCompleted;
    _handleInitOperation(sharedPreferencesUpdated: true);
  }

  onErrorLogoutTryAgain() {
    signOut(isEarlyExitCase: _errSignoutIsEarlyExitCase);
  }

  onErrorDbTryAgain() async {
    final err = await _doDbQueriesReturningErrors(_errDbUser);
    if (err == null) {
      _state = AuthenticationModelState.SIGNED_IN;
    } else {
      _err = err;
      _state = AuthenticationModelState.ERROR_DB;
    }
    notifyListeners();
  }

  Future<String> _doDbQueriesReturningErrors(firebaseAuth.User user) async {
    _errDbUser = user;
    User userObject;
    try {
      // Get user object
      userObject = await Api.getUserWithUid(user.uid);
      if (userObject == null) {
        throw 'User object is null';
      }
      if (userObject.userType == UserType.DONATOR) {
        final donatorObject = await Api.getDonator(user.uid);
        if (donatorObject == null) {
          throw 'Donator object is null';
        }
        _donator = donatorObject;
        final privateDonatorObject = await Api.getPrivateDonator(user.uid);
        if (privateDonatorObject == null) {
          throw 'PrivateDonator object is null';
        }
        _privateDonator = privateDonatorObject;
      } else if (userObject.userType == UserType.REQUESTER) {
        final requesterObject = await Api.getRequester(user.uid);
        if (requesterObject == null) {
          throw 'Requster object is null';
        }
        _requester = requesterObject;
        final privateRequesterObject = await Api.getPrivateRequester(user.uid);
        if (privateRequesterObject == null) {
          throw 'PrivateRequester object is null';
        }
        _privateRequester = privateRequesterObject;
      } else {
        throw 'userType is invalid';
      }
    } catch (e) {
      return e.toString();
    }
    _userType = userObject.userType;
    _email = user.email;
    _uid = user.uid;

    try {
      // Silently try to update the device token for the purpose of notifications
      _silentlyUpdateDeviceTokenForNotifications();
    } catch (e) {
      print('Error updating device token');
      print(e.toString());
    }

    return null;
  }

  void _silentlyUpdateDeviceTokenForNotifications() async {
    final token = await Api.getDeviceToken();
    if (token != null) {
      if (_userType == UserType.DONATOR) {
        if (token != _privateDonator.notificationsDeviceToken) {
          await Api.editPrivateDonator(
              _privateDonator..notificationsDeviceToken = token);
        }
      } else if (_userType == UserType.REQUESTER) {
        if (token != _privateRequester.notificationsDeviceToken) {
          await Api.editPrivateRequester(
              _privateRequester..notificationsDeviceToken = token);
        }
      } else {
        throw 'invalid user type';
      }
    }
  }

  Future<String> attemptSigninReturningErrors(
      String email, String password) async {
    analytics.logEvent(name: 'test_event');
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = userCredential.user;
      _state = AuthenticationModelState.LOADING_DB;
      notifyListeners();
      final err = await _doDbQueriesReturningErrors(user);
      if (err == null) {
        _state = AuthenticationModelState.SIGNED_IN;
        notifyListeners();
      } else {
        _state = AuthenticationModelState.ERROR_DB;
        _err = err;
        notifyListeners();
      }
      return null;
    } on firebaseAuth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return 'Wrong password';
      } else if (e.code == 'user-not-found') {
        return 'Wrong email';
      }
      return 'Sign-in error: code ${e.code}. Try signing in again.';
    } catch (e) {
      return 'Unknown sign-in error: ${e.toString()}.';
    }
  }

  Future<void> signOut({bool isEarlyExitCase = false}) async {
    // Bring up the loading spinner
    _state = AuthenticationModelState.LOADING_SIGNOUT;
    notifyListeners();

    try {
      await auth.signOut();
    } catch (e) {
      // Error case
      _err = e.toString();
      _errSignoutIsEarlyExitCase = isEarlyExitCase;
      _state = AuthenticationModelState.ERROR_SIGNOUT;
      notifyListeners();

      // Do NOT run the success case if the error case runs
      return;
    }
    if (isEarlyExitCase) {
      _state = AuthenticationModelState.FIRST_TIME_ENTRY;
    } else {
      _userType = null;
      _state = AuthenticationModelState.GUEST;
    }
    notifyListeners();
  }

  Future<void> signUpDonator(
      BaseUser user, BasePrivateUser privateUser, SignUpData data) async {
    final result = await auth.createUserWithEmailAndPassword(
        email: data.email, password: data.password);
    await Api.signUpDonator(user, privateUser, data, result.user);
    _updateForSignUp(result.user);
  }

  Future<void> signUpRequester(
      BaseUser user, BasePrivateUser privateUser, SignUpData data) async {
    final result = await auth.createUserWithEmailAndPassword(
        email: data.email, password: data.password);
    await Api.signUpRequester(user, privateUser, data, result.user);
    _updateForSignUp(result.user);
  }

  Future<void> editDonatorFromProfilePage(
      Donator x, ProfilePageInfo initialInfo) async {
    await Api._editDonatorFromProfilePage(x, initialInfo);
    _donator = x;
    notifyListeners();
  }

  Future<void> editRequesterFromProfilePage(
      Requester x, ProfilePageInfo initialInfo) async {
    await Api._editRequesterFromProfilePage(x, initialInfo);
    _requester = x;
    notifyListeners();
  }

  Future<void> editRequesterDietaryRestrictions(Requester x) async {
    await Api._editRequesterDietaryRestrictions(x);
    _requester = x;
    notifyListeners();
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
  num addressLatCoord;
  num addressLngCoord;
  String profilePictureStorageRef;

  // for Donator
  int numMeals;
  bool isRestaurant;
  String restaurantName;
  String foodDescription;

  // for BasePrivateUser
  String address;
  String phone;
  bool newsletter;

  // email and password
  String email;
  String newPassword;

  // current password
  String currentPassword;

  // modification for profilePictureStorageRef
  String profilePictureModification;

  // notifications
  bool notifications;

  Map<String, dynamic> formWrite() {
    return (FormWrite()
          ..s(name, 'name')
          ..b(isRestaurant, 'isRestaurant')
          ..s(restaurantName, 'restaurantName')
          ..s(foodDescription, 'foodDescription')
          ..s(phone, 'phone')
          ..b(newsletter, 'newsletter')
          ..s(email, 'email')
          ..s(profilePictureModification, 'profilePictureModification')
          ..addressInfo(address, addressLatCoord, addressLngCoord)
          // We cannot write a NULL to a checkbox!
          ..b(notifications ?? false, 'notifications'))
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
    final addressInfo = o.addressInfo();
    address = addressInfo.address;
    addressLatCoord = addressInfo.latCoord;
    addressLngCoord = addressInfo.lngCoord;
    profilePictureModification = o.s('profilePictureModification');
    notifications = o.b('notifications');
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

class Interest implements HasStatus {
  String id;
  String donationId;
  String donatorId;
  String requesterId;
  Status status;
  int numAdultMeals;
  int numChildMeals;
  String requestedPickupLocation;
  String requestedPickupDateAndTime;

  // this is to see if the sum of meals requested has been updated
  int initialNumMealsTotal;

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
    initialNumMealsTotal = numAdultMeals + numChildMeals;
  }

  void formRead(Map<String, dynamic> x) {
    final o = FormRead(x);
    numAdultMeals = o.i('numAdultMeals');
    numChildMeals = o.i('numChildMeals');
    requestedPickupLocation = o.s('requestedPickupLocation');
    requestedPickupDateAndTime = o.s('requestedPickupDateAndTime');
    status = Status.PENDING;
    initialNumMealsTotal = numAdultMeals + numChildMeals;
  }

  Map<String, dynamic> formWrite() {
    return (FormWrite()
          ..i(numAdultMeals, 'numAdultMeals')
          ..i(numChildMeals, 'numChildMeals')
          ..s(requestedPickupLocation, 'requestedPickupLocation')
          ..s(requestedPickupDateAndTime, 'requestedPickupDateAndTime'))
        .m;
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
  Requester requester;
}

class LeaderboardEntry {
  String name;
  int numMeals;
  String id;
}

/*

The form IO is not what you would expect for these next few classes
because the main case of form IO (profile page) is actually done
through ProfilePageInfo.

formRead/formWrite are very minimal, mostly for the sign up page.

*/

class BaseUser {
  String id;
  String name;
  String profilePictureStorageRef;
  num addressLatCoord;
  num addressLngCoord;

  DbRead _dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    id = o.id();
    name = o.s('name');
    addressLatCoord = o.n('addressLatCoord');
    addressLngCoord = o.n('addressLngCoord');
    profilePictureStorageRef = o.s('profilePictureStorageRef');
    return o;
  }

  FormRead _formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    name = o.s('name');
    addressLatCoord = o.addressInfo().latCoord;
    addressLngCoord = o.addressInfo().lngCoord;
    return o;
  }

  FormWrite _formWrite() {
    return FormWrite()..s(name, 'name');
  }

  DbWrite _dbWrite(String privateCollection) {
    return DbWrite()
      ..s(name, 'name')
      ..n(addressLatCoord, 'addressLatCoord')
      ..n(addressLngCoord, 'addressLngCoord')
      ..s(profilePictureStorageRef, 'profilePictureStorageRef');
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
    addressLatCoord = o.addressInfo().latCoord;
    addressLngCoord = o.addressInfo().lngCoord;
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
  String dietaryRestrictions;

  void dbRead(DocumentSnapshot x) {
    final o = _dbRead(x);
    dietaryRestrictions = o.s('dietaryRestrictions');
  }

  Map<String, dynamic> dbWrite() {
    return (_dbWrite('privateRequesters')
          ..s(dietaryRestrictions, 'dietaryRestrictions'))
        .m;
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
  String address;
  String phone;
  bool newsletter;

  bool wasAlertedAboutNotifications;
  bool notifications;

  // This is silently updated (updated without the user knowing it).
  // To them, they just change "bool notifications" and notifications just work.
  String notificationsDeviceToken;

  void dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    id = o.id();
    phone = o.s('phone');
    newsletter = o.b('newsletter');
    address = o.s('address');
    notifications = o.b('notifications');
    notificationsDeviceToken = o.s('notificationsDeviceToken');
    wasAlertedAboutNotifications = o.b('wasAlertedAboutNotifications');
  }

  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    phone = o.s('phone');
    newsletter = o.b('newsletter');
    address = o.addressInfo().address;
    // Notifications is always FALSE until the user decides to change it.
    notifications = false;
  }

  Map<String, dynamic> formWrite() {
    return (FormWrite()..b(newsletter, 'newsletter')).m;
  }

  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..s(phone, 'phone')
          ..b(newsletter, 'newsletter')
          ..s(address, 'address')
          ..s(notificationsDeviceToken, 'notificationsDeviceToken')
          ..b(wasAlertedAboutNotifications, 'wasAlertedAboutNotifications'))
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

/*

We will log the messages, but note that many of these are stub implementations and don't really do anything.
 */

void handleMessageInteraction(firebaseMessaging.RemoteMessage message) {
// https://firebase.flutter.dev/docs/messaging/usage/
  print('Got a message whilst in the foreground!');
  print('Message data: ${message.data}');

  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
  }
}

class Api {
  static final FirebaseFirestore fire = FirebaseFirestore.instance;
  static final firebaseStorage.FirebaseStorage fireStorage =
      firebaseStorage.FirebaseStorage.instance;

  static void initMessaging() async {
    // Some docs suggest calling configure()
    // However, I am pretty sure this has been removed in the latest version
    // because I can't access this method.

    // https://firebase.flutter.dev/docs/messaging/notifications
    // Header: "Handling Interaction"

    // This handles the case where the app is started because the user interacted with a notification.
    firebaseMessaging.RemoteMessage initialMessage =
        await firebaseMessaging.FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleMessageInteraction(initialMessage);
    }

    // This handles the case where the app is moved from the background to the foreground.
    firebaseMessaging.FirebaseMessaging.onMessageOpenedApp
        .listen(handleMessageInteraction);

    // This handles the case where the app is already in the foreground.
    firebaseMessaging.FirebaseMessaging.onMessage
        .listen(handleMessageInteraction);
  }

  static Future<String> getDeviceToken() {
    return firebaseMessaging.FirebaseMessaging.instance.getToken();
  }

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

  static Future<void> _editDonatorFromProfilePage(
      Donator x, ProfilePageInfo initialInfo) async {
    print(x.dbWrite());
    await fireUpdate('donators', x.id, x.dbWrite());
    if (x.name != initialInfo.name ||
        x.addressLatCoord != initialInfo.addressLatCoord ||
        x.addressLngCoord != initialInfo.addressLngCoord) {
      final result = (await fire
              .collection('donations')
              .where('donator', isEqualTo: fireRef('donators', x.id))
              .get())
          .docs;
      await fire.runTransaction((transaction) async {
        for (final y in result) {
          transaction.update(
              y.reference,
              (Donation()
                    ..dbRead(y)
                    ..donatorNameCopied =
                        x.name == initialInfo.name ? null : x.name
                    ..donatorAddressLatCoordCopied =
                        x.addressLatCoord == initialInfo.addressLatCoord
                            ? null
                            : x.addressLatCoord
                    ..donatorAddressLngCoordCopied =
                        x.addressLngCoord == initialInfo.addressLngCoord
                            ? null
                            : x.addressLngCoord)
                  .dbWrite());
        }
      });
    }
  }

  static Future<void> _editRequesterFromProfilePage(
      Requester x, ProfilePageInfo initialInfo) async {
    await fireUpdate('requesters', x.id, x.dbWrite());
    if (x.name != initialInfo.name ||
        x.addressLatCoord != initialInfo.addressLatCoord ||
        x.addressLngCoord != initialInfo.addressLngCoord) {
      final result = (await fire
              .collection('publicRequest')
              .where('requester', isEqualTo: fireRef('requesters', x.id))
              .get())
          .docs;
      await fire.runTransaction((transaction) async {
        for (final y in result) {
          transaction.update(
              y.reference,
              (PublicRequest()
                    ..dbRead(y)
                    ..requesterNameCopied =
                        x.name == initialInfo.name ? null : x.name
                    ..requesterAddressLatCoordCopied =
                        x.addressLatCoord == initialInfo.addressLatCoord
                            ? null
                            : x.addressLatCoord
                    ..requesterAddressLngCoordCopied =
                        x.addressLngCoord == initialInfo.addressLngCoord
                            ? null
                            : x.addressLngCoord)
                  .dbWrite());
        }
      });
    }
  }

  static Future<void> editDonation(Donation x) {
    return fire.runTransaction((transaction) async {
      print(x.donatorId);
      var result = Donator()
        ..dbRead(await transaction.get(fireRef('donators', x.donatorId)));
      result.numMeals -= x.initialNumMeals;
      result.numMeals += x.numMeals;
      transaction.update(fireRef('donators', result.id), result.dbWrite());
      transaction.update(fireRef('donations', x.id), x.dbWrite());
    });
  }

  static Future<void> newPublicRequest(
      PublicRequest x, AuthenticationModel authModel) async {
    final requester = authModel.requester;
    x.requesterNameCopied = requester.name;
    x.requesterAddressLatCoordCopied = requester.addressLatCoord;
    x.requesterAddressLngCoordCopied = requester.addressLngCoord;
    await fireAdd('publicRequests', x.dbWrite());
    if (requester.dietaryRestrictions != x.dietaryRestrictions) {
      await authModel.editRequesterDietaryRestrictions(requester);
    }
  }

  static Future<void> _editRequesterDietaryRestrictions(Requester x) {
    return fireUpdate('requesters', x.id,
        (Requester()..dietaryRestrictions = x.dietaryRestrictions).dbWrite());
  }

  static Future<void> newDonation(Donation x) {
    return fire.runTransaction((transaction) async {
      var result = Donator()
        ..dbRead(await transaction.get(fireRef('donators', x.donatorId)));
      print(result.dbWrite());
      print(x.dbWrite());
      result.numMeals += x.numMeals;
      x.donatorNameCopied = result.name;
      x.donatorAddressLatCoordCopied = result.addressLatCoord;
      x.donatorAddressLngCoordCopied = result.addressLngCoord;
      print(result.dbWrite());
      print(x.dbWrite());
      transaction.update(fireRef('donators', x.donatorId), result.dbWrite());
      transaction.set(fire.collection('donations').doc(), x.dbWrite());
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
      if (uid != null)
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

  static Stream<DonatorViewPublicRequestInfo>
      getStreamingDonatorViewPublicRequestInfo(
          PublicRequest publicRequest, String uid) async* {
    if (publicRequest.donatorId == null) {
      yield DonatorViewPublicRequestInfo()..publicRequest = publicRequest;
    } else {
      final requesterFuture = fireGet('requesters', publicRequest.requesterId);
      final streamOfMessages = fire
          .collection('chatMessages')
          .where('donator', isEqualTo: fireRef('donators', uid))
          .where('publicRequest',
              isEqualTo: fireRef('publicRequests', publicRequest.id))
          .snapshots();

      await for (final messages in streamOfMessages) {
        yield DonatorViewPublicRequestInfo()
          ..publicRequest = publicRequest
          ..messages =
              messages.docs.map((x) => ChatMessage()..dbRead(x)).toList()
          ..requester = (Requester()..dbRead(await requesterFuture));
      }
    }
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

  static Future<void> editInterest(Interest old, Interest x,
      [Status status]) async {
    final newStatus = status ?? x.status;
    final oldNumMealsRequested = x.status == Status.CANCELLED
        ? 0
        : old.numChildMeals + old.numAdultMeals;
    final newNumMealsRequested =
        newStatus == Status.CANCELLED ? 0 : x.numChildMeals + x.numAdultMeals;
    if (oldNumMealsRequested == newNumMealsRequested) {
      await fireUpdate(
          'interests', x.id, (Interest()..status = status).dbWrite());
    } else {
      String err;
      await fire.runTransaction((transaction) async {
        final donation = Donation()
          ..dbRead(await transaction.get(fireRef('donations', x.donationId)));
        final newValue = donation.numMealsRequested -
            oldNumMealsRequested +
            newNumMealsRequested;
        if (newValue > donation.numMeals) {
          err =
              'You requested $newNumMealsRequested meals, but only ${donation.numMeals - donation.numMealsRequested} meals are available.';
        } else {
          transaction.update(fireRef('donations', donation.id),
              (Donation()..numMealsRequested = newValue).dbWrite());
          transaction.update(
              fireRef('interests', x.id), (Interest()..status = status).dbWrite());
        }
      });
      if (err != null) {
        throw err;
      }
    }
  }

  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    final QuerySnapshot results = await fire
        .collection('donators')
        .orderBy('numMeals', descending: true)
        .get();
    return results.docs.map((x) {
      var y = Donator()..dbRead(x);
      return LeaderboardEntry()
        ..name = y.name
        ..numMeals = y.numMeals
        ..id = y.id;
    }).toList();
  }

  static Future<void> newInterest(Interest x) async {
    // https://stackoverflow.com/questions/55674071/firebase-firestore-addding-new-document-inside-a-transaction-transaction-add-i
    final newInterestDocRef = fire.collection('interests').doc();

    String err;

    await fire.runTransaction((transaction) async {
      final donation = Donation()
        ..dbRead(await transaction.get(fireRef('donations', x.donationId)));
      if (donation.numMealsRequested + x.numAdultMeals + x.numChildMeals >
          donation.numMeals) {
        err = 'You requested ${x.numAdultMeals + x.numChildMeals} meals, but only ${donation.numMeals - donation.numMealsRequested} meals are available.';
      } else {
        transaction.set(newInterestDocRef, x.dbWrite());
        transaction.update(fireRef('donations', x.donationId), (Donation()
          ..numMealsRequested = donation.numMealsRequested +
              x.numAdultMeals +
              x.numChildMeals)
            .dbWrite());
      }
    });

    if (err != null) {
      throw err;
    }
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
        .get();
    return results.docs.map((x) => ChatMessage()..dbRead(x)).toList();
  }

  static Future<List<ChatMessage>> getChatMessagesByRequestAndDonator(
      String publicRequestId, String donatorId) async {
    final QuerySnapshot results = await fire
        .collection('chatMessages')
        .where('', isEqualTo: fireRef('publicRequests', publicRequestId))
        .where('', isEqualTo: fireRef('donators', donatorId))
        .get();
    return results.docs.map((x) => ChatMessage()..dbRead(x)).toList();
  }

  static Stream<RequesterViewInterestInfo>
      getStreamingRequesterViewInterestInfo(
          Interest interest, String uid) async* {
    final donation = Donation()
      ..dbRead(await fireGet('donations', interest.donationId));
    final donator = Donator()
      ..dbRead(await fireGet('donators', donation.donatorId));
    final streamOfMessages = fire
        .collection('chatMessages')
        .where('requester', isEqualTo: fireRef('requesters', uid))
        .where('interest', isEqualTo: fireRef('interests', interest.id))
        .snapshots();
    await for (final messages in streamOfMessages) {
      yield RequesterViewInterestInfo()
        ..interest = interest
        ..donation = donation
        ..donator = donator
        ..messages =
            messages.docs.map((x) => ChatMessage()..dbRead(x)).toList();
    }
  }

  static Stream<DonatorViewInterestInfo> getStreamingDonatorViewInterestInfo(
      String uid, DonationInterestAndRequester val) async* {
    // https://dart.dev/articles/libraries/creating-streams
    final streamOfMessages = fire
        .collection('chatMessages')
        .where('donator', isEqualTo: fireRef('donators', uid))
        .where('interest', isEqualTo: fireRef('interests', val.interest.id))
        .snapshots();
    await for (final messages in streamOfMessages) {
      yield DonatorViewInterestInfo()
        ..interest = val.interest
        ..donation = val.donation
        ..requester = val.requester
        ..messages =
            messages.docs.map((x) => ChatMessage()..dbRead(x)).toList();
    }
  }

  static Stream<RequesterViewPublicRequestInfo>
      getStreamingRequesterViewPublicRequestInfo(
          PublicRequest publicRequest, String uid) async* {
    if (publicRequest.donatorId == null) {
      yield RequesterViewPublicRequestInfo()..publicRequest = publicRequest;
    } else {
      final donator = Donator()
        ..dbRead(await fireGet('donators', publicRequest.donatorId));
      final streamOfMessages = fire
          .collection('chatMessages')
          .where('requester', isEqualTo: fireRef('requesters', uid))
          .where('interest',
              isEqualTo: fireRef('publicRequest', publicRequest.id))
          .where('donator', isEqualTo: fireRef('donators', donator.id))
          .snapshots();
      await for (final messages in streamOfMessages) {
        yield RequesterViewPublicRequestInfo()
          ..publicRequest = publicRequest
          ..messages =
              messages.docs.map((x) => ChatMessage()..dbRead(x)).toList();
      }
    }
  }

  static Future<String> getUrlForProfilePicture(String ref) async {
    final url = await fireStorage.ref(ref).getDownloadURL();
    print(url);
    return url;
  }

  static Future<void> deleteProfilePicture(String ref) {
    return fireStorage.ref(ref).delete();
  }

  static Future<String> uploadProfilePicture(String fileRef, String uid) async {
    final result =
        await fireStorage.ref('/profilePictures/$uid').putFile(File(fileRef));
    return result.ref.fullPath;
  }
}

class ChatUsers {
  const ChatUsers({@required this.donatorId, @required this.requesterId});
  final String donatorId;
  final String requesterId;
}

// https://stackoverflow.com/questions/20791286/how-to-define-interfaces-in-dart
abstract class HasStatus {
  Status status;
}

class Donation implements HasStatus {
  String id;
  String donatorId;
  int numMeals;
  int initialNumMeals;
  String dateAndTime;
  String description; // TODO add dietary restrictions
  int numMealsRequested; // This value can be updated by any requester as they submit interests
  Status status;

  // copied from Donator document
  String donatorNameCopied;
  num donatorAddressLatCoordCopied;
  num donatorAddressLngCoordCopied;

  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..r(donatorId, 'donator', 'donators')
          ..i(numMeals, 'numMeals')
          ..s(dateAndTime, 'dateAndTime')
          ..s(description, 'description')
          ..i(numMealsRequested, 'numMealsRequested')
          ..s(donatorNameCopied, 'donatorNameCopied')
          ..n(donatorAddressLatCoordCopied, 'donatorAddressLatCoordCopied')
          ..n(donatorAddressLngCoordCopied, 'donatorAddressLngCoordCopied')
          ..st(status, 'status'))
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
    donatorNameCopied = o.s('donatorNameCopied');
    donatorAddressLatCoordCopied = o.n('donatorAddressLatCoordCopied');
    donatorAddressLngCoordCopied = o.n('donatorAddressLngCoordCopied');
    status = o.st('status');

    initialNumMeals = numMeals;
  }

  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    numMeals = o.i('numMeals');
    dateAndTime = o.s('dateAndTime');
    description = o.s('description');
  }

  Map<String, dynamic> formWrite() {
    return (FormWrite()
          ..i(numMeals, 'numMeals')
          ..s(dateAndTime, 'dateAndTime')
          ..s(description, 'description'))
        .m;
  }
}

class WithDistance<T> {
  WithDistance(this.object, this.distance);
  T object;
  num distance;
}

class PublicRequest implements HasStatus {
  String id;
  String dateAndTime;
  int numMealsAdult;
  int numMealsChild;
  String dietaryRestrictions;
  String requesterId;
  String donatorId;
  Status status;

  int initialNumMeals;
  String initialDonatorId;

  // These are copied in from the requester document
  String requesterNameCopied;
  num requesterAddressLatCoordCopied;
  num requesterAddressLngCoordCopied;

  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..s(dateAndTime, 'dateAndTime')
          ..i(numMealsAdult, 'numMealsAdult')
          ..i(numMealsChild, 'numMealsChild')
          ..s(dietaryRestrictions, 'dietaryRestrictions')
          ..r(requesterId, 'requester', 'requesters')
          ..r(donatorId, 'donator', 'donators')
          ..st(status, 'status')
          ..s(requesterNameCopied, 'requesterNameCopied')
          ..n(requesterAddressLatCoordCopied, 'requesterAddressLatCoordCopied')
          ..n(requesterAddressLngCoordCopied, 'requesterAddressLngCoordCopied'))
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
    requesterNameCopied = o.s('requesterNameCopied');
    requesterAddressLatCoordCopied = o.n('requesterAddressLatCoordCopied');
    requesterAddressLngCoordCopied = o.n('requesterAddressLngCoordCopied');

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

  Map<String, dynamic> formWrite() {
    return (FormWrite()..s(dietaryRestrictions, 'dietaryRestrictions')).m;
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

class InterestAndDonation {
  InterestAndDonation(this.interest, this.donation);
  Interest interest;
  Donation donation;
}

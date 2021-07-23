import 'dart:io';

import 'state-util.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' show Provider;
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

String statusToStringInDB(Status x) {
  switch (x) {
    case Status.PENDING:
      return 'PENDING';
    case Status.CANCELLED:
      return 'CANCELLED';
    case Status.COMPLETED:
      return 'COMPLETED';
  }
}

String statusToStringInUI(Status? x) {
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

class AddressInfo {
  String? address;
  num? latCoord;
  num? lngCoord;
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

AuthenticationModel provideAuthenticationModel(BuildContext context) {
  return Provider.of<AuthenticationModel>(context, listen: false);
}

class AuthenticationModel extends ChangeNotifier {
  static final FirebaseAnalytics analytics = FirebaseAnalytics();
  static final firebaseAuth.FirebaseAuth auth =
      firebaseAuth.FirebaseAuth.instance;

  AuthenticationModelState _state = AuthenticationModelState.LOADING_INIT;
  UserType? _userType;
  String? _uid;
  String? _email;
  Donator? _donator;
  Requester? _requester;
  PrivateDonator? _privateDonator;
  PrivateRequester? _privateRequester;
  String? _err;

  AuthenticationModelState get state => _state;
  UserType? get userType => _userType;
  String? get uid => _uid;
  String? get email => _email;
  Donator? get donator => _donator;
  Requester? get requester => _requester;
  String? get err => _err;
  PrivateDonator? get privateDonator => _privateDonator;
  PrivateRequester? get privateRequester => _privateRequester;

  bool _initFirstAuthUpdateWaiting = true;
  firebaseAuth.User? _initFirstAuthUpdateValue;
  bool? _initSharedPreferencesUpdate;
  bool _initDbUpdated = false;

  bool? _errSignoutIsEarlyExitCase;
  late firebaseAuth.User _errDbUser;

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
      String? dbError}) {
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
      _doDbQueriesReturningErrors(_initFirstAuthUpdateValue!).then((err) {
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

  Future<String?> _doDbQueriesReturningErrors(firebaseAuth.User user) async {
    _errDbUser = user;
    User userObject;
    try {
      // Get user object
      userObject = await Api.getUserWithUid(user.uid);
      if (userObject.userType == UserType.DONATOR) {
        final donatorObject = await Api.getDonator(user.uid);
        _donator = donatorObject;
        final privateDonatorObject = await Api.getPrivateDonator(user.uid);
        _privateDonator = privateDonatorObject;
      } else if (userObject.userType == UserType.REQUESTER) {
        final requesterObject = await Api.getRequester(user.uid);
        _requester = requesterObject;
        final privateRequesterObject = await Api.getPrivateRequester(user.uid);
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
      silentlyUpdateDeviceTokenForNotifications();
    } catch (e) {}

    return null;
  }

  void silentlyUpdateDeviceTokenForNotifications() async {
    final token = await Api.getDeviceToken();
    if (token != null) {
      if (_userType == UserType.DONATOR) {
        if (token != _privateDonator!.notificationsDeviceToken) {
          await Api.editPrivateDonator(
              _privateDonator!..notificationsDeviceToken = token);
        }
      } else if (_userType == UserType.REQUESTER) {
        if (token != _privateRequester!.notificationsDeviceToken) {
          await Api.editPrivateRequester(
              _privateRequester!..notificationsDeviceToken = token);
        }
      } else {
        throw 'invalid user type';
      }
    }
  }

  Future<String?> attemptSigninReturningErrors(
      String email, String password) async {
    analytics.logEvent(name: 'test_event');
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed user credential');
      }
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

  Future<void> signOut({bool? isEarlyExitCase = false}) async {
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
    if (isEarlyExitCase!) {
      _state = AuthenticationModelState.FIRST_TIME_ENTRY;
    } else {
      _userType = null;
      _state = AuthenticationModelState.GUEST;
    }
    notifyListeners();
  }

  Future<void> signUpDonator(
      Donator user, PrivateDonator privateUser, SignUpData data) async {
    final result = await auth.createUserWithEmailAndPassword(
        email: data.email!, password: data.password!);
    final resultUser = result.user;
    if (resultUser == null) {
      throw Exception('invalid user');
    }
    await Api.signUpDonator(user, privateUser, data, resultUser);
    _updateForSignUp(resultUser);
  }

  Future<void> signUpRequester(
      Requester user, PrivateRequester privateUser, SignUpData data) async {
    final result = await auth.createUserWithEmailAndPassword(
        email: data.email!, password: data.password!);
    final resultUser = result.user;
    if (resultUser == null) {
      throw Exception('invalid user');
    }
    await Api.signUpRequester(user, privateUser, data, resultUser);
    _updateForSignUp(resultUser);
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

  // Only called when user is signed in.
  Future<void> userChangePassword(UserChangePasswordData data) async {
    final user = auth.currentUser!;
    await user.reauthenticateWithCredential(
        firebaseAuth.EmailAuthProvider.credential(
            email: _email!, password: data.oldPassword!));
    await user.updatePassword(data.newPassword!);
  }

  // Only called when user is signed in.
  Future<void> userChangeEmail(UserChangeEmailData data) async {
    final user = auth.currentUser!;
    await user.reauthenticateWithCredential(
        firebaseAuth.EmailAuthProvider.credential(
            email: _email!, password: data.oldPassword!));
    await user.updateEmail(data.email!);
    _email = data.email;
  }
}

class ProfilePageInfo {
  // user type
  UserType? userType;

  // for base user
  String? name;
  num? addressLatCoord;
  num? addressLngCoord;
  String? profilePictureStorageRef;

  // for Donator
  int? numMeals;
  bool? isRestaurant;
  String? restaurantName;
  String? foodDescription;

  // for BasePrivateUser
  String? address;
  String? phone;
  bool? newsletter;

  // email and password
  String? email;
  String? newPassword;

  // current password
  String? currentPassword;

  // modification for profilePictureStorageRef
  String? profilePictureModification;

  // notifications
  bool? notifications;

  Map<String, dynamic> formWrite() {
    final testing = (FormWrite()
          ..s(name, 'name')
          ..b(isRestaurant, 'isRestaurant')
          ..s(restaurantName, 'restaurantName')
          ..s(foodDescription, 'foodDescription')
          ..s(phone, 'phone')
          // We cannot write a NULL to a checkbox!
          ..b(newsletter ?? false, 'newsletter')
          ..s(email, 'email')
          ..s(profilePictureModification, 'profilePictureModification')
          ..addressInfo(address, addressLatCoord, addressLngCoord)
          // We cannot write a NULL to a checkbox!
          ..b(notifications ?? false, 'notifications'))
        .m;
    return testing;
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
    final addressInfo = o.addressInfo()!;
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
  String? id;

  // these are optional
  String? interestId;
  String? publicRequestId;

  // these are required
  String? message;
  String? speakerUid;
  DateTime? timestamp;
  String? donatorId;
  String? requesterId;

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

class Interest implements HasStatus, HasDateRange {
  String? id;
  String? donationId;
  String? donatorId;
  String? requesterId;
  Status? status;
  int? numAdultMeals;
  int? numChildMeals;
  String? requestedPickupLocation;
  int? requestedPickupDateBegin;
  int? requestedPickupDateEnd;
  int? getDateBegin() => requestedPickupDateBegin;
  int? getDateEnd() => requestedPickupDateEnd;

  // this is to see if the sum of meals requested has been updated
  int? initialNumMealsTotal;

  static Map<String, dynamic> dbWriteOnlyStatus(Status x) {
    final testing = (DbWrite()..st(x, 'status')).m;
    return testing;
  }

  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..r(donationId, 'donation', 'donations')
          ..r(donatorId, 'donator', 'donators')
          ..r(requesterId, 'requester', 'requesters')
          ..st(status, 'status')
          ..i(numAdultMeals, 'numAdultMeals')
          ..i(numChildMeals, 'numChildMeals')
          ..s(requestedPickupLocation, 'requestedPickupLocation')
          ..i(requestedPickupDateBegin, 'requestedPickupDateBegin')
          ..i(requestedPickupDateEnd, 'requestedPickupDateEnd'))
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
    requestedPickupDateBegin = o.i('requestedPickupDateBegin');
    requestedPickupDateEnd = o.i('requestedPickupDateEnd');
    initialNumMealsTotal = numAdultMeals! + numChildMeals!;
  }

  void formRead(Map<String, dynamic> x) {
    final o = FormRead(x);
    numAdultMeals = o.i('numAdultMeals');
    numChildMeals = o.i('numChildMeals');
    requestedPickupLocation = o.s('requestedPickupLocation');
    requestedPickupDateBegin = o.i('requestedPickupDateBegin');
    requestedPickupDateEnd = o.i('requestedPickupDateEnd');
    status = Status.PENDING;
    initialNumMealsTotal = numAdultMeals! + numChildMeals!;
  }

  Map<String, dynamic> formWrite() {
    return (FormWrite()
          ..i(numAdultMeals, 'numAdultMeals')
          ..i(numChildMeals, 'numChildMeals')
          ..s(requestedPickupLocation, 'requestedPickupLocation')
          ..date(requestedPickupDateBegin, 'requestedPickupDateBegin')
          ..date(requestedPickupDateEnd, 'requestedPickupDateEnd'))
        .m;
  }
}

class DonatorPendingDonationsListInfo {
  const DonatorPendingDonationsListInfo(
      {required this.donations, required this.interests});
  final List<Donation> donations;
  final List<Interest> interests;
}

class RequesterDonationListInfo {
  List<Donation>? donations;
  List<Interest>? interests;
}

class RequesterViewInterestInfo {
  Interest? interest;
  Donation? donation;
  Donator? donator;
  late List<ChatMessage> messages;
}

class DonatorViewInterestInfo {
  Interest? interest;
  Donation? donation;
  Requester? requester;
  late List<ChatMessage> messages;
}

class ViewPublicRequestInfo<T> {
  ViewPublicRequestInfo(this.publicRequest, [this.messages, this.otherUser]);
  final PublicRequest publicRequest;
  final List<ChatMessage>? messages;
  final T? otherUser;
}

class LeaderboardEntry {
  String? name;
  int? numMeals;
  String? id;
}

/*

The form IO is not what you would expect for these next few classes
because the main case of form IO (profile page) is actually done
through ProfilePageInfo.

formRead/formWrite are very minimal, mostly for the sign up page.

*/

class BaseUser {
  String? id;
  String? name;
  String? profilePictureStorageRef;
  num? addressLatCoord;
  num? addressLngCoord;

  DbRead _dbRead(DocumentSnapshot x) {
    var o = DbRead(x);
    id = o.id();
    name = o.s('name');
    addressLatCoord = o.n('addressLatCoord');
    addressLngCoord = o.n('addressLngCoord');
    profilePictureStorageRef = o.s('profilePictureStorageRef');

    // This fixes a common bug.
    // The reason why the string "NULL" is used is because overwriting a field
    // with NULL is generally a mess.
    // We could try to find good ways to fix it, but it's a good workaround.
    if (profilePictureStorageRef == null) {
      profilePictureStorageRef = 'NULL';
    }

    return o;
  }

  FormRead _formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    name = o.s('name');
    addressLatCoord = o.addressInfo()!.latCoord;
    addressLngCoord = o.addressInfo()!.lngCoord;
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
  int? numMeals;
  bool? isRestaurant;
  String? restaurantName;
  String? foodDescription;

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
    addressLatCoord = o.addressInfo()!.latCoord;
    addressLngCoord = o.addressInfo()!.lngCoord;
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
  String? dietaryRestrictions;

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
  String? id;
  String? address;
  String? phone;
  bool? newsletter;

  bool? wasAlertedAboutNotifications;
  bool? notifications;

  // This is silently updated (updated without the user knowing it).
  // To them, they just change "bool notifications" and notifications just work.
  String? notificationsDeviceToken;

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
    address = o.addressInfo()!.address;
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
          ..b(wasAlertedAboutNotifications, 'wasAlertedAboutNotifications')
          ..b(notifications, 'notifications'))
        .m;
  }
}

class PrivateDonator extends BasePrivateUser {}

class PrivateRequester extends BasePrivateUser {}

class UserChangePasswordData {
  String? oldPassword;
  String? newPassword;
  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    oldPassword = o.s('oldPassword');
    newPassword = o.s('password');
  }
}

class UserChangeEmailData {
  String? oldPassword;
  String? email;
  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    oldPassword = o.s('oldPassword');
    email = o.s('email');
  }
}

class UserData {
  String? name;
  String? bio;
  String? email;
  String? phoneNumber;
  bool? newsletter;
}

/*
userReports
- id
- uid
- otherUid
- info
*/

// This class cannot be read from the database!

class UserReport {
  String? uid;
  String? otherUid;
  String? info;
  void formRead(Map<String, dynamic> x) {
    final o = FormRead(x);
    info = o.s('info');
    if (info == null) info = '';
  }

  Map<String, dynamic> dbWrite() {
    return (DbWrite()..s(uid, 'uid')..s(otherUid, 'otherUid')..s(info, 'info'))
        .m;
  }
}

class SignUpData {
  String? email;
  String? password;
  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    email = o.s('email');
    password = o.s('password');
  }
}

class User {
  UserType? userType;
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
  if (message.notification != null) {}
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

    // Request permission
    await firebaseMessaging.FirebaseMessaging.instance.requestPermission();

    // This handles the case where the app is started because the user interacted with a notification.
    firebaseMessaging.RemoteMessage? initialMessage =
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

  static Future<String?> getDeviceToken() {
    return firebaseMessaging.FirebaseMessaging.instance.getToken();
  }

  static dynamic fireRefNullable(String collection, String? id) {
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
    return fireUpdate('privateDonators', x.id!, x.dbWrite());
  }

  static Future<void> editPrivateRequester(PrivateRequester x) {
    return fireUpdate('privateRequesters', x.id!, x.dbWrite());
  }

  static Future<void> _editDonatorFromProfilePage(
      Donator x, ProfilePageInfo initialInfo) async {
    await fireUpdate('donators', x.id!, x.dbWrite());
    if (x.name != initialInfo.name ||
        x.addressLatCoord != initialInfo.addressLatCoord ||
        x.addressLngCoord != initialInfo.addressLngCoord) {
      final result = (await fire
              .collection('donations')
              .where('donator', isEqualTo: fireRef('donators', x.id!))
              .get())
          .docs;
      await fire.runTransaction((transaction) async {
        for (final y in result) {
          transaction.update(
              y.reference,
              (Donation()
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
                  .dbWriteCopied());
        }
      });
    }
  }

  static Future<void> _editRequesterFromProfilePage(
      Requester x, ProfilePageInfo initialInfo) async {
    await fireUpdate('requesters', x.id!, x.dbWrite());
    if (x.name != initialInfo.name ||
        x.addressLatCoord != initialInfo.addressLatCoord ||
        x.addressLngCoord != initialInfo.addressLngCoord) {
      final result = (await fire
              .collection('publicRequests')
              .where('requester', isEqualTo: fireRef('requesters', x.id!))
              .get())
          .docs;
      await fire.runTransaction((transaction) async {
        for (final y in result) {
          transaction.update(
              y.reference,
              (PublicRequest()
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
                  .dbWriteCopied());
        }
      });
    }
  }

  static Future<void> editDonation(Donation x) async {
    await fire.runTransaction((transaction) async {
      var donator = Donator()
        ..dbRead(await transaction.get(fireRef('donators', x.donatorId!)));
      // Assume that numMeals exists from the DB
      // Remember that this is a Donator, not a Donation

      // "Undo" the meals associated with the donation
      if (x.initialStatus == Status.PENDING ||
          x.initialStatus == Status.COMPLETED) {
        donator.numMeals = donator.numMeals! - x.initialNumMeals!;
      }
      if (x.status == Status.PENDING || x.status == Status.COMPLETED) {
        donator.numMeals = donator.numMeals! + x.numMeals!;
      }
      transaction.update(fireRef('donators', donator.id!), donator.dbWrite());
      transaction.update(fireRef('donations', x.id!), x.dbWrite());
    });
    x.initialNumMeals = x.numMeals;
    x.initialStatus = x.status;
  }

  static Future<void> newPublicRequest(
      PublicRequest x, AuthenticationModel authModel) async {
    final requester = authModel.requester!;
    x.requesterNameCopied = requester.name;
    x.requesterAddressLatCoordCopied = requester.addressLatCoord;
    x.requesterAddressLngCoordCopied = requester.addressLngCoord;
    await fireAdd('publicRequests', x.dbWrite());
    if (requester.dietaryRestrictions != x.dietaryRestrictions) {
      await authModel.editRequesterDietaryRestrictions(requester);
    }
  }

  static Future<void> _editRequesterDietaryRestrictions(Requester x) {
    return fireUpdate('requesters', x.id!,
        (Requester()..dietaryRestrictions = x.dietaryRestrictions).dbWrite());
  }

  static Future<void> newDonation(Donation x) {
    assert(x.status == Status.PENDING);

    return fire.runTransaction((transaction) async {
      var donator = Donator()
        ..dbRead(await transaction.get(fireRef('donators', x.donatorId!)));
      // Remember that this is a donator, not a donation
      donator.numMeals = donator.numMeals! + x.numMeals!;
      x.donatorNameCopied = donator.name;
      x.donatorAddressLatCoordCopied = donator.addressLatCoord;
      x.donatorAddressLngCoordCopied = donator.addressLngCoord;

      transaction.update(fireRef('donators', x.donatorId!), donator.dbWrite());
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
      String? id) async {
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
    return User()..dbRead(user);
  }

  static Future<PublicRequest> getPublicRequest(String id) async {
    return PublicRequest()..dbRead(await fireGet('publicRequests', id));
  }

  static Future<RequesterDonationListInfo> getRequesterDonationListInfo(
      String? uid) async {
    List<Donation>? donations;
    List<Interest>? interests;
    await Future.wait([
      fire
          .collection('donations')
          .where('status', isEqualTo: statusToStringInDB(Status.PENDING))
          .get()
          .then((x) =>
              donations = x.docs.map((x) => Donation()..dbRead(x)).toList()),
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
    List<Donation>? donations;
    List<Interest>? interests;
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
    if (donations == null) throw 'Donation query failed';
    if (interests == null) throw 'Interests query failed';
    return DonatorPendingDonationsListInfo(
        donations: donations!, interests: interests!);
  }

  static Stream<ViewPublicRequestInfo<Requester>>
      getStreamingDonatorViewPublicRequestInfo(
          PublicRequest publicRequest, String? uid) async* {
    if (publicRequest.donatorId == null) {
      yield ViewPublicRequestInfo(publicRequest);
    } else {
      final requesterFuture = fireGet('requesters', publicRequest.requesterId!);
      final streamOfMessages = fire
          .collection('chatMessages')
          .where('donator', isEqualTo: fireRef('donators', uid!))
          .where('publicRequest',
              isEqualTo: fireRef('publicRequests', publicRequest.id!))
          .snapshots();

      await for (final messages in streamOfMessages) {
        yield ViewPublicRequestInfo(
            publicRequest,
            messages.docs.map((x) => ChatMessage()..dbRead(x)).toList(),
            Requester()..dbRead(await requesterFuture));
      }
    }
  }

  static Future<void> editPublicRequest(PublicRequest? x) {
    return fire.runTransaction((transaction) async {
      // This is since all writes must come after all reads.
      final List<Function> updatesToRun = [
        () => transaction.update(fireRef('publicRequests', x!.id!), x.dbWrite())
      ];
      final currentNumMeals = x!.numMealsChild! + x.numMealsAdult!;
      if (x.initialDonatorId != null && currentNumMeals != x.initialNumMeals) {
        final donator = Donator()
          ..dbRead(
              await transaction.get(fireRef('donators', x.initialDonatorId!)));
        donator.numMeals = donator.numMeals! - x.initialNumMeals!;
        donator.numMeals = donator.numMeals! + currentNumMeals;
        updatesToRun.add(() => transaction.update(
            fireRef('donators', x.donatorId!), donator.dbWrite()));
      }
      if (x.initialDonatorId != null && x.donatorId == null) {
        final donator = Donator()
          ..dbRead(
              await transaction.get(fireRef('donators', x.initialDonatorId!)));
        donator.numMeals = donator.numMeals! - currentNumMeals;
        updatesToRun.add(() => transaction.update(
            fireRef('donators', x.initialDonatorId!), donator.dbWrite()));
      }
      if (x.initialDonatorId == null && x.donatorId != null) {
        final donator = Donator()
          ..dbRead(await transaction.get(fireRef('donators', x.donatorId!)));
        donator.numMeals = donator.numMeals! + currentNumMeals;
        updatesToRun.add(() => transaction.update(
            fireRef('donators', x.donatorId!), donator.dbWrite()));
      }
      updatesToRun.forEach((f) => f());
    });
  }

  static Future<void> editInterest(Interest? old, Interest x,
      [Status? status]) async {
    final newStatus = status ?? x.status;
    final oldNumMealsRequested = x.status == Status.CANCELLED
        ? 0
        : old!.numChildMeals! + old.numAdultMeals!;
    final newNumMealsRequested =
        newStatus == Status.CANCELLED ? 0 : x.numChildMeals! + x.numAdultMeals!;
    if (oldNumMealsRequested == newNumMealsRequested) {
      if (status != null)
        await fireUpdate(
            'interests', x.id!, Interest.dbWriteOnlyStatus(status));
    } else {
      String? err;
      await fire.runTransaction((transaction) async {
        final donation = Donation()
          ..dbRead(await transaction.get(fireRef('donations', x.donationId!)));
        final newValue = donation.numMealsRequested! -
            oldNumMealsRequested +
            newNumMealsRequested;
        if (newValue > donation.numMeals!) {
          err =
              'You requested $newNumMealsRequested meals, but only ${donation.numMeals! - donation.numMealsRequested!} meals are available.';
        } else {
          transaction.update(fireRef('donations', donation.id!),
              Donation.dbWriteOnlyNumMealsRequested(newValue));
          if (status != null)
            transaction.update(fireRef('interests', x.id!),
                Interest.dbWriteOnlyStatus(status));
        }
        if (status != null)
          transaction.update(
              fireRef('interests', x.id!), Interest.dbWriteOnlyStatus(status));
      });
      if (err != null) {
        throw err!;
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

    String? err;

    await fire.runTransaction((transaction) async {
      final donation = Donation()
        ..dbRead(await transaction.get(fireRef('donations', x.donationId!)));
      if (donation.numMealsRequested! + x.numAdultMeals! + x.numChildMeals! >
          donation.numMeals!) {
        err =
            'You requested ${x.numAdultMeals! + x.numChildMeals!} meals, but only ${donation.numMeals! - donation.numMealsRequested!} meals are available.';
      } else {
        transaction.set(fire.collection('interests').doc(), x.dbWrite());
        transaction.update(
            fireRef('donations', x.donationId!),
            (Donation.dbWriteOnlyNumMealsRequested(donation.numMealsRequested! +
                x.numAdultMeals! +
                x.numChildMeals!)));
      }
    });

    if (err != null) {
      throw err!;
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
      ..dbRead(await fireGet('donations', interest.donationId!));
    final donator = Donator()
      ..dbRead(await fireGet('donators', donation.donatorId!));
    final streamOfMessages = fire
        .collection('chatMessages')
        .where('requester', isEqualTo: fireRef('requesters', uid))
        .where('interest', isEqualTo: fireRef('interests', interest.id!))
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
        .where('interest', isEqualTo: fireRef('interests', val.interest.id!))
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

  static Stream<ViewPublicRequestInfo<Donator>>
      getStreamingRequesterViewPublicRequestInfo(
          PublicRequest publicRequest, String? uid) async* {
    if (publicRequest.donatorId == null) {
      yield ViewPublicRequestInfo(publicRequest);
    } else {
      final donator = Donator()
        ..dbRead(await fireGet('donators', publicRequest.donatorId!));
      final streamOfMessages = fire
          .collection('chatMessages')
          .where('requester', isEqualTo: fireRef('requesters', uid!))
          .where('interest',
              isEqualTo: fireRef('publicRequests', publicRequest.id!))
          .where('donator', isEqualTo: fireRef('donators', donator.id!))
          .snapshots();
      await for (final messages in streamOfMessages) {
        yield ViewPublicRequestInfo(
            publicRequest,
            messages.docs.map((x) => ChatMessage()..dbRead(x)).toList(),
            donator);
      }
    }
  }

  static Future<String> getUrlForProfilePicture(String ref) async {
    final url = await fireStorage.ref(ref).getDownloadURL();
    return url;
  }

  static Future<void> deleteProfilePicture(String ref) {
    return fireStorage.ref(ref).delete();
  }

  static Future<String> uploadProfilePicture(
      String fileRef, String? uid) async {
    final result =
        await fireStorage.ref('/profilePictures/$uid').putFile(File(fileRef));
    return result.ref.fullPath;
  }

  static Future<void> reportUser(
      {required String uid, required String otherUid, required String info}) {
    final obj = UserReport()
      ..uid = uid
      ..otherUid = otherUid
      ..info = info;
    return fireAdd('userReports', obj.dbWrite());
  }
}

class ChatUsers {
  const ChatUsers({required this.donatorId, required this.requesterId});
  final String donatorId;
  final String requesterId;
}

// https://stackoverflow.com/questions/20791286/how-to-define-interfaces-in-dart
abstract class HasStatus {
  Status? status;
}

abstract class HasDateRange {
  int? getDateBegin();
  int? getDateEnd();
}

class Donation implements HasStatus, HasDateRange {
  String? id;
  String? donatorId;
  int? numMeals;
  int? initialNumMeals;
  int? dateBegin;
  int? dateEnd;
  int? getDateBegin() => dateBegin;
  int? getDateEnd() => dateEnd;
  String? description; // TODO add dietary restrictions
  int?
      numMealsRequested; // This value can be updated by any requester as they submit interests
  Status? status;
  Status? initialStatus;

  // copied from Donator document
  String? donatorNameCopied;
  num? donatorAddressLatCoordCopied;
  num? donatorAddressLngCoordCopied;

  static Map<String, dynamic> dbWriteOnlyNumMealsRequested(
      int numMealsRequested) {
    final testing = (DbWrite()..i(numMealsRequested, 'numMealsRequested')).m;
    return testing;
  }

  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..r(donatorId, 'donator', 'donators')
          ..i(numMeals, 'numMeals')
          ..i(dateBegin, 'dateBegin')
          ..i(dateEnd, 'dateEnd')
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
    dateBegin = o.i('dateBegin');
    dateEnd = o.i('dateEnd');
    description = o.s('description');
    numMealsRequested = o.i('numMealsRequested');
    donatorNameCopied = o.s('donatorNameCopied');
    donatorAddressLatCoordCopied = o.n('donatorAddressLatCoordCopied');
    donatorAddressLngCoordCopied = o.n('donatorAddressLngCoordCopied');
    status = o.st('status');

    initialNumMeals = numMeals;
    initialStatus = status;
  }

  void formRead(Map<String, dynamic> x) {
    final o = FormRead(x);
    numMeals = o.i('numMeals');
    dateBegin = o.i('dateBegin');
    dateEnd = o.i('dateEnd');
    description = o.s('description');
  }

  Map<String, dynamic> formWrite() {
    return (FormWrite()
          ..i(numMeals, 'numMeals')
          ..date(dateBegin, 'dateBegin')
          ..date(dateEnd, 'dateEnd')
          ..s(description, 'description'))
        .m;
  }

  Map<String, dynamic> dbWriteCopied() {
    return (DbWrite()
          ..s(donatorNameCopied, 'donatorNameCopied')
          ..n(donatorAddressLatCoordCopied, 'donatorAddressLatCoordCopied')
          ..n(donatorAddressLngCoordCopied, 'donatorAddressLngCoordCopied'))
        .m;
  }
}

class WithDistance<T> {
  WithDistance(this.object, this.distance);
  T object;
  num? distance;
}

class PublicRequest implements HasStatus, HasDateRange {
  String? id;
  int? dateBegin;
  int? dateEnd;
  int? getDateBegin() => dateBegin;
  int? getDateEnd() => dateEnd;
  int? numMealsAdult;
  int? numMealsChild;
  String? dietaryRestrictions;
  String? requesterId;
  String? donatorId;
  Status? status;

  int? initialNumMeals;
  String? initialDonatorId;

  // These are copied in from the requester document
  String? requesterNameCopied;
  num? requesterAddressLatCoordCopied;
  num? requesterAddressLngCoordCopied;

  Map<String, dynamic> dbWriteCopied() {
    final xtemp = (DbWrite()
          ..s(requesterNameCopied, 'requesterNameCopied')
          ..n(requesterAddressLatCoordCopied, 'requesterAddressLatCoordCopied')
          ..n(requesterAddressLngCoordCopied, 'requesterAddressLngCoordCopied'))
        .m;
    return xtemp;
  }

  Map<String, dynamic> dbWrite() {
    return (DbWrite()
          ..i(dateBegin, 'dateBegin')
          ..i(dateEnd, 'dateEnd')
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
    dateBegin = o.i('dateBegin');
    dateEnd = o.i('dateEnd');
    numMealsAdult = o.i('numMealsAdult');
    numMealsChild = o.i('numMealsChild');
    dietaryRestrictions = o.s('dietaryRestrictions');
    requesterId = o.r('requester');
    donatorId = o.r('donator');
    status = o.st('status');
    requesterNameCopied = o.s('requesterNameCopied');
    requesterAddressLatCoordCopied = o.n('requesterAddressLatCoordCopied');
    requesterAddressLngCoordCopied = o.n('requesterAddressLngCoordCopied');

    initialNumMeals = numMealsAdult! + numMealsChild!;
    initialDonatorId = donatorId;
  }

  void formRead(Map<String, dynamic> x) {
    var o = FormRead(x);
    dateBegin = o.i('dateBegin');
    dateEnd = o.i('dateEnd');
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
  Interest? interest;
  Donation? donation;
}

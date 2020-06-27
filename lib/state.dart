import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum UserType { REQUESTER, DONATOR }

class AuthenticationModel extends ChangeNotifier {
  String _username;
  String _authenticationToken;
  UserType _userType;
  int _requesterId;
  int _donatorId;
  String get username => _username;
  String get token => _authenticationToken;
  UserType get userType => _userType;
  bool get isLoggedIn => _username != null;
  int get requesterId => _requesterId;
  int get donatorId => _donatorId;

  void attemptLogin(String username, String password) {
    _username = username;
    _authenticationToken = 'abc123';
    _userType = UserType.DONATOR;
    //_userType = UserType.REQUESTER;
    _donatorId = 123;
    _requesterId = 456;
    notifyListeners();
  }

  void logOut() {
    _username = null;
    _authenticationToken = null;
    notifyListeners();
  }
}

class ChatMessage {
  ChatMessage(
      {this.id, this.donatorId, this.requesterId, this.message, this.speaker});
  int id;
  int donatorId;
  int requesterId;
  String message;
  UserType speaker;
  @override
  String toString() {
    return '''id: $id;
donatorId: $donatorId;
requesterId: $requesterId;
message: $message;
speaker: $speaker;
''';
  }
}

class LeaderboardEntry {
  LeaderboardEntry({this.name, this.numMeals});
  String name;
  int numMeals;
}

class User {
  User({this.id, this.name, this.streetAddress, this.zipCode});
  int id;
  String name;
  String streetAddress;
  String zipCode;
}

class Donator extends User {
  Donator({int id, String name, String streetAddress, String zipCode}): super(id: id, name: name, streetAddress: streetAddress, zipCode: zipCode);
}

class Requester extends User {
  Requester({int id, String name, String streetAddress, String zipCode}): super(id: id, name: name, streetAddress: streetAddress, zipCode: zipCode);
}

class ChangeAddressData {
  String address;
  @override
  String toString() {
    return '''address: $address;
''';
  }
}

class Api {
  static Future<List<PublicRequest>> getPublicRequestsByDonationId(int id) {
    return Future.delayed(Duration(seconds: 2), () {
      return [for (int i = 0; i < 100; ++i) _makePublicRequestFromIdAndDonationId(i, id)];
    });
  }

  static Future<List<PublicRequest>> getRequesterPublicRequests() {
    return Future.delayed(Duration(seconds: 2), () {
      return [for (int i = 0; i < 100; ++i) _makePublicRequestFromId(i)];
    });
  }

  static Future<List<ChatMessage>> getChatMessagesByUsers(ChatUsers users) {
    return Future.delayed(Duration(seconds: 2), () {
      return [for (int i = 0; i < 100; ++i) _makeChatMessageFromId(i, users)];
    });
  }

  static ChatMessage _makeChatMessageFromId(int id, ChatUsers users) {
    return ChatMessage(
        id: id,
        donatorId: users.donatorId,
        requesterId: users.requesterId,
        message:
            'Chat Message $id :) Text should wrap if it is long enough. Text should wrap if it is long enough. Text should wrap if it is long enough. Text should wrap if it is long enough.',
        speaker: UserType.DONATOR);
  }

  static Future<Donator> getDonatorById(int id) {
    return Future.delayed(Duration(seconds: 2), () {
      return _makeDonatorFromId(id);
    });
  }
  static Future<Requester> getRequesterById(int id) {
    return Future.delayed(Duration(seconds: 2), () {
      return _makeRequesterFromId(id);
    });
  }

  static Future<PublicRequest> getPublicRequestById(int id) {
    return Future.delayed(Duration(seconds: 2), () {
      return _makePublicRequestFromId(id);
    });
  }

  static Donator _makeDonatorFromId(int id) {
    return Donator(id: id, name: 'Ms. Donator $id', streetAddress: '123$id State Road', zipCode: '12345');
  }

  static Requester _makeRequesterFromId(id) {
    return Requester(id: id, name: 'Ms. Requester $id', streetAddress: '456$id State Road', zipCode: '12345');
  }

  static Future<List<Donation>> getAllDonations() {
    return Future.delayed(Duration(seconds: 2), () {
      return [for (int i = 0; i < 100; ++i) _makeDonationFromId(i)];
    });
  }

  static Future<Donation> getDonationById(int id) {
    return Future.delayed(Duration(seconds: 2), () {
      return _makeDonationFromId(id);
    });
  }

  static Donation _makeDonationFromId(int id) {
    return Donation(
        id: id,
        donatorId: id,
        numMeals: 2 * id,
        description: 'Description',
        dateAndTime: '6.24.2020');
  }

  static PublicRequest _makePublicRequestFromId(int id) {
    return PublicRequest(
        id: id,
        description: 'Description $id',
        dateAndTime: 'Date and time $id',
        numMeals: 3 * id,
        requesterId: id,
        donationId: id % 10 == 0 ? id : null,
        committer: id % 10 == 0 ? (id % 20 == 0 ? UserType.DONATOR : UserType.REQUESTER) : null);
  }

  static PublicRequest _makePublicRequestFromIdAndDonationId(int id, int donationId) {
    return PublicRequest(
        id: id,
        description: 'Description $id',
        dateAndTime: 'Date and time $id',
        numMeals: 3 * id,
        requesterId: id,
        donationId: donationId,
        committer: donationId == null ? null : (id % 2 == 0 ? UserType.DONATOR : UserType.REQUESTER)
    );
  }

  static Future<List<Donation>> getDonatorDonations() {
    return Future.delayed(Duration(seconds: 2), () {
      return [for (int i = 0; i < 100; ++i) _makeDonationFromId(i)];
    });
  }

  static Future<void> deletePublicRequest(int id) {
    return Future.delayed(Duration(seconds: 2), () {});
  }

  static Future<void> editPublicRequestCommitting({@required int publicRequestId, @required int donationId, @required UserType committer}) {
    return Future.delayed(Duration(seconds: 2), () {});
  }

  static Future<List<LeaderboardEntry>> getLeaderboard() {
    return Future.delayed(Duration(seconds: 2), () {
      return [for (int i = 0; i < 100; ++i) _makeLeaderboardEntry(i)];
    });
  }

  static LeaderboardEntry _makeLeaderboardEntry(int n) {
    return LeaderboardEntry(name: 'Name $n', numMeals: 2000 - n);
  }

  static Future<List<Requester>> getRequestersWithChats() {
    return Future.delayed(Duration(seconds: 2), () {
      return [for (int i = 0; i < 100; ++i) _makeRequesterFromId(i)];
    });
  }

  static Future<List<Donator>> getDonatorsWithChats() {
    return Future.delayed(Duration(seconds: 2), () {
      return [for (int i = 0; i < 100; ++i) _makeDonatorFromId(i)];
    });
  }
}

class ChatUsers {
  const ChatUsers({@required this.donatorId, @required this.requesterId});
  final int donatorId;
  final int requesterId;
  @override
  String toString() {
    return '''donatorId: $donatorId;
requesterId: $requesterId;
''';
  }
}

class Donation {
  Donation(
      {this.id,
      this.donatorId,
      this.numMeals,
      this.dateAndTime,
      this.description});
  int id;
  int donatorId;
  int numMeals;
  String dateAndTime;
  String description;
  @override
  String toString() {
    return '''id: $id;
numMeals: $numMeals;
dateAndTime: $dateAndTime;
description: $description;
''';
  }
}

class PublicRequest {
  PublicRequest(
      {this.id,
      this.description,
      this.dateAndTime,
      this.numMeals,
      this.requesterId,
      this.donationId,
      this.committer});
  int id;
  String description;
  String dateAndTime;
  int numMeals;
  int requesterId;
  int donationId;
  UserType committer;
  @override
  String toString() {
    return '''id: $id;
description: $description;
dateAndTime: $dateAndTime;
numMeals: $numMeals;
requesterId: $requesterId;
donationId: $donationId;
committer: $committer;
''';
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
  int donationId;
}
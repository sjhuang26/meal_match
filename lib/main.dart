import 'dart:ffi';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:gradient_text/gradient_text.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state.dart';
import 'user-donator.dart';
import 'user-requester.dart';
import 'package:flutter/cupertino.dart';
import 'package:dash_chat/dash_chat.dart' as dashChat;

const colorDeepOrange = const Color(0xFFF27A54);
const colorPurple = const Color(0xFFA154F2);
const colorStandardGradient = const [colorDeepOrange, colorPurple];

AuthenticationModel provideAuthenticationModel(BuildContext context) {
  return Provider.of<AuthenticationModel>(context, listen: false);
}

enum MySnackbarOperationBehavior {
  POP_ZERO,
  POP_ONE,
  POP_ONE_AND_REFRESH,
  POP_TWO_AND_REFRESH,
  POP_THREE_AND_REFRESH
}

Future<void> doSnackbarOperation(BuildContext context, String initialText,
    String finalText, Future<void> future,
    [MySnackbarOperationBehavior behavior]) async {
  Scaffold.of(context).showSnackBar(SnackBar(content: Text(initialText)));
  try {
    await future;
    if (behavior == MySnackbarOperationBehavior.POP_ONE_AND_REFRESH) {
      Navigator.pop(
          context,
          MyNavigationResult()
            ..message = finalText
            ..refresh = true);
    } else if (behavior == MySnackbarOperationBehavior.POP_TWO_AND_REFRESH) {
      Navigator.pop(
          context,
          MyNavigationResult()
            ..pop = (MyNavigationResult()
              ..message = finalText
              ..refresh = true));
    } else if (behavior == MySnackbarOperationBehavior.POP_THREE_AND_REFRESH) {
      Navigator.pop(
          context,
          MyNavigationResult()
            ..pop = (MyNavigationResult()
              ..pop = (MyNavigationResult()
                ..message = finalText
                ..refresh = true)));
    } else if (behavior == MySnackbarOperationBehavior.POP_ONE) {
      Navigator.pop(context, MyNavigationResult()..message = finalText);
    } else {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(finalText)));
    }
  } catch (e) {
    Scaffold.of(context).hideCurrentSnackBar();
    Scaffold.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  }
  //Navigator.pop(context);
}

class TileTrailingAction<T> {
  const TileTrailingAction(this.text, this.onSelected);

  final String text;
  final void Function(List<T>, int) onSelected;
}

Widget buildMyStandardFutureBuilderCombo<T>(
    {@required Future<T> api,
    @required List<Widget> Function(BuildContext, T) children}) {
  return buildMyStandardFutureBuilder(
      api: api,
      child: (context, data) => ListView(children: children(context, data)));
}

Widget buildMyStandardBackButton(BuildContext context) {
  return GestureDetector(
    onTap: () => Navigator.of(context).pop(),
    child: Container(
      margin: EdgeInsets.only(right: 15, top: 5),
      width: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colorStandardGradient),
      ),
      child: Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
      ),
    ),
  );
}

Widget buildMyStandardScaffold(
    {String title,
    double fontSize: 30,
    @required BuildContext context,
    @required Widget body,
    Key scaffoldKey,
    bool showProfileButton = true,
    BottomNavigationBar bottomNavigationBar,
    Widget appBarBottom}) {
  return Scaffold(
    key: scaffoldKey,
    bottomNavigationBar: bottomNavigationBar,
    body: SafeArea(child: body),
    appBar: PreferredSize(
        preferredSize:
            appBarBottom == null ? Size.fromHeight(75) : Size.fromHeight(105),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 3),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ],
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(30)),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(30)),
            child: AppBar(
              bottom: appBarBottom,
              elevation: 0,
              title: title == null
                  ? null
                  : Container(
                      margin: EdgeInsets.only(top: 16),
                      child: Text(
                        title,
                        style: GoogleFonts.cabin(
                          textStyle: TextStyle(
                              color: Colors.black,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              actions: [
                if (showProfileButton)
                  Container(
                    padding: EdgeInsets.only(top: 5, right: 10),
                    child: IconButton(
                        iconSize: 45,
                        icon: Icon(Icons.account_circle, color: Colors.black),
                        onPressed: () =>
                            NavigationUtil.navigate(context, '/profile')),
                  ),
                if (!showProfileButton) buildMyStandardBackButton(context),
              ],
              automaticallyImplyLeading: false,
//                  titleSpacing: 10,
              backgroundColor: Colors.white,
            ),
          ),
        )),
  );
}

Widget buildMyStandardLoader() {
  print('Built loader');
  return Center(
      child: Container(
          padding: EdgeInsets.only(top: 30),
          child: CircularProgressIndicator()));
}

Widget buildMyStandardError(Object error) {
  return Center(child: Text('Error: $error', style: TextStyle(fontSize: 36)));
}

Widget buildMyStandardFutureBuilder<T>(
    {@required Future<T> api,
    @required Widget Function(BuildContext, T) child}) {
  return FutureBuilder<T>(
      future: api,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return buildMyStandardLoader();
        } else if (snapshot.hasError)
          return buildMyStandardError(snapshot.error);
        else
          return child(context, snapshot.data);
      });
}

class MyRefreshable extends StatefulWidget {
  MyRefreshable({@required this.builder});

  final Widget Function(BuildContext, void Function()) builder;

  @override
  _MyRefreshableState createState() => _MyRefreshableState();
}

class _MyRefreshableState extends State<MyRefreshable> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, () => setState(() {}));
  }
}

class MyRefreshableId<T> extends StatefulWidget {
  MyRefreshableId(
      {@required this.builder, @required this.api, this.initialValue});

  final Widget Function(BuildContext, T, Future<void> Function()) builder;
  final Future<T> Function() api;
  final T initialValue;

  @override
  _MyRefreshableIdState<T> createState() => _MyRefreshableIdState<T>();
}

class _MyRefreshableIdState<T> extends State<MyRefreshableId<T>> {
  Future<T> value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue == null
        ? widget.api()
        : Future.value(widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<T>(
        api: value,
        child: (context, data) => widget.builder(context, data, () async {
              setState(() {
                value = widget.api();
              });
            }));
  }
}

class MyNavigationResult {
  String message;
  bool refresh;
  MyNavigationResult pop;

  void apply(BuildContext context, [void Function() doRefresh]) {
    print('TESTING');
    print(doRefresh);
    print(refresh);
    if (pop != null) {
      NavigationUtil.pop(context, pop);
    } else {
      if (message != null) {
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      if (refresh == true) {
        print("Got into refresh");
        doRefresh();
      }
    }
  }
}

class NavigationUtil {
  static Future<MyNavigationResult> pushNamed<T>(
      BuildContext context, String routeName,
      [T arguments]) async {
    return (await Navigator.pushNamed(context, routeName, arguments: arguments))
        as MyNavigationResult;
  }

  static void pop(BuildContext context, MyNavigationResult result) {
    Navigator.pop(context, result);
  }

  static void navigate(BuildContext context, [String route, Object arguments]) {
    if (route == null) {
      NavigationUtil.pop(context, null);
    } else {
      NavigationUtil.pushNamed(context, route, arguments).then((result) {
        result?.apply(context, null);
      });
    }
  }

  static void navigateWithRefresh(
      BuildContext context, String route, void Function() refresh,
      [Object arguments]) {
    NavigationUtil.pushNamed(context, route, arguments).then((result) {
      final modifiedResult = result ?? MyNavigationResult();
      modifiedResult.refresh = true;
      modifiedResult.apply(context, refresh);
    });
  }
}

Widget buildMyStandardSliverCombo<T>(
    {@required Future<List<T>> Function() api,
    @required String titleText,
    @required String Function(List<T>) secondaryTitleText,
    @required Future<MyNavigationResult> Function(List<T>, int) onTap,
    @required String Function(List<T>, int) tileTitle,
    @required String Function(List<T>, int) tileSubtitle,
    @required Future<MyNavigationResult> Function() floatingActionButton,
    @required List<TileTrailingAction<T>> tileTrailing}) {
  return MyRefreshable(
    builder: (context, refresh) => Scaffold(
        floatingActionButton: floatingActionButton == null
            ? null
            : Builder(
                builder: (context) => FloatingActionButton.extended(
                    label: Text("New Request"),
                    onPressed: () async {
                      final result = await floatingActionButton();
                      result?.apply(context, refresh);
                    }),
              ),
        body: FutureBuilder<List<T>>(
            future: api(),
            builder: (context, snapshot) {
              return CustomScrollView(slivers: [
                if (titleText != null)
                  SliverAppBar(
                      title: Text(titleText),
                      floating: true,
                      expandedHeight: secondaryTitleText == null
                          ? null
                          : (snapshot.hasData ? 100 : null),
                      flexibleSpace: secondaryTitleText == null
                          ? null
                          : snapshot.hasData
                              ? FlexibleSpaceBar(
                                  title:
                                      Text(secondaryTitleText(snapshot.data)),
                                )
                              : null),
                if (snapshot.connectionState == ConnectionState.done &&
                    !snapshot.hasError)
                  SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= snapshot.data.length) return null;
                    return ListTile(
                        onTap: onTap == null
                            ? null
                            : () async {
                                final result =
                                    await onTap(snapshot.data, index);
                                result?.apply(context, refresh);
                              },
                        leading: Text('#${index + 1}',
                            style:
                                TextStyle(fontSize: 30, color: Colors.black54)),
                        title: tileTitle == null
                            ? null
                            : Text(tileTitle(snapshot.data, index),
                                style: TextStyle(fontSize: 24)),
                        subtitle: tileSubtitle == null
                            ? null
                            : Text(tileSubtitle(snapshot.data, index),
                                style: TextStyle(fontSize: 18)),
                        isThreeLine: tileSubtitle == null ? false : true,
                        trailing: tileTrailing == null
                            ? null
                            : PopupMenuButton<int>(
                                child: Icon(Icons.more_vert),
                                onSelected: (int result) => tileTrailing[result]
                                    .onSelected(snapshot.data, index),
                                itemBuilder: (BuildContext context) => [
                                      for (int i = 0;
                                          i < tileTrailing.length;
                                          ++i)
                                        PopupMenuItem(
                                            child: Text(tileTrailing[i].text),
                                            value: i)
                                    ]));
                  })),
                if (snapshot.hasError)
                  SliverList(
                      delegate: SliverChildListDelegate([
                    ListTile(
                        title: Text('Error: ${snapshot.error}',
                            style: TextStyle(fontSize: 24)))
                  ])),
                if (snapshot.connectionState != ConnectionState.done)
                  SliverList(
                      delegate: SliverChildListDelegate([
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: SpinKitWave(
                          color: Colors.black26,
                          size: 250.0,
                        ))
                  ]))
              ]);
            })),
  );
}

Widget buildMyNavigationButton(BuildContext context, String text,
    [String route, Object arguments, double textSize = 24]) {
  return buildMyStandardButton(text, () {
    NavigationUtil.navigate(context, route, arguments);
  }, textSize: textSize);
}

Widget buildMyNavigationButtonWithRefresh(
    BuildContext context, String text, String route, void Function() refresh,
    [Object arguments, double textSize = 24]) {
  return buildMyStandardButton(text, () async {
    NavigationUtil.navigateWithRefresh(context, route, refresh, arguments);
  }, textSize: textSize);
}

// https://stackoverflow.com/questions/52243364/flutter-how-to-make-a-raised-button-that-has-a-gradient-background
Widget buildMyStandardButton(String text, VoidCallback onPressed,
    {double textSize = 24}) {
  return Container(
    margin: EdgeInsets.only(top: 10, left: 15, right: 15),
    child: RaisedButton(
      onPressed: onPressed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(80.0)),
      padding: EdgeInsets.all(0.0),
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: colorStandardGradient),
          borderRadius: BorderRadius.all(Radius.circular(80.0)),
        ),
        child: Container(
          constraints: const BoxConstraints(
              minWidth: 88.0,
              minHeight: 36.0), // min sizes for Material buttons
          alignment: Alignment.center,
          child: Row(children: [
            SizedBox(width: 25),
            Expanded(
              child: Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: textSize, color: Colors.white)),
            ),
            Container(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward_ios,
                    size: 22, color: Colors.white)),
            SizedBox(width: 10)
          ]),
        ),
      ),
    ),
  );
}

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => AuthenticationModel(),
    child: Builder(
      builder: (context) => MaterialApp(
          title: 'Meal Match',
          initialRoute: '/',
          routes: {
            '/': (context) => MyHomePage(),
            '/profile': (context) => ProfilePage(),
            '/chatTest': (context) => ChatTestPage(),
            '/signIn': (context) => MySignInPage(),
            '/signUpAsDonator': (context) => MyDonatorSignUpPage(),
            '/signUpAsRequester': (context) => MyRequesterSignUpPage(),
            '/changePassword': (context) => MyChangePasswordPage(),
            '/changeEmail': (context) => MyChangeEmailPage(),
            // used by donator
            '/donator/donations/new': (context) => DonatorDonationsNewPage(),
            '/donator/donations/list': (context) => DonatorDonationsListPage(),
            '/donator/donations/view': (context) => DonatorDonationsViewPage(
                ModalRoute.of(context).settings.arguments as Donation),
            '/donator/donations/delete': (context) =>
                DonatorDonationsDeletePage(
                    ModalRoute.of(context).settings.arguments as Donation),
            '/donator/donations/publicRequests/list': (context) =>
                DonatorDonationsPublicRequestsListPage(
                    ModalRoute.of(context).settings.arguments as Donation),
            '/donator/donations/publicRequests/view': (context) =>
                DonatorDonationsPublicRequestsViewPage(ModalRoute.of(context)
                    .settings
                    .arguments as PublicRequestAndDonation),
            '/donator/publicRequests/list': (context) =>
                DonatorPublicRequestsListPage(),
            '/donator/publicRequests/view': (context) =>
                DonatorPublicRequestsViewPage(
                    ModalRoute.of(context).settings.arguments as PublicRequest),
            '/donator/publicRequests/donations/list': (context) =>
                DonatorPublicRequestsDonationsListPage(
                    ModalRoute.of(context).settings.arguments as PublicRequest),
            '/donator/publicRequests/donations/view': (context) =>
                DonatorPublicRequestsDonationsViewPage(ModalRoute.of(context)
                    .settings
                    .arguments as PublicRequestAndDonation),
            // used by requester
            '/requester/publicRequests/list': (context) =>
                RequesterPublicDonationsNearRequesterListPage(),
            '/requester/publicRequests/view': (context) =>
                RequesterPublicRequestsViewPage(
                    ModalRoute.of(context).settings.arguments as PublicRequest),
            '/requester/publicRequests/new': (context) =>
                RequesterPublicRequestsNewPage(),
            '/requester/publicRequests/delete': (context) =>
                RequesterPublicRequestsDeletePage(
                    ModalRoute.of(context).settings.arguments as PublicRequest),
            '/requester/publicRequests/donations/list': (context) =>
                RequesterPublicRequestsDonationsList(
                    ModalRoute.of(context).settings.arguments as PublicRequest),
            '/requester/publicRequests/donations/view': (context) =>
                RequesterPublicRequestsDonationsViewPage(ModalRoute.of(context)
                    .settings
                    .arguments as PublicRequestAndDonation),
            '/requester/publicRequests/donations/viewOld': (context) =>
                RequesterPublicRequestsDonationsViewOldPage(
                    ModalRoute.of(context).settings.arguments
                        as PublicRequestAndDonationId),
            // chat (both requester and donator)
            '/chat': (context) => ChatPage(
                ModalRoute.of(context).settings.arguments as ChatUsers),
            '/chat/newMessage': (context) => ChatNewMessagePage(
                ModalRoute.of(context).settings.arguments as ChatUsers),
            // user pages
            '/donator': (context) => DonatorPage(
                ModalRoute.of(context).settings.arguments as String),
            '/requester': (context) => RequesterPage(
                ModalRoute.of(context).settings.arguments as String),
            // user info
            '/donator/changeUserInfo': (context) => DonatorChangeUserInfoPage(),
            '/requester/changeUserInfo': (context) =>
                RequesterChangeUserInfoPage(),
            '/donator/changeUserInfo/private': (context) =>
                DonatorChangeUserInfoPrivatePage(
                    ModalRoute.of(context).settings.arguments as String),
            '/requester/changeUserInfo/private': (context) =>
                RequesterChangeUserInfoPrivatePage(
                    ModalRoute.of(context).settings.arguments as String),
            '/requester/publicDonations/specificPublicDonation': (context) =>
                SpecificPublicDonationInfoPage(ModalRoute.of(context)
                    .settings
                    .arguments as DonationAndDonator),
            '/requester/newInterestPage': (context) => InterestNewPage(
                ModalRoute.of(context).settings.arguments
                    as DonationIdAndRequesterId),
            '/requester/specificInterestPage': (context) =>
                SpecificPendingInterestPage(
                    ModalRoute.of(context).settings.arguments as Interest),
            '/requester/publicRequests/specificPublicRequestPage': (context) =>
                SpecificPendingPublicRequestPage(
                    ModalRoute.of(context).settings.arguments as PublicRequest)
          },
          theme: ThemeData(
            textTheme: GoogleFonts.cabinTextTheme(Theme.of(context).textTheme),
            primaryColor: colorDeepOrange,
            accentColor: Colors.black87,
          )),
    ),
  ));
}

List<Widget> buildViewPublicRequestContent(PublicRequest publicRequest) {
  return [
    ListTile(title: Text('Date and time: ${publicRequest.dateAndTime}')),
    ListTile(
        title: Text('Number of meals (adult): ${publicRequest.numMealsAdult}')),
    ListTile(
        title: Text('Number of meals (adult): ${publicRequest.numMealsAdult}')),
  ];
}

List<Widget> buildViewDonationContent(Donation donation) {
  return [
    ListTile(title: Text('ID#: ${donation.id}')),
    ListTile(title: Text('Food description: ${donation.description}')),
    ListTile(title: Text('Date and time range: ${donation.dateAndTime}')),
    ListTile(title: Text('Number of meals: ${donation.numMeals}')),
    ListTile(
        title: Text('Number of meals requested: ${donation.numMealsRequested}'))
  ];
}

class DonatorPage extends StatelessWidget {
  const DonatorPage(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Donor')), body: ViewDonator(id));
  }
}

List<Widget> buildPublicUserInfo(BaseUser user) {
  return [
    ListTile(title: Text('Name: ${user.name}')),
    ListTile(title: Text('ZIP code: ${user.zipCode}'))
  ];
}

class ViewDonator extends StatefulWidget {
  const ViewDonator(this.id);

  final String id;

  @override
  _ViewDonatorState createState() => _ViewDonatorState();
}

class _ViewDonatorState extends State<ViewDonator> {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilderCombo<Donator>(
        api: Api.getDonator(widget.id),
        children: (context, data) => [
              ...buildPublicUserInfo(data),
              buildMyNavigationButton(
                  context,
                  'Chat with donor',
                  '/chat',
                  ChatUsers(
                      donatorId: data.id,
                      requesterId:
                          provideAuthenticationModel(context).requesterId))
            ]);
  }
}

class RequesterPage extends StatelessWidget {
  const RequesterPage(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Requester')), body: ViewRequester(id));
  }
}

class ViewRequester extends StatelessWidget {
  const ViewRequester(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilderCombo<Requester>(
        api: Api.getRequester(id),
        children: (context, data) => [
              ...buildPublicUserInfo(data),
              buildMyNavigationButton(
                  context,
                  'Chat with requester',
                  '/chat',
                  ChatUsers(
                      donatorId: provideAuthenticationModel(context).donatorId,
                      requesterId: data.id))
            ]);
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage(this.chatUsers);

  final ChatUsers chatUsers;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardSliverCombo<ChatMessage>(
        api: () => Api.getChatMessagesByUsers(chatUsers),
        titleText: 'Chat',
        secondaryTitleText: (data) => '${data.length} messages',
        onTap: null,
        tileTitle: (data, index) =>
            '${data[index].speaker == UserType.DONATOR ? 'Donor' : 'Requester'}',
        tileSubtitle: (data, index) => '${data[index].message}',
        tileTrailing: null,
        floatingActionButton: () =>
            NavigationUtil.pushNamed(context, '/chat/newMessage', chatUsers));
  }
}

class ChatNewMessagePage extends StatelessWidget {
  const ChatNewMessagePage(this.chatUsers);

  final ChatUsers chatUsers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Send chat message')),
        body: NewChatMessage(chatUsers));
  }
}

class NewChatMessage extends StatelessWidget {
  NewChatMessage(this.chatUsers);

  final ChatUsers chatUsers;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardTextFormField('message', 'Message'),
      buildMyStandardButton('Submit new message', () {
        if (_formKey.currentState.saveAndValidate()) {
          var value = _formKey.currentState.value;
          doSnackbarOperation(
              context,
              'Submitting chat message...',
              'Submitted chat message!',
              Api.newChatMessage(ChatMessage()
                ..formRead(value)
                ..speaker = provideAuthenticationModel(context).userType
                ..donatorId = chatUsers.donatorId
                ..requesterId = chatUsers.requesterId),
              MySnackbarOperationBehavior.POP_ONE_AND_REFRESH);
        }
      })
    ];

    return buildMyFormListView(_formKey, children);
  }
}

class MyChangePasswordPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        title: 'Change Password',
        fontSize: 28,
        body: MyChangePasswordForm(),
        context: context);
  }
}

class MyChangeEmailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        title: 'Change Email',
        fontSize: 30,
        body: MyChangeEmailForm(),
        context: context);
  }
}

class MySignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Sign in')), body: MyLoginForm());
  }
}

class MyLoginForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardEmailFormField('email', 'Email'),
      buildMyStandardTextFormField('password', 'Password', obscureText: true),
      buildMyStandardButton('Login', () {
        if (_formKey.currentState.saveAndValidate()) {
          var value = _formKey.currentState.value;
          doSnackbarOperation(
              context,
              'Logging in...',
              'Successfully logged in!',
              provideAuthenticationModel(context)
                  .attemptLogin(value['email'], value['password']),
              MySnackbarOperationBehavior.POP_ZERO);
        }
      }),
      buildMyStandardButton('DEBUG: sharedpref', () async {
        final instance = await SharedPreferences.getInstance();
        instance.setBool('is_first_time', true);
      }),
      buildMyNavigationButton(context, 'Sign up as donor', '/signUpAsDonator'),
      buildMyNavigationButton(
          context, 'Sign up as requester', '/signUpAsRequester'),
    ];

    return buildMyFormListView(_formKey, children);
  }
}

class MyChangePasswordForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardTextFormField('oldPassword', 'Old password',
          obscureText: true),
      ...buildMyStandardPasswordSubmitFields(),
      buildMyStandardButton('Change password', () {
        if (_formKey.currentState.saveAndValidate()) {
          var value = _formKey.currentState.value;
          doSnackbarOperation(
              context,
              'Changing password...',
              'Password successfully changed!',
              provideAuthenticationModel(context).userChangePassword(
                  UserChangePasswordData()..formRead(value)),
              MySnackbarOperationBehavior.POP_ONE);
        }
      })
    ];

    return buildMyFormListView(_formKey, children);
  }
}

class MyChangeEmailForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardTextFormField('oldPassword', 'Enter password',
          obscureText: true),
      buildMyStandardEmailFormField('email', 'New email'),
      buildMyStandardButton('Change email', () {
        if (_formKey.currentState.saveAndValidate()) {
          var value = _formKey.currentState.value;
          doSnackbarOperation(
              context,
              'Changing email...',
              'Email successfully changed!',
              provideAuthenticationModel(context)
                  .userChangeEmail(UserChangeEmailData()..formRead(value)),
              MySnackbarOperationBehavior.POP_ONE);
        }
      })
    ];

    return buildMyFormListView(_formKey, children);
  }
}

class MyDonatorSignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Sign up as meal donor')),
        body: MyDonatorSignUpForm());
  }
}

class MyDonatorSignUpForm extends StatefulWidget {
  @override
  _MyDonatorSignUpFormState createState() => _MyDonatorSignUpFormState();
}

class _MyDonatorSignUpFormState extends State<MyDonatorSignUpForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  bool isRestaurant = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      FormBuilderSwitch(
        attribute: 'isRestaurant',
        label: Text('Are you a restaurant?'),
        onChanged: (newValue) {
          setState(() {
            isRestaurant = newValue;
          });
        },
      ),
      ...buildUserFormFields(),
      buildMyStandardEmailFormField('email', 'Email'),
      ...buildMyStandardPasswordSubmitFields(),
      ...buildPrivateUserFormFields(),
      if (isRestaurant)
        buildMyStandardTextFormField('restaurantName', 'Name of restaurant'),
      if (isRestaurant)
        buildMyStandardTextFormField('foodDescription', 'Food description'),
      buildMyStandardTermsAndConditions(),
      buildMyStandardButton('Sign up as donor', () {
        if (_formKey.currentState.saveAndValidate()) {
          var value = _formKey.currentState.value;
          doSnackbarOperation(
              context,
              'Signing up...',
              'Successfully signed up!',
              provideAuthenticationModel(context).signUpDonator(
                  Donator()
                    ..formRead(value)
                    ..numMeals = 0,
                  PrivateDonator()..formRead(value),
                  SignUpData()..formRead(value)),
              MySnackbarOperationBehavior.POP_ONE);
        }
      })
    ];
    return buildMyFormListView(_formKey, children,
        initialValue: (Donator()..isRestaurant = isRestaurant).formWrite());
  }
}

class MyRequesterSignUpForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      ...buildUserFormFields(),
      buildMyStandardEmailFormField('email', 'Email'),
      ...buildMyStandardPasswordSubmitFields(),
      ...buildPrivateUserFormFields(),
      buildMyStandardTermsAndConditions(),
      buildMyStandardButton('Sign up as requester', () {
        if (_formKey.currentState.saveAndValidate()) {
          var value = _formKey.currentState.value;
          doSnackbarOperation(
              context,
              'Signing up...',
              'Successfully signed up!',
              provideAuthenticationModel(context).signUpRequester(
                  Requester()..formRead(value),
                  PrivateRequester()..formRead(value),
                  SignUpData()..formRead(value)));
        }
      })
    ];
    return buildMyFormListView(_formKey, children);
  }
}

Widget buildMyStandardTextFormField(String attribute, String labelText,
    {List<FormFieldValidator> validators,
    bool obscureText,
    void Function(dynamic) onChanged}) {
  return FormBuilderTextField(
    attribute: attribute,
    decoration: InputDecoration(labelText: labelText),
    validators:
        validators == null ? [FormBuilderValidators.required()] : validators,
    obscureText: obscureText == null ? false : true,
    maxLines: obscureText == true ? 1 : null,
    onChanged: onChanged,
  );
}

Widget buildMyStandardEmailFormField(String attribute, String labelText,
    {void Function(dynamic) onChanged}) {
  return FormBuilderTextField(
    attribute: attribute,
    decoration: InputDecoration(labelText: labelText),
    validators: [FormBuilderValidators.email()],
    keyboardType: TextInputType.emailAddress,
    onChanged: onChanged,
  );
}

Widget buildMyStandardNumberFormField(String attribute, String labelText) {
  return FormBuilderTextField(
      attribute: attribute,
      decoration: InputDecoration(labelText: labelText),
      validators: [
        (val) {
          return int.tryParse(val) == null ? 'Must be number' : null;
        }
      ],
      valueTransformer: (val) => int.tryParse(val));
}

// https://stackoverflow.com/questions/53479942/checkbox-form-validation
Widget buildMyStandardNewsletterSignup() {
  return FormBuilderCheckbox(
      attribute: 'newsletter', label: Text('I agree to receive promotions'));
}

// https://stackoverflow.com/questions/43583411/how-to-create-a-hyperlink-in-flutter-widget
Widget buildMyStandardTermsAndConditions() {
  return ListTile(
      subtitle: RichText(
          text: TextSpan(children: [
    TextSpan(
        text: 'By signing up, you agree to the ',
        style: TextStyle(color: Colors.black)),
    TextSpan(
        text: 'Terms and Conditions',
        style: TextStyle(color: Colors.blue),
        recognizer: TapGestureRecognizer()
          ..onTap = () => launch('https://mealmatch-855f81.webflow.io/')),
    TextSpan(text: '.', style: TextStyle(color: Colors.black))
  ])));
}

List<Widget> buildMyStandardPasswordSubmitFields(
    {bool required = true, ValueChanged<String> onChanged}) {
  String password = '';
  return [
    buildMyStandardTextFormField('password', 'Password', obscureText: true,
        onChanged: (value) {
      password = value;
      if (onChanged != null) onChanged(password);
    }, validators: [if (required) FormBuilderValidators.required()]),
    buildMyStandardTextFormField('repeatPassword', 'Repeat password',
        obscureText: true,
        validators: [
          (val) {
            if (val != password) {
              return 'Passwords do not match';
            }
            return null;
          },
          if (required) FormBuilderValidators.required(),
        ])
  ];
}

List<Widget> buildUserFormFields() {
  return [
    buildMyStandardTextFormField('name', 'Name'),
    buildMyStandardTextFormField('zipCode', 'Zip code')
  ];
}

List<Widget> buildNewInterestForm() {
  return [
    buildMyStandardTextFormField(
        'requestedPickupLocation', 'Desired Pickup Location'),
    buildMyStandardTextFormField(
        'requestedPickupDateAndTime', 'Desired Pickup Date and Time'),
    buildMyStandardNumberFormField('numAdultMeals', 'Number of Adult Meals'),
    buildMyStandardNumberFormField('numChildMeals', 'Number of Child Meals'),
  ];
}

List<Widget> buildPrivateUserFormFields() {
  return [
    buildMyStandardTextFormField('phone', 'Phone'),
    buildMyStandardNewsletterSignup()
  ];
}

Widget buildMyFormListView(
    GlobalKey<FormBuilderState> key, List<Widget> children,
    {Map<String, dynamic> initialValue = const {}}) {
  return FormBuilder(
    key: key,
    child: CupertinoScrollbar(
        child: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.all(16.0),
                child: Column(children: children)))),
    initialValue: initialValue,
  );
}

class MyRequesterSignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Sign up as meal requester')),
        body: MyRequesterSignUpForm());
  }
}

Widget buildStandardButtonColumn(List<Widget> children) {
  return Container(
      padding: EdgeInsets.all(8.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: children));
}

class IntroPanel extends StatelessWidget {
  const IntroPanel(this.imagePath, this.titleText, this.contentText,
      [this.fullSizeImage = false]);

  final String imagePath;
  final String titleText;
  final String contentText;
  final bool fullSizeImage;

  @override
  Widget build(BuildContext context) {
    // TODO
    if (fullSizeImage) {
      return Container(
          margin: EdgeInsets.all(20.0),
          padding: EdgeInsets.all(8.0),
          width: double.infinity,
          child: Column(children: [
            Expanded(child: Image.asset(imagePath)),
            Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              child: GradientText(
                titleText,
                gradient: LinearGradient(colors: colorStandardGradient),
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Text(contentText, style: TextStyle(fontSize: 24))
          ]));
    } else {
      return Container(
          margin: EdgeInsets.all(20.0),
          padding: EdgeInsets.all(8.0),
          width: double.infinity,
          child: Column(children: [
            Expanded(child: Image.asset(imagePath)),
            Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              child: GradientText(
                titleText,
                gradient: LinearGradient(colors: colorStandardGradient),
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Text(contentText, style: TextStyle(fontSize: 24))
          ]));
    }
  }
}

class MyIntroduction extends StatefulWidget {
  const MyIntroduction(this.scaffoldKey, this.isFirstTime);

  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool isFirstTime;

  @override
  _MyIntroductionState createState() => _MyIntroductionState();
}

class _MyIntroductionState extends State<MyIntroduction> {
  static const numItems = 6;
  static const loremIpsum =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.';

  int position;

  @override
  void initState() {
    super.initState();
    position = widget.isFirstTime ? 5 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: widget.scaffoldKey,
        body: SafeArea(
          child: Builder(
            builder: (context) => CarouselSlider(
                items: [
                  IntroPanel('assets/logo.png', 'Welcome to Meal Match',
                      loremIpsum, true),
                  IntroPanel('assets/logo.png', 'About Us', loremIpsum),
                  IntroPanel(
                      'assets/intro-1.png', 'Request or Donate', loremIpsum),
                  IntroPanel(
                      'assets/intro-2.png', 'Chat Functionality', loremIpsum),
                  IntroPanel('assets/intro-3.png', 'Leaderboards', loremIpsum),
                  Container(
                      width: double.infinity,
                      child: Column(children: [
                        Container(
                          padding: EdgeInsets.only(top: 20),
                          child: Image.asset('assets/logo.png', height: 200),
                        ),
//                        Spacer(),
                        Expanded(
                          child: Builder(
                            builder: (context) => Container(
                                margin: EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                        colors: colorStandardGradient),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    )),
                                padding: EdgeInsets.all(3),
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        )),
                                    child: MyLoginForm())),
                          ),
                        ),
                      ]))
                ],
                options: CarouselOptions(
                    height: MediaQuery.of(context).size.height,
                    viewportFraction: 1,
                    onPageChanged: (index, reason) {
                      setState(() {
                        position = index;
                      });
                    })),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
            child: Container(
                height: 50,
                child: Center(
                    child: DotsIndicator(
                  dotsCount: numItems,
                  position: position.toDouble(),
                  decorator: DotsDecorator(
                    color: Colors.black87,
                    activeColor: Colors.redAccent,
                  ),
                )))));
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<SharedPreferences>(
        api: Future.wait(
                [firebaseInitializeApp(), SharedPreferences.getInstance()])
            .then((values) => values[1] as SharedPreferences),
        child: (context, sharedPrefInstance) =>
            Consumer<AuthenticationModel>(builder: (context, authModel, child) {
              switch (authModel.state) {
                case AuthenticationModelState.NOT_LOGGED_IN:
                  var isFirstTime = true;
                  if (sharedPrefInstance.containsKey('is_first_time')) {
                    isFirstTime = sharedPrefInstance.getBool('is_first_time');
                    if (isFirstTime) {
                      sharedPrefInstance.setBool('is_first_time', false);
                    }
                  } else {
                    sharedPrefInstance.setBool('is_first_time', false);
                  }
                  return MyIntroduction(_scaffoldKey, isFirstTime);
                case AuthenticationModelState.LOADING_LOGIN_DB:
                  return Scaffold(
                      key: _scaffoldKey,
                      body: SafeArea(child: buildMyStandardLoader()));
                case AuthenticationModelState.LOADING_LOGIN_DB_FAILED:
                  return Scaffold(
                      key: _scaffoldKey,
                      body: SafeArea(
                          child: buildMyStandardError(authModel.error)));
                case AuthenticationModelState.LOGGED_IN:
                  return MyUserPage(_scaffoldKey, authModel.userType);
                default:
                  throw Exception('invalid state');
              }
            }));
  }
}

Widget buildLeaderboardEntry(int index, List<LeaderboardEntry> snapshotData,
    [bool isYou = false]) {
  return Row(children: [
    Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: colorStandardGradient),
            borderRadius: BorderRadius.all(Radius.circular(500))),
        child: Container(
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(500)),
          ),
          child: Center(
              child: GradientText('${index + 1}',
                  gradient: LinearGradient(colors: colorStandardGradient),
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
        )),
    SizedBox(width: 10),
    Expanded(
        child: Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ],
                borderRadius: BorderRadius.all(Radius.circular(500))),
            child: Row(children: [
              Expanded(
                // https://stackoverflow.com/questions/44579918/flutter-wrap-text-on-overflow-like-insert-ellipsis-or-fade
                child: Text(isYou ? 'You' : '${snapshotData[index].name}',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Text('${snapshotData[index].numMeals} Meals Served',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 15)),
            ]))),
  ]);
}

class MyUserPage extends StatefulWidget {
  const MyUserPage(this.scaffoldKey, this.userType);

  final GlobalKey<ScaffoldState> scaffoldKey;
  final UserType userType;

  @override
  _MyUserPageState createState() => _MyUserPageState();
}

class _MyUserPageState extends State<MyUserPage> with TickerProviderStateMixin {
  TabController _requestsInterestsTabController;
  int _selectedIndex = 1;
  int leaderboardTotalNumServed;
  Future<void> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _requestsInterestsTabController = TabController(vsync: this, length: 2);
  }

  Future<void> _makeLeaderboardFuture() {
    return (() async {
      final result = await Api.getLeaderboard();
      setState(() {
        leaderboardTotalNumServed =
            result.fold(0, (previousValue, x) => previousValue + x.numMeals);
      });
      return result;
    })();
  }

  @override
  Widget build(BuildContext context) {
    final authModel = provideAuthenticationModel(context);
    return buildMyStandardScaffold(
      context: context,
      scaffoldKey: widget.scaffoldKey,
      appBarBottom: widget.userType == UserType.REQUESTER && _selectedIndex == 2
          ? TabBar(
              controller: _requestsInterestsTabController,
              labelColor: Colors.black,
              tabs: [
                  Tab(text: 'Interests'),
                  Tab(text: 'Requests'),
                ])
          : (_selectedIndex == 3 && leaderboardTotalNumServed != null
              ? PreferredSize(
                  preferredSize: null,
                  child: Container(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                          'Total: ${leaderboardTotalNumServed} meals served',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 24))))
              : null),
      title: (widget.userType == UserType.DONATOR
          ? (_selectedIndex == 0
              ? 'Profile'
              : (_selectedIndex == 1
                  ? 'Home'
                  : (_selectedIndex == 2
                      ? 'Existing Donations'
                      : (_selectedIndex == 3
                          ? 'Leaderboard'
                          : 'Meal Match (Donor)'))))
          : (_selectedIndex == 0
              ? 'Profile'
              : (_selectedIndex == 1
                  ? 'Home'
                  : (_selectedIndex == 2
                      ? 'Pending'
                      : (_selectedIndex == 3
                          ? 'Leaderboard'
                          : 'Meal Match (REQUESTER)'))))),
      fontSize: 30.0 +
          (_selectedIndex == 0
              ? 5
              : (_selectedIndex == 1
                  ? 5
                  : (_selectedIndex == 2
                      ? 5
                      : (_selectedIndex == 3 ? 0 : -2)))),
      body: Center(
        child: Builder(builder: (context) {
          List<Widget> subpages = [
            null, // used to be the profile page
            if (widget.userType == UserType.DONATOR)
              buildStandardButtonColumn([
                buildMyNavigationButton(
                    context, 'My Donations', '/donator/donations/list'),
                buildMyNavigationButton(
                    context, 'New Donation', '/donator/donations/new'),
                buildMyNavigationButton(context, 'People in Your Area',
                    '/donator/publicRequests/list')
              ]),
            if (widget.userType == UserType.REQUESTER)
              RequesterPublicDonationsNearRequesterListPage(),
            if (widget.userType == UserType.DONATOR)
              buildMyStandardSliverCombo<Requester>(
                  api: () => Api.getRequestersWithChats(
                      provideAuthenticationModel(context).donatorId),
                  titleText: null,
                  secondaryTitleText: null,
                  onTap: (data, index) => NavigationUtil.pushNamed(
                      context,
                      '/chat',
                      ChatUsers(
                          donatorId:
                              provideAuthenticationModel(context).donatorId,
                          requesterId: data[index].id)),
                  tileTitle: (data, index) => '${data[index].name}',
                  tileSubtitle: null,
                  tileTrailing: null,
                  floatingActionButton: null),
            if (widget.userType == UserType.REQUESTER)
              RequesterPendingRequestsAndInterestsView(
                  _requestsInterestsTabController),
            buildMyStandardFutureBuilder<List<LeaderboardEntry>>(
                api: _leaderboardFuture,
                child: (context, snapshotData) => Column(children: [
                      Expanded(
                        child: CupertinoScrollbar(
                            child: ListView.builder(
                                itemCount: snapshotData.length,
                                padding: EdgeInsets.only(
                                    top: 10, bottom: 20, right: 15, left: 15),
                                itemBuilder:
                                    (BuildContext context, int index) =>
                                        buildLeaderboardEntry(
                                            index, snapshotData))),
                      ),
                      if (authModel.userType == UserType.DONATOR)
                        Container(
                            padding: EdgeInsets.only(
                                top: 10, bottom: 20, right: 15, left: 15),
                            child: buildLeaderboardEntry(
                                snapshotData.indexWhere(
                                    (x) => x.id == authModel.donatorId),
                                snapshotData,
                                true)),
                    ]))
          ];
          return subpages[_selectedIndex];
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home), title: Text('Home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.people),
                title: Text('Pending Requests')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.cloud), title: Text('Leaderboard'))
          ],
          currentIndex: _selectedIndex - 1,
          unselectedItemColor: Colors.black,
          selectedItemColor: colorDeepOrange,
          onTap: (index) {
            setState(() {
              _selectedIndex = index + 1;
              if (_selectedIndex == 3) {
                _leaderboardFuture = _makeLeaderboardFuture();
              }
            });
          }),
    );
  }
}

class ChatTestPage extends StatefulWidget {
  @override
  _ChatTestPageState createState() => _ChatTestPageState();
}

class _ChatTestPageState extends State<ChatTestPage> {
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController
          .jumpTo(_scrollController.position.maxScrollExtent - 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(80.0);
    return buildMyStandardScaffold(
        title: 'Chat Test',
        context: context,
        body: dashChat.DashChat(
            scrollController: _scrollController,
            shouldStartMessagesFromTop: true,
            onLoadEarlier: () => null, // required
            messageContainerPadding: EdgeInsets.only(top: 20),
            messageDecorationBuilder: (dashChat.ChatMessage msg, bool isUser) {
              if (isUser) {
                return const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: colorStandardGradient),
                  borderRadius: BorderRadius.only(
                      topLeft: radius, bottomLeft: radius, bottomRight: radius),
                );
              } else {
                return BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFB4B5B6)),
                  borderRadius: BorderRadius.only(
                      topRight: radius,
                      bottomLeft: radius,
                      bottomRight: radius),
                );
              }
            },
            onSend: (chatMessage) => null,
            user: dashChat.ChatUser(name: "Heyo", uid: "123412093841"),
            messageTimeBuilder: (_, [__]) => SizedBox.shrink(),
            messageTextBuilder: (text, [chatMessage]) => chatMessage
                        ?.user?.uid ==
                    "123412093841"
                ? Text(text, style: TextStyle(color: Colors.white))
                : Text(text, style: TextStyle(color: const Color(0xFF2C2929))),
            avatarBuilder: (_) => SizedBox.shrink(),
            inputContainerStyle: BoxDecoration(
                border: Border.all(color: const Color(0xFFB4B5B6)),
                borderRadius: BorderRadius.all(radius)),
            inputToolbarMargin: EdgeInsets.all(20.0),
            inputToolbarPadding: EdgeInsets.only(left: 8.0),
            inputDecoration:
                InputDecoration.collapsed(hintText: 'Type your message...'),
            sendButtonBuilder: (onSend) => Container(
                  padding: EdgeInsets.only(right: 8),
                  child: RaisedButton(
                    onPressed: onSend,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80.0)),
                    padding: EdgeInsets.all(0.0),
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: colorStandardGradient),
                        borderRadius: BorderRadius.all(Radius.circular(80.0)),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(
                            minWidth: 88.0, minHeight: 36.0),
                        alignment: Alignment.center,
                        child:
                            const Icon(Icons.arrow_upward, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            messages: <dashChat.ChatMessage>[
              dashChat.ChatMessage(
                  text: "Hello",
                  user: dashChat.ChatUser(name: "Fayeed", uid: "123456789"),
                  createdAt: DateTime.now()),
              dashChat.ChatMessage(
                  text: "Heyo!!!!!!!!!!!!!!!!!!!!!!",
                  user:
                      dashChat.ChatUser(name: "Jeffreee", uid: "123412093841"),
                  createdAt: DateTime.now())
            ]));
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  ProfilePageInfo _initialInfo;
  Object _initialInfoError;
  bool _isRestaurant;
  bool _needsCurrentPassword = false;

  // these aren't used by build
  String _emailContent;
  String _passwordContent;

  Future<void> _updateInitialInfo() async {
    try {
      final authModel = provideAuthenticationModel(context);
      final x = ProfilePageInfo();
      final List<Future<void> Function()> operations = [];
      if (authModel.userType == UserType.DONATOR) {
        operations.add(() async {
          final y = await Api.getDonator(authModel.donatorId);
          x.name = y.name;
          x.isRestaurant = y.isRestaurant;
          x.restaurantName = y.restaurantName;
          x.foodDescription = y.foodDescription;
        });
        operations.add(() async {
          final y = await Api.getPrivateDonator(authModel.donatorId);
          x.phone = y.phone;
          x.newsletter = y.newsletter;
        });
      }
      if (authModel.userType == UserType.REQUESTER) {
        operations.add(() async {
          final y = await Api.getRequester(authModel.requesterId);
          x.name = y.name;
        });
        operations.add(() async {
          final y = await Api.getPrivateRequester(authModel.donatorId);
          x.phone = y.phone;
          x.newsletter = y.newsletter;
        });
      }
      x.email = authModel.email;
      print(authModel.email);

      setState(() {
        _initialInfo = null;
        _initialInfoError = null;
      });
      await Future.wait(operations.map((f) => f()));
      setState(() {
        _initialInfo = x;
        _initialInfoError = null;
        _isRestaurant = _initialInfo.isRestaurant;
      });
    } catch (e) {
      _initialInfo = null;
      _initialInfoError = e;
    }
  }

  void _updateNeedsCurrentPassword() {
    if (_initialInfo == null) {
      bool newValue = false;
      if (newValue != _needsCurrentPassword) {
        setState(() {
          _needsCurrentPassword = newValue;
        });
      }
    } else {
      bool newValue = (_emailContent != _initialInfo.email ||
          (_passwordContent != '' && _passwordContent != null));
      if (newValue != _needsCurrentPassword) {
        setState(() {
          _needsCurrentPassword = newValue;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _updateInitialInfo();
    _updateNeedsCurrentPassword();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_initialInfo == null) {
      if (_initialInfoError == null) {
        body = buildMyStandardLoader();
      } else {
        body = buildMyStandardError(_initialInfoError);
      }
    } else {
      body = Builder(
        builder: (context) => buildMyFormListView(
            _formKey,
            [
              buildMyNavigationButton(context, 'Chat test', '/chatTest'),
              buildMyStandardButton('Log out', () {
                Navigator.of(context).pop();
                provideAuthenticationModel(context).signOut();
              }),
              buildMyStandardTextFormField('name', 'Name'),
              if (_initialInfo.userType == UserType.DONATOR)
                FormBuilderSwitch(
                  attribute: 'isRestaurant',
                  label: Text('Are you a restaurant?'),
                  onChanged: (newValue) {
                    setState(() {
                      _isRestaurant = newValue;
                    });
                  },
                ),
              if (_isRestaurant == true)
                buildMyStandardTextFormField(
                    'restaurantName', 'Restaurant name'),
              if (_isRestaurant == true)
                buildMyStandardTextFormField(
                    'foodDescription', 'Food description'),
              buildMyStandardTextFormField('phone', 'Phone'),
              buildMyStandardNewsletterSignup(),
              buildMyStandardEmailFormField('email', 'Email',
                  onChanged: (value) {
                print(value);
                _emailContent = value;
                _updateNeedsCurrentPassword();
              }),
              ...buildMyStandardPasswordSubmitFields(
                  required: false,
                  onChanged: (value) {
                    _passwordContent = value;
                    _updateNeedsCurrentPassword();
                  }),
              if (_needsCurrentPassword)
                buildMyStandardTextFormField(
                    'currentPassword', 'Current password',
                    obscureText: true),
              buildMyStandardButton('Save', () {
                if (_formKey.currentState.saveAndValidate()) {
                  doSnackbarOperation(context, 'Saving...', 'Saved!',
                      (() async {
                    final List<Future<void>> operations = [];
                    final authModel = provideAuthenticationModel(context);
                    final value = ProfilePageInfo()
                      ..formRead(_formKey.currentState.value);
                    if (authModel.userType == UserType.DONATOR &&
                        (value.name != _initialInfo.name ||
                            value.isRestaurant != _initialInfo.isRestaurant ||
                            value.restaurantName !=
                                _initialInfo.restaurantName ||
                            value.foodDescription !=
                                _initialInfo.foodDescription)) {
                      operations.add(Api.editDonator(Donator()
                        ..id = authModel.donatorId
                        ..name = value.name
                        ..isRestaurant = value.isRestaurant
                        ..restaurantName = value.restaurantName
                        ..foodDescription = value.foodDescription));
                    }
                    if (authModel.userType == UserType.REQUESTER &&
                        value.name != _initialInfo.name) {
                      operations.add(Api.editRequester(Requester()
                        ..id = authModel.requesterId
                        ..name = value.name));
                    }
                    if (authModel.userType == UserType.DONATOR &&
                        (value.phone != _initialInfo.phone ||
                            value.newsletter != _initialInfo.newsletter)) {
                      operations.add(Api.editPrivateDonator(PrivateDonator()
                        ..id = authModel.donatorId
                        ..phone = value.phone
                        ..newsletter = value.newsletter));
                    }
                    if (authModel.userType == UserType.REQUESTER &&
                        (value.phone != _initialInfo.phone ||
                            value.newsletter != _initialInfo.newsletter)) {
                      operations.add(Api.editPrivateRequester(PrivateRequester()
                        ..id = authModel.donatorId
                        ..phone = value.phone
                        ..newsletter = value.newsletter));
                    }
                    if (value.email != _initialInfo.email) {
                      operations
                          .add(authModel.userChangeEmail(UserChangeEmailData()
                            ..email = value.email
                            ..oldPassword = value.currentPassword));
                    }
                    if (value.newPassword != _initialInfo.newPassword) {
                      operations.add(
                          authModel.userChangePassword(UserChangePasswordData()
                            ..newPassword = value.newPassword
                            ..oldPassword = value.currentPassword));
                    }
                    await Future.wait(operations);
                    await _updateInitialInfo();
                  })(), MySnackbarOperationBehavior.POP_ZERO);
                }
              })
            ],
            initialValue: _initialInfo.formWrite()),
      );
    }
    return buildMyStandardScaffold(
        showProfileButton: false,
        title: 'Profile',
        context: context,
        body: body);
  }
}

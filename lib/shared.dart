import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart' show ChangeNotifierProvider, Consumer;
import 'package:flutter/cupertino.dart' show CupertinoScrollbar;
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_form_builder/flutter_form_builder.dart'
    show FormBuilderState, FormBuilderSwitch, FormBuilderCheckbox;

// import 'package:flutter_spinkit/flutter_spinkit.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:gradient_text/gradient_text.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:dots_indicator/dots_indicator.dart';
import 'state.dart';
import 'user-donator.dart';
import 'user-requester.dart';
import 'ui.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:dash_chat/dash_chat.dart' as dashChat;

// ignore: import_of_legacy_library_into_null_safe
import 'package:camera/camera.dart';
// import 'package:path/path.dart' show join;
// import 'package:path_provider/path_provider.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:permission_handler/permission_handler.dart';

void formSubmitLogic(GlobalKey<FormBuilderState> formKey,
    void Function(Map<String, dynamic>) callback) {
  print(formKey.currentState);
  if (formKey.currentState?.saveAndValidate() == true) {
    final value = formKey.currentState?.value;
    if (value != null) callback(value);
  }
}

class TileTrailingAction<T> {
  const TileTrailingAction(this.text, this.onSelected);

  final String text;
  final void Function(List<T>, int) onSelected;
}

dynamic contextToArg(BuildContext context) {
  return ModalRoute.of(context)?.settings.arguments;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebaseInitializeApp();
  Api.initMessaging();

  runApp(ChangeNotifierProvider(
    create: (context) => AuthenticationModel(),
    child: Builder(
      builder: (context) => MaterialApp(
          title: 'Meal Match',
          initialRoute: '/',
          routes: {
            '/': (context) => MyHomePage(),
            '/reportUser': (context) => ReportUserPage(contextToArg(context)),
            '/profile': (context) => GuestOrUserProfilePage(),
            '/profile/picture': (context) =>
                ProfilePicturePage(contextToArg(context)),
            '/signUpAsDonator': (context) => MyDonatorSignUpPage(),
            '/signUpAsRequester': (context) => MyRequesterSignUpPage(),
            // used by donator
            '/donator/donations/interests/view': (context) =>
                DonatorDonationsInterestsViewPage(contextToArg(context)),
            '/donator/donations/new': (context) => DonatorDonationsNewPage(),
            '/donator/donations/view': (context) =>
                DonatorDonationsViewPage(contextToArg(context)),
            '/donator/publicRequests/view': (context) =>
                DonatorPublicRequestsViewPage(contextToArg(context)),
            '/donator/publicRequests/view/moreInfo': (context) =>
                DonatorPublicRequestsViewMoreInfoPage(contextToArg(context)),
            // used by requester
            '/requester/publicRequests/view': (context) =>
                RequesterPublicRequestsViewPage(contextToArg(context)),
            '/requester/publicRequests/new': (context) =>
                RequesterPublicRequestsNewPage(),
            '/requester/donations/view': (context) =>
                RequesterDonationsViewPage(contextToArg(context)),
            '/requester/newInterestPage': (context) =>
                InterestNewPage(contextToArg(context)),
            '/requester/interests/view': (context) =>
                RequesterInterestsViewPage(contextToArg(context)),
            '/requester/interests/edit': (context) =>
                RequesterInterestsEditPage(contextToArg(context))
          },
          theme: getThemeData(context)),
    ),
  ));
}

List<Widget> buildPublicUserInfo(BaseUser user) {
  return [ListTile(title: Text('Name: ${user.name}'))];
}

class GuestSigninForm extends StatefulWidget {
  GuestSigninForm({required this.isEmbeddedInHomePage});
  final bool isEmbeddedInHomePage;

  @override
  _GuestSigninFormState createState() => _GuestSigninFormState();
}

class _GuestSigninFormState extends State<GuestSigninForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  void _popIfNecessary(BuildContext context) {
    if (!widget.isEmbeddedInHomePage) {
      NavigationUtil.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authModel = provideAuthenticationModel(context);
    return buildMyFormListView(_formKey, [
      Container(
        padding: EdgeInsets.only(top: 20),
        child: Image.asset('assets/logo.png', height: 200),
      ),
      if (authModel.userType == null)
        buildMyStandardButton('Guest donor', () {
          authModel.guestChangeUserType(UserType.DONATOR);
          _popIfNecessary(context);
        }),
      if (authModel.userType == null)
        buildMyStandardButton('Guest requester', () {
          authModel.guestChangeUserType(UserType.REQUESTER);
          _popIfNecessary(context);
        }),
      if (authModel.userType == UserType.DONATOR)
        buildMyStandardButton('Switch to requester', () {
          authModel.guestChangeUserType(UserType.REQUESTER);
          _popIfNecessary(context);
        }),
      if (authModel.userType == UserType.REQUESTER)
        buildMyStandardButton('Switch to donor', () {
          authModel.guestChangeUserType(UserType.DONATOR);
          _popIfNecessary(context);
        }),
      buildMyStandardEmailFormField('email', 'Email', buildContext: context),
      buildMyStandardTextFormField('password', 'Password',
          obscureText: true, buildContext: context),
      buildMyStandardButton('Login', () {
        formSubmitLogic(_formKey, (formValue) {
          doSnackbarOperation(
              context, 'Logging in...', 'Successfully logged in!', (() async {
            final err = await provideAuthenticationModel(context)
                .attemptSigninReturningErrors(
                    formValue['email'], formValue['password']);
            if (err != null) {
              // Later, we might adopt a better error handling system.
              throw err;
            }
          })(),
              widget.isEmbeddedInHomePage
                  ? MySnackbarOperationBehavior.POP_ZERO
                  : MySnackbarOperationBehavior.POP_ONE);
        });
      }),
    ]);
  }
}

class MyDonatorSignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        title: 'Sign up as meal donor',
        showProfileButton: false,
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
        name: 'isRestaurant',
        title: Text('Are you a restaurant?'),
        onChanged: (newValue) {
          setState(() {
            isRestaurant = newValue;
          });
        },
      ),
      if (isRestaurant)
        buildMyStandardTextFormField('restaurantName', 'Name of restaurant',
            buildContext: context),
      if (isRestaurant)
        buildMyStandardTextFormField('foodDescription', 'Food description',
            buildContext: context),
      buildMyStandardTextFormField('name', 'Name', buildContext: context),
      buildMyStandardEmailFormField('email', 'Email', buildContext: context),
      buildMyStandardTextFormField('phone', 'Phone', buildContext: context),
      AddressField(),
      ...buildMyStandardPasswordSubmitFields(buildContext: context),
      buildMyStandardNewsletterSignup(),
      buildMyStandardTermsAndConditions(),
      buildMyStandardButton('Sign up as donor', () {
        formSubmitLogic(_formKey, (formValue) {
          doSnackbarOperation(
              context,
              'Signing up...',
              'Successfully signed up!',
              provideAuthenticationModel(context).signUpDonator(
                  Donator()
                    ..formRead(formValue)
                    ..numMeals = 0,
                  PrivateDonator()..formRead(formValue),
                  SignUpData()..formRead(formValue)),
              MySnackbarOperationBehavior.POP_ONE);
        });
      })
    ];
    return buildMyFormListView(_formKey, children, initialValue: {
      ...(Donator()..isRestaurant = isRestaurant).formWrite(),
      ...(PrivateDonator()..newsletter = true).formWrite()
    });
  }
}

class MyRequesterSignUpForm extends StatefulWidget {
  @override
  _MyRequesterSignUpFormState createState() => _MyRequesterSignUpFormState();
}

class _MyRequesterSignUpFormState extends State<MyRequesterSignUpForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardTextFormField('name', 'Name', buildContext: context),
      buildMyStandardEmailFormField('email', 'Email', buildContext: context),
      buildMyStandardTextFormField('phone', 'Phone', buildContext: context),
      AddressField(),
      ...buildMyStandardPasswordSubmitFields(buildContext: context),
      buildMyStandardTermsAndConditions(),
      buildMyStandardNewsletterSignup(),
      buildMyStandardButton('Sign up as requester', () {
        formSubmitLogic(_formKey, (formValue) {
          doSnackbarOperation(
              context,
              'Signing up...',
              'Successfully signed up!',
              provideAuthenticationModel(context).signUpRequester(
                  Requester()..formRead(formValue),
                  PrivateRequester()..formRead(formValue),
                  SignUpData()..formRead(formValue)),
              MySnackbarOperationBehavior.POP_ONE);
        });
      })
    ];
    return buildMyFormListView(_formKey, children,
        initialValue: (PrivateRequester()..newsletter = true).formWrite());
  }
}

class MyRequesterSignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        showProfileButton: false,
        title: 'Sign up as requester',
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

class IntroductionForFirstTimeEntry extends StatefulWidget {
  const IntroductionForFirstTimeEntry(this.scaffoldKey);

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  _IntroductionForFirstTimeEntryState createState() =>
      _IntroductionForFirstTimeEntryState();
}

class _IntroductionForFirstTimeEntryState
    extends State<IntroductionForFirstTimeEntry> {
  static const numItems = 6;

  int position = 0;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildFirstTimeEntryNavigation(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(20),
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: colorStandardGradient),
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
          child: Column(children: [
            Container(
              padding: EdgeInsets.only(top: 20),
              child: Image.asset('assets/logo.png', height: 200),
            ),
            buildMyStandardButton(
                'Continue as donor',
                () => provideAuthenticationModel(context)
                    .onFirstTimeEntryNavigateToGuest(UserType.DONATOR),
                textSize: 20),
            buildMyStandardButton(
                'Continue as requester',
                () => provideAuthenticationModel(context)
                    .onFirstTimeEntryNavigateToGuest(UserType.REQUESTER),
                textSize: 20)
          ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: widget.scaffoldKey,
        body: SafeArea(
          child: Builder(
            builder: (context) => CarouselSlider(
                items: [
                  IntroPanel(
                      'assets/logo.png',
                      'Welcome to Meal Match',
                      'MealMatch is a way for people to donate food to those in need.',
                      true),
                  IntroPanel('assets/logo.png', 'About Us',
                      'We offer an easy app for the exchange of food.'),
                  IntroPanel('assets/intro-1.png', 'Request or Donate',
                      'You can donate or request food using our app.'),
                  IntroPanel('assets/intro-2.png', 'Chat Functionality',
                      'You can chat with others to arrange a donation.'),
                  IntroPanel('assets/intro-3.png', 'Leaderboards',
                      'Donors can advance upwards in the leaderboard! :)'),
                  Container(
                      width: double.infinity,
                      child: Builder(builder: _buildFirstTimeEntryNavigation))
                ],
                options: CarouselOptions(
                    height: MediaQuery.of(context).size.height,
                    viewportFraction: 1,
                    onPageChanged: (index, reason) {
                      setState(() {
                        position = index;
                      });
                    },
                    initialPage: position)),
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
    return Consumer<AuthenticationModel>(builder: (context, authModel, child) {
      switch (authModel.state) {
        case AuthenticationModelState.FIRST_TIME_ENTRY:
          return IntroductionForFirstTimeEntry(_scaffoldKey);
        case AuthenticationModelState.LOADING_DB:
          return _buildLoader('Loading your profile');
        case AuthenticationModelState.LOADING_INIT:
          return _buildLoader('Initializing');
        case AuthenticationModelState.LOADING_SIGNOUT:
          return _buildLoader('Signing you out');
        case AuthenticationModelState.SIGNED_IN:
        case AuthenticationModelState.GUEST:
          return GuestOrUserPage(_scaffoldKey, authModel.userType);
        case AuthenticationModelState.ERROR_DB:
          return SafeArea(
              child: Center(
                  child: Column(children: [
            Text('Error loading your profile'),
            buildMyStandardButton('Try again', authModel.onErrorDbTryAgain),
            buildMyStandardButton('Go to guest', authModel.signOut)
          ])));
        case AuthenticationModelState.ERROR_SIGNOUT:
          return SafeArea(
              child: Center(
                  child: Column(children: [
            Text('Error signing out'),
            buildMyStandardButton('Try again', authModel.signOut),
          ])));
      }
    });
  }

  Widget _buildLoader(String message) {
    return Scaffold(
        key: _scaffoldKey,
        body: SafeArea(child: buildMyStandardLoader(message: message)));
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

class GuestOrUserPage extends StatefulWidget {
  // Remember that even if the user is a guest, they still have a user type!
  const GuestOrUserPage(this.scaffoldKey, this.userType);

  final GlobalKey<ScaffoldState> scaffoldKey;
  final UserType? userType;

  @override
  _GuestOrUserPageState createState() => _GuestOrUserPageState();
}

enum _GuestOrUserPageStateCase {
  NULL_GUEST,
  DONATOR_GUEST,
  DONATOR,
  REQUESTER_GUEST,
  REQUESTER
}

class _GuestOrUserPageState extends State<GuestOrUserPage>
    with TickerProviderStateMixin {
  TabController? _tabControllerForPending;
  int _selectedIndex = 0;
  _GuestOrUserPageStateCase? _oldCase;
  int? leaderboardTotalNumServed;
  late Future<void> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _tabControllerForPending = TabController(vsync: this, length: 2);
  }

  Future<void> _makeLeaderboardFuture() {
    return (() async {
      final result = await Api.getLeaderboard();
      setState(() {
        leaderboardTotalNumServed = result
            .fold<double>(
                0.0, ((double previousValue, x) => previousValue + x.numMeals!))
            .round();
      });
      return result;
    })();
  }

  _utilDoAdjustSelected(_GuestOrUserPageStateCase newCase, int selectedIndex) {
    if (_oldCase != newCase) {
      _selectedIndex = selectedIndex;
      _oldCase = newCase;
    }
  }

  List<_GuestOrUserPageInfo> _getPageInfoAndAdjustSelected(
      AuthenticationModel authModel) {
    final isDonator = widget.userType == UserType.DONATOR;
    final isRequester = widget.userType == UserType.REQUESTER;
    final isGuest = authModel.state == AuthenticationModelState.GUEST;
    final isNullGuest = isGuest && widget.userType == null;

    final buildLeaderboard = () => _GuestOrUserPageInfo(
        appBarBottom: () => leaderboardTotalNumServed == null
            ? null
            : PreferredSize(
                preferredSize: Size.fromHeight(100),
                child: Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                        'Total: $leaderboardTotalNumServed meals served',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20))),
              ),
        title: 'Leaderboard',
        bottomNavigationBarIconData: Icons.cloud,
        body: () => buildMyStandardFutureBuilder<List<LeaderboardEntry>>(
            api: _leaderboardFuture as Future<List<LeaderboardEntry>>,
            child: (context, snapshotData) => Column(children: [
                  Expanded(
                      child: CupertinoScrollbar(
                          child: ListView.builder(
                              itemCount: snapshotData.length,
                              itemBuilder: (BuildContext context, int index) =>
                                  Container(
                                      padding: EdgeInsets.only(
                                          top: 10,
                                          bottom: 5,
                                          right: 15,
                                          left: 15),
                                      child: buildLeaderboardEntry(
                                          index, snapshotData))))),
                  if (isDonator &&
                      authModel.state != AuthenticationModelState.GUEST)
                    // https://stackoverflow.com/questions/52227846/how-can-i-add-shadow-to-the-widget-in-flutter
                    // copy-and-paste lol
                    // I'm not going to bother with tweaking the shadow
                    Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset:
                                  Offset(0, -5), // changes position of shadow
                            ),
                          ],
                        ),
                        child: buildLeaderboardEntry(
                            snapshotData
                                .indexWhere((x) => x.id == authModel.uid),
                            snapshotData,
                            true)),
                ])));

    if (isNullGuest) {
      _utilDoAdjustSelected(_GuestOrUserPageStateCase.NULL_GUEST, 0);
      return [
        _GuestOrUserPageInfo(
            appBarBottom: () => null,
            title: 'Sign in',
            noButton: true,
            bottomNavigationBarIconData: Icons.people,
            body: () => GuestSigninForm(isEmbeddedInHomePage: true)),
        buildLeaderboard()
      ];
    } else if (isDonator) {
      print('call');
      if (isGuest) {
        _utilDoAdjustSelected(_GuestOrUserPageStateCase.DONATOR_GUEST, 1);
      } else {
        _utilDoAdjustSelected(_GuestOrUserPageStateCase.DONATOR, 1);
      }
      return [
        if (isGuest)
          _GuestOrUserPageInfo(
              appBarBottom: () => null,
              title: 'Sign in',
              bottomNavigationBarIconData: Icons.people,
              body: () => GuestSigninForm(isEmbeddedInHomePage: true)),
        if (!isGuest)
          (() {
            final tabs = [
              Tab(text: 'Donations'),
              Tab(text: 'Requests'),
            ];
            final tabBar = TabBar(
                controller: _tabControllerForPending!,
                labelColor: Colors.black,
                tabs: tabs);
            return _GuestOrUserPageInfo(
                appBarBottom: () => tabBar,
                title: 'Pending',
                bottomNavigationBarIconData: Icons.people,
                body: () => DonatorPendingDonationsAndRequestsView(
                    _tabControllerForPending));
          })(),
        _GuestOrUserPageInfo(
            appBarBottom: () => null,
            title: 'Home',
            bottomNavigationBarIconData: Icons.home,
            body: () => DonatorPublicRequestList()),
        buildLeaderboard()
      ];
    } else if (isRequester) {
      if (isGuest) {
        _utilDoAdjustSelected(_GuestOrUserPageStateCase.REQUESTER_GUEST, 1);
      } else {
        _utilDoAdjustSelected(_GuestOrUserPageStateCase.REQUESTER, 1);
      }
      return [
        if (isGuest)
          _GuestOrUserPageInfo(
              appBarBottom: () => null,
              title: 'Sign in',
              bottomNavigationBarIconData: Icons.people,
              body: () => GuestSigninForm(isEmbeddedInHomePage: true)),
        if (!isGuest)
          (() {
            final tabs = [
              Tab(text: 'Interests'),
              Tab(text: 'Requests'),
            ];
            final tabBar = TabBar(
                controller: _tabControllerForPending!,
                labelColor: Colors.black,
                tabs: tabs);
            return _GuestOrUserPageInfo(
              appBarBottom: () => tabBar,
              title: 'Pending',
              bottomNavigationBarIconData: Icons.people,
              body: () => RequesterPendingRequestsAndInterestsView(
                  _tabControllerForPending),
            );
          })(),
        _GuestOrUserPageInfo(
            appBarBottom: () => null,
            title: 'Home',
            bottomNavigationBarIconData: Icons.home,
            body: () => RequesterDonationList()),
        buildLeaderboard()
      ];
    }
    throw 'error in _getPageInfo';
  }

  Widget _buildBottomNavigationBar(List<_GuestOrUserPageInfo> pageInfo) {
    return Container(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.5),
                topRight: Radius.circular(15.5))),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15.5), topRight: Radius.circular(15.5)),
          child: BottomNavigationBar(
              items:
                  pageInfo.map((x) => x.getBottomNavigationBarItem()).toList(),
              iconSize: 40,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              currentIndex: _selectedIndex,
              backgroundColor: Colors.black,
              unselectedItemColor: Colors.grey,
              selectedItemColor: Colors.white,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (pageInfo[_selectedIndex].title == 'Leaderboard') {
                    _leaderboardFuture = _makeLeaderboardFuture();
                  }
                });
              }),
        ));
  }

  void _alertForNotifications(BuildContext context, void Function(bool) after) {
    // https://stackoverflow.com/questions/53844052/how-to-make-an-alertdialog-in-flutter
    // https://stackoverflow.com/questions/50649006/prevent-dialog-from-closing-on-outside-touch-in-flutter

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
            onWillPop: () => Future.value(false),
            child: AlertDialog(
              title: Text("Enable notifications?"),
              actions: [
                TextButton(
                  child: Text("Yes"),
                  onPressed: () {
                    after(true);
                    // This is required
                    // https://api.flutter.dev/flutter/material/AlertDialog-class.html
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                    child: Text("No"),
                    onPressed: () {
                      after(false);
                      Navigator.of(context).pop();
                    }),
              ],
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = provideAuthenticationModel(context);
    final pageInfo = _getPageInfoAndAdjustSelected(auth);

    // Ask the user if notifications should be enabled, if appropriate

    // Without this callback, you will get an error
    // https://stackoverflow.com/questions/47592301/setstate-or-markneedsbuild-called-during-build

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      print(auth.state);
      print(auth.privateRequester);
      if (auth.state == AuthenticationModelState.SIGNED_IN) {
        if (auth.userType == UserType.DONATOR) {
          if (auth.privateDonator!.wasAlertedAboutNotifications != true) {
            _alertForNotifications(context, (permission) {
              Api.editPrivateDonator(auth.privateDonator!
                ..notifications = permission
                ..wasAlertedAboutNotifications = true);
            });
          }
        } else {
          if (auth.privateRequester!.wasAlertedAboutNotifications != true) {
            _alertForNotifications(context, (permission) {
              Api.editPrivateRequester(auth.privateRequester!
                ..notifications = permission
                ..wasAlertedAboutNotifications = true);
            });
          }
        }
      }
    });

    return buildMyStandardScaffold(
        context: context,
        scaffoldKey: widget.scaffoldKey,
        appBarBottom: pageInfo[_selectedIndex].appBarBottom(),
        title: pageInfo[_selectedIndex].title,
        fontSize: pageInfo[_selectedIndex].calcTitleFontSize(),
        body: pageInfo[_selectedIndex].body(),
        noButton: pageInfo[_selectedIndex].noButton,
        bottomNavigationBar: _buildBottomNavigationBar(pageInfo));
/*
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        child: CurvedNavigationBar(
            items: [
              Icon(Icons.people, size: 30, color: Colors.white),
              Icon(Icons.home, size: 30, color: Colors.white),
              Icon(Icons.cloud, size: 30, color: Colors.white),
            ],
            animationCurve: Curves.fastLinearToSlowEaseIn,
            index: _selectedIndex - 1,
            backgroundColor: Color(0xE5E5E5),
            color: Colors.black,
            //Color(0xff30353B),
            height: 75,
            onTap: (index) {
              setState(() {
                _selectedIndex = index + 1;
              });
            }),
      ),
*/
  }
}

class _GuestOrUserPageInfo {
  const _GuestOrUserPageInfo({
    required this.appBarBottom,
    required this.title,
    required this.bottomNavigationBarIconData,
    required this.body,
    this.noButton = false,
  });

  final PreferredSizeWidget? Function() appBarBottom;
  final String title;
  final Widget Function() body;
  final bool noButton;

  double calcTitleFontSize() {
    switch (title) {
      case 'Leaderboard':
        return 25;
      default:
        return 30;
    }
  }

  final IconData bottomNavigationBarIconData;

  BottomNavigationBarItem getBottomNavigationBarItem() {
    return BottomNavigationBarItem(
        icon: Icon(bottomNavigationBarIconData), label: title);
  }
}

class StatusInterface extends StatefulWidget {
  StatusInterface(
      {required this.initialStatus,
      required this.onStatusChanged,
      this.unacceptDonator}) {
    if (initialStatus == null) {
      print(
          'Warning: The initial status of status interface is null. This should not happen; please figure out the root cause.');
    }
  }
  final Future<void> Function(Status) onStatusChanged;

  // We will gracefully handle the case initialStatus == null, even though it shouldn't exist.
  final Status? initialStatus;

  final void Function()? unacceptDonator;

  @override
  _StatusInterfaceState createState() => _StatusInterfaceState();
}

class _StatusInterfaceState extends State<StatusInterface> {
  late List<bool> isSelected;

  // This ensures that onStatusChanged isn't called when the previous onStatusChanged hasn't completed.
  // This fixes a bug.
  Future<void> _lastOperation = Future.value();

  @override
  void initState() {
    super.initState();
    isSelected = [false, false, false];
    switch (widget.initialStatus) {
      case Status.PENDING:
        isSelected[0] = true;
        break;
      case Status.CANCELLED:
        isSelected[1] = true;
        break;
      case Status.COMPLETED:
        isSelected[2] = true;
        break;
      case null:
        break;
    }
  }

  void _notifyStatusChanged(Status newStatus) {
    _lastOperation = _lastOperation
        .then((_) => widget.onStatusChanged(newStatus))
        .catchError((e, _) => print(e));
  }

  @override
  Widget build(BuildContext context) {
    // https://api.flutter.dev/flutter/material/ToggleButtons-class.html
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 10),
          child: ToggleButtons(
            borderColor: Colors.black26,
            fillColor: colorDeepOrange,
            color: Colors.black,
            selectedColor: Colors.white,
            borderRadius: BorderRadius.circular(10),
            children: [
              for (final text in ['Pending', 'Cancelled', 'Completed'])
                Container(
                    padding: EdgeInsets.all(10),
                    child: Text(text, style: TextStyle(fontSize: 16)))
            ],
            onPressed: (int index) {
              setState(() {
                for (int buttonIndex = 0;
                    buttonIndex < isSelected.length;
                    buttonIndex++) {
                  if (buttonIndex == index) {
                    isSelected[buttonIndex] = true;
                  } else {
                    isSelected[buttonIndex] = false;
                  }
                }
                switch (index) {
                  case 0:
                    _notifyStatusChanged(Status.PENDING);
                    break;
                  case 1:
                    _notifyStatusChanged(Status.CANCELLED);
                    break;
                  case 2:
                    _notifyStatusChanged(Status.COMPLETED);
                    break;
                }
              });
            },
            isSelected: isSelected,
          ),
        ),
        if (widget.unacceptDonator != null)
          buildMyStandardButton('Unaccept donor', widget.unacceptDonator)
      ],
    );
  }
}

class ChatInterface extends StatefulWidget {
  ChatInterface(this.otherUser, messages, this.onNewMessage)
      : this.messagesSorted = List<ChatMessage>.from(messages) {
    messagesSorted.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
  }

  final BaseUser? otherUser;
  final List<ChatMessage> messagesSorted;
  final void Function(String) onNewMessage;

  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  String? _otherUserProfileUrl;

  @override
  void initState() {
    super.initState();
    (() async {
      if (widget.otherUser!.profilePictureStorageRef != null &&
          widget.otherUser!.profilePictureStorageRef != 'NULL') {
        final x = await Api.getUrlForProfilePicture(
            widget.otherUser!.profilePictureStorageRef!);
        setState(() {
          _otherUserProfileUrl = x;
        });
      }
    })();
  }

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(80.0);
    final uid = provideAuthenticationModel(context).uid;
    final scrollController = ScrollController();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent - 100);
    });
    final messages = widget.messagesSorted
        .map((x) => dashChat.ChatMessage(
            text: x.message!,
            user: dashChat.ChatUser(uid: x.speakerUid!),
            createdAt: x.timestamp!))
        .toList();
    if (_otherUserProfileUrl != null) {
      print('inserting');
      messages.insert(
          0,
          dashChat.ChatMessage(
              text: 'Profile picture',
              image: _otherUserProfileUrl!,
              user: dashChat.ChatUser(uid: widget.otherUser!.id!)));
    }
    return dashChat.DashChat(
        scrollController: scrollController,
        shouldStartMessagesFromTop: false,
        onLoadEarlier: () => null, // required
        messageContainerPadding: EdgeInsets.only(top: 10),
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
                  topRight: radius, bottomLeft: radius, bottomRight: radius),
            );
          }
        },
        onSend: (chatMessage) => widget.onNewMessage(chatMessage.text),
        user: dashChat.ChatUser(uid: provideAuthenticationModel(context).uid!),
        messageTimeBuilder: (_, [dynamic __]) => SizedBox.shrink(),
        messageTextBuilder: (text, [dynamic chatMessage]) =>
            chatMessage?.user?.uid == uid
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
              child: ButtonTheme(
                // https://stackoverflow.com/questions/50293503/how-to-set-the-width-of-a-raisedbutton-in-flutter
                minWidth: 0,
                child: ElevatedButton(
                  onPressed: onSend as void Function(),
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(80.0)),
                      padding: const EdgeInsets.all(0.0)),
                  child: Ink(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: colorStandardGradient),
                      borderRadius: BorderRadius.all(Radius.circular(80.0)),
                    ),
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 68.0, minHeight: 36.0),
                      alignment: Alignment.center,
                      child:
                          const Icon(Icons.arrow_upward, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        messages: messages);
  }
}

class ProfilePicturePage extends StatefulWidget {
  const ProfilePicturePage(this.profilePictureStorageRef);
  final String profilePictureStorageRef;

  @override
  _ProfilePicturePageState createState() => _ProfilePicturePageState();
}

enum ProfilePicturePageCameraState {
  UNUSED_UNACQUIRED, // Base state
  USED_UNACQUIRED,
  USED_ACQUIRING_LIST, // Loading the list of cameras
  // (I think this will trigger the permission check)
  USED_ACQUIRING_CONTROLLER, // Loading the controller object
  USED_ACQUIRING_INIT, // Initializing the controller
  USED_ERROR_LIST,
  USED_ERROR_CONTROLLER,
  USED_ERROR_INIT,
  USED_ERROR_PERMISSION,
  USED_ERROR_ZERO_CAMERAS,
  USED_ACQUIRED
}

extension ProfilePicturePageCameraStateExtension
    on ProfilePicturePageCameraState {
  bool get isAcquiring {
    switch (this) {
      case ProfilePicturePageCameraState.USED_ACQUIRING_LIST:
      case ProfilePicturePageCameraState.USED_ACQUIRING_CONTROLLER:
      case ProfilePicturePageCameraState.USED_ACQUIRING_INIT:
        return true;
      default:
        return false;
    }
  }
}

// https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html
class _ProfilePicturePageState extends State<ProfilePicturePage>
    with WidgetsBindingObserver {
  /*
  Modification is set to null as a default (do nothing).
   */
  String? _modification;
  int? _cameraId;
  CameraController? _cameraController;
  ProfilePicturePageCameraState _cameraState =
      ProfilePicturePageCameraState.UNUSED_UNACQUIRED;
  Object? _err;

  /*
  This ensures that the same camera controller is not disposed twice.
   */
  void _disposeCameraControllerIfNecessary() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _disposeCameraControllerIfNecessary();
    super.dispose();
  }

  void _setCameraState(ProfilePicturePageCameraState newState,
      [Object? error]) {
    print(newState);
    setState(() {
      _cameraState = newState;
      _err = error;
    });
  }

  void _useCamera() async {
    _setCameraState(ProfilePicturePageCameraState.USED_ACQUIRING_LIST);
    _disposeCameraControllerIfNecessary();
    if (!(await Permission.camera.status).isGranted) {
      await Permission.camera.request();
    }
    if (_cameraId == null) {
      _cameraId = 0;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.length <= _cameraId!) {
        _cameraId = 0;
      }
      try {
        if (cameras.length == 0) {
          _setCameraState(
              ProfilePicturePageCameraState.USED_ERROR_ZERO_CAMERAS);
        } else {
          _cameraController = CameraController(
              cameras[_cameraId!], ResolutionPreset.medium,
              enableAudio: false // avoid requesting the audio permission
              );
        }
        try {
          await _cameraController!.initialize();
          _setCameraState(ProfilePicturePageCameraState.USED_ACQUIRED);
        } on CameraException catch (e) {
          // TODO: Test this
          if (e.code == 'permissionDenied') {
            _setCameraState(
                ProfilePicturePageCameraState.USED_ERROR_PERMISSION, e);
            _disposeCameraControllerIfNecessary();
          } else {
            _setCameraState(ProfilePicturePageCameraState.USED_ERROR_INIT, e);
            _disposeCameraControllerIfNecessary();
          }
        } catch (e) {
          _setCameraState(ProfilePicturePageCameraState.USED_ERROR_INIT, e);
          _disposeCameraControllerIfNecessary();
        }
      } catch (e) {
        _setCameraState(ProfilePicturePageCameraState.USED_ERROR_CONTROLLER, e);
        _disposeCameraControllerIfNecessary();
      }
    } catch (e) {
      _setCameraState(ProfilePicturePageCameraState.USED_ERROR_LIST, e);
    }
  }

  void _unuseCamera() {
    _setCameraState(ProfilePicturePageCameraState.UNUSED_UNACQUIRED);
    _disposeCameraControllerIfNecessary();
  }

  // https://github.com/flutter/flutter/issues/21917
  // https://api.flutter.dev/flutter/dart-ui/AppLifecycleState-class.html
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Anytime the state isn't resumed, we dispose of the camera.
    print('changed state');
    if (state == AppLifecycleState.resumed) {
      if (_cameraState == ProfilePicturePageCameraState.USED_UNACQUIRED) {
        _useCamera();
      }
    } else if (_cameraState == ProfilePicturePageCameraState.USED_ACQUIRED) {
      _disposeCameraControllerIfNecessary();
      setState(() {
        _cameraState = ProfilePicturePageCameraState.USED_UNACQUIRED;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usingCamera =
        _cameraState != ProfilePicturePageCameraState.UNUSED_UNACQUIRED;

    print(widget.profilePictureStorageRef);
    return buildMyStandardScaffold(
        showProfileButton: false,
        title: 'Profile picture',
        context: context,
        body: Builder(
            builder: (contextScaffold) => Column(children: [
                  // If you are using the camera, obviously show the preview of the camera
                  if (usingCamera &&
                      _cameraState ==
                          ProfilePicturePageCameraState.USED_ACQUIRED)
                    Expanded(child: CameraPreview(_cameraController)),
                  if (usingCamera &&
                      _cameraState !=
                          ProfilePicturePageCameraState.USED_ACQUIRED &&
                      _cameraState.isAcquiring)
                    buildMyStandardLoader(),
                  if (usingCamera &&
                      _cameraState !=
                          ProfilePicturePageCameraState.USED_ACQUIRED &&
                      !_cameraState.isAcquiring)
                    buildMyStandardError('$_cameraState $_err', () {
                      _useCamera();
                    }),
                  if (!usingCamera)
                    ProfilePictureDisplay(
                        modification: _modification,
                        profilePictureStorageRef:
                            widget.profilePictureStorageRef),
                  // The user can delete their existing picture
                  if (!usingCamera && _modification == null)
                    buildMyStandardButton(
                      'Remove profile picture',
                      () {
                        setState(() {
                          _modification = "NULL";
                        });
                      },
                    ),
                  // The user can decide to not use their new camera picture
                  if (!usingCamera &&
                      _modification != null &&
                      _modification != "NULL")
                    buildMyStandardButton('Cancel', () {
                      setState(() {
                        _modification = null;
                      });
                    }),

                  if (!usingCamera)
                    buildMyStandardButton('Take picture', () async {
                      _useCamera();
                    }),
                  if (usingCamera)
                    buildMyStandardButton('Capture', () async {
                      /*final path = join(
                        (await getTemporaryDirectory()).path,
                        '${DateTime.now()}.png',
                      );*/
                      final path = await _cameraController!.takePicture();
                      setState(() {
                        _modification = path.path;
                      });
                      _unuseCamera();
                    }),
                  if (usingCamera)
                    buildMyStandardButton('Switch camera', () {
                      // Attempt to increment the camera id
                      _cameraId = _cameraId! + 1;
                      _useCamera();
                    }),
                  if (usingCamera)
                    buildMyStandardButton('Cancel', () async {
                      _unuseCamera();
                    }),
                  if (!usingCamera)
                    buildMyStandardButton('Save Profile Picture', () {
                      _unuseCamera();
                      NavigationUtil.pop(context,
                          MyNavigationResult()..returnValue = _modification);
                    })
                ])));
  }
}

class GuestOrUserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = provideAuthenticationModel(context);
    if (auth.state == AuthenticationModelState.GUEST) {
      return buildMyStandardScaffold(
          context: context,
          title: 'Sign in',
          body: GuestSigninForm(isEmbeddedInHomePage: false),
          showProfileButton: false);
    } else {
      return UserProfilePage();
    }
  }
}

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}
/*
// stateful because of the session token
class MyAddressSearcher extends StatefulWidget {
  // Session token should be used because that is how the Google Places API works.
  final String sessionToken;
  final void Function(Prediction) usePredictionToEditAddress;

  MyAddressSearcher(this.usePredictionToEditAddress): sessionToken = uuid.v4(), super();

  @override
  _MyAddressSearcherState createState() => _MyAddressSearcherState();
}

class _MyAddressSearcherState extends State<MyAddressSearcher> {
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: AppBarPlacesAutoCompleteTextField());
    final body = PlacesAutocompleteResult(
      onTap: (p) {
        widget.(p, searchScaffoldKey.currentState);
      },
      logo: Row(
        children: [FlutterLogo()],
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
    return Scaffold(appBar: appBar, body: body);
  }

  @override
  void onResponseError(PlacesAutocompleteResponse response) {
    super.onResponseError(response);
    searchScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  @override
  void onResponse(PlacesAutocompleteResponse response) {
    super.onResponse(response);
    if (response != null && response.predictions.isNotEmpty) {
      searchScaffoldKey.currentState.showSnackBar(
        SnackBar(content: Text("Got answer")),
      );
    }
  }
}
*/

/*class MyAddressSearcher extends StatefulWidget {
  const MyAddressSearcher(this.editAddress);
  final void Function(AddressInfo) editAddress;

  @override
  _MyAddressSearcherState createState() => _MyAddressSearcherState();
}

class _MyAddressSearcherState extends State<MyAddressSearcher> {
  String _newAddressText = "";

  // null means loading
  List<Address> _addressList;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      width: 300,
      child: Column(children: [
        TextField(onChanged: (newAddressText) {
          setState(() {
            _newAddressText = newAddressText;
            print(newAddressText);
            _addressList = null;
          });
        }),
        if (_newAddressText != '')
          Expanded(
              child: (_addressList == null)
                  ? buildMyStandardLoader()
                  : CupertinoScrollbar(
                      child: ListView.builder(
                          itemCount: _addressList.length,
                          itemBuilder: (BuildContext context, int index) =>
                              ListTile(
                                  title: Text(_addressList[index].addressLine),
                                  onTap: () => widget.editAddress(AddressInfo()
                                    ..address = _addressList[index].addressLine
                                    ..latCoord =
                                        _addressList[index].coordinates.latitude
                                    ..lngCoord = _addressList[index]
                                        .coordinates
                                        .longitude)))))
      ]),
    );
  }
}*/

class _UserProfilePageState extends State<UserProfilePage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ProfilePageInfo? _initialInfo;
  Object? _initialInfoError;
  bool? _isRestaurant;
  bool _needsCurrentPassword = false;

  // these aren't used by build
  String? _emailContent;
  String? _passwordContent;

  Future<void> _updateInitialInfo() async {
    try {
      final authModel = provideAuthenticationModel(context);
      final x = ProfilePageInfo();
      final List<Future<void> Function()> operations = [];
      if (authModel.userType == UserType.DONATOR) {
        final donator = authModel.donator!;
        x.name = donator.name;
        x.addressLatCoord = donator.addressLatCoord;
        x.addressLngCoord = donator.addressLngCoord;
        x.numMeals = donator.numMeals;
        x.isRestaurant = donator.isRestaurant;
        x.restaurantName = donator.restaurantName;
        x.foodDescription = donator.foodDescription;
        x.profilePictureStorageRef = donator.profilePictureStorageRef;
        operations.add(() async {
          final y = await Api.getPrivateDonator(authModel.uid!);
          x.address = y.address;
          x.phone = y.phone;
          x.newsletter = y.newsletter;
          x.notifications = y.notifications;
        });
      }
      if (authModel.userType == UserType.REQUESTER) {
        final requester = authModel.requester!;
        x.name = requester.name;
        x.addressLatCoord = requester.addressLatCoord;
        x.addressLngCoord = requester.addressLngCoord;
        x.profilePictureStorageRef = requester.profilePictureStorageRef;
        operations.add(() async {
          final y = await Api.getPrivateRequester(authModel.uid!);
          x.address = y.address;
          x.phone = y.phone;
          x.newsletter = y.newsletter;
          x.notifications = y.notifications;
        });
      }
      _emailContent = x.email = authModel.email;

      setState(() {
        _initialInfo = null;
        _initialInfoError = null;
      });
      await Future.wait(operations.map((f) => f()).toList());
      setState(() {
        _initialInfo = x;
        _initialInfoError = null;
        _isRestaurant = _initialInfo!.isRestaurant;
      });
    } catch (e) {
      setState(() {
        _initialInfo = null;
        _initialInfoError = e;
      });
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
      bool newValue = (_emailContent != _initialInfo!.email ||
          (_passwordContent != '' && _passwordContent != null));
      if (newValue != _needsCurrentPassword) {
        print(_emailContent);
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
    final authModel = provideAuthenticationModel(context);
    final contextForm = _scaffoldKey.currentContext;
    return buildMyStandardScaffold(
        scaffoldKey: _scaffoldKey,
        showProfileButton: false,
        title: 'Profile',
        context: context,
        fontSize: 35,
        body: Builder(builder: (contextScaffold) {
          final authModel = provideAuthenticationModel(contextScaffold);
          if (_initialInfo == null) {
            if (_initialInfoError == null) {
              return buildMyStandardLoader();
            } else {
              return buildMyStandardError(_initialInfoError);
            }
          } else {
            return Column(
              children: [
                Expanded(
                  child: buildMyFormListView(
                      _formKey,
                      [
                        Text('Profile picture',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 30)),
                        ProfilePictureField(
                            _initialInfo!.profilePictureStorageRef!),
                        /*Card(
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: 36.0, left: 6.0, right: 6.0, bottom: 6.0),
                            child: ExpansionTile(
                              title: Text('Birth of Universe'),
                              children: <Widget>[
                                Text('Big Bang'),
                                Text('Birth of the Sun'),
                                Text('Earth is Born'),
                              ],
                            ),
                          ),
                        ),*/
                        SizedBox(height: 30),
                        Text('Info',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 30)),
                        buildMyStandardTextFormField('name', 'Name',
                            buildContext: contextForm),
                        if (authModel.userType == UserType.DONATOR)
                          FormBuilderSwitch(
                            name: 'isRestaurant',
                            title: Text('Are you a restaurant?'),
                            onChanged: (newValue) {
                              setState(() {
                                _isRestaurant = newValue;
                              });
                            },
                          ),
                        // FormBuilder doesn't seem to like the widgets vanishing out of existence,
                        // so we use Visibility so that the widget is always there,
                        // even if it's hidden
                        Visibility(
                          child: buildMyStandardTextFormField(
                              'restaurantName', 'Restaurant name',
                              buildContext: contextForm),
                          visible: _isRestaurant == true,
                        ),
                        Visibility(
                            child: buildMyStandardTextFormField(
                                'foodDescription', 'Food description',
                                buildContext: contextForm),
                            visible: _isRestaurant == true),
                        buildMyStandardTextFormField('phone', 'Phone',
                            buildContext: contextForm),
                        AddressField(),
                        SizedBox(height: 30),
                        Text('Permissions',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 30)),
                        buildMyStandardNewsletterSignup(),
                        FormBuilderCheckbox(
                            name: 'notifications',
                            title: Text('I agree to receive notifications')),
                        SizedBox(height: 30),
                        Text('Email & Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 30)),
                        buildMyStandardEmailFormField('email', 'Email',
                            buildContext: context, onChanged: (value) {
                          print(value);
                          _emailContent = value;
                          _updateNeedsCurrentPassword();
                        }),
                        ...buildMyStandardPasswordSubmitFields(
                            buildContext: contextForm,
                            required: false,
                            passwordLabel: 'Change password',
                            onChanged: (value) {
                              _passwordContent = value;
                              _updateNeedsCurrentPassword();
                            }),
                        Visibility(
                            child: buildMyStandardTextFormField(
                                'currentPassword', 'Current password',
                                obscureText: true, buildContext: contextForm),
                            visible: _needsCurrentPassword)
                      ],
                      initialValue: _initialInfo!.formWrite()),
                ),
                Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      buildMyStandardButton('Log out', () {
                        // https://stackoverflow.com/questions/49672706/flutter-navigation-pop-to-index-1
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                        authModel.signOut();
                      }),
                      Spacer(),
                      buildMyStandardButton(
                          'Save', () => _save(contextScaffold))
                    ]))
              ],
            );
          }
        }));
  }

  void _save(BuildContext contextScaffold) {
    formSubmitLogic(_formKey, (formValue) {
      doSnackbarOperation(contextScaffold, 'Saving...', 'Saved!', (() async {
        final authModel = provideAuthenticationModel(contextScaffold);
        final value = ProfilePageInfo()..formRead(formValue);

        var newProfilePictureStorageRef =
            _initialInfo!.profilePictureStorageRef;

        // The first step MUST be uploading the profile image.
        if (value.profilePictureModification != null) {
          if (_initialInfo!.profilePictureStorageRef != "NULL") {
            print('removing profile picture');
            await Api.deleteProfilePicture(
                _initialInfo!.profilePictureStorageRef!);
            newProfilePictureStorageRef = "NULL";
          }
          if (value.profilePictureModification != "NULL") {
            print('uploading profile picture');
            newProfilePictureStorageRef = await Api.uploadProfilePicture(
                value.profilePictureModification!, authModel.uid);
          }
        }

        final List<Future<void>> operations = [];
        if (authModel.userType == UserType.DONATOR &&
            (value.name != _initialInfo!.name ||
                value.isRestaurant != _initialInfo!.isRestaurant ||
                value.restaurantName != _initialInfo!.restaurantName ||
                value.foodDescription != _initialInfo!.foodDescription ||
                value.addressLatCoord != _initialInfo!.addressLatCoord ||
                value.addressLngCoord != _initialInfo!.addressLngCoord ||
                newProfilePictureStorageRef !=
                    _initialInfo!.profilePictureStorageRef)) {
          print('editing donator');
          operations.add(authModel.editDonatorFromProfilePage(
              Donator()
                ..id = authModel.uid
                ..name = value.name
                ..numMeals = value.numMeals
                ..isRestaurant = value.isRestaurant
                ..restaurantName = value.restaurantName
                ..foodDescription = value.foodDescription
                ..addressLatCoord = value.addressLatCoord
                ..addressLngCoord = value.addressLngCoord
                ..profilePictureStorageRef = newProfilePictureStorageRef,
              _initialInfo!));
        }
        if (authModel.userType == UserType.REQUESTER &&
            (value.name != _initialInfo!.name ||
                value.addressLatCoord != _initialInfo!.addressLatCoord ||
                value.addressLngCoord != _initialInfo!.addressLngCoord ||
                newProfilePictureStorageRef !=
                    _initialInfo!.profilePictureStorageRef)) {
          print('editing requester');
          operations.add(authModel.editRequesterFromProfilePage(
              Requester()
                ..id = authModel.uid
                ..name = value.name
                ..addressLatCoord = value.addressLatCoord
                ..addressLngCoord = value.addressLngCoord
                ..profilePictureStorageRef = newProfilePictureStorageRef,
              _initialInfo!));
        }
        if (authModel.userType == UserType.DONATOR &&
            (value.address != _initialInfo!.address ||
                value.phone != _initialInfo!.phone ||
                value.newsletter != _initialInfo!.newsletter ||
                value.notifications != _initialInfo!.notifications)) {
          print('editing private donator');
          operations.add(Api.editPrivateDonator(PrivateDonator()
            ..id = authModel.uid
            ..address = value.address
            ..phone = value.phone
            ..newsletter = value.newsletter
            ..notifications = value.notifications));
        }
        if (authModel.userType == UserType.REQUESTER &&
            (value.address != _initialInfo!.address ||
                value.phone != _initialInfo!.phone ||
                value.newsletter != _initialInfo!.newsletter ||
                value.notifications != _initialInfo!.notifications)) {
          print('editing private requester');
          operations.add(Api.editPrivateRequester(PrivateRequester()
            ..id = authModel.uid
            ..address = value.address
            ..phone = value.phone
            ..newsletter = value.newsletter
            ..notifications = value.notifications));
        }
        if (value.email != _initialInfo!.email) {
          print('editing email');
          operations.add(authModel.userChangeEmail(UserChangeEmailData()
            ..email = value.email
            ..oldPassword = value.currentPassword));
        }
        if (value.newPassword != _initialInfo!.newPassword) {
          print('editing password');
          operations.add(authModel.userChangePassword(UserChangePasswordData()
            ..newPassword = value.newPassword
            ..oldPassword = value.currentPassword));
        }
        await Future.wait(operations);
        // Notifications
        if (value.notifications == true) {
          try {
            // Silently try to update the device token for the purpose of notifications
            authModel.silentlyUpdateDeviceTokenForNotifications();
          } catch (e) {
            print('Error updating device token');
            print(e.toString());
          }
        }
        await _updateInitialInfo();
      })(), MySnackbarOperationBehavior.POP_ZERO);
    });
  }
}

class ReportUserPage extends StatelessWidget {
  const ReportUserPage(this.otherUid);

  final String otherUid;

  @override
  Widget build(BuildContext context) {
    final authModel = provideAuthenticationModel(context);
    final uid = authModel.uid!;

    return buildMyStandardScaffold(
        title: 'Report user',
        context: context,
        body: ReportUserForm(uid: uid, otherUid: otherUid));
  }
}

class ReportUserForm extends StatefulWidget {
  const ReportUserForm({required this.uid, required this.otherUid});
  final String uid;
  final String otherUid;

  @override
  _ReportUserFormState createState() => _ReportUserFormState();
}

class _ReportUserFormState extends State<ReportUserForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScrollableGradientBoxWithBack(
        context,
        'Report user',
        buildMyFormListView(
          _formKey,
          [
            Text('Reports are private to the administrators.'),
            Text(
                'Feel free to add any other information about the user which could help us.'),
            buildMyStandardTextFormField('info', 'Info',
                buildContext: context, validator: []),
          ],
        ),
        buttonText: 'Report',
        buttonAction: () => formSubmitLogic(
            _formKey,
            (x) => doSnackbarOperation(
                context,
                'Reporting user...',
                'User reported!',
                Api.reportUser(
                    uid: widget.uid,
                    otherUid: widget.otherUid,
                    info: (UserReport()..formRead(x)).info!),
                MySnackbarOperationBehavior.POP_ONE)));
  }
}

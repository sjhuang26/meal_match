import 'dart:ffi';
import 'dart:io';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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
import 'keys.dart';
import 'user-requester.dart';
import 'package:flutter/cupertino.dart';
import 'package:dash_chat/dash_chat.dart' as dashChat;
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:uuid/uuid.dart';
import 'package:geodesy/geodesy.dart';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

const colorDeepOrange = const Color(0xFFF27A54);
const colorPurple = const Color(0xFFA154F2);
const colorStandardGradient = const [colorDeepOrange, colorPurple];
const milesPerMeter = 0.000621371;
const distanceThreshold = 50.0;
final googlePlacesApi = GoogleMapsPlaces(apiKey: googlePlacesKey);
final uuid = Uuid();
final geodesy = Geodesy();

num calculateDistanceBetween(num lat1, num lng1, num lat2, num lng2) {
  return (geodesy.distanceBetweenTwoGeoPoints(
              LatLng(lat1, lng1), LatLng(lat2, lng2)) *
          milesPerMeter)
      .round();
}

LatLng addRandomOffset(num lat, num lng) {
  return geodesy.destinationPointByDistanceAndBearing(LatLng(lat, lng),
      500.0 + Random().nextDouble() * 1000.0, Random().nextDouble() * 360.0);
}

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
  Scaffold.of(context).hideCurrentSnackBar();
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

class ProfilePictureField extends StatefulWidget {
  const ProfilePictureField(this.profilePictureStorageRef);
  final String profilePictureStorageRef;

  @override
  _ProfilePictureFieldState createState() => _ProfilePictureFieldState();
}

class _ProfilePictureFieldState extends State<ProfilePictureField> {
  @override
  Widget build(BuildContext context) {
    return FormBuilderCustomField(
        attribute: "profilePictureModification",
        formField: FormField(
            enabled: true,
            builder: (FormFieldState<String> field) =>
                buildMyStandardButton('Edit profile picture', () {
                  NavigationUtil.navigate(context, '/profile/picture',
                      widget.profilePictureStorageRef, (result) {
                    if (result.returnValue == null) return;
                    if (result.returnValue == "NULL")
                      field.didChange("NULL");
                    else
                      field.didChange(result.returnValue);
                  });
                })));
  }
}

class AddressField extends StatefulWidget {
  @override
  _AddressFieldState createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  @override
  Widget build(BuildContext context) {
    return FormBuilderCustomField(
        attribute: "addressInfo",
        validators: [FormBuilderValidators.required()],
        formField: FormField(
            enabled: true,
            builder: (FormFieldState<AddressInfo> field) => Row(children: [
                  Expanded(
                      child:
                          Text(field.value?.address ?? 'No address selected')),
                  buildMyStandardButton('Edit', () async {
                    /*showDialog(
                                context: contextScaffold,
                                builder: (context) => AlertDialog(
                                        title: Text('Search for address'),
                                        content: MyAddressSearcher((x) {
                                          field.didChange(x);
                                          Navigator.of(context).pop();
                                        }),
                                        actions: [
                                          FlatButton(
                                              child: Text('Cancel'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              }),
                                        ]));*/
                    final sessionToken = uuid.v4();
                    final prediction = await PlacesAutocomplete.show(
                        context: context,
                        sessionToken: sessionToken,
                        apiKey: googlePlacesKey,
                        mode: Mode.overlay,
                        language: "en",
                        components: [new Component(Component.country, "us")]);
                    if (prediction != null) {
                      final place = await googlePlacesApi.getDetailsByPlaceId(
                          prediction.placeId,
                          sessionToken: sessionToken,
                          language: "en");
                      // The rounding of the coordinates takes place here.
                      final roundedLatLng = addRandomOffset(
                          place.result.geometry.location.lat,
                          place.result.geometry.location.lng);

                      field.didChange(AddressInfo()
                        ..address = place.result.formattedAddress
                        ..latCoord = roundedLatLng.latitude
                        ..lngCoord = roundedLatLng.longitude);
                    }
                  }, textSize: 12)
                ])));
  }
}

Widget buildMyStandardFutureBuilderCombo<T>(
    {@required Future<T> api,
    @required List<Widget> Function(BuildContext, T) children}) {
  return buildMyStandardFutureBuilder(
      api: api,
      child: (context, data) => ListView(children: children(context, data)));
}

Widget buildMyStandardBackButton(BuildContext context, {double scaleSize = 1}) {
  return GestureDetector(
    onTap: () => Navigator.of(context).pop(),
    child: Container(
      // margin: EdgeInsets.only(right: 15*scaleSize, top: 10*scaleSize),
      width: 42 * (scaleSize),
      height: 42 * (scaleSize),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colorStandardGradient),
      ),
      child: Container(
        margin: EdgeInsets.all(3 * scaleSize),
        padding: EdgeInsets.only(),
        decoration: BoxDecoration(
          // border: Border.all(width: 0.75, color: Colors.white), //optional border, looks okay-ish
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: IconButton(
            iconSize: 20 * scaleSize,
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop()),
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
    dynamic bottomNavigationBar,
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
                if (!showProfileButton)
                  Container(
                      padding: EdgeInsets.only(top: 15, right: 15),
                      child: buildMyStandardBackButton(context)),
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

Widget buildMyStandardEmptyPlaceholderBox({@required String content}) {
  return Center(
    child: Text(
      content,
      style: TextStyle(
          fontSize: 20, fontStyle: FontStyle.italic, color: Colors.grey),
    ),
  );
}

Widget buildMyStandardBlackBox(
    {@required String title,
    @required String content,
    @required void Function() moreInfo}) {
  return GestureDetector(
    onTap: moreInfo,
    child: Container(
        margin: EdgeInsets.only(top: 8.0, bottom: 12.0),
        padding: EdgeInsets.only(left: 20, right: 5, top: 15, bottom: 15),
        decoration: BoxDecoration(
            color: Color(0xff30353B),
            borderRadius: BorderRadius.all(Radius.circular(15))),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: Colors.white),
                ),
                Container(padding: EdgeInsets.only(top: 3)),
                Text(content,
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.white)),
                Align(
                    alignment: Alignment.bottomRight,
                    child: Row(children: [
                      Spacer(), // TODO change to expanded?
                      Container(
                          child: buildMyStandardButton(
                        "More Info",
                        moreInfo,
                        textSize: 13,
                        fillWidth: false,
                      )),
                    ]))
              ],
            ),
          ],
        )),
  );
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

Widget buildMyStandardStreamBuilder<T>(
    {@required Stream<T> api,
    @required Widget Function(BuildContext, T) child}) {
  return StreamBuilder<T>(
      stream: api,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
  Object returnValue;
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

  static void navigate(BuildContext context,
      [String route,
      Object arguments,
      void Function(MyNavigationResult) onReturn]) {
    if (route == null) {
      NavigationUtil.pop(context, null);
    } else {
      NavigationUtil.pushNamed(context, route, arguments).then((result) {
        onReturn?.call(result);
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
    {String route,
    Object arguments,
    double textSize = 24,
    bool fillWidth = false,
    bool centralized = false}) {
  return buildMyStandardButton(text, () {
    NavigationUtil.navigate(context, route, arguments);
  }, textSize: textSize, fillWidth: fillWidth, centralized: centralized);
}

Widget buildMyNavigationButtonWithRefresh(
    BuildContext context, String text, String route, void Function() refresh,
    {Object arguments,
    double textSize = 24,
    bool fillWidth = false,
    bool centralized = false}) {
  return buildMyStandardButton(text, () async {
    NavigationUtil.navigateWithRefresh(context, route, refresh, arguments);
  }, textSize: textSize, fillWidth: fillWidth, centralized: centralized);
}

// https://stackoverflow.com/questions/52243364/flutter-how-to-make-a-raised-button-that-has-a-gradient-background
Widget buildMyStandardButton(String text, VoidCallback onPressed,
    {double textSize = 24, bool fillWidth = false, bool centralized = false}) {
  final textCapitalized = text.toUpperCase();
  if (centralized) {
    return Row(
      children: [
        Spacer(),
        Container(
          margin: EdgeInsets.only(top: 10, left: 15, right: 15),
          child: RaisedButton(
            onPressed: onPressed,
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
                    minWidth: 100.0,
                    minHeight: 40.0), // min sizes for Material buttons
                alignment: Alignment.center,
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 25),
                  fillWidth
                      ? Expanded(
                          child: Text(textCapitalized,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: textSize, color: Colors.white)),
                        )
                      : Container(
                          child: Text(textCapitalized,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: textSize, color: Colors.white)),
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
        ),
        Spacer(),
      ],
    );
  } else {
    return Container(
      margin: EdgeInsets.only(top: 10, left: 15, right: 15),
      child: RaisedButton(
        onPressed: onPressed,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(80.0)),
        padding: EdgeInsets.all(0.0),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: colorStandardGradient),
            borderRadius: BorderRadius.all(Radius.circular(80.0)),
          ),
          child: Container(
            constraints: const BoxConstraints(
                minWidth: 100.0,
                minHeight: 40.0), // min sizes for Material buttons
            alignment: Alignment.center,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 25),
              fillWidth
                  ? Expanded(
                      child: Text(textCapitalized,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: textSize, color: Colors.white)),
                    )
                  : Container(
                      child: Text(textCapitalized,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: textSize, color: Colors.white)),
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
}

Widget buildMyStandardScrollableGradientBoxWithBack(
    BuildContext context, String title, Widget child,
    {String buttonText, void Function() buttonAction}) {
  return Align(
    child: Container(
        margin: EdgeInsets.all(20),
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: colorStandardGradient),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            )),
        padding: EdgeInsets.all(3),
        child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                )),
            child: Column(
              children: [
                Center(
                  child: Container(
                    padding: EdgeInsets.only(
                        top: 10, left: 15, right: 15, bottom: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            child: Text(
                              title,
                              style: TextStyle(
                                  fontSize: 47.0 - (title.length * 1.12) > 15
                                      ? 47.0 - (title.length * 1.12)
                                      : 15,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        buildMyStandardBackButton(context, scaleSize: 1),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoScrollbar(
                      child: SingleChildScrollView(child: child)),
                ),
                if (buttonText != null)
                  buildMyStandardButton(buttonText, buttonAction,
                      textSize: 14, fillWidth: false, centralized: true),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                )
              ],
            ))),
    alignment: Alignment.center,
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
            '/profile/picture': (context) => ProfilePicturePage(
                ModalRoute.of(context).settings.arguments as BaseUser),
            '/signUpAsDonator': (context) => MyDonatorSignUpPage(),
            '/signUpAsRequester': (context) => MyRequesterSignUpPage(),
            // used by donator
            '/donator/donations/interests/view': (context) =>
                DonatorDonationsInterestsViewPage(ModalRoute.of(context)
                    .settings
                    .arguments as DonationInterestAndRequester),
            '/donator/donations/new': (context) => DonatorDonationsNewPage(),
            '/donator/donations/view': (context) => DonatorDonationsViewPage(
                ModalRoute.of(context).settings.arguments
                    as DonationAndInterests),
            '/donator/publicRequests/view': (context) =>
                DonatorPublicRequestsViewPage(
                    ModalRoute.of(context).settings.arguments as PublicRequest),
            // used by requester
            '/requester/publicRequests/view': (context) =>
                RequesterPublicRequestsViewPage(
                    ModalRoute.of(context).settings.arguments as PublicRequest),
            '/requester/publicRequests/new': (context) =>
                RequesterPublicRequestsNewPage(),
            '/requester/publicRequests/donations/viewOld': (context) =>
                RequesterPublicRequestsDonationsViewOldPage(
                    ModalRoute.of(context).settings.arguments
                        as PublicRequestAndDonationId),
            '/requester/donations/view': (context) =>
                RequesterDonationsViewPage(
                    ModalRoute.of(context).settings.arguments as Donation),
            '/requester/newInterestPage': (context) => InterestNewPage(
                ModalRoute.of(context).settings.arguments as Donation),
            '/requester/interests/view': (context) =>
                RequesterInterestsViewPage(
                    ModalRoute.of(context).settings.arguments as Interest)
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

List<Widget> buildPublicUserInfo(BaseUser user) {
  return [ListTile(title: Text('Name: ${user.name}'))];
}

class MyLoginForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyFormListView(_formKey, [
      Container(
        padding: EdgeInsets.only(top: 20),
        child: Image.asset('assets/logo.png', height: 200),
      ),
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
      // buildMyStandardButton('DEBUG: sharedpref', () async {
      //   final instance = await SharedPreferences.getInstance();
      //   instance.setBool('is_first_time', true);
      // }),
      buildMyNavigationButton(context, 'Sign up as donor',
          route: '/signUpAsDonator'),
      buildMyNavigationButton(context, 'Sign up as requester',
          route: '/signUpAsRequester'),
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
        attribute: 'isRestaurant',
        label: Text('Are you a restaurant?'),
        onChanged: (newValue) {
          setState(() {
            isRestaurant = newValue;
          });
        },
      ),
      if (isRestaurant)
        buildMyStandardTextFormField('restaurantName', 'Name of restaurant'),
      if (isRestaurant)
        buildMyStandardTextFormField('foodDescription', 'Food description'),
      buildMyStandardTextFormField('name', 'Name'),
      buildMyStandardEmailFormField('email', 'Email'),
      buildMyStandardTextFormField('phone', 'Phone'),
      AddressField(),
      ...buildMyStandardPasswordSubmitFields(),
      buildMyStandardNewsletterSignup(),
      buildMyStandardTermsAndConditions(),
      buildMyStandardButton('Sign up as donor', () {
        if (_formKey.currentState.saveAndValidate()) {
          final value = _formKey.currentState.value;
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
      buildMyStandardTextFormField('name', 'Name'),
      buildMyStandardEmailFormField('email', 'Email'),
      buildMyStandardTextFormField('phone', 'Phone'),
      AddressField(),
      ...buildMyStandardPasswordSubmitFields(),
      buildMyStandardTermsAndConditions(),
      buildMyStandardButton('Sign up as requester', () {
        if (_formKey.currentState.saveAndValidate()) {
          final value = _formKey.currentState.value;
          doSnackbarOperation(
              context,
              'Signing up...',
              'Successfully signed up!',
              provideAuthenticationModel(context).signUpRequester(
                  Requester()..formRead(value),
                  PrivateRequester()..formRead(value),
                  SignUpData()..formRead(value)),
              MySnackbarOperationBehavior.POP_ONE);
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

class MyIntroduction extends StatefulWidget {
  const MyIntroduction(this.scaffoldKey, this.isFirstTime);

  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool isFirstTime;

  @override
  _MyIntroductionState createState() => _MyIntroductionState();
}

class _MyIntroductionState extends State<MyIntroduction> {
  static const numItems = 6;

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
                      ))
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
              final forceLogOutButton = buildMyStandardButton('Log out', () {
                authModel.signOut();
              });
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
                      body: SafeArea(
                          child: Center(
                              child: Column(children: [
                        buildMyStandardLoader(),
                        forceLogOutButton
                      ]))));
                case AuthenticationModelState.LOADING_LOGIN_DB_FAILED:
                  return Scaffold(
                      key: _scaffoldKey,
                      body: SafeArea(
                          child: Center(
                              child: Column(children: [
                        buildMyStandardError(authModel.error),
                        forceLogOutButton
                      ]))));
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
  TabController _tabControllerForPending;
  int _selectedIndex = 2;
  int leaderboardTotalNumServed;
  Future<void> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _tabControllerForPending = TabController(vsync: this, length: 2);
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
      appBarBottom:
          (widget.userType == UserType.REQUESTER && _selectedIndex == 1)
              ? TabBar(
                  controller: _tabControllerForPending,
                  labelColor: Colors.black,
                  tabs: [
                      Tab(text: 'Interests'),
                      Tab(text: 'Requests'),
                    ])
              : (_selectedIndex == 3 && leaderboardTotalNumServed != null)
                  ? PreferredSize(
                      preferredSize: null,
                      child: Container(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                              'Total: $leaderboardTotalNumServed meals served',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 24))))
                  : (widget.userType == UserType.DONATOR && _selectedIndex == 1)
                      ? TabBar(
                          controller: _tabControllerForPending,
                          labelColor: Colors.black,
                          tabs: [
                              Tab(text: 'Donations'),
                              Tab(text: 'Requests'),
                            ])
                      : null,
      title: (widget.userType == UserType.DONATOR
          ? (_selectedIndex == 0
              ? 'Profile'
              : (_selectedIndex == 2
                  ? 'Home'
                  : (_selectedIndex == 1
                      ? 'Pending'
                      : (_selectedIndex == 3
                          ? 'Leaderboard'
                          : 'Meal Match (Donor)'))))
          : (_selectedIndex == 0
              ? 'Profile'
              : (_selectedIndex == 2
                  ? 'Home'
                  : (_selectedIndex == 1
                      ? 'Pending'
                      : (_selectedIndex == 3
                          ? 'Leaderboard'
                          : 'Meal Match (REQUESTER)'))))),
      fontSize: 30.0 +
          (_selectedIndex == 0
              ? 5
              : (_selectedIndex == 2
                  ? 5
                  : (_selectedIndex == 1
                      ? 5
                      : (_selectedIndex == 3 ? 0 : -2)))),
      body: Center(
        child: Builder(builder: (context) {
          List<Widget> subpages = [
            (null), // used to be the profile page
            if (widget.userType == UserType.DONATOR)
              DonatorPendingDonationsAndRequestsView(_tabControllerForPending),
            if (widget.userType == UserType.REQUESTER)
              RequesterPendingRequestsAndInterestsView(
                  _tabControllerForPending),
            if (widget.userType == UserType.DONATOR) DonatorPublicRequestList(),
            if (widget.userType == UserType.REQUESTER) RequesterDonationList(),
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
                                snapshotData
                                    .indexWhere((x) => x.id == authModel.uid),
                                snapshotData,
                                true)),
                    ]))
          ];
          return subpages[_selectedIndex];
        }),
      ),
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
      bottomNavigationBar: Container(
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
              items: [
                BottomNavigationBarItem(
                    icon: const Icon(Icons.people),
                    title: Text('Pending Requests')),
                BottomNavigationBarItem(
                    icon: const Icon(Icons.home), title: Text('Home')),
                BottomNavigationBarItem(
                    icon: const Icon(Icons.cloud), title: Text('Leaderboard'))
              ],
              iconSize: 40,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              currentIndex: _selectedIndex - 1,
              backgroundColor: Colors.black,
              unselectedItemColor: Colors.grey,
              selectedItemColor: Colors.white,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index + 1;
                  if (_selectedIndex == 3) {
                    _leaderboardFuture = _makeLeaderboardFuture();
                  }
                });
              }),
        ),
      ),
    );
  }
}

class StatusInterface extends StatefulWidget {
  const StatusInterface({this.initialStatus, this.onStatusChanged});
  final void Function(Status) onStatusChanged;
  final Status initialStatus;

  @override
  _StatusInterfaceState createState() => _StatusInterfaceState();
}

class _StatusInterfaceState extends State<StatusInterface> {
  List<bool> isSelected;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    // https://api.flutter.dev/flutter/material/ToggleButtons-class.html
    return Container(
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
                widget.onStatusChanged(Status.PENDING);
                break;
              case 1:
                widget.onStatusChanged(Status.CANCELLED);
                break;
              case 2:
                widget.onStatusChanged(Status.COMPLETED);
                break;
            }
          });
        },
        isSelected: isSelected,
      ),
    );
  }
}

class ChatInterface extends StatefulWidget {
  ChatInterface(messages, this.onNewMessage)
      : this.messagesSorted = List<ChatMessage>.from(messages) {
    messagesSorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  final List<ChatMessage> messagesSorted;
  final void Function(String) onNewMessage;

  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(80.0);
    final uid = provideAuthenticationModel(context).uid;
    final scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent - 100);
    });
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
        user: dashChat.ChatUser(uid: provideAuthenticationModel(context).uid),
        messageTimeBuilder: (_, [__]) => SizedBox.shrink(),
        messageTextBuilder: (text, [chatMessage]) =>
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
        messages: widget.messagesSorted
            .map((x) => dashChat.ChatMessage(
                text: x.message,
                user: dashChat.ChatUser(uid: x.speakerUid),
                createdAt: x.timestamp))
            .toList());
  }
}

class ProfilePicturePage extends StatefulWidget {
  const ProfilePicturePage(this.baseUser);
  final BaseUser baseUser;

  @override
  _ProfilePicturePageState createState() => _ProfilePicturePageState();
}

class _ProfilePicturePageState extends State<ProfilePicturePage> {
  String _modification;
  bool _usingCamera = false;
  CameraController _cameraController;
  Future<void> _cameraControllerInitFuture;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        showProfileButton: false,
        title: 'Profile picture',
        context: context,
        body: Builder(
            builder: (contextScaffold) => Column(children: [
                  Expanded(
                      child: _usingCamera
                          ? buildMyStandardFutureBuilder<void>(
                              api: _cameraControllerInitFuture,
                              child: (context, _) =>
                                  CameraPreview(_cameraController))
                          : _modification == null && widget.baseUser.profilePictureStorageRef == "NULL" ||
                                  _modification == "NULL"
                              ? buildMyStandardEmptyPlaceholderBox(
                                  content: 'No profile picture')
                              : _modification != null && _modification != "NULL"
                                  ? Image.file(File(_modification),
                                      errorBuilder: (context, error, stackTrace) =>
                                          buildMyStandardError(error))
                                  : buildMyStandardFutureBuilder<String>(
                                      api: Api.getUrlForProfilePicture(widget
                                          .baseUser.profilePictureStorageRef),
                                      child: (context, value) => Image.network(value,
                                          loadingBuilder: (context, _, __) => buildMyStandardLoader(),
                                          errorBuilder: (context, error, stackTrace) => buildMyStandardError(error),
                                          fit: BoxFit.fitWidth))),
                  if (!_usingCamera)
                    buildMyStandardButton('Remove picture', () {
                      setState(() {
                        _modification = null;
                      });
                    }),
                  if (!_usingCamera)
                    buildMyStandardButton('Take picture', () async {
                      setState(() {
                        _usingCamera = true;
                        _cameraControllerInitFuture = (() async {
                          final cameras = await availableCameras();
                          final firstCamera = cameras.first;
                          _cameraController?.dispose();
                          _cameraController = CameraController(
                              firstCamera, ResolutionPreset.medium,
                              enableAudio:
                                  false // avoid requesting the audio permission
                              );
                          await _cameraController.initialize();
                        })();
                      });
                    }),
                  if (_usingCamera)
                    buildMyStandardButton('Capture', () async {
                      final path = join(
                        (await getTemporaryDirectory()).path,
                        '${DateTime.now()}.png',
                      );
                      await _cameraController.takePicture(path);
                      setState(() {
                        _usingCamera = false;
                        _modification = path;
                      });
                    }),
                  if (_usingCamera)
                    buildMyStandardButton('Use other camera', () async {
                      setState(() {
                        _usingCamera = true;
                        _cameraControllerInitFuture = (() async {
                          final cameras = await availableCameras();
                          final secondCamera = cameras[1];
                          _cameraController?.dispose();
                          _cameraController = CameraController(
                              secondCamera, ResolutionPreset.medium,
                              enableAudio:
                                  false // avoid requesting the audio permission
                              );
                          await _cameraController.initialize();
                        })();
                      });
                    }),
                  if (_usingCamera)
                    buildMyStandardButton('Cancel', () async {
                      setState(() {
                        _usingCamera = false;
                        _cameraController?.dispose();
                      });
                    })
                ])));
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
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
        final donator = authModel.donator;
        x.name = donator.name;
        x.addressLatCoord = donator.addressLatCoord;
        x.addressLngCoord = donator.addressLngCoord;
        x.numMeals = donator.numMeals;
        x.isRestaurant = donator.isRestaurant;
        x.restaurantName = donator.restaurantName;
        x.foodDescription = donator.foodDescription;
        operations.add(() async {
          final y = await Api.getPrivateDonator(authModel.uid);
          x.address = y.address;
          x.phone = y.phone;
          x.newsletter = y.newsletter;
        });
      }
      if (authModel.userType == UserType.REQUESTER) {
        final requester = authModel.requester;
        x.name = requester.name;
        x.addressLatCoord = requester.addressLatCoord;
        x.addressLngCoord = requester.addressLngCoord;
        operations.add(() async {
          final y = await Api.getPrivateRequester(authModel.uid);
          x.address = y.address;
          x.phone = y.phone;
          x.newsletter = y.newsletter;
        });
      }
      x.email = authModel.email;

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
    return buildMyStandardScaffold(
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
            return buildMyFormListView(
                _formKey,
                [
                  buildMyStandardButton('Log out', () {
                    Navigator.of(contextScaffold).pop();
                    authModel.signOut();
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
                  AddressField(),
                  ProfilePictureField(_initialInfo.profilePictureStorageRef),
                  buildMyNavigationButton(
                    context,
                    'Edit profile picture',
                  ),
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
                      doSnackbarOperation(
                          contextScaffold, 'Saving...', 'Saved!', (() async {
                        final authModel =
                            provideAuthenticationModel(contextScaffold);
                        final value = ProfilePageInfo()
                          ..formRead(_formKey.currentState.value);

                        var newProfilePictureStorageRef =
                            _initialInfo.profilePictureStorageRef;

                        // The first step MUST be uploading the profile image.
                        if (value.profilePictureModification != null) {
                          if (_initialInfo.profilePictureStorageRef != "NULL") {
                            print('removing profile picture');
                            await Api.deleteProfilePicture(
                                _initialInfo.profilePictureStorageRef);
                            newProfilePictureStorageRef = "NULL";
                          }
                          if (value.profilePictureModification != "NULL") {
                            print('uploading profile picture');
                            newProfilePictureStorageRef =
                                await Api.uploadProfilePicture(
                                    value.profilePictureModification);
                          }
                        }

                        final List<Future<void>> operations = [];
                        if (authModel.userType == UserType.DONATOR &&
                            (value.name != _initialInfo.name ||
                                value.isRestaurant !=
                                    _initialInfo.isRestaurant ||
                                value.restaurantName !=
                                    _initialInfo.restaurantName ||
                                value.foodDescription !=
                                    _initialInfo.foodDescription ||
                                value.addressLatCoord !=
                                    _initialInfo.addressLatCoord ||
                                value.addressLngCoord !=
                                    _initialInfo.addressLngCoord ||
                                newProfilePictureStorageRef !=
                                    _initialInfo.profilePictureStorageRef)) {
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
                                ..profilePictureStorageRef =
                                    newProfilePictureStorageRef,
                              _initialInfo));
                        }
                        if (authModel.userType == UserType.REQUESTER &&
                            (value.name != _initialInfo.name ||
                                value.addressLatCoord !=
                                    _initialInfo.addressLatCoord ||
                                value.addressLngCoord !=
                                    _initialInfo.addressLngCoord ||
                                newProfilePictureStorageRef !=
                                    _initialInfo.profilePictureStorageRef)) {
                          print('editing requester');
                          operations.add(authModel.editRequesterFromProfilePage(
                              Requester()
                                ..id = authModel.uid
                                ..name = value.name
                                ..addressLatCoord = value.addressLatCoord
                                ..addressLngCoord = value.addressLngCoord
                                ..profilePictureStorageRef =
                                    newProfilePictureStorageRef,
                              _initialInfo));
                        }
                        if (authModel.userType == UserType.DONATOR &&
                            (value.address != _initialInfo.address ||
                                value.phone != _initialInfo.phone ||
                                value.newsletter != _initialInfo.newsletter)) {
                          print('editing private donator');
                          operations.add(Api.editPrivateDonator(PrivateDonator()
                            ..id = authModel.uid
                            ..address = value.address
                            ..phone = value.phone
                            ..newsletter = value.newsletter));
                        }
                        if (authModel.userType == UserType.REQUESTER &&
                            (value.address != _initialInfo.address ||
                                value.phone != _initialInfo.phone ||
                                value.newsletter != _initialInfo.newsletter)) {
                          print('editing private requester');
                          operations
                              .add(Api.editPrivateRequester(PrivateRequester()
                                ..id = authModel.uid
                                ..address = value.address
                                ..phone = value.phone
                                ..newsletter = value.newsletter));
                        }
                        if (value.email != _initialInfo.email) {
                          print('editing email');
                          operations.add(
                              authModel.userChangeEmail(UserChangeEmailData()
                                ..email = value.email
                                ..oldPassword = value.currentPassword));
                        }
                        if (value.newPassword != _initialInfo.newPassword) {
                          print('editing password');
                          operations.add(authModel
                              .userChangePassword(UserChangePasswordData()
                                ..newPassword = value.newPassword
                                ..oldPassword = value.currentPassword));
                        }
                        await Future.wait(operations);
                        await _updateInitialInfo();
                      })(), MySnackbarOperationBehavior.POP_ZERO);
                    }
                  })
                ],
                initialValue: _initialInfo.formWrite());
          }
        }));
  }
}

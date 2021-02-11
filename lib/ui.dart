import 'package:flutter/material.dart';
import 'state.dart';
import 'geography.dart';
import 'package:flutter/cupertino.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:google_fonts/google_fonts.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter/gestures.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:url_launcher/url_launcher.dart';

const colorDeepOrange = const Color(0xFFF27A54);
const colorPurple = const Color(0xFFA154F2);
const colorStandardGradient = const [colorDeepOrange, colorPurple];
ThemeData getThemeData(BuildContext context) {
  return ThemeData(
    textTheme: GoogleFonts.cabinTextTheme(Theme.of(context).textTheme),
    primaryColor: colorDeepOrange,
    accentColor: Colors.black87,
  );
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
    [MySnackbarOperationBehavior? behavior]) async {
  // This is a tricky deprecation and requires some work!
  // ignore: deprecated_member_use
  Scaffold.of(context).hideCurrentSnackBar();
  // ignore: deprecated_member_use
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
      // ignore: deprecated_member_use
      Scaffold.of(context).hideCurrentSnackBar();
      // ignore: deprecated_member_use
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(finalText)));
    }
  } catch (e) {
    // ignore: deprecated_member_use
    Scaffold.of(context).hideCurrentSnackBar();
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  }
  //Navigator.pop(context);
}

// This is a good example of a useful generic function.
Widget buildSplitHistory<T extends HasStatus>(
    List<T> hasStatus, Widget Function(T) buildTile) {
  final nonHistory =
      hasStatus.where((x) => x.status == Status.PENDING).toList();
  final history = hasStatus.where((x) => x.status != Status.PENDING).toList();

  return CupertinoScrollbar(
    child: ListView.builder(
        itemCount:
            nonHistory.length + history.length + (history.length == 0 ? 0 : 1),
        padding: EdgeInsets.only(top: 10, bottom: 20, right: 15, left: 15),
        itemBuilder: (BuildContext context, int index) {
          if (index == nonHistory.length) {
            return Container(
                padding: EdgeInsets.only(top: 60),
                child: Text('History',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30)));
          } else {
            final x = index < nonHistory.length
                ? nonHistory[index]
                : history[index - nonHistory.length - 1];
            return buildTile(x);
          }
        }),
  );
}

Widget buildMyStandardFutureBuilderCombo<T>(
    {required Future<T> api,
    required List<Widget> Function(BuildContext, T?) children}) {
  return buildMyStandardFutureBuilder(
      api: api,
      child: (context, dynamic data) =>
          ListView(children: children(context, data)));
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
        padding: EdgeInsets.only(left: 4),
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
    {String? title,
    double fontSize: 30,
    required BuildContext context,
    required Widget body,
    Key? scaffoldKey,
    bool showProfileButton = true,
    dynamic bottomNavigationBar,
    Widget? appBarBottom}) {
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
              bottom: appBarBottom as PreferredSizeWidget,
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
  return Center(
      child: Container(
          padding: EdgeInsets.only(top: 30),
          child: CircularProgressIndicator()));
}

Widget buildMyStandardError(Object? error) {
  return Center(child: Text('Error: $error', style: TextStyle(fontSize: 36)));
}

Widget buildMyStandardEmptyPlaceholderBox({required String content}) {
  return Center(
    child: Text(
      content,
      style: TextStyle(
          fontSize: 20, fontStyle: FontStyle.italic, color: Colors.grey),
    ),
  );
}

Widget buildMyStandardBlackBox(
    {required String title,
    required String content,
    required void Function() moreInfo,
    Status? status}) {
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
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                Align(
                    alignment: Alignment.bottomRight,
                    child: Row(children: [
                      if (status != null)
                        Expanded(
                            child: Text('Status: ${statusToString(status)}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18))),
                      if (status == null) Spacer(),
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
    {required Future<T> api, required Widget Function(BuildContext, T) child}) {
  return FutureBuilder<T>(
      future: api,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return buildMyStandardLoader();
        } else if (snapshot.hasError || data == null)
          return buildMyStandardError(snapshot.error);
        else
          return child(context, data);
      });
}

Widget buildMyStandardStreamBuilder<T>(
    {required Stream<T> api, required Widget Function(BuildContext, T) child}) {
  return StreamBuilder<T>(
      stream: api,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildMyStandardLoader();
        } else if (snapshot.hasError || data == null)
          return buildMyStandardError(snapshot.error);
        else
          return child(context, data);
      });
}

class MyRefreshable extends StatefulWidget {
  MyRefreshable({required this.builder});

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
      {required this.builder, required this.api, this.initialValue});

  final Widget Function(BuildContext, T, Future<void> Function()) builder;
  final Future<T> Function() api;
  final T? initialValue;

  @override
  _MyRefreshableIdState<T> createState() => _MyRefreshableIdState<T>();
}

class _MyRefreshableIdState<T> extends State<MyRefreshableId<T>> {
  late Future<T> value;

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
  String? message;
  Object? returnValue;
  bool? refresh;
  MyNavigationResult? pop;

  void apply(BuildContext context, [void Function()? doRefresh]) {
    print('TESTING');
    print(doRefresh);
    print(refresh);
    if (pop != null) {
      NavigationUtil.pop(context, pop!);
    } else {
      if (message != null) {
        // Again, this deprecation is tricky.
        // ignore: deprecated_member_use
        Scaffold.of(context).hideCurrentSnackBar();
        // ignore: deprecated_member_use
        Scaffold.of(context).showSnackBar(SnackBar(content: Text(message!)));
      }
      if (refresh == true) {
        print("Got into refresh");
        doRefresh!();
      }
    }
  }
}

class NavigationUtil {
  static Future<MyNavigationResult?> pushNamed<T>(
      BuildContext context, String routeName,
      [T? arguments]) async {
    return (await Navigator.pushNamed(context, routeName, arguments: arguments))
        as MyNavigationResult?;
  }

  static void pop(BuildContext context, MyNavigationResult? result) {
    Navigator.pop(context, result);
  }

  static void navigate(BuildContext context,
      [String? route,
      Object? arguments,
      void Function(MyNavigationResult)? onReturn]) {
    if (route == null) {
      NavigationUtil.pop(context, null);
    } else {
      NavigationUtil.pushNamed(context, route, arguments).then((result) {
        if (result != null) onReturn?.call(result);
        result?.apply(context, null);
      });
    }
  }

  static void navigateWithRefresh(
      BuildContext context, String route, void Function() refresh,
      [Object? arguments]) {
    NavigationUtil.pushNamed(context, route, arguments).then((result) {
      final modifiedResult = result ?? MyNavigationResult();
      modifiedResult.refresh = true;
      modifiedResult.apply(context, refresh);
    });
  }
}

/*
Widget buildMyStandardSliverCombo<T>(
    {required Future<List<T>> Function() api,
    required String titleText,
    required String Function(List<T>) secondaryTitleText,
    required Future<MyNavigationResult> Function(List<T>, int) onTap,
    required String Function(List<T>, int) tileTitle,
    required String Function(List<T>, int) tileSubtitle,
    required Future<MyNavigationResult> Function() floatingActionButton,
    required List<TileTrailingAction<T>> tileTrailing}) {
  return MyRefreshable(
    builder: (context, refresh) => Scaffold(
        floatingActionButton: floatingActionButton == null
            ? null!
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
              final data = snapshot.data;
              return CustomScrollView(slivers: [
                if (titleText != null)
                  SliverAppBar(
                      title: Text(titleText),
                      floating: true,
                      expandedHeight: secondaryTitleText == null
                          ? null!
                          : (snapshot.hasData ? 100 : null!),
                      flexibleSpace: secondaryTitleText == null
                          ? null!
                          : snapshot.hasData
                              ? FlexibleSpaceBar(
                                  title:
                                      Text(secondaryTitleText(data)),
                                )
                              : null!),
                if (snapshot.connectionState == ConnectionState.done &&
                    !snapshot.hasError)
                  SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= snapshot.data.length) return null!;
                    return ListTile(
                        onTap: onTap == null
                            ? null!
                            : () async {
                                final result =
                                    await onTap(snapshot.data, index);
                                result?.apply(context, refresh);
                              },
                        leading: Text('#${index + 1}',
                            style:
                                TextStyle(fontSize: 30, color: Colors.black54)),
                        title: tileTitle == null
                            ? null!
                            : Text(tileTitle(snapshot.data, index),
                                style: TextStyle(fontSize: 24)),
                        subtitle: tileSubtitle == null
                            ? null!
                            : Text(tileSubtitle(snapshot.data, index),
                                style: TextStyle(fontSize: 18)),
                        isThreeLine: tileSubtitle == null ? false : true,
                        trailing: tileTrailing == null
                            ? null!
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
*/

Widget buildMyNavigationButton(BuildContext context, String text,
    {String? route,
    Object? arguments,
    double textSize = 24,
    bool fillWidth = false,
    bool centralized = false}) {
  return buildMyStandardButton(text, () {
    NavigationUtil.navigate(context, route, arguments);
  }, textSize: textSize, fillWidth: fillWidth, centralized: centralized);
}

Widget buildMyNavigationButtonWithRefresh(
    BuildContext context, String text, String route, void Function() refresh,
    {Object? arguments,
    double textSize = 24,
    bool fillWidth = false,
    bool centralized = false}) {
  return buildMyStandardButton(text, () async {
    NavigationUtil.navigateWithRefresh(context, route, refresh, arguments);
  }, textSize: textSize, fillWidth: fillWidth, centralized: centralized);
}

// https://stackoverflow.com/questions/52243364/flutter-how-to-make-a-raised-button-that-has-a-gradient-background
Widget buildMyStandardButton(String text, VoidCallback? onPressed,
    {double textSize = 24, bool fillWidth = false, bool centralized = false}) {
  final textCapitalized = text.toUpperCase();
  if (centralized) {
    return Row(
      children: [
        Spacer(),
        Container(
          margin: EdgeInsets.only(top: 10, left: 15, right: 15),
          // Note that RaisedButton is deprecated.
          child: ElevatedButton(
            onPressed: onPressed,
            // https://www.woolha.com/tutorials/flutter-using-elevatedbutton-widget-examples
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(80.0))),
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
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(80.0)),
        ),
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

Widget buildMoreInfo(List<List<String?>> data) {
  return Column(
      children: data
          .expand((x) => [
                Text(x[0].toString(), textAlign: TextAlign.center),
                Text(x[1].toString(),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: EdgeInsets.only(bottom: 15),
                ),
              ])
          .toList());
}

Widget buildMyStandardScrollableGradientBoxWithBack(
    BuildContext context, String title, Widget child,
    {String? buttonText,
    void Function()? buttonAction,
    String? buttonTextSignup,
    bool requiresSignUpToContinue = false}) {
  if (provideAuthenticationModel(context).state ==
      AuthenticationModelState.SIGNED_IN) {
    requiresSignUpToContinue = false;
  }

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
                  buildMyStandardButton(
                      requiresSignUpToContinue
                          ? (buttonTextSignup ?? 'YOU MUST SIGN UP!!!')
                          : buttonText,
                      requiresSignUpToContinue
                          ? () {
                              // Instead of doing the action, navigate them to the sign up page.
                              NavigationUtil.navigate(
                                  context,
                                  provideAuthenticationModel(context)
                                              .userType ==
                                          UserType.DONATOR
                                      ? '/signUpAsDonator'
                                      : '/signUpAsRequester');
                            }
                          : buttonAction,
                      textSize: 14,
                      fillWidth: false,
                      centralized: true),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                )
              ],
            ))),
    alignment: Alignment.center,
  );
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

Widget buildMyStandardTextFormField(String name, String labelText,
    {List<FormFieldValidator>? validator,
    bool? obscureText,
    void Function(String)? onChanged,
    required BuildContext? buildContext}) {
  return FormBuilderTextField(
    name: name,
    decoration: InputDecoration(labelText: labelText),
    validator: FormBuilderValidators.compose(
      validator == null
          ? [FormBuilderValidators.required(buildContext!)]
          : validator as List<String Function(String)>,
    ),
    obscureText: obscureText == null ? false : true,
    maxLines: obscureText == true ? 1 : null,
    onChanged: onChanged,
  );
}

Widget buildMyStandardEmailFormField(String name, String labelText,
    {void Function(dynamic)? onChanged, required BuildContext buildContext}) {
  return FormBuilderTextField(
    name: name,
    decoration: InputDecoration(labelText: labelText),
    validator: FormBuilderValidators.compose(
      [FormBuilderValidators.email(buildContext)],
    ),
    keyboardType: TextInputType.emailAddress,
    onChanged: onChanged,
  );
}

Widget buildMyStandardNumberFormField(String name, String labelText) {
  return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(labelText: labelText),
      validator: FormBuilderValidators.compose(
        [
          (val) {
            // Still guard against null
            // ignore: unnecessary_cast
            final valCasted = val as String?;

            if (valCasted == null) return 'Number required';
            return int.tryParse(valCasted) == null ? 'Must be number' : '';
          }
        ],
      ),
      valueTransformer: (val) => int.tryParse(val));
}

// https://stackoverflow.com/questions/53479942/checkbox-form-validation
Widget buildMyStandardNewsletterSignup() {
  return FormBuilderCheckbox(
      name: 'newsletter', title: Text('I agree to receive promotions'));
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

List<Widget> buildMyStandardPasswordSubmitFields({
  bool required = true,
  ValueChanged<String>? onChanged,
  BuildContext? buildContext,
}) {
  String password = '';
  return [
    buildMyStandardTextFormField('password', 'Password',
        obscureText: true, buildContext: buildContext, onChanged: (value) {
      password = value;
      if (onChanged != null) onChanged(password);
    }, validator: [
      if (required) FormBuilderValidators.required(buildContext!)
    ]),
    buildMyStandardTextFormField('repeatPassword', 'Repeat password',
        buildContext: buildContext,
        obscureText: true,
        validator: [
          (val) {
            if (password != "" && val != password) {
              return 'Passwords do not match';
            }
            return null;
          },
          if (required) FormBuilderValidators.required(buildContext!),
        ])
  ];
}

class ProfilePictureField extends StatefulWidget {
  const ProfilePictureField(this.profilePictureStorageRef);
  final String? profilePictureStorageRef;

  @override
  _ProfilePictureFieldState createState() => _ProfilePictureFieldState();
}

class _ProfilePictureFieldState extends State<ProfilePictureField> {
  @override
  Widget build(BuildContext context) {
    return FormBuilderField(
        name: "profilePictureModification",
        enabled: true,
        builder: (FormFieldState<String?> field) =>
            buildMyStandardButton('Edit profile picture', () {
              NavigationUtil.navigate(
                  context, '/profile/picture', widget.profilePictureStorageRef,
                  (result) {
                if (result.returnValue == null) return;
                if (result.returnValue == "NULL")
                  field.didChange("NULL");
                else
                  field.didChange(result.returnValue as String?);
              });
            }));
  }
}

class AddressField extends StatefulWidget {
  @override
  _AddressFieldState createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  @override
  Widget build(BuildContext context) {
    return FormBuilderField(
        name: "addressInfo",
        validator: FormBuilderValidators.compose(
          [FormBuilderValidators.required(context)],
        ),
        enabled: true,
        builder: (FormFieldState<AddressInfo> field) => Row(children: [
              Expanded(
                  child: Text(field.value?.address ?? 'No address selected')),
              buildMyStandardButton('Use GPS', () async {
                field.didChange(await getGPS());
              }, textSize: 12),
              buildMyStandardButton(
                  'Edit', () => getAddress(context, field.didChange),
                  textSize: 12)
            ]));
  }
}

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:gradient_text/gradient_text.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'state.dart';
import 'user-donator.dart';
import 'user-requester.dart';

AuthenticationModel provideAuthenticationModel(BuildContext context) {
  return Provider.of<AuthenticationModel>(context, listen: false);
}

void doSnackbarOperation(BuildContext context, String initialText,
    String finalText, Future<void> future) async {
  Scaffold.of(context).showSnackBar(SnackBar(content: Text(initialText)));
  try {
    await future;
    Scaffold.of(context).showSnackBar(SnackBar(content: Text(finalText)));
  } catch (e) {
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

Widget buildMyStandardFutureBuilder<T>(
    {@required Future<T> api,
    @required Widget Function(BuildContext, T) child}) {
  return FutureBuilder<T>(
      future: api,
      builder: (context, snapshot) {
        if (snapshot.hasData) return child(context, snapshot.data);
        if (snapshot.hasError)
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(fontSize: 36)));
        return Center(
            child: SpinKitWave(
          color: Colors.black26,
          size: 250.0,
        ));
      });
}

Widget buildMyStandardSliverCombo<T>(
    {@required Future<List<T>> api,
    @required String titleText,
    @required String Function(List<T>) secondaryTitleText,
    @required void Function(List<T>, int) onTap,
    @required String Function(List<T>, int) tileTitle,
    @required String Function(List<T>, int) tileSubtitle,
    @required void Function() floatingActionButton,
    @required List<TileTrailingAction<T>> tileTrailing}) {
  return Scaffold(
      floatingActionButton: floatingActionButton == null
          ? null
          : FloatingActionButton(
              child: const Icon(Icons.add), onPressed: floatingActionButton),
      body: FutureBuilder<List<T>>(
          future: api,
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
                                title: Text(secondaryTitleText(snapshot.data)),
                              )
                            : null),
              if (snapshot.hasData)
                SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                  if (index >= snapshot.data.length) return null;
                  return ListTile(
                      onTap: onTap == null
                          ? null
                          : () {
                              onTap(snapshot.data, index);
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
              if (!snapshot.hasData && !snapshot.hasError)
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
          }));
}

Widget buildMyNavigationButton(BuildContext context, String text,
    [String route, Object arguments]) {
  return buildMyStandardButton(text, () {
    if (route == null) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamed(context, route, arguments: arguments);
    }
  });
}

// https://stackoverflow.com/questions/52243364/flutter-how-to-make-a-raised-button-that-has-a-gradient-background
Widget buildMyStandardButton(String text, VoidCallback onPressed) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
    child: RaisedButton(
      onPressed: onPressed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(80.0)),
      padding: const EdgeInsets.all(0.0),
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.deepOrange, Colors.purple]),
          borderRadius: BorderRadius.all(Radius.circular(80.0)),
        ),
        child: Container(
          constraints: const BoxConstraints(
              minWidth: 88.0,
              minHeight: 36.0), // min sizes for Material buttons
          alignment: Alignment.center,
          child: Stack(alignment: Alignment.center, children: [
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            Container(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_right, size: 50, color: Colors.white))
          ]),
        ),
      ),
    ),
  );
}

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => AuthenticationModel(),
    child: MaterialApp(
        title: 'Meal Match',
        initialRoute: '/',
        routes: {
          '/': (context) => MyHomePage(),
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
          '/donator/donations/delete': (context) => DonatorDonationsDeletePage(
              ModalRoute.of(context).settings.arguments as Donation),
          '/donator/donations/publicRequests/list': (context) =>
              DonatorDonationsPublicRequestsListPage(
                  ModalRoute.of(context).settings.arguments as Donation),
          '/donator/donations/publicRequests/view': (context) =>
              DonatorDonationsPublicRequestsViewPage(ModalRoute.of(context)
                  .settings
                  .arguments as PublicRequestAndDonation),
          '/donator/donations/edit': (context) => DonatorDonationsEditPage(
              ModalRoute.of(context).settings.arguments as Donation),
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
              RequesterPublicRequestsListPage(),
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
              RequesterPublicRequestsDonationsViewOldPage(ModalRoute.of(context)
                  .settings
                  .arguments as PublicRequestAndDonationId),
          // chat (both requester and donator)
          '/chat': (context) =>
              ChatPage(ModalRoute.of(context).settings.arguments as ChatUsers),
          '/chat/newMessage': (context) => ChatNewMessagePage(
              ModalRoute.of(context).settings.arguments as ChatUsers),
          // user pages
          '/donator': (context) =>
              DonatorPage(ModalRoute.of(context).settings.arguments as String),
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
        },
        theme: ThemeData(primarySwatch: Colors.deepOrange)),
  ));
}

List<Widget> buildViewPublicRequestContent(PublicRequest publicRequest) {
  return [
    ListTile(title: Text('ID#: ${publicRequest.id}')),
    ListTile(title: Text('Description: ${publicRequest.description}')),
    ListTile(title: Text('Date and time: ${publicRequest.dateAndTime}')),
    ListTile(title: Text('Number of meals: ${publicRequest.numMeals}')),
  ];
}

List<Widget> buildViewDonationContent(Donation donation) {
  return [
    ListTile(title: Text('ID#: ${donation.id}')),
    ListTile(title: Text('Description: ${donation.description}')),
    ListTile(title: Text('Date and time: ${donation.dateAndTime}')),
    ListTile(title: Text('Number of meals: ${donation.numMeals}')),
    ListTile(title: Text('Number of meals requested: ${donation.numMealsRequested}'))
  ];
}

class DonatorPage extends StatelessWidget {
  const DonatorPage(this.id);
  final String id;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Donator id#$id')), body: ViewDonator(id));
  }
}

List<Widget> buildPublicUserInfo(BaseUser user) {
  return [
    ListTile(title: Text('Street address: ${user.streetAddress}')),
    ListTile(title: Text('ZIP code: ${user.zipCode}')),
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
                  'Chat with donator',
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
        appBar: AppBar(title: Text('Requester id#$id')),
        body: ViewRequester(id));
  }
}

class ViewRequester extends StatefulWidget {
  const ViewRequester(this.id);
  final String id;
  @override
  _ViewRequesterState createState() => _ViewRequesterState();
}

class _ViewRequesterState extends State<ViewRequester> {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilderCombo<Requester>(
        api: Api.getRequester(widget.id),
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
        api: Api.getChatMessagesByUsers(chatUsers),
        titleText: 'Chat',
        secondaryTitleText: (data) => '${data.length} messages',
        onTap: null,
        tileTitle: (data, index) =>
            '${data[index].speaker == UserType.DONATOR ? 'Donator' : 'Requester'}',
        tileSubtitle: (data, index) => '${data[index].message}',
        tileTrailing: null,
        floatingActionButton: () => Navigator.pushNamed(
            context, '/chat/newMessage',
            arguments: chatUsers));
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
                ..requesterId = chatUsers.requesterId));
        }
      })
    ];

    return buildMyFormListView(_formKey, children);
  }
}

class MyChangePasswordPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Change password')),
        body: MyChangePasswordForm());
  }
}

class MyChangeEmailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Change email')),
        body: MyChangeEmailForm());
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
                  .attemptLogin(value['email'], value['password']));
        }
      })
    ];

    return buildMyFormListView(_formKey, children);
  }
}

class MyChangePasswordForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _newPasswordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardTextFormField('oldPassword', 'Old password',
          obscureText: true),
      ...buildMyStandardPasswordSubmitFields(_newPasswordController),
      buildMyStandardButton('Change password', () {
        if (_formKey.currentState.saveAndValidate()) {
          var value = _formKey.currentState.value;
          doSnackbarOperation(
              context,
              'Changing password...',
              'Password successfully changed!',
              provideAuthenticationModel(context).userChangePassword(
                  UserChangePasswordData()..formRead(value)));
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
      buildMyStandardTextFormField('oldPassword', 'Old password',
          obscureText: true),
      buildMyStandardEmailFormField('email', 'New email'),
      buildMyStandardButton('Change email', () {
        if (_formKey.currentState.saveAndValidate()) {
          var value = _formKey.currentState.value;
          doSnackbarOperation(
              context,
              'Changing password...',
              'Password successfully changed!',
              provideAuthenticationModel(context).userChangeEmail(
                  UserChangeEmailData()..formRead(value)));
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
        appBar: AppBar(title: Text('Sign up as meal donator')),
        body: MyDonatorSignUpForm());
  }
}

class MyDonatorSignUpForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      ...buildMyStandardPasswordSubmitFields(_passwordController),
      buildMyStandardEmailFormField('email', 'Email'),
      ...buildUserFormFields(),
      ...buildPrivateUserFormFields(),
      ListTile(
          subtitle:
          Text('By signing up, you agree to the Terms and Conditions.')),
      buildMyStandardButton('Sign up as donator', () {if (_formKey.currentState.saveAndValidate()) {
        var value = _formKey.currentState.value;
        doSnackbarOperation(
            context,
            'Signing up...',
            'Successfully signed up!',
            provideAuthenticationModel(context).signUpDonator(
                Donator()..formRead(value)..numMeals = 0,
                PrivateDonator()..formRead(value),
                SignUpData()..formRead(value)));
      }})
    ];
    return buildMyFormListView(_formKey, children);
  }
}

class MyRequesterSignUpForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      ...buildMyStandardPasswordSubmitFields(_passwordController),
      buildMyStandardEmailFormField('email', 'Email'),
      ...buildUserFormFields(),
      ...buildPrivateUserFormFields(),
      ListTile(
          subtitle:
          Text('By signing up, you agree to the Terms and Conditions.')),
      buildMyStandardButton('Sign up as requester', (){
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
    TextEditingController controller}) {
  return FormBuilderTextField(
    attribute: attribute,
    decoration: InputDecoration(labelText: labelText),
    validators:
        validators == null ? [FormBuilderValidators.required()] : validators,
    obscureText: obscureText == null ? false : true,
    maxLines: obscureText == true ? 1 : null,
    controller: controller,
  );
}

Widget buildMyStandardEmailFormField(String attribute, String labelText) {
  return FormBuilderTextField(
    attribute: attribute,
    decoration: InputDecoration(labelText: labelText),
    validators: [FormBuilderValidators.email()],
    keyboardType: TextInputType.emailAddress,
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
      attribute: 'newsletter', label: Text('Sign up for newsletter'));
}

List<Widget> buildMyStandardPasswordSubmitFields(
    TextEditingController controller) {
  return [
    buildMyStandardTextFormField('password', 'Password',
        obscureText: true, controller: controller),
    buildMyStandardTextFormField('repeatPassword', 'Repeat password',
        obscureText: true,
        validators: [
          (val) {
            if (val != controller.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          FormBuilderValidators.required(),
        ])
  ];
}

List<Widget> buildUserFormFields() {
  return [
    buildMyStandardTextFormField('name', 'Name'),
    buildMyStandardTextFormField('streetAddress', 'Street address'),
    buildMyStandardTextFormField('zipCode', 'Zip code'),
    buildMyStandardTextFormField('bio', 'Bio')
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
    child: ListView(padding: EdgeInsets.all(16.0), children: children),
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

const List<String> introTitles = [
  'Welcome to Meal Match!',
  'Are you donating meals?',
  'Are you requesting a meal?',
  'Learn more'
];
const List<String> introActions = [
  'Sign in',
  'Sign up as donator',
  'Sign up as requester',
  null
];
const List<String> introActionRoutes = [
  '/signIn',
  '/signUpAsDonator',
  '/signUpAsRequester',
  null
];

class MyIntroduction extends StatefulWidget {
  @override
  _MyIntroductionState createState() => _MyIntroductionState();
}

class _MyIntroductionState extends State<MyIntroduction> {
  int position = 0;
  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [
      for (var i = 0; i < introTitles.length; ++i)
        Container(
          margin: EdgeInsets.all(8.0),
          child: Container(
              padding: EdgeInsets.all(8.0),
              width: double.infinity,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GradientText(
                      introTitles[i],
                      gradient: LinearGradient(
                          colors: [Colors.deepOrange, Colors.deepPurple]),
                      style:
                          TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (introActions[i] != null)
                      buildMyNavigationButton(
                          context, introActions[i], introActionRoutes[i])
                  ])),
        )
    ];
    return Scaffold(
        appBar: AppBar(title: Text('Meal Match')),
        body: CarouselSlider(
            items: items,
            options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                viewportFraction: 1,
                onPageChanged: (index, reason) {
                  setState(() {
                    position = index;
                  });
                })),
        bottomNavigationBar: BottomAppBar(
            child: Container(
                height: 50,
                child: Center(
                    child: DotsIndicator(
                  dotsCount: introTitles.length,
                  position: position.toDouble(),
                  decorator: DotsDecorator(
                    color: Colors.black87,
                    activeColor: Colors.redAccent,
                  ),
                )))));
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationModel>(builder: (context, value, child) {
      if (value.isLoggedIn) {
        return MyUserPage(value.userType);
      } else {
        return MyIntroduction();
      }
    });
  }
}

class MyUserPage extends StatefulWidget {
  const MyUserPage(this.userType);
  final UserType userType;
  @override
  _MyUserPageState createState() => _MyUserPageState();
}

class _MyUserPageState extends State<MyUserPage> {
  int _selectedIndex = 1;
  @override
  Widget build(BuildContext context) {
    List<Widget> subpages = [
      buildStandardButtonColumn([
        buildMyNavigationButton(
            context,
            'Change user info',
            widget.userType == UserType.DONATOR
                ? '/donator/changeUserInfo'
                : '/requester/changeUserInfo'),
        buildMyNavigationButton(context, 'Change email', '/changeEmail'),
        buildMyNavigationButton(context, 'Change password', '/changePassword'),
        buildMyStandardButton('Log out', () {
          provideAuthenticationModel(context).signOut();
        })
      ]),
      buildStandardButtonColumn([
        if (widget.userType == UserType.DONATOR)
          buildMyNavigationButton(
              context, 'My Donations', '/donator/donations/list'),
        if (widget.userType == UserType.DONATOR)
          buildMyNavigationButton(
              context, 'Unfulfilled Requests', '/donator/publicRequests/list'),
        if (widget.userType == UserType.REQUESTER)
          buildMyNavigationButton(
              context, 'My Requests', '/requester/publicRequests/list')
      ]),
      if (widget.userType == UserType.DONATOR)
        buildMyStandardSliverCombo<Requester>(
            api: Api.getRequestersWithChats(
                provideAuthenticationModel(context).donatorId),
            titleText: null,
            secondaryTitleText: null,
            onTap: (data, index) => Navigator.pushNamed(context, '/chat',
                arguments: ChatUsers(
                    donatorId: provideAuthenticationModel(context).donatorId,
                    requesterId: data[index].id)),
            tileTitle: (data, index) => '${data[index].name}',
            tileSubtitle: null,
            tileTrailing: null,
            floatingActionButton: null),
      if (widget.userType == UserType.REQUESTER)
        buildMyStandardSliverCombo<Donator>(
            api: Api.getDonatorsWithChats(
                provideAuthenticationModel(context).requesterId),
            titleText: null,
            secondaryTitleText: null,
            onTap: (data, index) => Navigator.pushNamed(context, '/chat',
                arguments: ChatUsers(
                    requesterId:
                        provideAuthenticationModel(context).requesterId,
                    donatorId: data[index].id)),
            tileTitle: (data, index) => '${data[index].name}',
            tileSubtitle: null,
            tileTrailing: null,
            floatingActionButton: null),
      buildMyStandardSliverCombo<LeaderboardEntry>(
          api: Api.getLeaderboard(),
          titleText: null,
          secondaryTitleText: null,
          onTap: null,
          tileTitle: (data, index) => '${data[index].name}',
          tileSubtitle: (data, index) => '${data[index].numMeals} meals',
          tileTrailing: null,
          floatingActionButton: null)
    ];
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.userType == UserType.DONATOR
              ? 'Meal Match (DONATOR)'
              : 'Meal Match (REQUESTER)')),
      body: Center(
        child: subpages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.person), title: Text('Profile')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.home), title: Text('Home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.chat), title: Text('Chats')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.cloud), title: Text('Leaderboard'))
          ],
          currentIndex: _selectedIndex,
          unselectedItemColor: Colors.black,
          selectedItemColor: Colors.deepOrange,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          }),
    );
  }
}

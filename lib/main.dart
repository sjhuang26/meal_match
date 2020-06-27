import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:gradient_text/gradient_text.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'state.dart';
import 'user-donator.dart';
import 'user-requester.dart';

class TileTrailingAction<T> {
  const TileTrailingAction(this.text, this.onSelected);
  final String text;
  final void Function(List<T>, int) onSelected;
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
              if (titleText != null) SliverAppBar(
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
                      leading:
                          Text('#${index + 1}', style: TextStyle(fontSize: 30, color: Colors.black54)),
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
                  ListTile(title: Text('Error', style: TextStyle(fontSize: 24)))
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
          constraints: const BoxConstraints(minWidth: 88.0, minHeight: 36.0), // min sizes for Material buttons
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                  )
              ),
              Container(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.arrow_right, size: 50, color: Colors.white)
              )
            ]
          ),
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
          '/changeAddress': (context) => MyChangeAddressPage(),
          // used by donator
          '/donator/donations/new': (context) => DonatorDonationsNewPage(),
          '/donator/donations/list': (context) => DonatorDonationsListPage(),
          '/donator/donations/view': (context) => DonatorDonationsViewPage(
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
              DonatorPage(ModalRoute.of(context).settings.arguments as int),
          '/requester': (context) =>
              RequesterPage(ModalRoute.of(context).settings.arguments as int)
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
  ];
}

class DonatorPage extends StatelessWidget {
  const DonatorPage(this.id);
  final int id;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Donator id#$id')), body: ViewDonator(id));
  }
}

List<Widget> buildPublicUserInfo(User user) {
  return [
    ListTile(
        title:
        Text('Street address: ${user.streetAddress}')),
    ListTile(
        title:
        Text('ZIP code: ${user.zipCode}')),
  ];
}

class ViewDonator extends StatefulWidget {
  const ViewDonator(this.id);
  final int id;
  @override
  _ViewDonatorState createState() => _ViewDonatorState();
}

class _ViewDonatorState extends State<ViewDonator> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Donator>(
        future: Api.getDonatorById(widget.id),
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return ListView(children: <Widget>[
              ...buildPublicUserInfo(snapshot.data),
              buildMyNavigationButton(
                  context,
                  'Chat with donator',
                  '/chat',
                  ChatUsers(
                      donatorId: snapshot.data.id,
                      requesterId: Provider.of<AuthenticationModel>(context,
                              listen: false)
                          .requesterId))
            ]);
          if (snapshot.hasError)
            return Center(child: Text('Error', style: TextStyle(fontSize: 36)));
          return Center(
              child: Text('Loading...', style: TextStyle(fontSize: 36)));
        });
  }
}

class RequesterPage extends StatelessWidget {
  const RequesterPage(this.id);
  final int id;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Requester id#$id')),
        body: ViewRequester(id));
  }
}

class ViewRequester extends StatefulWidget {
  const ViewRequester(this.id);
  final int id;
  @override
  _ViewRequesterState createState() => _ViewRequesterState();
}

class _ViewRequesterState extends State<ViewRequester> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Requester>(
        future: Api.getRequesterById(widget.id),
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return ListView(children: <Widget>[
              ...buildPublicUserInfo(snapshot.data),
              buildMyNavigationButton(
                  context,
                  'Chat with requester',
                  '/chat',
                  ChatUsers(
                      donatorId: Provider.of<AuthenticationModel>(context,
                              listen: false)
                          .donatorId,
                      requesterId: snapshot.data.id))
            ]);
          if (snapshot.hasError)
            return Center(child: Text('Error', style: TextStyle(fontSize: 36)));
          return Center(
              child: Text('Loading...', style: TextStyle(fontSize: 36)));
        });
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

class NewChatMessage extends StatefulWidget {
  const NewChatMessage(this.chatUsers);
  final ChatUsers chatUsers;
  @override
  _NewChatMessageState createState() => _NewChatMessageState();
}

class _NewChatMessageState extends State<NewChatMessage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ChatMessage _data = ChatMessage();

  _submitForm() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text(_data.toString())));
    }
  }

  @override
  void initState() {
    super.initState();
    _data.speaker =
        Provider.of<AuthenticationModel>(context, listen: false).userType;
    _data.donatorId = widget.chatUsers.donatorId;
    _data.requesterId = widget.chatUsers.requesterId;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardTextFormField('Message', (newValue) {
        _data.message = newValue;
      }),
      buildMyStandardButton(
        'Submit new message',
        _submitForm,
      )
    ];

    return Form(key: _formKey, child: buildMyFormListView(children));
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

class MyChangeAddressPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Change address')),
        body: MyChangeAddressForm());
  }
}

class MySignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Sign in')), body: MyLoginForm());
  }
}

class MyLoginForm extends StatefulWidget {
  @override
  _MyLoginFormState createState() => _MyLoginFormState();
}

class MyChangePasswordForm extends StatefulWidget {
  @override
  _MyChangePasswordFormState createState() => _MyChangePasswordFormState();
}

class _MyChangePasswordFormState extends State<MyChangePasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _ChangePasswordData _data = _ChangePasswordData();
  final TextEditingController _newPasswordController = TextEditingController();

  _submitForm() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text(_data.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardPasswordSigninField((newValue) {
        _data.oldPassword = newValue;
      }, 'Old password'),
      ...buildMyStandardPasswordSignupFields(_newPasswordController,
          (newValue) {
        _data.newPassword = newValue;
      }),
      buildMyStandardButton(
        'Change password',
        _submitForm,
      )
    ];

    return Form(key: _formKey, child: buildMyFormListView(children));
  }
}

class MyChangeAddressForm extends StatefulWidget {
  @override
  _MyChangeAddressFormState createState() => _MyChangeAddressFormState();
}

class _MyChangeAddressFormState extends State<MyChangeAddressForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ChangeAddressData _data = ChangeAddressData();

  _submitForm() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text(_data.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardTextFormField('Address', (newValue) {
        _data.address = newValue;
      }),
      buildMyStandardButton(
        'Change address',
        _submitForm,
      )
    ];

    return Form(key: _formKey, child: buildMyFormListView(children));
  }
}

class _ChangePasswordData {
  String oldPassword;
  String newPassword;
  @override
  String toString() {
    return '''Old password: $oldPassword;
New password: $newPassword
''';
  }
}

class _LoginData {
  String username;
  String password;
  @override
  String toString() {
    return '''Username: $username;
Password: $password;
''';
  }
}

class _MyLoginFormState extends State<MyLoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _LoginData _data = _LoginData();

  _submitForm() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text(_data.toString())));
      Provider.of<AuthenticationModel>(context, listen: false)
          .attemptLogin(_data.username, _data.password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      TextFormField(
          validator: (text) {
            if (text == '') {
              return 'Please enter a username';
            } else {
              return null;
            }
          },
          decoration: InputDecoration(labelText: 'Username'),
          onSaved: (newValue) {
            _data.username = newValue;
          }),
      buildMyStandardPasswordSigninField((newValue) {
        _data.password = newValue;
      }, 'Password'),
      buildMyStandardButton('Login', _submitForm)
    ];

    return Form(key: _formKey, child: buildMyFormListView(children));
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

class MyDonatorSignUpForm extends StatefulWidget {
  @override
  _MyDonatorSignUpFormState createState() => _MyDonatorSignUpFormState();
}

class MyRequesterSignUpForm extends StatefulWidget {
  @override
  _MyRequesterSignUpFormState createState() => _MyRequesterSignUpFormState();
}

class _UserSignUpData {
  String name;
  String email;
  String username;
  String password;
  String streetAddress;
  String phoneNumber;
  String zipCode;
  bool termsAndConditions;
  bool newsletter;
}

class _DonatorSignUpData extends _UserSignUpData {
}

class _RequesterSignUpData extends _UserSignUpData {
}

Widget buildMyStandardPasswordSigninField(
    FormFieldSetter<String> onSaved, String labelText) {
  return TextFormField(
      validator: (text) {
        if (text == '') {
          return 'Please enter a password';
        } else {
          return null;
        }
      },
      decoration: InputDecoration(labelText: labelText),
      obscureText: true,
      onSaved: onSaved);
}

Widget buildMyStandardTextFormField(
    String labelText, FormFieldSetter<String> onSaved,
    [String initialValue]) {
  return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: labelText),
      validator: (text) {
        if (text == '') {
          return 'Required';
        } else {
          return null;
        }
      },
      onSaved: onSaved);
}

Widget buildMyStandardEmailFormField(
    String labelText, FormFieldSetter<String> onSaved,
    [String initialValue]) {
  return TextFormField(
      initialValue: initialValue,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(labelText: labelText),
      validator: (text) {
        if (text == '') {
          return 'Required';
        } else {
          return null;
        }
      },
      onSaved: onSaved);
}

Widget buildMyStandardNumberFormField(
    String labelText, FormFieldSetter<String> onSaved,
    [String initialValue]) {
  return TextFormField(
      initialValue: initialValue,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: labelText),
      validator: (text) {
        try {
          if (int.parse(text) <= 0) return 'Not a valid number';
        } on FormatException {
          return 'Not a valid number';
        }
        return null;
      },
      onSaved: onSaved);
}

// https://stackoverflow.com/questions/53479942/checkbox-form-validation
Widget buildMyStandardNewsletterSignup(_UserSignUpData data) {
  return FormField<bool>(
      builder: (state) {
        return CheckboxListTile(
            title: Text('Sign up for newsletter'),
            value: state.value,
            onChanged: (value) {
              state.didChange(value);
            });
      },
      initialValue: true,
      onSaved: (value) {
        data.newsletter = value;
      });
}

List<Widget> buildMyStandardPasswordSignupFields(
    TextEditingController controller, FormFieldSetter<String> onSaved) {
  return [
    TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: 'Password'),
        obscureText: true,
        validator: (text) {
          if (text == '') {
            return 'Required';
          } else {
            return null;
          }
        },
        onSaved: onSaved),
    TextFormField(
        decoration:
            InputDecoration(labelText: 'Retype password'),
        obscureText: true,
        validator: (text) {
          if (text == controller.text) {
            return null;
          } else {
            return 'Passwords do not match';
          }
        }),
  ];
}

class _MyDonatorSignUpFormState extends State<MyDonatorSignUpForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final _DonatorSignUpData _data = _DonatorSignUpData();

  void _submitForm() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text(_data.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardTextFormField('Name', (newValue) {
        _data.name = newValue;
      }),
      buildMyStandardEmailFormField('Email', (newValue) {
        _data.email = newValue;
      }),
      buildMyStandardTextFormField('Username', (newValue) {
        _data.username = newValue;
      }),
      ...buildMyStandardPasswordSignupFields(_passwordController, (newValue) {
        _data.password = newValue;
      }),
      buildMyStandardTextFormField('Street address', (newValue) {
        _data.streetAddress = newValue;
      }),
      buildMyStandardTextFormField('Phone', (newValue) {
        _data.phoneNumber = newValue;
      }),
      buildMyStandardTextFormField('Zip code', (newValue) {
        _data.zipCode = newValue;
      }),
      ListTile(
        subtitle: Text('By signing up, you agree to the Terms and Conditions.')
      ),
      // https://stackoverflow.com/questions/53479942/checkbox-form-validation
      buildMyStandardNewsletterSignup(_data),
      buildMyStandardButton('Sign up as donator', _submitForm)
    ];
    return Form(key: _formKey, child: buildMyFormListView(children));
  }
}

class _MyRequesterSignUpFormState extends State<MyRequesterSignUpForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final _RequesterSignUpData _data = _RequesterSignUpData();

  void _submitForm() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text(_data.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardTextFormField('Name', (newValue) {
        _data.name = newValue;
      }),
      buildMyStandardEmailFormField('Email', (newValue) {
        _data.email = newValue;
      }),
      buildMyStandardTextFormField('Username', (newValue) {
        _data.username = newValue;
      }),
      ...buildMyStandardPasswordSignupFields(_passwordController, (newValue) {
        _data.password = newValue;
      }),
      buildMyStandardTextFormField('Street address', (newValue) {
        _data.streetAddress = newValue;
      }),
      buildMyStandardTextFormField('Phone', (newValue) {
        _data.phoneNumber = newValue;
      }),
      buildMyStandardTextFormField('Zip code', (newValue) {
        _data.zipCode = newValue;
      }),
      ListTile(
          subtitle: Text('By signing up, you agree to the Terms and Conditions.')
      ),
      buildMyStandardNewsletterSignup(_data),
      buildMyStandardButton('Sign up as requester', _submitForm)
    ];
    return Form(key: _formKey, child: buildMyFormListView(children));
  }
}

Widget buildMyFormListView(List<Widget> children) {
  return ListView(padding: EdgeInsets.all(16.0), children: children);
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
      child:
          Column(mainAxisSize: MainAxisSize.min, children: children));
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
        buildMyNavigationButton(context, 'Change address', '/changeAddress'),
        buildMyNavigationButton(context, 'Change password', '/changePassword'),
        buildMyStandardButton('Log out', () {
          Provider.of<AuthenticationModel>(context, listen: false).logOut();
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
      if (widget.userType == UserType.DONATOR) buildMyStandardSliverCombo<Requester>(
          api: Api.getRequestersWithChats(),
          titleText: null,
          secondaryTitleText: null,
          onTap: (data, index) => Navigator.pushNamed(context, '/chat', arguments: ChatUsers(
            donatorId: Provider.of<AuthenticationModel>(context, listen: false).donatorId,
            requesterId: data[index].id
          )),
          tileTitle: (data, index) => '${data[index].name}',
          tileSubtitle: null,
          tileTrailing: null,
          floatingActionButton: null),
      if (widget.userType == UserType.REQUESTER) buildMyStandardSliverCombo<Donator>(
          api: Api.getDonatorsWithChats(),
          titleText: null,
          secondaryTitleText: null,
          onTap: (data, index) => Navigator.pushNamed(context, '/chat', arguments: ChatUsers(
              requesterId: Provider.of<AuthenticationModel>(context, listen: false).requesterId,
              donatorId: data[index].id
          )),
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'state.dart';
import 'main.dart';

class RequesterPublicRequestsDonationsViewOldPage extends StatelessWidget {
  const RequesterPublicRequestsDonationsViewOldPage(
      this.publicRequestAndDonationId);

  final PublicRequestAndDonationId publicRequestAndDonationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Donation')),
        body: ViewOldDonation(publicRequestAndDonationId));
  }
}

class ViewDonation extends StatelessWidget {
  const ViewDonation(this.donation);

  final Donation donation;

  @override
  Widget build(BuildContext context) {
    return ListView(children: <Widget>[
      ...buildViewDonationContent(donation),
      buildMyNavigationButton(context, 'Request meals',
          route: '/requester/donationRequests/new', arguments: donation),
      buildMyNavigationButton(context, 'Open donor profile',
          route: '/donator', arguments: donation.donatorId)
    ]);
  }
}

class ViewOldDonation extends StatefulWidget {
  const ViewOldDonation(this.publicRequestAndDonationId);

  final PublicRequestAndDonationId publicRequestAndDonationId;

  @override
  _ViewOldDonationState createState() => _ViewOldDonationState();
}

class _ViewOldDonationState extends State<ViewOldDonation> {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilderCombo<Donation>(
        api: Api.getDonationById(widget.publicRequestAndDonationId.donationId),
        children: (context, data) => [
              ...buildViewDonationContent(data),
              buildMyNavigationButton(
                context,
                'Open donor profile',
                route: '/donator',
                arguments: data.donatorId,
              )
            ]);
  }
}

class RequesterPendingRequestsAndInterestsView extends StatefulWidget {
  const RequesterPendingRequestsAndInterestsView(this.controller);

  final TabController controller;

  @override
  RequesterPendingRequestsAndInterestsViewState createState() =>
      RequesterPendingRequestsAndInterestsViewState();
}

class RequesterPendingRequestsAndInterestsViewState
    extends State<RequesterPendingRequestsAndInterestsView> {
  @override
  Widget build(BuildContext context) {
    return TabBarView(controller: widget.controller, children: [
      RequesterPendingInterestsView(),
      RequesterPendingRequestsView()
    ]);
  }
}

class RequesterPendingRequestsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MyRefreshable(
      builder: (context, refresh) => buildMyStandardFutureBuilder(
          api: Api.getRequesterPublicRequests(
              provideAuthenticationModel(context).uid),
          child: (context, snapshotData) {
            if (snapshotData.length == 0) {
              return buildMyStandardEmptyPlaceholderBox(
                  content: 'No Pending Requests');
            }
            return CupertinoScrollbar(
              child: ListView.builder(
                  itemCount: snapshotData.length,
                  padding:
                      EdgeInsets.only(top: 10, bottom: 20, right: 15, left: 15),
                  itemBuilder: (BuildContext context, int index) {
                    final request = snapshotData[index];
                    return buildMyStandardBlackBox(
                        title: 'Date: ${request.dateAndTime}',
                        content:
                            'Number of Adult Meals: ${request.numMealsAdult}\nNumber of Child Meals: ${request.numMealsChild}\nDietary Restrictions: ${request.dietaryRestrictions}\n',
                        moreInfo: () => NavigationUtil.navigateWithRefresh(
                            context,
                            '/requester/publicRequests/view',
                            refresh,
                            request));
                  }),
            );
          }),
    );
  }
}

class RequesterPendingInterestsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) => buildMyStandardFutureBuilder(
          api: Api.getInterestsByRequesterId(
              provideAuthenticationModel(context).uid),
          child: (context, snapshotData) {
            if (snapshotData.length == 0) {
              return Center(
                child: Text(
                  "No Pending Interests",
                  style: TextStyle(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey),
                ),
              );
            }
            return CupertinoScrollbar(
              child: ListView.builder(
                  itemCount: snapshotData.length,
                  padding:
                      EdgeInsets.only(top: 10, bottom: 20, right: 15, left: 15),
                  itemBuilder: (BuildContext context, int index) {
                    final interest = snapshotData[index];
                    return buildMyStandardBlackBox(
                        title: "Date: " +
                            interest.requestedPickupDateAndTime.toString(),
                        content:
                            "Address: ${interest.requestedPickupLocation}\nNumber of Adult Meals: ${interest.numAdultMeals}\nNumber of Child Meals: ${interest.numChildMeals}",
                        moreInfo: () => NavigationUtil.navigateWithRefresh(
                            originalContext,
                            '/requester/interests/view',
                            refresh,
                            interest));
                  }),
            );
          }),
    );
  }
}

class RequesterInterestsViewPage extends StatelessWidget {
  const RequesterInterestsViewPage(this.interest);

  final Interest interest;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context, body: ViewInterest(interest), title: 'Interest');
  }
}

class ViewInterest extends StatelessWidget {
  const ViewInterest(this.interest);
  final Interest interest;

  @override
  Widget build(BuildContext context) {
    final uid = provideAuthenticationModel(context).uid;
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) =>
          buildMyStandardFutureBuilder<RequesterViewInterestInfo>(
              api: Api.getRequesterViewInterestInfo(interest, uid),
              child: (context, x) => Column(children: [
                    StatusInterface(
                        initialStatus: x.interest.status,
                        onStatusChanged: (newStatus) => doSnackbarOperation(
                            context,
                            'Changing status...',
                            'Status changed!',
                            Api.editInterest(x.interest..status = newStatus))),
                    Expanded(
                        child: ChatInterface(x.messages, (message) async {
                      await doSnackbarOperation(
                          context,
                          'Sending message...',
                          'Message sent!',
                          Api.newChatMessage(ChatMessage()
                            ..timestamp = DateTime.now()
                            ..speakerUid = uid
                            ..donatorId = x.donator.id
                            ..requesterId = uid
                            ..interestId = x.interest.id
                            ..message = message));
                      refresh();
                    })),
                    buildMyStandardButton('Delete', () {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                  title: Text('Really delete?'),
                                  actions: [
                                    FlatButton(
                                        child: Text('Yes'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          doSnackbarOperation(
                                              originalContext,
                                              'Deleting request...',
                                              'Request deleted!',
                                              Api.deleteInterest(x.interest),
                                              MySnackbarOperationBehavior
                                                  .POP_ONE_AND_REFRESH);
                                        }),
                                    FlatButton(
                                        child: Text('No'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        })
                                  ]));
                    })
                  ])),
    );
  }
}

class RequesterDonationList extends StatefulWidget {
  @override
  _RequesterDonationListState createState() => _RequesterDonationListState();
}

class _RequesterDonationListState extends State<RequesterDonationList> {
  @override
  Widget build(BuildContext context) {
    final uid = provideAuthenticationModel(context).uid;
    return Column(children: [
      Container(
        padding: EdgeInsets.only(left: 27, right: 5, top: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            (Text("Donations Near You",
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
            Spacer(),
            Container(
                child: buildMyNavigationButton(context, "New Request",
                    route: '/requester/publicRequests/new',
                    textSize: 15,
                    fillWidth: false)),
          ],
        ),
      ),
      buildMyStandardFutureBuilder<RequesterDonationListInfo>(
          api: Api.getRequesterDonationListInfo(uid),
          child: (context, result) {
            final alreadyInterestedDonations = Set<String>();
            for (final x in result.interests) {
              alreadyInterestedDonations.add(x.donationId);
            }
            final filteredDonations = result.donations
                .where((x) => !alreadyInterestedDonations.contains(x.id))
                .toList();

            if (filteredDonations.length == 0) {
              return buildMyStandardEmptyPlaceholderBox(
                  content: "No donations found nearby.");
            }

            return Expanded(
              child: CupertinoScrollbar(
                child: ListView.builder(
                    itemCount: filteredDonations.length,
                    padding: EdgeInsets.only(
                        top: 10, bottom: 20, right: 15, left: 15),
                    itemBuilder: (BuildContext context, int index) {
                      return FutureBuilder<Donator>(
                          future: Api.getDonator(
                              filteredDonations[index].donatorId),
                          builder: (context, donatorSnapshot) {
                            if (donatorSnapshot.connectionState ==
                                ConnectionState.done) {
                              final donation = filteredDonations[index];
                              final donator = donatorSnapshot.data;
                              return buildMyStandardBlackBox(
                                  title:
                                      '${donator.name} ${donation.dateAndTime}',
                                  content:
                                      'Address: ${donation.streetAddress}\nDescription: ${donation.description}\nMeals: ${donation.numMeals - donation.numMealsRequested}/${donation.numMeals}',
                                  moreInfo: () => NavigationUtil.navigate(
                                      context,
                                      '/requester/donations/view',
                                      DonationAndDonator(donation, donator)));
                            }
                            return Container();
                          });
                    }),
              ),
            );
          })
    ]);
  }
}

class RequesterPublicRequestsViewPage extends StatelessWidget {
  const RequesterPublicRequestsViewPage(this.publicRequest);

  final PublicRequest publicRequest;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        body: ViewPublicRequest(publicRequest),
        title: 'Request');
  }
}

class ViewPublicRequest extends StatelessWidget {
  const ViewPublicRequest(this.initialValue);

  final PublicRequest initialValue;

  @override
  Widget build(BuildContext context) {
    final uid = provideAuthenticationModel(context).uid;
    return MyRefreshable(
      builder: (context, refresh) => buildMyStandardFutureBuilder<
              RequesterViewPublicRequestInfo>(
          api: Api.getRequesterViewPublicRequestInfo(initialValue, uid),
          child: (context, x) => Column(children: [
                if (x.donator != null)
                  StatusInterface(
                      initialStatus: x.publicRequest.status,
                      onStatusChanged: (newStatus) => doSnackbarOperation(
                          context,
                          'Changing status...',
                          'Status changed!',
                          Api.editPublicRequest(
                              x.publicRequest..status = newStatus))),
                Expanded(
                    child: x.donator == null
                        ? buildMyStandardEmptyPlaceholderBox(
                            content: 'Waiting for donor')
                        : ChatInterface(x.messages, (message) async {
                            await doSnackbarOperation(
                                context,
                                'Sending message...',
                                'Message sent!',
                                Api.newChatMessage(ChatMessage()
                                  ..timestamp = DateTime.now()
                                  ..speakerUid = uid
                                  ..donatorId = x.donator.id
                                  ..requesterId = uid
                                  ..publicRequestId = x.publicRequest.id
                                  ..message = message));
                            refresh();
                          })),
                buildMyStandardButton('Delete', () {
                  showDialog(
                      context: context,
                      builder: (context) =>
                          AlertDialog(title: Text('Really delete?'), actions: [
                            FlatButton(
                                child: Text('Yes'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  doSnackbarOperation(
                                      context,
                                      'Deleting request...',
                                      'Request deleted!',
                                      Api.deletePublicRequest(x.publicRequest),
                                      MySnackbarOperationBehavior
                                          .POP_ONE_AND_REFRESH);
                                }),
                            FlatButton(
                                child: Text('No'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                })
                          ]));
                })
              ])),
    );
  }
}

class RequesterPublicRequestsNewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context, title: 'New Request', body: NewPublicRequestForm());
  }
}

class NewPublicRequestForm extends StatefulWidget {
  @override
  _NewPublicRequestFormState createState() => _NewPublicRequestFormState();
}

class _NewPublicRequestFormState extends State<NewPublicRequestForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardNumberFormField(
          'numMealsAdult', 'Number of meals (adult)'),
      buildMyStandardNumberFormField(
          'numMealsChild', 'Number of meals (child)'),
      buildMyStandardTextFormField(
          'dateAndTime', 'Date and time to receive meal'),
      buildMyStandardTextFormField(
          'dietaryRestrictions', 'Dietary restrictions',
          validators: []),
      buildMyStandardButton(
        'Submit new request',
        () {
          if (_formKey.currentState.saveAndValidate()) {
            var value = _formKey.currentState.value;
            doSnackbarOperation(
                context,
                'Submitting request...',
                'Added request!',
                Api.newPublicRequest(PublicRequest()
                  ..formRead(value)
                  ..requesterId = provideAuthenticationModel(context).uid),
                MySnackbarOperationBehavior.POP_ONE);
          }
        },
      )
    ];
    return buildMyStandardScrollableGradientBoxWithBack(
        context, 'Request Details', buildMyFormListView(_formKey, children));
  }
}

class RequesterChangeUserInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        title: 'Edit Information',
        fontSize: 25,
        context: context,
        body: ChangeRequesterInfoForm());
  }
}

class ChangeRequesterInfoForm extends StatefulWidget {
  @override
  _ChangeRequesterInfoFormState createState() =>
      _ChangeRequesterInfoFormState();
}

class _ChangeRequesterInfoFormState extends State<ChangeRequesterInfoForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<Requester>(
        api: Api.getRequester(provideAuthenticationModel(context).uid),
        child: (context, data) {
          final List<Widget> children = [
            ...buildUserFormFields(),
            buildMyNavigationButton(context, 'Change private user info',
                route: '/requester/changeUserInfo/private', arguments: data.id),
            buildMyStandardButton('Save', () {
              if (_formKey.currentState.saveAndValidate()) {
                var value = _formKey.currentState.value;
                doSnackbarOperation(
                    context,
                    'Saving...',
                    'Successfully saved',
                    Api.editRequester(data..formRead(value)),
                    MySnackbarOperationBehavior.POP_ZERO);
              }
            })
          ];
          return buildMyFormListView(_formKey, children,
              initialValue: data.formWrite());
        });
  }
}

class InterestNewPage extends StatelessWidget {
  const InterestNewPage(this.donationAndDonator);

  final DonationAndDonator donationAndDonator;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
      context: context,
      title: 'New Interest',
      body: CreateNewInterestForm(this.donationAndDonator),
    );
  }
}

class CreateNewInterestForm extends StatefulWidget {
  const CreateNewInterestForm(this.donationAndDonator);

  final DonationAndDonator donationAndDonator;

  @override
  _CreateNewInterestFormState createState() => _CreateNewInterestFormState();
}

class _CreateNewInterestFormState extends State<CreateNewInterestForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScrollableGradientBoxWithBack(
        context,
        'Enter Information Below',
        buildMyFormListView(_formKey, [
          ...buildNewInterestForm(),
          buildMyStandardButton('Submit', () {
            if (_formKey.currentState.saveAndValidate()) {
              var value = _formKey.currentState.value;
              Interest newInterest = Interest()
                ..formRead(value)
                ..donationId = widget.donationAndDonator.donation.id
                ..donatorId = widget.donationAndDonator.donator.id
                ..requesterId = provideAuthenticationModel(context).uid;
              doSnackbarOperation(
                  context,
                  'Submitting...',
                  'Successfully Submitted',
                  Api.newInterest(newInterest),
                  MySnackbarOperationBehavior.POP_TWO_AND_REFRESH);
            }
          }, centralized: true, fillWidth: false, textSize: 18)
        ]));
  }
}

class RequesterDonationsViewPage extends StatelessWidget {
  const RequesterDonationsViewPage(this.donationAndDonator);

  final DonationAndDonator donationAndDonator;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        title: 'Donation Information',
        body: Align(
            child: Builder(
                builder: (context) =>
                    buildMyStandardScrollableGradientBoxWithBack(
                        context,
                        donationAndDonator.donator.name,
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                  topRight: Radius.circular(20),
                                  topLeft: Radius.circular(20)),
                            ),
                            Expanded(
                              child: CupertinoScrollbar(
                                  child: SingleChildScrollView(
                                child: Container(
                                    padding: EdgeInsets.only(
                                        left: 9, right: 7, bottom: 7, top: 0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(bottom: 0),
                                        ),
                                        Text("Number of Meals Remaining"),
                                        Text(
                                            (donationAndDonator
                                                            .donation.numMeals -
                                                        donationAndDonator
                                                            .donation
                                                            .numMealsRequested)
                                                    .toString() +
                                                "/" +
                                                donationAndDonator
                                                    .donation.numMeals
                                                    .toString(),
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: EdgeInsets.only(bottom: 15),
                                        ),
                                        Text("Address of Meal Pickup Location"),
                                        Text(
                                            donationAndDonator
                                                .donation.streetAddress,
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: EdgeInsets.only(bottom: 15),
                                        ),
                                        Text("Date and Time of Meal Retrieval"),
                                        Text(
                                            donationAndDonator
                                                .donation.dateAndTime,
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: EdgeInsets.only(bottom: 15),
                                        ),
                                        Text("Address of Meal Pickup Location"),
                                        Text(
                                            donationAndDonator
                                                .donation.streetAddress,
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: EdgeInsets.only(bottom: 15),
                                        ),
                                        Text("Description"),
                                        Text(
                                            donationAndDonator
                                                .donation.description,
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: EdgeInsets.only(bottom: 15),
                                        ),
                                      ],
                                    )),
                              )),
                            ),
                            Container(
                              padding: EdgeInsets.only(bottom: 10),
                              child: buildMyNavigationButton(
                                  context, "Send Interest",
                                  route: "/requester/newInterestPage",
                                  arguments: donationAndDonator,
                                  textSize: 18,
                                  fillWidth: false,
                                  centralized: true),
                            )
                          ],
                        )))));
  }
}

class RequesterChangeUserInfoPrivatePage extends StatelessWidget {
  const RequesterChangeUserInfoPrivatePage(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        title: 'Edit Private Information',
        fontSize: 25,
        context: context,
        body: ChangePrivateRequesterInfoForm(id));
  }
}

class ChangePrivateRequesterInfoForm extends StatefulWidget {
  ChangePrivateRequesterInfoForm(this.id);

  final String id;

  @override
  _ChangePrivateRequesterInfoFormState createState() =>
      _ChangePrivateRequesterInfoFormState();
}

class _ChangePrivateRequesterInfoFormState
    extends State<ChangePrivateRequesterInfoForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<PrivateRequester>(
        api: Api.getPrivateRequester(widget.id),
        child: (context, data) {
          final List<Widget> children = [
            ...buildPrivateUserFormFields(),
            buildMyStandardButton('Save', () {
              if (_formKey.currentState.saveAndValidate()) {
                var value = _formKey.currentState.value;
                doSnackbarOperation(
                    context,
                    'Saving...',
                    'Successfully saved',
                    Api.editPrivateRequester(data..formRead(value)),
                    MySnackbarOperationBehavior.POP_ZERO);
              }
            })
          ];
          return buildMyFormListView(_formKey, children,
              initialValue: data.formWrite());
        });
  }
}

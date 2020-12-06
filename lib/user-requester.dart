import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'state.dart';
import 'main.dart';

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
    final originalContext = context;
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
                        status: request.status,
                        content:
                            'Number of Adult Meals: ${request.numMealsAdult}\nNumber of Child Meals: ${request.numMealsChild}\nDietary Restrictions: ${request.dietaryRestrictions}\n',
                        moreInfo: () => NavigationUtil.navigateWithRefresh(
                            originalContext,
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
                        status: interest.status,
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

class RequesterInterestsEditPage extends StatelessWidget {
  const RequesterInterestsEditPage(this.initialInfo);
  final InterestAndDonation initialInfo;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context, body: EditInterest(initialInfo), title: 'Edit');
  }
}

class EditInterest extends StatefulWidget {
  const EditInterest(this.initialInfo);
  final InterestAndDonation initialInfo;
  @override
  _EditInterestState createState() => _EditInterestState();
}

class _EditInterestState extends State<EditInterest> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return buildMyStandardScrollableGradientBoxWithBack(
        context,
        'Edit',
        buildMyFormListView(
            _formKey,
            [
              buildMyStandardTextFormField(
                  'requestedPickupDateAndTime', 'Desired Pickup Date and Time', buildContext: context),
              Text(
                  '${widget.initialInfo.donation.numMeals - widget.initialInfo.donation.numMealsRequested} meals are available'),
              buildMyStandardNumberFormField(
                  'numAdultMeals', 'Number of Adult Meals'),
              buildMyStandardNumberFormField(
                  'numChildMeals', 'Number of Child Meals'),
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
                                    originalContext,
                                    'Deleting interest...',
                                    'Interest deleted!',
                                    Api.deleteInterest(
                                        widget.initialInfo.interest),
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
            ],
            initialValue: widget.initialInfo.interest.formWrite()),
        buttonText: 'Save', buttonAction: () {
      if (_formKey.currentState.saveAndValidate()) {
        var value = _formKey.currentState.value;
        doSnackbarOperation(
            context,
            'Saving interest...',
            'Saved!',
            Api.editInterest(
                widget.initialInfo.interest, Interest()..formRead(value)),
            MySnackbarOperationBehavior.POP_ONE_AND_REFRESH);
      }
    });
  }
}

class RequesterInterestsViewPage extends StatefulWidget {
  const RequesterInterestsViewPage(this.interest);

  final Interest interest;

  @override
  _RequesterInterestsViewPageState createState() =>
      _RequesterInterestsViewPageState();
}

class _RequesterInterestsViewPageState
    extends State<RequesterInterestsViewPage> {
  String _title = 'Chat';

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        showProfileButton: false,
        context: context,
        body: ViewInterest(widget.interest, (x) => setState(() => _title = x)),
        title: _title);
  }
}

class ViewInterest extends StatelessWidget {
  const ViewInterest(this.interest, this.changeTitle);
  final Interest interest;
  final void Function(String) changeTitle;

  @override
  Widget build(BuildContext context) {
    final uid = provideAuthenticationModel(context).uid;
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) =>
          buildMyStandardStreamBuilder<RequesterViewInterestInfo>(
              api: Api.getStreamingRequesterViewInterestInfo(interest, uid),
              child: (context, x) {
                if (x.donation != null)
                  changeTitle(x.donation.donatorNameCopied);
                return Column(children: [
                  StatusInterface(
                      initialStatus: x.interest.status,
                      onStatusChanged: (newStatus) => doSnackbarOperation(
                          context,
                          'Changing status...',
                          'Status changed!',
                          Api.editInterest(x.interest, x.interest, newStatus))),
                  Expanded(
                      child:
                          ChatInterface(x.donator, x.messages, (message) async {
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
                    // no refresh, stream is used
                  })),
                  buildMyNavigationButtonWithRefresh(originalContext,
                      'Edit or delete', '/requester/interests/edit', refresh,
                      arguments: InterestAndDonation(x.interest, x.donation))
                ]);
              }),
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
    final originalContext = context;
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
      Expanded(
        child: buildMyStandardFutureBuilder<RequesterDonationListInfo>(
            api: Api.getRequesterDonationListInfo(uid),
            child: (context, result) {
              final authModel = provideAuthenticationModel(context);
              final alreadyInterestedDonations = Set<String>();
              for (final x in result.interests) {
                alreadyInterestedDonations.add(x.donationId);
              }
              final List<WithDistance<Donation>> filteredDonations = result
                  .donations
                  .map((x) => WithDistance<Donation>(
                      x,
                      calculateDistanceBetween(
                          authModel.requester.addressLatCoord,
                          authModel.requester.addressLngCoord,
                          x.donatorAddressLatCoordCopied,
                          x.donatorAddressLngCoordCopied)))
                  .where((x) =>
                      !alreadyInterestedDonations.contains(x.object.id) &&
                      x.distance < distanceThreshold)
                  .toList();

              if (filteredDonations.length == 0) {
                return buildMyStandardEmptyPlaceholderBox(
                    content: "No donations found nearby.");
              }

              return CupertinoScrollbar(
                child: ListView.builder(
                    itemCount: filteredDonations.length,
                    padding: EdgeInsets.only(
                        top: 10, bottom: 20, right: 15, left: 15),
                    itemBuilder: (BuildContext context, int index) {
                      final donation = filteredDonations[index].object;
                      final distance = filteredDonations[index].distance;
                      return buildMyStandardBlackBox(
                          title:
                              '${donation.donatorNameCopied} ${donation.dateAndTime}',
                          status: donation.status,
                          content:
                              'Number of meals available:${donation.numMeals - donation.numMealsRequested}\nDistance: $distance miles\nDescription: ${donation.description}\nMeals: ${donation.numMeals - donation.numMealsRequested}/${donation.numMeals}',
                          moreInfo: () => NavigationUtil.navigate(
                              originalContext,
                              '/requester/donations/view',
                              donation));
                    }),
              );
            }),
      )
    ]);
  }
}

class RequesterPublicRequestsViewPage extends StatefulWidget {
  const RequesterPublicRequestsViewPage(this.publicRequest);

  final PublicRequest publicRequest;

  @override
  _RequesterPublicRequestsViewPageState createState() =>
      _RequesterPublicRequestsViewPageState();
}

class _RequesterPublicRequestsViewPageState
    extends State<RequesterPublicRequestsViewPage> {
  String _title;

  @override
  void initState() {
    super.initState();
    _title = widget.publicRequest.donatorId == null ? 'Request' : 'Chat';
  }

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        showProfileButton: false,
        body: ViewPublicRequest(
            widget.publicRequest, (x) => setState(() => _title = x)),
        title: _title);
  }
}

class ViewPublicRequest extends StatelessWidget {
  const ViewPublicRequest(this.initialValue, this.changeTitle);

  final PublicRequest initialValue;
  final void Function(String) changeTitle;

  @override
  Widget build(BuildContext context) {
    final uid = provideAuthenticationModel(context).uid;
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) => buildMyStandardStreamBuilder<
              RequesterViewPublicRequestInfo>(
          api:
              Api.getStreamingRequesterViewPublicRequestInfo(initialValue, uid),
          child: (context, x) {
            if (x.donator != null) changeTitle(x.donator.name);
            return Column(children: [
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
                      : ChatInterface(x.donator, x.messages, (message) async {
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
                                // Pop the alert dialog
                                Navigator.of(context).pop();
                                doSnackbarOperation(
                                    originalContext,
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
              }),
              Padding(padding: EdgeInsets.only(bottom: 10))
            ]);
          }),
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
    return buildMyStandardScrollableGradientBoxWithBack(
      context,
      'Request Details',
      buildMyFormListView(
          _formKey,
          [
            buildMyStandardNumberFormField(
                'numMealsAdult', 'Number of meals (adult)'),
            buildMyStandardNumberFormField(
                'numMealsChild', 'Number of meals (child)'),
            buildMyStandardTextFormField(
                'dateAndTime', 'Date and time to receive meal', buildContext: context),
            buildMyStandardTextFormField(
                'dietaryRestrictions', 'Dietary restrictions', buildContext: context,
                validator: [],),
          ],
          initialValue: (PublicRequest()
                ..dietaryRestrictions = provideAuthenticationModel(context)
                    .requester
                    .dietaryRestrictions)
              .formWrite()),
      buttonText: 'Submit new request',
      buttonAction: () {
        if (_formKey.currentState.saveAndValidate()) {
          final value = _formKey.currentState.value;
          final authModel = provideAuthenticationModel(context);
          final requester = authModel.requester;
          final publicRequest = PublicRequest()
            ..formRead(value)
            ..requesterId = requester.id;
          requester.dietaryRestrictions = publicRequest.dietaryRestrictions;

          doSnackbarOperation(
              context,
              'Submitting request...',
              'Added request!',
              Api.newPublicRequest(publicRequest, authModel),
              MySnackbarOperationBehavior.POP_ONE);
        }
      },
    );
  }
}

class InterestNewPage extends StatelessWidget {
  const InterestNewPage(this.donation);

  final Donation donation;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
      context: context,
      title: 'New Interest',
      body: CreateNewInterestForm(this.donation),
    );
  }
}

class CreateNewInterestForm extends StatefulWidget {
  const CreateNewInterestForm(this.donation);

  final Donation donation;

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
          buildMyStandardTextFormField(
              'requestedPickupDateAndTime', 'Desired Pickup Date and Time', buildContext: context),
          Text(
              '${widget.donation.numMeals - widget.donation.numMealsRequested} meals are available'),
          buildMyStandardNumberFormField(
              'numAdultMeals', 'Number of Adult Meals'),
          buildMyStandardNumberFormField(
              'numChildMeals', 'Number of Child Meals')
        ]),
        buttonText: 'Submit', buttonAction: () {
      if (_formKey.currentState.saveAndValidate()) {
        var value = _formKey.currentState.value;
        Interest newInterest = Interest()
          ..formRead(value)
          ..donationId = widget.donation.id
          ..donatorId = widget.donation.donatorId
          ..requesterId = provideAuthenticationModel(context).uid;
        doSnackbarOperation(
            context,
            'Submitting...',
            'Successfully submitted!',
            Api.newInterest(newInterest),
            MySnackbarOperationBehavior.POP_TWO_AND_REFRESH);
      }
    });
  }
}

class RequesterDonationsViewPage extends StatelessWidget {
  const RequesterDonationsViewPage(this.donation);

  final Donation donation;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        title: 'Donation Information',
        body: Builder(
          builder: (context) => buildMyStandardScrollableGradientBoxWithBack(
              context,
              donation.donatorNameCopied,
              Column(children: [
                Text("Number of Meals Remaining"),
                Text(
                    (donation.numMeals - donation.numMealsRequested)
                            .toString() +
                        "/" +
                        donation.numMeals.toString(),
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: EdgeInsets.only(bottom: 15),
                ),
                Text("Date and Time of Meal Retrieval"),
                Text(donation.dateAndTime,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: EdgeInsets.only(bottom: 15),
                ),
                Text("Description"),
                Text(donation.description,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: EdgeInsets.only(bottom: 15),
                ),
              ]),
              buttonText: 'Send interest', buttonAction: () {
            NavigationUtil.navigate(
                context, "/requester/newInterestPage", donation);
          }),
        ));
  }
}

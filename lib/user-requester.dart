import 'package:flutter/cupertino.dart';
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
          '/requester/donationRequests/new', donation),
      buildMyNavigationButton(
          context, 'Open donor profile', '/donator', donation.donatorId)
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
                '/donator',
                data.donatorId,
              )
            ]);
  }
}

class RequesterPendingRequestsAndInterestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RequesterPendingRequestsAndInterestsView();
  }
}

class RequesterPendingRequestsAndInterestsView extends StatefulWidget {
  @override
  RequesterPendingRequestsAndInterestsViewState createState() =>
      RequesterPendingRequestsAndInterestsViewState();
}

class RequesterPendingRequestsAndInterestsViewState
    extends State<RequesterPendingRequestsAndInterestsView> {
  var showingRequests = true;

  void toggleShowingRequests() {
    setState(() {
      showingRequests = !showingRequests;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: CupertinoSwitch(
            value: showingRequests,
            onChanged: (value) {
              setState(() {
                showingRequests = value;
              });
            },
          ),
        ),
        showingRequests
            ? RequesterPendingRequestsView()
            : RequesterPendingInterestsView(),
      ],
    );
  }
}

class RequesterPendingRequestsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder(
        api: Api.getRequesterPublicRequests(
            provideAuthenticationModel(context).requesterId),
        child: (context, snapshotData) {
          if (snapshotData.length == 0) {
            return Container(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                "No Pending Requests",
                style: TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey),
              ),
            );
          }
          return Expanded(
            child: CupertinoScrollbar(
              child: ListView.builder(
                  itemCount: snapshotData.length,
                  padding:
                      EdgeInsets.only(top: 10, bottom: 20, right: 15, left: 15),
                  itemBuilder: (BuildContext context, int index) {
                    return _buildCustomRequest(context, snapshotData[index]);
                  }),
            ),
          );
        });
  }

  Widget _buildCustomRequest(BuildContext context, PublicRequest request) {
    return GestureDetector(
      onTap: () {
        NavigationUtil.navigate(context,
            '/requester/publicRequests/specificPublicRequestPage', request);
      },
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
                    "Date: " + request.dateAndTime,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        color: Colors.white),
                  ),
                  Container(padding: EdgeInsets.only(top: 3)),
                  Text("Number of Meals: " + request.numMeals.toString(),
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.white)),
                  Text("Number of Adult Meals: " + request.description,
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.white)),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: Row(children: [
                        Expanded(
                          child: Container(),
                        ),
                        Expanded(
                          child: buildMyNavigationButton(
                              context,
                              "More Info",
                              '/requester/publicRequests/specificPublicRequestPage',
                              request,
                              20 //TextSize (optional)
                              ),
                        ),
                      ]))
                ],
              ),
            ],
          )),
    );
  }
}

class SpecificPendingPublicRequestPage extends StatelessWidget {
  const SpecificPendingPublicRequestPage(this.request);

  final PublicRequest request;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(body: Container(
      child: Text("Jeffrey Look Here for Pending Public Request!"),
    ), title: 'Public Request', contextForBackButton: context);
  }
}

class RequesterPendingInterestsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder(
        api: Api.getInterestsByRequesterId(
            provideAuthenticationModel(context).requesterId),
        child: (context, snapshotData) {
          if (snapshotData.length == 0) {
            return Container(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                "No Pending Interests",
                style: TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey),
              ),
            );
          }
          return Expanded(
            child: CupertinoScrollbar(
              child: ListView.builder(
                  itemCount: snapshotData.length,
                  padding:
                      EdgeInsets.only(top: 10, bottom: 20, right: 15, left: 15),
                  itemBuilder: (BuildContext context, int index) {
                    return _buildInterest(context, snapshotData[index]);
                  }),
            ),
          );
        });
  }

//  Widget _buildInterest(BuildContext context, Interest interest){
//    return Container();

  Widget _buildInterest(BuildContext context, Interest interest) {
    return GestureDetector(
      onTap: () {
        NavigationUtil.navigate(
            context, '/requester/specificInterestPage', interest);
      },
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
                    "Date: " + interest.requestedPickupDateAndTime.toString(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        color: Colors.white),
                  ),
                  Container(padding: EdgeInsets.only(top: 3)),
                  Text("Address: " + interest.requestedPickupLocation,
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.white)),
                  Text(
                      "Number of Adult Meals: " +
                          interest.numAdultMeals.toString(),
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.white)),
                  Text(
                      "Number of Child Meals: " +
                          interest.numChildMeals.toString(),
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.white)),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: Row(children: [
                        Expanded(
                          child: Container(),
                        ),
                        Expanded(
                          child: buildMyNavigationButton(
                              context,
                              "More Info",
                              '/requester/specificInterestPage',
                              interest,
                              20 //TextSize (optional)
                              ),
                        ),
                      ]))
                ],
              ),
            ],
          )),
    );
  }
}

class SpecificPendingInterestPage extends StatelessWidget {
  const SpecificPendingInterestPage(this.interest);

  final Interest interest;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(contextForBackButton: context,
        body: Container(
      child: Text("Jeffrey Look Here for Pending Interest!"),
    ), title: 'Interest');
  }
}

class RequesterPublicDonationsNearRequesterListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PublicDonationsNearRequesterList();
  }
}

class PublicDonationsNearRequesterList extends StatefulWidget {
  @override
  _PublicDonationsNearRequesterListState createState() =>
      _PublicDonationsNearRequesterListState();
}

class _PublicDonationsNearRequesterListState
    extends State<PublicDonationsNearRequesterList> {
  _buildDonation(BuildContext context, Donation donation, Donator donator) {
    return GestureDetector(
      onTap: () {
        NavigationUtil.navigate(
            context,
            '/requester/publicDonations/specificPublicDonation',
            DonationAndDonator(donation, donator));
      },
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
                    donator.name + "  " + donation.dateAndTime,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        color: Colors.white),
                  ),
                  Container(padding: EdgeInsets.only(top: 3)),
                  Text("Address: " + donation.streetAddress,
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.white)),
                  Text("Description: " + donation.description,
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.white)),
//            Text("Date and Time: " + donation.dateAndTime, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white)),
                  Text(
                      "Meals:  " +
                          (donation.numMeals - donation.numMealsRequested)
                              .toString() +
                          "/" +
                          (donation.numMeals).toString(),
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.white)),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: Row(children: [
                        Expanded(
                          child: Container(),
                        ),
                        Expanded(
                          child: buildMyNavigationButton(
                              context,
                              "More Info",
                              '/requester/publicDonations/specificPublicDonation',
                              DonationAndDonator(donation, donator),
                              15 //TextSize (optional)
                              ),
                        ),
                      ]))
                ],
              ),
            ],
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
//    return buildMyStandardSliverCombo<PublicRequest>(
//        api: () => Api.getRequesterPublicRequests(
//            provideAuthenticationModel(context).requesterId),
//        titleText: null,
//        secondaryTitleText: null,
//        onTap: (data, index) {
//          return NavigationUtil.pushNamed(context, '/requester/publicRequests/view',
//              data[index]);
//        },
//        tileTitle: (data, index) => 'Date and time: ${data[index].dateAndTime}',
//        tileSubtitle: (data, index) =>
//            '${data[index].numMeals} meals / ${data[index].donationId == null ? 'UNFULFILLED' : 'FULFILLED'}',
//        tileTrailing: null,
//        floatingActionButton: () =>
//            NavigationUtil.pushNamed(context, '/requester/publicRequests/new')
//    );
    return Column(children: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 27, right: 5, top: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            (Text("Donations Near You",
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
            Spacer(),
            (buildMyNavigationButton(context, "New Request",
                '/requester/publicRequests/new', null, 18)),
            Container(
              padding: EdgeInsets.only(right: 5),
            )
          ],
        ),
      ),
      buildMyStandardFutureBuilder<List<Donation>>(
          api: Api.getAllDonations(),
          child: (context, snapshotData) {
            if (snapshotData.length == 0) {
              return Container(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "No donations found nearby.",
                  style: TextStyle(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey),
                ),
              );
            }
            return Expanded(
              child: CupertinoScrollbar(
                child: ListView.builder(
                    itemCount: snapshotData.length,
                    padding: EdgeInsets.only(
                        top: 10, bottom: 20, right: 15, left: 15),
                    itemBuilder: (BuildContext context, int index) {
                      return FutureBuilder<Donator>(
                          future: Api.getDonator(snapshotData[index].donatorId),
                          builder: (context, donatorSnapshot) {
                            if (donatorSnapshot.connectionState ==
                                ConnectionState.done)
                              return _buildDonation(context,
                                  snapshotData[index], donatorSnapshot.data);
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
    return Scaffold(
        appBar: AppBar(title: Text('Request')),
        body: ViewPublicRequest(publicRequest));
  }
}

class ViewPublicRequest extends StatelessWidget {
  const ViewPublicRequest(this.publicRequest);

  final PublicRequest publicRequest;

  @override
  Widget build(BuildContext context) {
    return MyRefreshableId<PublicRequest>(
        builder: (context, publicRequest, refresh) =>
            ListView(children: <Widget>[
              ...buildViewPublicRequestContent(publicRequest),
              if (publicRequest.donationId == null)
                ListTile(title: Text('Request has not yet been fulfilled.')),
              if (publicRequest.donationId == null)
                buildMyNavigationButtonWithRefresh(
                    context,
                    'Browse available meals',
                    '/requester/publicRequests/donations/list',
                    refresh,
                    publicRequest),
              if (publicRequest.donationId != null)
                ListTile(title: Text('Request has been fulfilled.')),
              if (publicRequest.committer != null &&
                  publicRequest.committer == UserType.REQUESTER)
                ListTile(
                    title:
                        Text('Pick up meal at the address of the donation.')),
              if (publicRequest.committer != null &&
                  publicRequest.committer == UserType.DONATOR)
                ListTile(
                    title: Text(
                        'Meal will be delivered to address specified in request.')),
              if (publicRequest.donationId != null)
                buildMyNavigationButtonWithRefresh(
                    context,
                    'View donation',
                    '/requester/publicRequests/donations/viewOld',
                    refresh,
                    PublicRequestAndDonationId(
                        publicRequest, publicRequest.donationId)),
              if (publicRequest.committer != null)
                buildMyStandardButton('Uncommit from donation', () async {
                  await doSnackbarOperation(
                      context,
                      'Uncommitting from donation...',
                      'Uncommitted from donation!',
                      Api.editPublicRequestCommitting(
                          publicRequest: publicRequest,
                          donation: null,
                          committer: null),
                      MySnackbarOperationBehavior.POP_ZERO);
                  refresh();
                }),
              buildMyNavigationButtonWithRefresh(context, 'Delete request',
                  '/requester/publicRequests/delete', refresh, publicRequest)
            ]),
        initialValue: publicRequest,
        api: () => Api.getPublicRequest(publicRequest.id));
  }
}

class RequesterPublicRequestsNewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
      contextForBackButton: context,
        title: 'New Request',
        body: NewPublicRequestForm());
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
      buildMyStandardTextFormField('address', 'Address'),
      buildMyStandardNumberFormField(
          'numMealsAdult', 'Number of meals (adults)'),
      buildMyStandardNumberFormField('numMealsKid', 'Number of meals (kids)'),
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
                  ..requesterId =
                      provideAuthenticationModel(context).requesterId),
                MySnackbarOperationBehavior.POP_ONE);
          }
        },
      )
    ];
    return buildMyFormListView(_formKey, children);
  }
}

class RequesterPublicRequestsDeletePage extends StatelessWidget {
  const RequesterPublicRequestsDeletePage(this.publicRequest);

  final PublicRequest publicRequest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Delete request')),
        body: DeletePublicRequest(publicRequest));
  }
}

class DeletePublicRequest extends StatelessWidget {
  const DeletePublicRequest(this.publicRequest);

  final PublicRequest publicRequest;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: buildStandardButtonColumn([
      buildMyStandardButton('Delete request', () async {
        doSnackbarOperation(
            context,
            'Deleting request...',
            'Request deleted!',
            Api.deletePublicRequest(publicRequest.id),
            MySnackbarOperationBehavior.POP_TWO_AND_REFRESH);
      }),
      buildMyNavigationButton(context, 'Go back')
    ]));
  }
}

class RequesterPublicRequestsDonationsList extends StatelessWidget {
  const RequesterPublicRequestsDonationsList(this.publicRequest);

  final PublicRequest publicRequest;

  @override
  Widget build(BuildContext context) {
    return PublicRequestDonationList(publicRequest);
  }
}

class PublicRequestDonationList extends StatelessWidget {
  const PublicRequestDonationList(this.publicRequest);

  final PublicRequest publicRequest;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardSliverCombo<Donation>(
        api: () => Api.getAllDonations(),
        titleText: 'View donations',
        secondaryTitleText: (data) => '${data.length} donations',
        onTap: (data, index) {
          return NavigationUtil.pushNamed(
              context,
              '/requester/publicRequests/donations/view',
              PublicRequestAndDonation(publicRequest, data[index]));
        },
        tileTitle: (data, index) => '${data[index].description}',
        tileSubtitle: (data, index) =>
            'Date and time: ${data[index].dateAndTime}\n${data[index].numMeals - data[index].numMealsRequested - publicRequest.numMeals < 0 ? 'INSUFFICIENT MEALS' : 'SUFFICIENT MEALS'}',
        tileTrailing: null,
        floatingActionButton: null);
  }
}

class RequesterPublicRequestsDonationsViewPage extends StatelessWidget {
  const RequesterPublicRequestsDonationsViewPage(this.publicRequestAndDonation);

  final PublicRequestAndDonation publicRequestAndDonation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Donation')),
        body: ViewPublicRequestDonation(publicRequestAndDonation));
  }
}

class ViewPublicRequestDonation extends StatelessWidget {
  const ViewPublicRequestDonation(this.publicRequestAndDonation);

  final PublicRequestAndDonation publicRequestAndDonation;

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      ...buildViewDonationContent(publicRequestAndDonation.donation),
      buildMyNavigationButton(
        context,
        'Open donor profile',
        '/donator',
        publicRequestAndDonation.donation.donatorId,
      ),
      buildMyStandardButton('Commit', () {
        doSnackbarOperation(
            context,
            'Committing to donation...',
            'Committed to donation!',
            Api.editPublicRequestCommitting(
                publicRequest: publicRequestAndDonation.publicRequest,
                donation: publicRequestAndDonation.donation,
                committer: UserType.REQUESTER),
            MySnackbarOperationBehavior.POP_TWO_AND_REFRESH);
      })
    ]);
  }
}

class RequesterChangeUserInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
      title: 'Edit Information', fontSize: 25,
        contextForBackButton: context,
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
        api: Api.getRequester(provideAuthenticationModel(context).requesterId),
        child: (context, data) {
          final List<Widget> children = [
            ...buildUserFormFields(),
            buildMyNavigationButton(context, 'Change private user info',
                '/requester/changeUserInfo/private', data.id),
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
  const InterestNewPage(this.donationIdAndRequesterId);

  final DonationIdAndRequesterId donationIdAndRequesterId;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
      contextForBackButton: context,
      title: 'New Interest',
      body: CreateNewInterestForm(this.donationIdAndRequesterId),
    );
  }
}

class CreateNewInterestForm extends StatefulWidget {
  const CreateNewInterestForm(this.donationIdAndRequesterId);

  final DonationIdAndRequesterId donationIdAndRequesterId;

  @override
  _CreateNewInterestFormState createState() => _CreateNewInterestFormState();
}

class _CreateNewInterestFormState extends State<CreateNewInterestForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<Requester>(
        api: Api.getRequester(widget.donationIdAndRequesterId.requesterId),
        child: (context, requesterData) {
          return buildMyStandardFutureBuilder(
              api: Api.getDonationById(
                  widget.donationIdAndRequesterId.donationId),
              child: (context, donationData) {
                final List<Widget> children = [
                  ...buildNewInterestForm(),
                  buildMyStandardButton('Submit', () {
                    if (_formKey.currentState.saveAndValidate()) {
                      var value = _formKey.currentState.value;
                      print(value.toString());
                      Interest newInterest = Interest()
                        ..donationId = donationData.id
                        ..requesterId = requesterData.id
                        ..status = Status.ACTIVE
                        ..numAdultMeals = value['numAdultMeals']
                        ..numChildMeals = value['numChildMeals']
                        ..requestedPickupLocation =
                            value['requestedPickupLocation']
                        ..requestedPickupDateAndTime =
                            value['requestedPickupDateAndTime'];
                      doSnackbarOperation(
                          context,
                          'Submitting...',
                          'Successfully Submitted',
                          Api.newInterest(newInterest),
                          MySnackbarOperationBehavior.POP_ONE);
                    }
                  })
                ];
                return buildMyFormListView(_formKey, children);
              });
        });
  }
}

class SpecificPublicDonationInfoPage extends StatelessWidget {
  const SpecificPublicDonationInfoPage(this.donationAndDonator);

  final DonationAndDonator donationAndDonator;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
      contextForBackButton: context,
        title: 'Donation Information',
        body: Align(
            child: Builder(
                builder: (context) => Container(
                      margin: EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: colorStandardGradient),
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
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                    topRight: Radius.circular(20),
                                    topLeft: Radius.circular(20)),
                                child: CupertinoScrollbar(
                                    child: SingleChildScrollView(
                                  child: Container(
                                      padding: EdgeInsets.all(7),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Text(
                                                donationAndDonator.donator.name,
                                                style: TextStyle(
                                                    fontSize: 50,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Container(
                                            padding:
                                                EdgeInsets.only(bottom: 15),
                                          ),
                                          Text("Number of Meals Remaining"),
                                          Text(
                                              (donationAndDonator.donation
                                                              .numMeals -
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
                                            padding:
                                                EdgeInsets.only(bottom: 15),
                                          ),
                                          Text(
                                              "Address of Meal Pickup Location"),
                                          Text(
                                              donationAndDonator
                                                  .donation.streetAddress,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                          Container(
                                            padding:
                                                EdgeInsets.only(bottom: 15),
                                          ),
                                          Text(
                                              "Date and Time of Meal Retrieval"),
                                          Text(
                                              donationAndDonator
                                                  .donation.dateAndTime,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                          Container(
                                            padding:
                                                EdgeInsets.only(bottom: 15),
                                          ),
                                          Text(
                                              "Address of Meal Pickup Location"),
                                          Text(
                                              donationAndDonator
                                                  .donation.streetAddress,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                          Container(
                                            padding:
                                                EdgeInsets.only(bottom: 15),
                                          ),
                                          Text("Description"),
                                          Text(
                                              donationAndDonator
                                                  .donation.description,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                          Container(
                                            padding:
                                                EdgeInsets.only(bottom: 15),
                                          ),
                                        ],
                                      )),
                                )),
                              ),
                            ),
                            Container(
                              child: GestureDetector(
                                  child: buildMyNavigationButton(
                                context,
                                "Send Interest",
                                "/requester/newInterestPage",
                                DonationIdAndRequesterId(
                                    donationAndDonator.donation.id,
                                    provideAuthenticationModel(context)
                                        .requesterId),
                              )),
                              padding: EdgeInsets.only(bottom: 8),
                            )
                          ],
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                    ))));
  }
}

class RequesterChangeUserInfoPrivatePage extends StatelessWidget {
  const RequesterChangeUserInfoPrivatePage(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        title: 'Edit Private Information', fontSize: 25,
        contextForBackButton: context,
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

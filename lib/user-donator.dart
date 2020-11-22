import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'main.dart';
import 'state.dart';

class DonatorDonationsNewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context, body: NewDonationForm(), title: 'New Donation');
  }
}

class NewDonationForm extends StatefulWidget {
  @override
  _NewDonationFormState createState() => _NewDonationFormState();
}

class _NewDonationFormState extends State<NewDonationForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScrollableGradientBoxWithBack(
        context,
        'Enter Information Below',
        buildMyFormListView(_formKey, [
          buildMyStandardNumberFormField('numMeals', 'Number of meals'),
          buildMyStandardTextFormField('dateAndTime', 'Date and time range'),
          buildMyStandardTextFormField('description', 'Food description'),
        ]),
        buttonText: 'Submit new donation', buttonAction: () {
      if (_formKey.currentState.saveAndValidate()) {
        var value = _formKey.currentState.value;
        doSnackbarOperation(
            context,
            'Adding new donation...',
            'Added new donation!',
            Api.newDonation(Donation()
              ..formRead(value)
              ..donatorId = provideAuthenticationModel(context).uid
              ..numMealsRequested = 0),
            MySnackbarOperationBehavior.POP_ONE);
      }
    });
  }
}

class DonatorDonationsViewPage extends StatelessWidget {
  const DonatorDonationsViewPage(this.donationAndInterests);

  final DonationAndInterests donationAndInterests;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        body: ViewDonation(donationAndInterests),
        title: 'Donation');
  }
}

class ViewDonation extends StatefulWidget {
  ViewDonation(this.initialValue);

  final DonationAndInterests initialValue;

  @override
  _ViewDonationState createState() => _ViewDonationState();
}

class _ViewDonationState extends State<ViewDonation> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return buildMyStandardScrollableGradientBoxWithBack(
        context,
        'Info',
        buildMyFormListView(
            _formKey,
            [
              buildMyStandardNumberFormField('numMeals', 'Number of meals'),
              buildMyStandardTextFormField('dateAndTime', 'Date and time'),
              buildMyStandardTextFormField('description', 'Description'),
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
                                    'Deleting donation...',
                                    'Donation deleted!',
                                    Api.deleteDonation(
                                        widget.initialValue.donation),
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
              // I decided that the extra queries are OK because there aren't that many interests on one page
              for (final interest in widget.initialValue.interests)
                FutureBuilder<Requester>(
                    future: Api.getRequester(interest.requesterId),
                    builder: (context, requesterSnapshot) {
                      if (requesterSnapshot.connectionState ==
                          ConnectionState.done) {
                        return buildMyStandardBlackBox(
                            title:
                                "${requesterSnapshot.data.name} Date: ${interest.requestedPickupDateAndTime}",
                            content:
                                "Address: ${interest.requestedPickupLocation}\nNumber of Adult Meals: ${interest.numAdultMeals}\nNumber of Child Meals: ${interest.numChildMeals}",
                            moreInfo: () => NavigationUtil.navigate(
                                context,
                                '/donator/donations/interests/view',
                                DonationInterestAndRequester(
                                    widget.initialValue.donation,
                                    interest,
                                    requesterSnapshot.data)));
                      }
                      return buildMyStandardLoader();
                    })
            ],
            initialValue: widget.initialValue.donation.formWrite()),
        buttonText: 'Save', buttonAction: () {
      if (_formKey.currentState.saveAndValidate()) {
        var value = _formKey.currentState.value;
        doSnackbarOperation(
            context,
            'Saving...',
            'Saved!',
            Api.editDonation(widget.initialValue.donation..formRead(value)),
            MySnackbarOperationBehavior.POP_ONE_AND_REFRESH);
      }
    });
  }
}

class DonatorDonationsInterestsViewPage extends StatelessWidget {
  const DonatorDonationsInterestsViewPage(this.initialValue);

  final DonationInterestAndRequester initialValue;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        body: DonationsInterestView(initialValue),
        title: 'Interest');
  }
}

class DonationsInterestView extends StatelessWidget {
  const DonationsInterestView(this.initialValue);

  final DonationInterestAndRequester initialValue;

  @override
  Widget build(BuildContext context) {
    final uid = provideAuthenticationModel(context).uid;
    return MyRefreshable(
      builder: (context, refresh) =>
          buildMyStandardStreamBuilder<DonatorViewInterestInfo>(
              api: Api.getStreamingDonatorViewInterestInfo(uid, initialValue),
              child: (context, x) => Column(children: [
                    StatusInterface(
                        initialStatus: x.interest.status,
                        onStatusChanged: (newStatus) => doSnackbarOperation(
                            context,
                            'Changing status...',
                            'Status changed!',
                            Api.editInterestStatus(x.interest, newStatus))),
                    Expanded(
                        child: ChatInterface(x.messages, (message) async {
                      await doSnackbarOperation(
                          context,
                          'Sending message...',
                          'Message sent!',
                          Api.newChatMessage(ChatMessage()
                            ..timestamp = DateTime.now()
                            ..speakerUid = uid
                            ..donatorId = uid
                            ..requesterId = x.requester.id
                            ..interestId = x.interest.id
                            ..message = message));
                      // A refresh is not necessary because a stream is used.
                    }))
                  ])),
    );
  }
}

class DonatorPublicRequestsViewPage extends StatelessWidget {
  const DonatorPublicRequestsViewPage(this.publicRequest);

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
  const ViewPublicRequest(this.publicRequest);

  final PublicRequest publicRequest;

  @override
  Widget build(BuildContext context) {
    final uid = provideAuthenticationModel(context).uid;
    return MyRefreshable(
      builder: (context, refresh) => buildMyStandardStreamBuilder<
              DonatorViewPublicRequestInfo>(
          api: Api.getStreamingDonatorViewPublicRequestInfo(publicRequest, uid),
          child: (context, x) => Column(children: [
                if (x.publicRequest.donatorId != null)
                  StatusInterface(
                      initialStatus: x.publicRequest.status,
                      onStatusChanged: (newStatus) => doSnackbarOperation(
                          context,
                          'Changing status...',
                          'Status changed!',
                          Api.editPublicRequest(
                              x.publicRequest..status = newStatus))),
                if (x.publicRequest.donatorId == null)
                  buildMyStandardButton(
                      'Accept Request',
                      () => doSnackbarOperation(
                          context,
                          'Accepting request...',
                          'Request accepted!',
                          Api.editPublicRequest(
                              x.publicRequest..donatorId = uid),
                          MySnackbarOperationBehavior.POP_ONE_AND_REFRESH)),
                if (x.publicRequest.donatorId != null)
                  buildMyStandardButton(
                      'Unaccept Request',
                      () => doSnackbarOperation(
                          context,
                          'Unaccepting request...',
                          'Request unaccepted!',
                          Api.editPublicRequest(
                              x.publicRequest..donatorId = null),
                          MySnackbarOperationBehavior.POP_ONE_AND_REFRESH)),
                if (x.publicRequest.donatorId != null)
                  Expanded(
                      child: ChatInterface(x.messages, (message) async {
                    await doSnackbarOperation(
                        context,
                        'Sending message...',
                        'Message sent!',
                        Api.newChatMessage(ChatMessage()
                          ..timestamp = DateTime.now()
                          ..speakerUid = uid
                          ..donatorId = uid
                          ..requesterId = x.publicRequest.requesterId
                          ..publicRequestId = x.publicRequest.id
                          ..message = message));
                    // no refresh, stream used
                  }))
              ])),
    );
  }
}

class DonatorPendingDonationsAndRequestsView extends StatefulWidget {
  const DonatorPendingDonationsAndRequestsView(this.controller);

  final TabController controller;

  @override
  _DonatorPendingDonationsAndRequestsViewState createState() =>
      _DonatorPendingDonationsAndRequestsViewState();
}

class _DonatorPendingDonationsAndRequestsViewState
    extends State<DonatorPendingDonationsAndRequestsView> {
  @override
  Widget build(BuildContext context) {
    return TabBarView(controller: widget.controller, children: [
      DonatorPendingDonationsList(),
      DonatorPendingRequestsList()
    ]);
  }
}

class DonatorPendingDonationsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) =>
          buildMyStandardFutureBuilder<DonatorPendingDonationsListInfo>(
              api: Api.getDonatorPendingDonationsListInfo(
                  provideAuthenticationModel(context).uid),
              child: (context, result) {
                if (result.donations.length == 0) {
                  return buildMyStandardEmptyPlaceholderBox(
                      content: 'No Donations');
                }
                final Map<String, int> numInterestsForDonation = {};
                for (final x in result.donations) {
                  numInterestsForDonation[x.id] = 0;
                }
                for (final x in result.interests) {
                  if (numInterestsForDonation.containsKey(x.donationId)) {
                    ++numInterestsForDonation[x.donationId];
                  }
                }
                return CupertinoScrollbar(
                  child: ListView.builder(
                      itemCount: result.donations.length,
                      padding: EdgeInsets.only(
                          top: 10, bottom: 20, right: 15, left: 15),
                      itemBuilder: (BuildContext context, int index) {
                        final x = result.donations[index];
                        return buildMyStandardBlackBox(
                            title: 'Date: ${x.dateAndTime}',
                            content:
                                'Number of Meals: ${x.numMeals}\nNumber of interests: ${numInterestsForDonation[x.id]}\n',
                            moreInfo: () => NavigationUtil.navigateWithRefresh(
                                originalContext,
                                '/donator/donations/view',
                                refresh,
                                DonationAndInterests(
                                    x,
                                    result.interests
                                        .where((interest) =>
                                            interest.donationId == x.id)
                                        .toList())));
                      }),
                );
              }),
    );
  }
}

class DonatorPendingRequestsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) => buildMyStandardFutureBuilder<
              List<PublicRequest>>(
          api: Api.getPublicRequestsByDonatorId(
              provideAuthenticationModel(context).uid),
          child: (context, result) {
            if (result.length == 0) {
              return buildMyStandardEmptyPlaceholderBox(content: 'No Requests');
            }
            return CupertinoScrollbar(
              child: ListView.builder(
                  itemCount: result.length,
                  padding:
                      EdgeInsets.only(top: 10, bottom: 20, right: 15, left: 15),
                  itemBuilder: (BuildContext context, int index) {
                    final x = result[index];
                    return buildMyStandardBlackBox(
                        title: 'Date: ${x.dateAndTime}',
                        content:
                            'Number of Adult Meals: ${x.numMealsAdult}\nNumber of Child Meals: ${x.numMealsChild}\nDietary Restrictions: ${x.dietaryRestrictions}',
                        moreInfo: () => NavigationUtil.navigateWithRefresh(
                            originalContext,
                            '/donator/publicRequests/view',
                            refresh,
                            x));
                  }),
            );
          }),
    );
  }
}

class DonatorPublicRequestList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) => Column(children: [
        Container(
          padding: EdgeInsets.only(left: 27, right: 5, top: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              (Text("Requests Near You",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
              Spacer(),
              Container(
                  child: buildMyNavigationButton(
                      originalContext, "New Donation",
                      route: '/donator/donations/new',
                      textSize: 15,
                      fillWidth: false)),
            ],
          ),
        ),
        Expanded(
          child: buildMyStandardFutureBuilder<List<PublicRequest>>(
              api: Api.getOpenPublicRequests(),
              child: (context, snapshotData) {
                final authModel = provideAuthenticationModel(context);
                final List<WithDistance<PublicRequest>> filteredRequests =
                    snapshotData
                        .map((x) => WithDistance<PublicRequest>(
                            x,
                            calculateDistanceBetween(
                                authModel.donator.addressLatCoord,
                                authModel.donator.addressLngCoord,
                                x.requesterAddressLatCoordCopied,
                                x.requesterAddressLngCoordCopied)))
                        .where((x) => x.distance < distanceThreshold)
                        .toList();

                if (filteredRequests.length == 0) {
                  return buildMyStandardEmptyPlaceholderBox(
                      content: "No requests found nearby.");
                }

                return CupertinoScrollbar(
                  child: ListView.builder(
                      itemCount: filteredRequests.length,
                      padding: EdgeInsets.only(
                          top: 10, bottom: 20, right: 15, left: 15),
                      itemBuilder: (BuildContext context, int index) {
                        final request = filteredRequests[index].object;
                        final distance = filteredRequests[index].distance;
                        return buildMyStandardBlackBox(
                            title:
                                '${request.requesterNameCopied} ${request.dateAndTime}',
                            content:
                                'Distance: $distance miles\nNumber of adult meals: ${request.numMealsAdult}\nNumber of child meals: ${request.numMealsChild}\nDietary restrictions: ${request.dietaryRestrictions}\n',
                            moreInfo: () => NavigationUtil.navigateWithRefresh(
                                originalContext,
                                '/donator/publicRequests/view',
                                refresh,
                                request));
                      }),
                );
              }),
        )
      ]),
    );
  }
}

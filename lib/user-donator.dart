import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'shared.dart';
import 'state.dart';
import 'geography.dart';
import 'ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

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
          ...buildMyStandardDateFormFields(context, 'date'),
          buildMyStandardTextFormField(
              'description', 'Food description (include dietary restrictions)',
              buildContext: context),
        ]),
        buttonText: 'Submit',
        buttonTextSignup: 'Sign up to submit',
        requiresSignUpToContinue: true, buttonAction: () {
      formSubmitLogic(
          _formKey,
          (formValue) => doSnackbarOperation(
              context,
              'Adding new donation...',
              'Added new donation!',
              Api.newDonation(Donation()
                ..formRead(formValue)
                ..donatorId = provideAuthenticationModel(context).uid
                ..numMealsRequested = 0
                ..status = Status.PENDING),
              MySnackbarOperationBehavior.POP_ONE));
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
    // The simplest way to handle concurrency issues involving the two places
    // to edit the donation is to introduce a lock.
    bool isApiLocked = false;

    return buildMyStandardScrollableGradientBoxWithBack(
        context,
        'Info',
        buildMyFormListView(
            _formKey,
            [
              StatusInterface(
                  initialStatus: widget.initialValue.donation.status,
                  onStatusChanged: (x) async {
                    if (isApiLocked) return;
                    isApiLocked = true;
                    try {
                      await Api.editDonation(
                          widget.initialValue.donation..status = x);
                    } catch (e) {} finally {
                      isApiLocked = false;
                    }
                  }),
              buildMyStandardNumberFormField('numMeals', 'Number of meals'),
              ...buildMyStandardDateFormFields(context, 'date'),
              buildMyStandardTextFormField('description', 'Description',
                  buildContext: context),
              Text('Interested Requesters', style: TextStyle(fontSize: 24)),
              if (widget.initialValue.interests.length == 0)
                buildMyStandardEmptyPlaceholderBox(
                    content:
                        'No requesters have expressed interest in your donation yet.'),
              // I decided that the extra queries are OK because there aren't that many interests on one page
              for (final interest in widget.initialValue.interests)
                FutureBuilder<Requester>(
                    future: Api.getRequester(interest.requesterId!),
                    builder: (context, requesterSnapshot) {
                      final data = requesterSnapshot.data;
                      if (requesterSnapshot.connectionState ==
                              ConnectionState.done &&
                          data != null) {
                        return buildMyStandardBlackBox(
                            title:
                                "${data.name} Date: ${datesToString(interest)}",
                            content:
                                "Address: ${interest.requestedPickupLocation}\nNumber of Adult Meals: ${interest.numAdultMeals}\nNumber of Child Meals: ${interest.numChildMeals}",
                            status: interest.status,
                            moreInfo: () => NavigationUtil.navigate(
                                originalContext,
                                '/donator/donations/interests/view',
                                DonationInterestAndRequester(
                                    widget.initialValue.donation,
                                    interest,
                                    data)));
                      }
                      return buildMyStandardLoader();
                    })
            ],
            initialValue: widget.initialValue.donation.formWrite()),
        buttonText: 'Save', buttonAction: () async {
      if (isApiLocked) return;
      isApiLocked = true;
      try {
        formSubmitLogic(
            _formKey,
            (formValue) => doSnackbarOperation(
                originalContext,
                'Saving...',
                'Saved!',
                Api.editDonation(
                    widget.initialValue.donation..formRead(formValue)),
                MySnackbarOperationBehavior.POP_ONE_AND_REFRESH));
      } catch (e) {} finally {
        isApiLocked = false;
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
        title: 'Chat with ${initialValue.donation.donatorNameCopied}',
        showProfileButton: false,
        reportButtonAction: (context) => NavigationUtil.navigate(
            context, '/reportUser', initialValue.requester.id));
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
              api: Api.getStreamingDonatorViewInterestInfo(uid!, initialValue),
              child: (context, x) => Column(children: [
                    StatusInterface(
                        initialStatus: x.interest!.status,
                        onStatusChanged: (newStatus) => doSnackbarOperation(
                            context,
                            'Changing status...',
                            'Status changed!',
                            Api.editInterest(
                                x.interest, x.interest!, newStatus))),
                    Expanded(
                        child: ChatInterface(x.requester, x.messages,
                            (message) async {
                      await doSnackbarOperation(
                          context,
                          'Sending message...',
                          'Message sent!',
                          Api.newChatMessage(ChatMessage()
                            ..timestamp = DateTime.now()
                            ..speakerUid = uid
                            ..donatorId = uid
                            ..requesterId = x.requester!.id
                            ..interestId = x.interest!.id
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
    final dietaryRestr = publicRequest.dietaryRestrictions.toString();
    final moreInfo = buildMoreInfo([
      ["Number of adult meals", publicRequest.numMealsAdult.toString()],
      ["Number of child meals", publicRequest.numMealsChild.toString()],
      ["Dietary restrictions", dietaryRestr == '' ? 'None' : dietaryRestr]
    ]);

    return buildMyStandardScaffold(
        context: context,
        showProfileButton: false,
        infoButtonAction: publicRequest.donatorId == null
            ? null
            : () => NavigationUtil.navigate(
                context, '/donator/publicRequests/view/moreInfo', moreInfo),
        body: ViewPublicRequest(publicRequest, moreInfo),
        title: publicRequest.donatorId == null
            ? 'Request'
            : 'Chat with ${publicRequest.requesterNameCopied}');
  }
}

class ViewPublicRequest extends StatelessWidget {
  const ViewPublicRequest(this.publicRequest, this.moreInfo);

  final PublicRequest publicRequest;
  final Widget moreInfo;

  @override
  Widget build(BuildContext context) {
    final auth = provideAuthenticationModel(context);
    final uid = auth.uid;
    return MyRefreshable(
      builder: (context, refresh) => buildMyStandardStreamBuilder<
              ViewPublicRequestInfo<Requester>>(
          api: Api.getStreamingDonatorViewPublicRequestInfo(publicRequest, uid),
          child: (context, x) => x.publicRequest.donatorId == null
              ? buildMyStandardScrollableGradientBoxWithBack(
                  context, 'More info', moreInfo,
                  requiresSignUpToContinue: true,
                  buttonText: 'Accept',
                  buttonTextSignup: 'Sign up to accept',
                  buttonAction: () => doSnackbarOperation(
                      context,
                      'Accepting request...',
                      'Request accepted!',
                      Api.editPublicRequest(x.publicRequest..donatorId = uid),
                      MySnackbarOperationBehavior.POP_ONE_AND_REFRESH))
              : Column(children: [
                  StatusInterface(
                      initialStatus: x.publicRequest.status,
                      onStatusChanged: (newStatus) => doSnackbarOperation(
                          context,
                          'Changing status...',
                          'Status changed!',
                          Api.editPublicRequest(
                              x.publicRequest..status = newStatus))),
                  buildMyStandardButton(
                      'Unaccept Request',
                      () => doSnackbarOperation(
                          context,
                          'Unaccepting request...',
                          'Request unaccepted!',
                          Api.editPublicRequest(
                              x.publicRequest..donatorId = null),
                          MySnackbarOperationBehavior.POP_ONE_AND_REFRESH)),
                  Expanded(
                      child: ChatInterface(
                          x.otherUser,
                          x.messages,
                          (message) => doSnackbarOperation(
                              context,
                              'Sending message...',
                              'Message sent!',
                              Api.newChatMessage(ChatMessage()
                                ..timestamp = DateTime.now()
                                ..speakerUid = uid
                                ..donatorId = uid
                                ..requesterId = x.publicRequest.requesterId
                                ..publicRequestId = x.publicRequest.id
                                ..message = message))
                          // no refresh, stream used
                          ))
                ])),
    );
  }
}

class DonatorPublicRequestsViewMoreInfoPage extends StatelessWidget {
  const DonatorPublicRequestsViewMoreInfoPage(this.moreInfo);

  final Widget moreInfo;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScrollableGradientBoxWithBack(
        context, 'More info', moreInfo);
  }
}

class DonatorPendingDonationsAndRequestsView extends StatefulWidget {
  const DonatorPendingDonationsAndRequestsView(this.controller);

  final TabController? controller;

  @override
  _DonatorPendingDonationsAndRequestsViewState createState() =>
      _DonatorPendingDonationsAndRequestsViewState();
}

class _DonatorPendingDonationsAndRequestsViewState
    extends State<DonatorPendingDonationsAndRequestsView> {
  @override
  Widget build(BuildContext context) {
    return TabBarView(controller: widget.controller!, children: [
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
                  provideAuthenticationModel(context).uid!),
              child: (context, result) {
                if (result.donations.length == 0) {
                  return buildMyStandardEmptyPlaceholderBox(
                      content: 'No Donations');
                }
                final Map<String?, int> numInterestsForDonation = {};
                for (final x in result.donations) {
                  numInterestsForDonation[x.id] = 0;
                }
                for (final x in result.interests) {
                  if (numInterestsForDonation.containsKey(x.donationId)) {
                    numInterestsForDonation[x.donationId] =
                        numInterestsForDonation[x.donationId]! + 1;
                  }
                }
                return buildSplitHistory<Donation>(
                    result.donations,
                    (x) => buildMyStandardBlackBox(
                        title: 'Date: ${datesToString(x)}',
                        status: x.status,
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
                                    .toList()))));
              }),
    );
  }
}

class DonatorPendingRequestsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return MyRefreshable(
        builder: (context, refresh) =>
            buildMyStandardFutureBuilder<List<PublicRequest>>(
                api: Api.getPublicRequestsByDonatorId(
                    provideAuthenticationModel(context).uid!),
                child: (context, result) {
                  if (result.length == 0) {
                    return buildMyStandardEmptyPlaceholderBox(
                        content: 'No Requests');
                  }
                  return buildSplitHistory(
                      result,
                      (dynamic x) => buildMyStandardBlackBox(
                          title: 'Date: ${datesToString(x)}',
                          status: x.status,
                          content:
                              'Number of Adult Meals: ${x.numMealsAdult}\nNumber of Child Meals: ${x.numMealsChild}\nDietary Restrictions: ${x.dietaryRestrictions}',
                          moreInfo: () => NavigationUtil.navigateWithRefresh(
                              originalContext,
                              '/donator/publicRequests/view',
                              refresh,
                              x)));
                }));
  }
}

class DonatorPublicRequestList extends StatefulWidget {
  @override
  _DonatorPublicRequestListState createState() =>
      _DonatorPublicRequestListState();
}

class _DonatorPublicRequestListState extends State<DonatorPublicRequestList> {
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
                  child: buildMyNavigationButtonWithRefresh(originalContext,
                      "New Donation", '/donator/donations/new', refresh,
                      textSize: 13, fillWidth: false)),
            ],
          ),
        ),
        Expanded(
            child: buildMyStandardFutureBuilder<List<PublicRequest>>(
                api: Api.getOpenPublicRequests(),
                child: (context, snapshotData) {
                  final authModel = provideAuthenticationModel(context);
                  final List<
                      WithDistance<PublicRequest>> filteredRequests = authModel
                              .donator ==
                          null
                      ? snapshotData
                          .map(((x) => WithDistance<PublicRequest>(x, null)))
                          .toList()
                      : snapshotData
                          .map(((x) => WithDistance<PublicRequest>(
                              x,
                              calculateDistanceBetween(
                                  authModel.donator!.addressLatCoord as double,
                                  authModel.donator!.addressLngCoord as double,
                                  x.requesterAddressLatCoordCopied as double,
                                  x.requesterAddressLngCoordCopied as double))))
                          .where(((x) => x.distance! < distanceThreshold))
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
                            String placemark = 'unavailable';
                            return StatefulBuilder(
                                builder: (context, innerSetState) {
                              if (distance == null) {
                                coordToPlacemarkStringWithCache(
                                        request.requesterAddressLatCoordCopied
                                            as double,
                                        request.requesterAddressLngCoordCopied
                                            as double)
                                    .then((x) {
                                  if (x != null && mounted) {
                                    innerSetState(() => placemark = x);
                                  }
                                });
                              }
                              return buildMyStandardBlackBox(
                                  title:
                                      '${request.requesterNameCopied} ${datesToString(request)}',
                                  status: request.status,
                                  content:
                                      'Distance: ${distance == null ? placemark : '$distance miles'}\nNumber of adult meals: ${request.numMealsAdult}\nNumber of child meals: ${request.numMealsChild}\nDietary restrictions: ${request.dietaryRestrictions}\n',
                                  moreInfo: () =>
                                      NavigationUtil.navigateWithRefresh(
                                          originalContext,
                                          '/donator/publicRequests/view',
                                          refresh,
                                          request));
                            });
                          }));
                })),
      ]),
    );
  }
}

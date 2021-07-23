import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'state.dart';
import 'shared.dart';
import 'geography.dart';
import 'ui.dart';

class RequesterPendingRequestsAndInterestsView extends StatefulWidget {
  const RequesterPendingRequestsAndInterestsView(this.controller);

  final TabController? controller;

  @override
  RequesterPendingRequestsAndInterestsViewState createState() =>
      RequesterPendingRequestsAndInterestsViewState();
}

class RequesterPendingRequestsAndInterestsViewState
    extends State<RequesterPendingRequestsAndInterestsView> {
  @override
  Widget build(BuildContext context) {
    return TabBarView(controller: widget.controller!, children: [
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
      builder: (context, refresh) =>
          buildMyStandardFutureBuilder<List<PublicRequest>>(
              api: Api.getRequesterPublicRequests(
                  provideAuthenticationModel(context).uid),
              child: (context, snapshotData) {
                if (snapshotData.length == 0) {
                  return buildMyStandardEmptyPlaceholderBox(
                      content: 'No Pending Requests');
                }
                return buildSplitHistory<PublicRequest>(
                    snapshotData,
                    (request) => buildMyStandardBlackBox(
                        title: 'Date: ${datesToString(request)}',
                        status: request.status,
                        content:
                            'Number of Adult Meals: ${request.numMealsAdult}\nNumber of Child Meals: ${request.numMealsChild}\nDietary Restrictions: ${request.dietaryRestrictions}\n',
                        moreInfo: () => NavigationUtil.navigateWithRefresh(
                            originalContext,
                            '/requester/publicRequests/view',
                            refresh,
                            request)));
              }),
    );
  }
}

class RequesterPendingInterestsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) =>
          buildMyStandardFutureBuilder<List<Interest>>(
              api: Api.getInterestsByRequesterId(
                  provideAuthenticationModel(context).uid!),
              child: (context, snapshotData) {
                if (snapshotData.length == 0) {
                  return buildMyStandardEmptyPlaceholderBox(
                      content: 'No Pending Interests');
                }
                return buildSplitHistory(
                    snapshotData,
                    (dynamic interest) => buildMyStandardBlackBox(
                        title: "Date: " + datesToString(interest),
                        status: interest.status,
                        content:
                            "Address: ${interest.requestedPickupLocation}\nNumber of Adult Meals: ${interest.numAdultMeals}\nNumber of Child Meals: ${interest.numChildMeals}",
                        moreInfo: () => NavigationUtil.navigateWithRefresh(
                            originalContext,
                            '/requester/interests/view',
                            refresh,
                            interest)));
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
    // final originalContext = context;
    return buildMyStandardScrollableGradientBoxWithBack(
        context,
        'Edit',
        buildMyFormListView(
            _formKey,
            [
              buildMyStandardTextFormField(
                  'requestedPickupDateAndTime', 'Desired Pickup Date and Time',
                  buildContext: context),
              Text(
                  '${widget.initialInfo.donation!.numMeals! - widget.initialInfo.donation!.numMealsRequested!} meals are available'),
              buildMyStandardNumberFormField(
                  'numAdultMeals', 'Number of Adult Meals'),
              buildMyStandardNumberFormField(
                  'numChildMeals', 'Number of Child Meals'),
            ],
            initialValue: widget.initialInfo.interest!.formWrite()),
        buttonText: 'Save',
        buttonAction: () => formSubmitLogic(
            _formKey,
            (formValue) => doSnackbarOperation(
                context,
                'Saving interest...',
                'Saved!',
                Api.editInterest(widget.initialInfo.interest,
                    Interest()..formRead(formValue)),
                MySnackbarOperationBehavior.POP_ONE_AND_REFRESH)));
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
  Stream<RequesterViewInterestInfo>? _api;

  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    final uid = provideAuthenticationModel(context).uid;
    if (_api == null) {
      _api = Api.getStreamingRequesterViewInterestInfo(widget.interest, uid!);
    }

    return MyRefreshable(
        builder: (context, refresh) =>
            buildMyStandardStreamBuilder<RequesterViewInterestInfo>(
                api: _api!,
                child: (context, x) => buildMyStandardScaffold(
                    showProfileButton: false,
                    context: context,
                    title: x.donation?.donatorNameCopied ?? 'Chat',
                    body: Column(children: [
                      StatusInterface(
                          initialStatus: x.interest!.status,
                          onStatusChanged: (newStatus) => doSnackbarOperation(
                              context,
                              'Changing status...',
                              'Status changed!',
                              Api.editInterest(
                                  x.interest, x.interest!, newStatus))),
                      Expanded(
                          child: ChatInterface(x.donator, x.messages,
                              (message) async {
                        await doSnackbarOperation(
                            context,
                            'Sending message...',
                            'Message sent!',
                            Api.newChatMessage(ChatMessage()
                              ..timestamp = DateTime.now()
                              ..speakerUid = uid
                              ..donatorId = x.donator!.id
                              ..requesterId = uid
                              ..interestId = x.interest!.id
                              ..message = message));
                        // no refresh, stream is used
                      })),
                      buildMyNavigationButtonWithRefresh(originalContext,
                          'Edit', '/requester/interests/edit', refresh,
                          arguments:
                              InterestAndDonation(x.interest, x.donation))
                    ]))));
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
    final isGuest = provideAuthenticationModel(context).state ==
        AuthenticationModelState.GUEST;
    final uid = isGuest ? null : provideAuthenticationModel(context).uid;
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
              final alreadyInterestedDonations = Set<String?>();
              if (result.interests != null)
                for (final x in result.interests!) {
                  alreadyInterestedDonations.add(x.donationId);
                }
              final List<WithDistance<Donation>> filteredDonations = authModel
                          .requester ==
                      null
                  ? result.donations!
                      .map(((x) => WithDistance<Donation>(x, null)))
                      .toList()
                  : result.donations!
                      .map(((x) => WithDistance<Donation>(
                          x,
                          calculateDistanceBetween(
                              authModel.requester!.addressLatCoord as double,
                              authModel.requester!.addressLngCoord as double,
                              x.donatorAddressLatCoordCopied as double,
                              x.donatorAddressLngCoordCopied as double))))
                      .where(((x) =>
                          !alreadyInterestedDonations.contains(x.object.id) &&
                          x.distance! < distanceThreshold))
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
                      String placemark = 'unavailable';
                      return StatefulBuilder(builder: (context, innerSetState) {
                        if (distance == null) {
                          coordToPlacemarkStringWithCache(
                                  donation.donatorAddressLatCoordCopied
                                      as double,
                                  donation.donatorAddressLngCoordCopied
                                      as double)
                              .then((x) {
                            if (x != null && mounted) {
                              innerSetState(() => placemark = x);
                            }
                          });
                        }
                        return buildMyStandardBlackBox(
                            title:
                                '${donation.donatorNameCopied} ${datesToString(donation)}',
                            status: donation.status,
                            content:
                                'Distance: ${distance == null ? placemark : '$distance miles'}\nDescription: ${donation.description}\nMeals: ${donation.numMeals! - donation.numMealsRequested!}/${donation.numMeals}',
                            moreInfo: () => NavigationUtil.navigate(
                                originalContext,
                                '/requester/donations/view',
                                donation));
                      });
                    }),
              );
            }),
      ),
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
  Stream<ViewPublicRequestInfo<Donator>>? _stream;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final uid = provideAuthenticationModel(context).uid;
    if (_stream == null) {
      _stream = Api.getStreamingRequesterViewPublicRequestInfo(
          widget.publicRequest, uid);
    }
    return MyRefreshable(
        builder: (context, refresh) =>
            buildMyStandardStreamBuilder<ViewPublicRequestInfo<Donator>>(
                api: _stream!,
                child: (context, x) => buildMyStandardScaffold(
                    context: context,
                    showProfileButton: false,
                    title: x.otherUser?.name ??
                        (widget.publicRequest.donatorId == null
                            ? 'Request'
                            : 'Chat'),
                    body: Column(children: [
                      if (x.otherUser != null)
                        StatusInterface(
                            initialStatus: x.publicRequest.status,
                            unacceptDonator: () => doSnackbarOperation(
                                context,
                                'Unaccepting donor...',
                                'Unaccepted donor!',
                                Api.editPublicRequest(
                                    x.publicRequest..donatorId = null)),
                            onStatusChanged: (newStatus) => doSnackbarOperation(
                                context,
                                'Changing status...',
                                'Status changed!',
                                Api.editPublicRequest(
                                    x.publicRequest..status = newStatus))),
                      Expanded(
                          child: x.otherUser == null
                              ? buildMyStandardEmptyPlaceholderBox(
                                  content: 'Waiting for donor')
                              : ChatInterface(x.otherUser, x.messages,
                                  (message) async {
                                  await doSnackbarOperation(
                                      context,
                                      'Sending message...',
                                      'Message sent!',
                                      Api.newChatMessage(ChatMessage()
                                        ..timestamp = DateTime.now()
                                        ..speakerUid = uid
                                        ..donatorId = x.otherUser!.id
                                        ..requesterId = uid
                                        ..publicRequestId = x.publicRequest.id
                                        ..message = message));
                                  refresh();
                                })),
                      Padding(padding: EdgeInsets.only(bottom: 10))
                    ]))));
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
        'Details',
        buildMyFormListView(
            _formKey,
            [
              buildMyStandardNumberFormField(
                  'numMealsAdult', 'Number of meals (adult)'),
              buildMyStandardNumberFormField(
                  'numMealsChild', 'Number of meals (child)'),
              ...buildMyStandardDateFormFields(context, 'date'),
              buildMyStandardTextFormField(
                'dietaryRestrictions',
                'Dietary restrictions',
                buildContext: context,
                validator: [],
              ),
            ],
            initialValue: (PublicRequest()
                  ..dietaryRestrictions = provideAuthenticationModel(context)
                      .requester
                      ?.dietaryRestrictions)
                .formWrite()),
        buttonText: 'Submit',
        buttonTextSignup: 'Sign up to submit',
        requiresSignUpToContinue: true,
        buttonAction: () => formSubmitLogic(_formKey, (formValue) {
              final authModel = provideAuthenticationModel(context);
              final requester = authModel.requester!;
              final publicRequest = PublicRequest()
                ..formRead(formValue)
                ..requesterId = requester.id;
              requester.dietaryRestrictions = publicRequest.dietaryRestrictions;

              doSnackbarOperation(
                  context,
                  'Submitting request...',
                  'Added request!',
                  Api.newPublicRequest(publicRequest, authModel),
                  MySnackbarOperationBehavior.POP_ONE);
            }));
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
          ...buildMyStandardDateFormFields(
            context,
            'requestedPickupDate',
            labelTextBegin: 'Requested pickup date and time (begin)',
            labelTextEnd: 'Requested pickup date and time (end)',
          ),
          SizedBox(height: 20),
          Text(
              '${widget.donation.numMeals! - widget.donation.numMealsRequested!} meals are available',
              style: TextStyle(fontSize: 20)),
          buildMyStandardNumberFormField(
              'numAdultMeals', 'Number of Adult Meals'),
          buildMyStandardNumberFormField(
              'numChildMeals', 'Number of Child Meals')
        ]),
        buttonText: 'Submit',
        requiresSignUpToContinue: true,
        buttonAction: () => formSubmitLogic(
            _formKey,
            (formValue) => doSnackbarOperation(
                context,
                'Submitting...',
                'Successfully submitted!',
                Api.newInterest(Interest()
                  ..formRead(formValue)
                  ..donationId = widget.donation.id
                  ..donatorId = widget.donation.donatorId
                  ..requesterId = provideAuthenticationModel(context).uid),
                MySnackbarOperationBehavior.POP_TWO_AND_REFRESH)));
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
              donation.donatorNameCopied!,
              buildMoreInfo([
                [
                  "Number of Meals Remaining",
                  "${donation.numMeals! - donation.numMealsRequested!}/${donation.numMeals}"
                ],
                ["Date and Time of Meal Retrieval", datesToString(donation)],
                ["Description", donation.description],
              ]),
              buttonText: 'Send interest', buttonAction: () {
            NavigationUtil.navigate(
                context, "/requester/newInterestPage", donation);
          }),
        ));
  }
}

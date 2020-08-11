import 'dart:ffi';

import 'package:flutter/material.dart';
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

class RequesterPublicRequestsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PublicRequestList();
  }
}

class PublicRequestList extends StatefulWidget {
  @override
  _PublicRequestListState createState() => _PublicRequestListState();
}

class _PublicRequestListState extends State<PublicRequestList> {
  _buildDonation(BuildContext context, String dateAndTime, String description, int numMeals, String donator, int numMealsRequested, String streetAddress){
    return Container(
      margin: EdgeInsets.only(top: 8.0, bottom: 8.0),
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepOrange, Colors.purple]),
        borderRadius: BorderRadius.all(Radius.circular(15))
      ),
      child: Column(
        children: [
          Text("Donor: " + donator),
          Text("Number of Meals: " + (numMealsRequested).toString() + "/" + (numMeals).toString()),
          Text("Description: " + description),
          Text("Address: " + streetAddress),
          Text("Date and Time: " + dateAndTime),
          Row(
            children: [
              Spacer(),
              buildMyNavigationButton(context, "More Info", '/requester/publicDonations/specificPublicDonation')
            ],
          )
        ],
      ),
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
    return Column(
      children:
        [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:
            [
//              (
//                  buildMyNavigationButton(context, "Filter", '/requester/publicDonations/filter')
//              ),
              (
                Spacer()
              ),
              (
                buildMyNavigationButton(context, "Custom Request", '/requester/publicRequests/new')
              ),
            ],
          ),
//          Expanded(
//            child: ListView.builder(
//                  scrollDirection: Axis.vertical,
//                  shrinkWrap: true,
//                  itemCount: 4,
//                  padding: EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 5),
//                  itemBuilder: (BuildContext context, int index) {
//                    return _buildDonation(context, "dateAndTime", "description", 2, "donator", 1, "streetAddress");
//                  }
//              ),
//          )

//          _buildDonation(context, "dateAndTime", "description", 2, "donator", 1, "streetAddress"),
//          _buildDonation(context, "dateAndTime", "description", 2, "donator", 1, "streetAddress")
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 10, right: 10, top: 10),
            padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.deepOrange, Colors.purple]),
              borderRadius: BorderRadius.all(Radius.circular(12))
    ),
            child: Text(
              "Donations Near You",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )
          ),
          FutureBuilder(
            future: Api.getAllDonations(),
            builder: (context, snapshot){
              if(snapshot.connectionState == ConnectionState.done) {
                print("Length of All Donations: " + snapshot.data.length.toString());
                print("Snapshot Data: " + snapshot.data.toString());
                return Expanded(
                  child: ListView.builder(
                      itemCount: snapshot.data.length,
                      padding: EdgeInsets.only(top: 10, bottom: 20, right: 10, left: 10),
                      itemBuilder: (BuildContext context, int index) {
                        return _buildDonation(
                            context,
                            snapshot.data[index].dateAndTime,
                            snapshot.data[index].description,
                            snapshot.data[index].numMeals,
                            snapshot.data[index].donatorId,
                            snapshot.data[index].numMealsRequested,
                            snapshot.data[index].streetAddress
                        );
                      }
                  ),
                );
              } else {
                return CircularProgressIndicator();
              }
            },
          )
        ]
    );
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
        builder: (context, publicRequest, refresh) => ListView(children: <Widget>[
                  ...buildViewPublicRequestContent(publicRequest),
                  if (publicRequest.donationId == null)
                    ListTile(
                        title: Text('Request has not yet been fulfilled.')),
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
                        title: Text(
                            'Pick up meal at the address of the donation.')),
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
                              committer: null), MySnackbarOperationBehavior.POP_ZERO);
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
    return Scaffold(
        appBar: AppBar(title: Text('New request')),
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
      buildMyStandardNumberFormField('numMealsAdult', 'Number of meals (adults)'),
      buildMyStandardNumberFormField('numMealsKid', 'Number of meals (kids)'),
      buildMyStandardTextFormField(
          'dateAndTime', 'Date and time to receive meal'),
      buildMyStandardTextFormField('dietaryRestrictions', 'Dietary restrictions', validators: []),
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
                      provideAuthenticationModel(context).requesterId), MySnackbarOperationBehavior.POP_ONE_AND_REFRESH);
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
        doSnackbarOperation(context, 'Deleting request...', 'Request deleted!',
            Api.deletePublicRequest(publicRequest.id), MySnackbarOperationBehavior.POP_TWO_AND_REFRESH);
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
              context, '/requester/publicRequests/donations/view',
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
                committer: UserType.REQUESTER), MySnackbarOperationBehavior.POP_TWO_AND_REFRESH);
      })
    ]);
  }
}

class RequesterChangeUserInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Change user info')),
        body: ChangeRequesterInfoForm());
  }
}

class ChangeRequesterInfoForm extends StatefulWidget {
  @override
  _ChangeRequesterInfoFormState createState() => _ChangeRequesterInfoFormState();
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
                doSnackbarOperation(context, 'Saving...', 'Successfully saved',
                    Api.editRequester(data..formRead(value)), MySnackbarOperationBehavior.POP_ZERO);
              }
            })
          ];
          return buildMyFormListView(_formKey, children,
              initialValue: data.formWrite());
        });
  }
}

class SpecificPublicDonationInfoPage extends StatelessWidget {
  const SpecificPublicDonationInfoPage(this.id);
  final String id;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Donation Information')),
        body: Text("Donation Information"));
  }
}

class RequesterChangeUserInfoPrivatePage extends StatelessWidget {
  const RequesterChangeUserInfoPrivatePage(this.id);
  final String id;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Change private user info')),
        body: ChangePrivateRequesterInfoForm(id));
  }
}

class ChangePrivateRequesterInfoForm extends StatefulWidget {
  ChangePrivateRequesterInfoForm(this.id);

  final String id;

  @override
  _ChangePrivateRequesterInfoFormState createState() => _ChangePrivateRequesterInfoFormState();
}

class _ChangePrivateRequesterInfoFormState extends State<ChangePrivateRequesterInfoForm> {
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
                doSnackbarOperation(context, 'Saving...', 'Successfully saved',
                    Api.editPrivateRequester(data..formRead(value)), MySnackbarOperationBehavior.POP_ZERO);
              }
            })
          ];
          return buildMyFormListView(_formKey, children,
              initialValue: data.formWrite());
        });
  }
}

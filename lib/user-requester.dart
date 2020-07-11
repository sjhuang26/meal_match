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
        appBar: AppBar(
            title: Text(
                'View donation id#${publicRequestAndDonationId.donationId}')),
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
          context, 'Open donator profile', '/donator', donation.donatorId)
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
                'Open donator profile',
                '/donator',
                data.donatorId,
              ),
              if (widget.publicRequestAndDonationId.publicRequest.committer ==
                  UserType.REQUESTER)
                buildMyStandardButton('Uncommit from donation', () {
                  doSnackbarOperation(
                      context,
                      'Uncommitting from donation...',
                      'Uncommitted from donation!',
                      Api.editPublicRequestCommitting(
                          publicRequest: widget
                              .publicRequestAndDonationId.publicRequest,
                          donation: null,
                          committer: null));
                })
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
  @override
  Widget build(BuildContext context) {
    return buildMyStandardSliverCombo<PublicRequest>(
        api: Api.getRequesterPublicRequests(
            provideAuthenticationModel(context).requesterId),
        titleText: 'My Requests',
        secondaryTitleText: (data) => '${data.length} requests',
        onTap: (data, index) {
          Navigator.pushNamed(context, '/requester/publicRequests/view',
              arguments: data[index]);
        },
        tileTitle: (data, index) => 'Date and time: ${data[index].dateAndTime}',
        tileSubtitle: (data, index) => '${data[index].numMeals} meals',
        tileTrailing: null,
        floatingActionButton: () {
          Navigator.pushNamed(context, '/requester/publicRequests/new');
        });
  }
}

class RequesterPublicRequestsViewPage extends StatelessWidget {
  const RequesterPublicRequestsViewPage(this.publicRequest);
  final PublicRequest publicRequest;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('View request id#${publicRequest.id}')),
        body: ViewPublicRequest(publicRequest));
  }
}

class ViewPublicRequest extends StatelessWidget {
  const ViewPublicRequest(this.publicRequest);
  final PublicRequest publicRequest;
  @override
  Widget build(BuildContext context) {
    return ListView(children: <Widget>[
      ...buildViewPublicRequestContent(publicRequest),
      if (publicRequest.donationId == null)
        ListTile(title: Text('Request has not yet been fulfilled')),
      if (publicRequest.donationId == null)
        buildMyNavigationButton(context, 'View donations',
            '/requester/publicRequests/donations/list', publicRequest),
      if (publicRequest.donationId != null)
        buildMyNavigationButton(
            context,
            'View donation that fulfills the request',
            '/requester/publicRequests/donations/viewOld',
            PublicRequestAndDonationId(
                publicRequest, publicRequest.donationId)),
      buildMyNavigationButton(context, 'Delete request',
          '/requester/publicRequests/delete', publicRequest)
    ]);
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

class NewPublicRequestForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardTextFormField('description', 'Description'),
      buildMyStandardTextFormField(
          'dateAndTime', 'Date and time to receive meal'),
      buildMyStandardNumberFormField('numMeals', 'Number of meals'),
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
                      provideAuthenticationModel(context).requesterId));
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
        appBar: AppBar(title: Text('Delete request id#${publicRequest.id}')),
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
            Api.deletePublicRequest(publicRequest.id));
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
        api: Api.getAllDonations(),
        titleText: 'View donations',
        secondaryTitleText: (data) => '${data.length} donations',
        onTap: (data, index) {
          Navigator.pushNamed(
              context, '/requester/publicRequests/donations/view',
              arguments:
              PublicRequestAndDonation(publicRequest, data[index]));
        },
        tileTitle: (data, index) => '${data[index].description}',
        tileSubtitle: (data, index) => '${data[index].numMeals - data[index].numMealsRequested - publicRequest.numMeals < 0 ? 'INSUFFICIENT MEALS' : 'SUFFICIENT MEALS'}',
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
        appBar: AppBar(
            title: Text(
                'View donation id#${publicRequestAndDonation.donation.id}')),
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
        'Open donator profile',
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
                committer: UserType.REQUESTER));
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

class ChangeRequesterInfoForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<Requester>(
        api: Api.getRequester(provideAuthenticationModel(context).requesterId),
        child: (context, data) {
          final List<Widget> children = [
            ...buildUserFormFields(),
            buildMyNavigationButton(context, 'Change private user info',
                '/requester/changeUserInfo/private', data.privateId),
            buildMyStandardButton('Save', () {
              if (_formKey.currentState.saveAndValidate()) {
                var value = _formKey.currentState.value;
                doSnackbarOperation(context, 'Saving...', 'Successfully saved',
                    Api.editRequester(data..formRead(value)));
              }
            })
          ];
          return buildMyFormListView(_formKey, children,
              initialValue: data.formWrite());
        });
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

class ChangePrivateRequesterInfoForm extends StatelessWidget {
  ChangePrivateRequesterInfoForm(this.id);

  final String id;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<PrivateRequester>(
        api: Api.getPrivateRequester(id),
        child: (context, data) {
          final List<Widget> children = [
            ...buildPrivateUserFormFields(),
            buildMyStandardButton('Save', () {
              if (_formKey.currentState.saveAndValidate()) {
                var value = _formKey.currentState.value;
                doSnackbarOperation(context, 'Saving...', 'Successfully saved',
                    Api.editPrivateRequester(data..formRead(value)));
              }
            })
          ];
          return buildMyFormListView(_formKey, children,
              initialValue: data.formWrite());
        });
  }
}

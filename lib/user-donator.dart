import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'main.dart';
import 'state.dart';

class DonatorDonationsNewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('New donation')), body: NewDonationForm());
  }
}

class DonatorDonationsEditPage extends StatelessWidget {
  const DonatorDonationsEditPage(this.donation);
  final Donation donation;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Edit donation')),
        body: EditDonationForm(donation));
  }
}

class NewDonationForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardNumberFormField('numMeals', 'Number of meals'),
      buildMyStandardTextFormField('dateAndTime', 'Date and time'),
      buildMyStandardTextFormField('description', 'Description'),
      buildMyStandardButton('Submit new donation', () {
        if (_formKey.currentState.saveAndValidate()) {
          var value = _formKey.currentState.value;
          doSnackbarOperation(
              context,
              'Submitting new donation...',
              'Added new donation!',
              Api.newDonation(Donation()
                ..formRead(value)
                ..donatorId = provideAuthenticationModel(context).donatorId
                ..numMealsRequested = 0));
        }
      })
    ];

    return buildMyFormListView(_formKey, children);
  }
}

class EditDonationForm extends StatelessWidget {
  EditDonationForm(this.initialValue);
  final Donation initialValue;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardNumberFormField('numMeals', 'Number of meals'),
      buildMyStandardTextFormField('dateAndTime', 'Date and time'),
      buildMyStandardTextFormField('description', 'Description'),
      buildMyStandardButton('Save', () {
        if (_formKey.currentState.saveAndValidate()) {
          var value = _formKey.currentState.value;
          doSnackbarOperation(context, 'Saving...', 'Saved!',
              Api.editDonation(initialValue..formRead(value)));
        }
      })
    ];

    return buildMyFormListView(_formKey, children,
        initialValue: initialValue.formWrite());
  }
}

class DonatorDonationsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DonationList();
  }
}

class DonationList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardSliverCombo<Donation>(
        api: Api.getDonatorDonations(
            provideAuthenticationModel(context).donatorId),
        titleText: 'My Donations',
        secondaryTitleText: (data) =>
            '${data.fold(0, (total, current) => total + current.numMeals)} meals donated',
        onTap: (data, index) {
          Navigator.pushNamed(context, '/donator/donations/view',
              arguments: data[index]);
        },
        tileTitle: (data, index) => '${data[index].dateAndTime}',
        tileSubtitle: (data, index) => '${data[index].numMeals} meals',
        tileTrailing: null,
        floatingActionButton: () =>
            Navigator.pushNamed(context, '/donator/donations/new'));
  }
}

class DonatorDonationsViewPage extends StatelessWidget {
  const DonatorDonationsViewPage(this.donation);
  final Donation donation;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('View donation id#${donation.id}')),
        body: ViewDonation(donation));
  }
}

class ViewDonation extends StatelessWidget {
  const ViewDonation(this.donation);
  final Donation donation;
  @override
  Widget build(BuildContext context) {
    return ListView(children: <Widget>[
      ...buildViewDonationContent(donation),
      buildMyNavigationButton(
          context, 'Edit', '/donator/donations/edit', donation),
      buildMyNavigationButton(
          context, 'Delete', '/donator/donations/delete', donation),
      buildMyNavigationButton(context, 'Current requests',
          '/donator/donations/publicRequests/list', donation)
    ]);
  }
}

class DonatorDonationsDeletePage extends StatelessWidget {
  const DonatorDonationsDeletePage(this.x);
  final Donation x;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Delete donation')),
        body: DeleteDonation(x));
  }
}

class DeleteDonation extends StatelessWidget {
  const DeleteDonation(this.x);
  final Donation x;
  @override
  Widget build(BuildContext context) {
    return Center(
        child: buildStandardButtonColumn([
      buildMyStandardButton('Delete donation', () async {
        doSnackbarOperation(context, 'Deleting donation...',
            'Donation deleted!', Api.deleteDonation(x));
      }),
      buildMyNavigationButton(context, 'Go back')
    ]));
  }
}

class DonatorDonationsPublicRequestsListPage extends StatelessWidget {
  const DonatorDonationsPublicRequestsListPage(this.donation);
  final Donation donation;
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: PublicRequestListByDonation(donation));
  }
}

class DonatorPublicRequestsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: PublicRequestList());
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
        api: Api.getPublicRequestsByDonationId(null),
        titleText: 'Unfulfilled requests',
        secondaryTitleText: (data) => '${data.length} requests',
        onTap: (data, index) => Navigator.pushNamed(
            context, '/donator/publicRequests/view', arguments: data[index]),
        tileTitle: (data, index) => '${data[index].dateAndTime}',
        tileSubtitle: (data, index) =>
            '${data[index].description} (${data[index].numMeals} meals)',
        tileTrailing: null,
        floatingActionButton: null);
  }
}

class PublicRequestListByDonation extends StatefulWidget {
  const PublicRequestListByDonation(this.donation);
  final Donation donation;
  @override
  _PublicRequestListByDonationState createState() =>
      _PublicRequestListByDonationState();
}

class _PublicRequestListByDonationState
    extends State<PublicRequestListByDonation> {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardSliverCombo<PublicRequest>(
        api: Api.getPublicRequestsByDonationId(widget.donation.id),
        titleText: 'Requests for donation id#${widget.donation.id}',
        secondaryTitleText: (data) =>
            '${data.fold(0, (total, current) => total + current.numMeals)} meals requested',
        onTap: (data, index) => Navigator.pushNamed(
            context, '/donator/donations/publicRequests/view',
            arguments: PublicRequestAndDonation(data[index], widget.donation)),
        tileTitle: (data, index) => '${data[index].numMeals} meals',
        tileSubtitle: (data, index) =>
            'Committer: ${data[index].committer == UserType.DONATOR ? 'Donator' : 'Requester'}',
        tileTrailing: null,
        floatingActionButton: null);
  }
}

class DonatorDonationsPublicRequestsViewPage extends StatelessWidget {
  const DonatorDonationsPublicRequestsViewPage(this.publicRequestAndDonation);
  final PublicRequestAndDonation publicRequestAndDonation;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
                'View request id#${publicRequestAndDonation.publicRequest.id}')),
        body: ViewDonationPublicRequest(publicRequestAndDonation));
  }
}

class ViewDonationPublicRequest extends StatelessWidget {
  const ViewDonationPublicRequest(this.publicRequestAndDonation);
  final PublicRequestAndDonation publicRequestAndDonation;
  @override
  Widget build(BuildContext context) {
    return ListView(children: <Widget>[
      ...buildViewPublicRequestContent(publicRequestAndDonation.publicRequest),
      buildMyNavigationButton(
        context,
        'Open requester profile',
        '/requester',
        publicRequestAndDonation.publicRequest.requesterId,
      ),
      if (publicRequestAndDonation.publicRequest.committer == UserType.DONATOR)
        buildMyStandardButton('Uncommit', () async {
          doSnackbarOperation(
              context,
              'Uncommitting to public request...',
              'Uncommitted to public request!',
              Api.editPublicRequestCommitting(
                  publicRequest: publicRequestAndDonation.publicRequest,
                  donation: null,
                  committer: null));
        })
    ]);
  }
}

class DonatorPublicRequestsViewPage extends StatelessWidget {
  const DonatorPublicRequestsViewPage(this.publicRequest);
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
      buildMyNavigationButton(
        context,
        'Open requester profile',
        '/requester',
        publicRequest.requesterId,
      ),
      buildMyNavigationButton(context, 'Commit',
          '/donator/publicRequests/donations/list', publicRequest)
    ]);
  }
}

class DonatorPublicRequestsDonationsListPage extends StatelessWidget {
  const DonatorPublicRequestsDonationsListPage(this.publicRequest);
  final PublicRequest publicRequest;
  @override
  Widget build(BuildContext context) {
    return PublicRequestDonationList(publicRequest);
  }
}

class PublicRequestDonationList extends StatefulWidget {
  const PublicRequestDonationList(this.publicRequest);
  final PublicRequest publicRequest;
  @override
  _PublicRequestDonationListState createState() =>
      _PublicRequestDonationListState();
}

class _PublicRequestDonationListState extends State<PublicRequestDonationList> {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardSliverCombo<Donation>(
        api: Api.getDonatorDonations(
            provideAuthenticationModel(context).donatorId),
        titleText: 'Which donation?',
        secondaryTitleText: null,
        onTap: (data, index) {
          Navigator.pushNamed(context, '/donator/publicRequests/donations/view',
              arguments:
                  PublicRequestAndDonation(widget.publicRequest, data[index]));
        },
        tileTitle: (data, index) => '${data[index].dateAndTime}',
        tileSubtitle: (data, index) => '${data[index].description} (${data[index].numMeals - data[index].numMealsRequested - widget.publicRequest.numMeals < 0 ? 'NOT ENOUGH MEALS' : 'ENOUGH MEALS'})',
        tileTrailing: null,
        floatingActionButton: null);
  }
}

class DonatorPublicRequestsDonationsViewPage extends StatelessWidget {
  const DonatorPublicRequestsDonationsViewPage(this.publicRequestAndDonation);
  final PublicRequestAndDonation publicRequestAndDonation;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text('Donation id#${publicRequestAndDonation.donation.id}')),
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
      buildMyStandardButton('Commit', () async {
        doSnackbarOperation(
            context,
            'Committing to request...',
            'Committed to request!',
            Api.editPublicRequestCommitting(
                publicRequest: publicRequestAndDonation.publicRequest,
                donation: publicRequestAndDonation.donation,
                committer: UserType.DONATOR));
      })
    ]);
  }
}

class DonatorChangeUserInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Change user info')),
        body: ChangeDonatorInfoForm());
  }
}

class ChangeDonatorInfoForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<Donator>(
        api: Api.getDonator(provideAuthenticationModel(context).donatorId),
        child: (context, data) {
          final List<Widget> children = [
            ...buildUserFormFields(),
            buildMyNavigationButton(context, 'Change private user info',
                '/donator/changeUserInfo/private', data.privateId),
            buildMyStandardButton('Save', () {
              if (_formKey.currentState.saveAndValidate()) {
                var value = _formKey.currentState.value;
                doSnackbarOperation(context, 'Saving...', 'Successfully saved',
                    Api.editDonator(data..formRead(value)));
              }
            })
          ];
          return buildMyFormListView(_formKey, children,
              initialValue: data.formWrite());
        });
  }
}

class DonatorChangeUserInfoPrivatePage extends StatelessWidget {
  const DonatorChangeUserInfoPrivatePage(this.id);
  final String id;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Change private user info')),
        body: ChangePrivateDonatorInfoForm(id));
  }
}

class ChangePrivateDonatorInfoForm extends StatelessWidget {
  ChangePrivateDonatorInfoForm(this.id);

  final String id;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<PrivateDonator>(
        api: Api.getPrivateDonator(id),
        child: (context, data) {
          final List<Widget> children = [
            ...buildPrivateUserFormFields(),
            buildMyStandardButton('Save', () {
              if (_formKey.currentState.saveAndValidate()) {
                var value = _formKey.currentState.value;
                doSnackbarOperation(context, 'Saving...', 'Successfully saved',
                    Api.editPrivateDonator(data..formRead(value)));
              }
            })
          ];
          return buildMyFormListView(_formKey, children,
              initialValue: data.formWrite());
        });
  }
}

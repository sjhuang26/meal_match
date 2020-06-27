import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class NewDonationForm extends StatefulWidget {
  @override
  _NewDonationFormState createState() => _NewDonationFormState();
}

class _NewDonationFormState extends State<NewDonationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Donation _data = Donation();

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
    _data.donatorId =
        Provider.of<AuthenticationModel>(context, listen: false).donatorId;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      buildMyStandardNumberFormField('Number of meals', (newValue) {
        _data.numMeals = int.parse(newValue);
      }),
      buildMyStandardTextFormField('Date and time', (newValue) {
        _data.dateAndTime = newValue;
      }),
      buildMyStandardTextFormField('Description', (newValue) {
        _data.description = newValue;
      }),
      buildMyStandardButton(
        'Submit new donation',
        _submitForm,
      )
    ];

    return Form(key: _formKey, child: buildMyFormListView(children));
  }
}

class EditDonationForm extends StatefulWidget {
  const EditDonationForm(this.donation);
  final Donation donation;
  @override
  _EditDonationFormState createState() => _EditDonationFormState();
}

class _EditDonationFormState extends State<EditDonationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Donation _data = Donation();

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
      buildMyStandardNumberFormField('Number of meals', (newValue) {
        _data.numMeals = int.parse(newValue);
      }, widget.donation.numMeals.toString()),
      buildMyStandardTextFormField('Date and time', (newValue) {
        _data.dateAndTime = newValue;
      }, widget.donation.dateAndTime),
      buildMyStandardTextFormField('Description', (newValue) {
        _data.description = newValue;
      }, widget.donation.description),
      buildMyStandardButton(
        'Submit edit to donation',
        _submitForm,
      )
    ];

    return Form(key: _formKey, child: buildMyFormListView(children));
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
        api: Api.getDonatorDonations(),
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
      buildMyNavigationButton(context, 'Current requests',
          '/donator/donations/publicRequests/list', donation)
    ]);
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
        tileSubtitle: (data, index) => '${data[index].description} (${data[index].numMeals} meals)',
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
        tileSubtitle: (data, index) => 'Committer: ${data[index].committer}',
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
        appBar:
            AppBar(title: Text('View request id#${publicRequestAndDonation.publicRequest.id}')),
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
      buildMyStandardButton('Uncommit', () async {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Uncommitting to public request...')));
        await Api.editPublicRequestCommitting(publicRequestId: publicRequestAndDonation.publicRequest.id, donationId: null, committer: null);
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Uncommitted to public request!')));
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
      body: ViewPublicRequest(publicRequest)
    );
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
      buildMyNavigationButton(context, 'Commit', '/donator/publicRequests/donations/list', publicRequest)
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
  _PublicRequestDonationListState createState() => _PublicRequestDonationListState();
}

class _PublicRequestDonationListState extends State<PublicRequestDonationList> {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardSliverCombo<Donation>(
        api: Api.getDonatorDonations(),
        titleText: 'Which donation?',
        secondaryTitleText: null,
        onTap: (data, index) {
          Navigator.pushNamed(context, '/donator/publicRequests/donations/view',
              arguments: PublicRequestAndDonation(widget.publicRequest, data[index]));
        },
        tileTitle: (data, index) => '${data[index].dateAndTime}',
        tileSubtitle: (data, index) => '${data[index].description}',
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
      appBar: AppBar(title: Text('Donation id#${publicRequestAndDonation.donation.id}')),
      body: ViewPublicRequestDonation(publicRequestAndDonation)
    );
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
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Committing to request...')));
        await Api.editPublicRequestCommitting(publicRequestId: publicRequestAndDonation.publicRequest.id, donationId: publicRequestAndDonation.donation.id, committer: UserType.DONATOR);
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Committed to request!')));
      })
    ]);
  }
}

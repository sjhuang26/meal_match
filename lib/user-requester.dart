import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state.dart';
import 'main.dart';

class RequesterPublicRequestsDonationsViewOldPage extends StatelessWidget {
  const RequesterPublicRequestsDonationsViewOldPage(this.publicRequestAndDonationId);
  final PublicRequestAndDonationId publicRequestAndDonationId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('View donation id#${publicRequestAndDonationId.donationId}')),
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
          context,
          'Open donator profile',
          '/donator',
          donation.donatorId)
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
    return FutureBuilder<Donation>(
        future: Api.getDonationById(widget.publicRequestAndDonationId.donationId),
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return ListView(children: <Widget>[
              ...buildViewDonationContent(snapshot.data),
              buildMyNavigationButton(
                  context,
                  'Open donator profile',
                  '/donator',
                  snapshot.data.donatorId,
                  ),
              buildMyStandardButton('Uncommit from donation', ()  async {
                Scaffold.of(context).showSnackBar(SnackBar(content: Text('Uncommitting from donation...')));
                await Api.editPublicRequestCommitting(publicRequestId: widget.publicRequestAndDonationId.publicRequest.id, donationId: null, committer: null);
                Scaffold.of(context).showSnackBar(SnackBar(content: Text('Uncommitted from donation!')));
              })
            ]);
          if (snapshot.hasError)
            return Center(child: Text('Error', style: TextStyle(fontSize: 36)));
          return Center(
              child: Text('Loading...', style: TextStyle(fontSize: 36)));
        });
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
        api: Api.getRequesterPublicRequests(),
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
    }
    );
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
      if (publicRequest.donationId == null) ListTile(title: Text('Request has not yet been fulfilled')),
      if (publicRequest.donationId == null) buildMyNavigationButton(context, 'View donations',
          '/requester/publicRequests/donations/list', publicRequest),
      if (publicRequest.donationId != null) buildMyNavigationButton(context, 'View donation that fulfills the request',
          '/requester/publicRequests/donations/viewOld', PublicRequestAndDonationId(publicRequest, publicRequest.donationId)),
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

class NewPublicRequestForm extends StatefulWidget {
  @override
  _NewPublicRequestFormState createState() => _NewPublicRequestFormState();
}

class _NewPublicRequestFormState extends State<NewPublicRequestForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PublicRequest _data = PublicRequest();

  @override
  void initState() {
    _data.requesterId =
        Provider.of<AuthenticationModel>(context, listen: false).requesterId;
    _data.committer = null;
    super.initState();
  }

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
      buildMyStandardTextFormField('Description', (newValue) {
        _data.description = newValue;
      }),
      buildMyStandardTextFormField('Date and time', (newValue) {
        _data.dateAndTime = newValue;
      }),
      buildMyStandardNumberFormField('Number of meals', (newValue) {
        _data.numMeals = int.parse(newValue);
      }),
      buildMyStandardButton(
        'Submit new request',
        _submitForm,
      )
    ];

    return Form(key: _formKey, child: buildMyFormListView(children));
  }
}

class RequesterPublicRequestsDeletePage extends StatelessWidget {
  const RequesterPublicRequestsDeletePage(this.publicRequest);
  final PublicRequest publicRequest;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            AppBar(title: Text('Delete request id#${publicRequest.id}')),
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
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text('Deleting request...')));
        await Api.deletePublicRequest(publicRequest.id);
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text('Request deleted!')));
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
        api: Api.getAllDonations(),
        titleText: 'View donations',
        secondaryTitleText: (data) => '${data.length} donations',
        onTap: (data, index) {
          Navigator.pushNamed(context, '/requester/publicRequests/donations/view',
              arguments: PublicRequestAndDonation(widget.publicRequest, data[index]));
        },
        tileTitle: (data, index) => '${data[index].description}',
        tileSubtitle: null,
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
        appBar: AppBar(title: Text('View donation id#${publicRequestAndDonation.donation.id}')),
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
      buildMyStandardButton('Commit', () async {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Committing to donation...')));
        await Api.editPublicRequestCommitting(publicRequestId: publicRequestAndDonation.publicRequest.id, donationId: publicRequestAndDonation.donation.id, committer: UserType.REQUESTER);
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Committed to donation!')));
      })
    ]);
  }
}

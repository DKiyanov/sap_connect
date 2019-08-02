import 'package:flutter/material.dart';

import 'package:sap_connect/sap_application.dart';
import 'package:sap_connect/sap_authorization.dart';
import 'package:sap_connect/sap_connect.dart';

import 'fake_sap_server.dart';

import 'flights.dart';

bool kFakeSapServer = true; // true = simulation of work with a SAP server

void main() {
  Route _getRoute(RouteSettings settings) {
    switch (settings.name){
      case '/flights' :
        return MaterialPageRoute( builder: (context) => FlightsPage() );
      default :
        return null;
    }
  }

  final sapApplicationParams = SapApplicationParams(
    title: 'Flights',
    onGenerateRoute: _getRoute,
  );

  final sapStartParams = SapStartParams(
    nextRouteName: "/flights",
    useSecondaryLogin: true,
  );

  if (kFakeSapServer) {
    SapConnect.registerFakeHandler(HandlerType.System, fakeSapServer);
    SapConnect.registerFakeHandler(HandlerType.Method, fakeSapServer);
  }

  runApp( SapApplication(sapApplicationParams, sapStartParams) );
}



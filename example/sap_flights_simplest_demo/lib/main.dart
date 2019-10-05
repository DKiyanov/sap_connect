import 'package:flutter/material.dart';

import 'package:sap_connect/sap_application.dart';
import 'package:sap_connect/sap_authorization.dart';
import 'package:sap_connect/sap_connect.dart';

import 'fake_sap_server.dart';

import 'flights.dart';

/// variable for switching between working with simulated SAP server (true) and a real SAP server (false)
bool kFakeSapServer = true;
// kFakeSapServer = false; // uncomment this line to connect to real SAP server

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
  );

  if (kFakeSapServer) {
    kFakeHandler = fakeSapServer;
  }

  runApp( SapApplication(sapApplicationParams, sapStartParams) );
}



import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:sap_connect/sap_connect.dart';
import 'package:sap_connect/sap_const.dart';
import 'package:sap_connect/sap_utils.dart';

class FlightsPage extends StatefulWidget {
  @override
  FlightsPageState createState() => FlightsPageState();
}

class Flight {
  final String carrid;
  final String connid;
  final String fldate;

  Flight({
    this.carrid,
    this.connid,
    this.fldate,
  });

  factory Flight.fromJson(Map<String, dynamic> parsedJson){
    return Flight(
      carrid     : parsedJson['CARRID'],
      connid     : parsedJson['CONNID'],
      fldate     : parsedJson['FLDATE'],
    );
  }
}

class FlightsPageState extends State<FlightsPage> {
  final _flightList = List<Flight>();

  void _queryFlights(){
    final query = json.encode({
      'carrid'  : [SapRange( low : 'AA')],
    });

    SapConnect().fetchPostWS(
      handlerType  : HandlerType.Method,
      handlerID    : 'YDK_CL_WEBS_FLIGHTS',
      action       : 'GET_FLIGHTS',
      actionData   : query,
      context      : context,
      postCallback : (Post post) {
        if (post.returnStatus != PostStatus.OK) return;
        setState(() {
          _flightList.clear();
          _flightList.addAll((json.decode(post.returnData) as List).map((subJson) => Flight.fromJson(subJson)).toList());
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queryFlights();
    });
  }

  @override
  Widget build(BuildContext context) {
    final flightsView = ListView(
      children: _flightList.map( (flight) => ListTile(
        title: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text(flight.carrid),
          Text(flight.connid),
          Text(fromSapDate(flight.fldate).toIso8601String()),
        ],) ,
      )).toList(),
    );

    return Scaffold(
      appBar: AppBar( title: Text("Flights"), ),
      body: flightsView,
    );
  }
}
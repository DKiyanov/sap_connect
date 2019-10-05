import 'package:sap_connect/sap_connect.dart';
import 'package:flutter/services.dart' show rootBundle;

/// function to simulate request processing on the SAP server, look [kFakeSapServer] and [kFakeHandler] in sap_connect.dart
Future<Post> fakeSapServer( String handlerID, String action, String actionData) async {
  final actionStr = '$handlerID/$action';

  print('action $actionStr data $actionData');

  String returnData;
  String returnStatus = PostStatus.Error;

  switch (actionStr){
    case 'SYSTEM/ENTRY' :
      await Future.delayed(const Duration(milliseconds: 500));
      returnData = '';
      break;
    case 'YDK_CL_WEBS_FLIGHTS/GET_FLIGHTS' :
      returnData = await rootBundle.loadString('assets/flights.json');
      break;
  }

  if (returnData != null) {
    returnStatus = PostStatus.OK;
  }
  else {
    returnData = 'not processed';
  }

  return Post(returnData, returnStatus);
}
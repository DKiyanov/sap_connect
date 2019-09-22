import 'package:sap_connect/sap_connect.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<Post> fakeSapServer(String handlerType, String handlerID, String action, String actionData) async {
  final actionStr = '$handlerType/$handlerID/$action';

  print('action $actionStr data $actionData');

  String returnData;
  String returnStatus = PostStatus.Error;

  switch (actionStr){
    case 'SYS/SYS/ENTRY' :
      await Future.delayed(const Duration(milliseconds: 500));
      returnData = '';
      break;
    case 'CLAS/YDK_CL_WEBS_FLIGHTS/GET_FLIGHTS' :
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
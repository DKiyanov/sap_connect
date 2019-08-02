import 'package:sap_connect/sap_connect.dart';

Post fakeSapServer(String handlerType, String handlerID, String action, String actionData){
  final actionStr = '$handlerType/$handlerID/$action';

  print('action $actionStr data $actionData');

  String returnData;
  String returnStatus = PostStatus.Error;

  final Map<String, String> answerMap = {
    'SYS/SYS/ENTRY' : '',
    'CLAS/YDK_CL_WEBS_FLIGHTS/GET_FLIGHTS' : '[{"CARRID":"AA","CONNID":"0017","FLDATE":"20141224"},{"CARRID":"AA","CONNID":"0017","FLDATE":"20150121"},{"CARRID":"AA","CONNID":"0017","FLDATE":"20150218"},{"CARRID":"AA","CONNID":"0017","FLDATE":"20150318"}]',
  };

  returnData = answerMap[actionStr];

  if (returnData != null) {
    returnStatus = PostStatus.OK;
  }
  else {
    returnData = 'not processed';
  }

  return Post(returnData, returnStatus);
}
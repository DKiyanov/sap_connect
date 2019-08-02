/// Utilities for working with SAP data
library sap_utils;

import 'package:flutter/material.dart';

/// convert Dart DateTime to SAP date
String toSapDate(DateTime dt){
  var str = dt.toIso8601String();
  str = str.replaceAll("-", "");
  return str.substring(0,8);
}

/// convert SAP date to Dart DateTime
DateTime fromSapDate(String sapDate){
  return DateTime(
      int.parse(sapDate.substring(0,4)), // year
      int.parse(sapDate.substring(4,6)), // month
      int.parse(sapDate.substring(6,8))  // day
  );
}

/// convert Dart DateTime to SAP time
String toSapTime(DateTime dt){
  final str = dt.toIso8601String();
  return
    str.substring(11,13) +
    str.substring(14,16) +
    str.substring(17,19);
}

/// convert SAP time to Dart TimeOfDay
TimeOfDay fromSapTime(String sapTime){
  return TimeOfDay(
      hour  : int.parse(sapTime.substring(0,2)), // hour
      minute: int.parse(sapTime.substring(2,4)), // minute
  );
}

/// convert SAP date + time to Dart DateTime
DateTime fromSapDateTime(String sapDate, String sapTime){
  return DateTime(
      int.parse(sapDate.substring(0,4)), // year
      int.parse(sapDate.substring(4,6)), // month
      int.parse(sapDate.substring(6,8)), // day
      int.parse(sapTime.substring(0,2)), // hour
      int.parse(sapTime.substring(2,4)), // minute
      int.parse(sapTime.substring(4,6)), // second
  );
}

/// remove leading zero chars from string
String shiftLeadingZero(String str){
  return str.replaceFirst(RegExp("^0+(?!\$)"), "");
}
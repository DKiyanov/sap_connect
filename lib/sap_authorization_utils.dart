/// Utilities for authorization
library sap_authorization_utils;

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// salt generator look [kSalter]
typedef Salter = String Function(Salt saltID);

/// This is the global link to the salt generator's function<br>
/// I recommend you to replace Salter in your project
Salter kSalter = (saltID){
  switch(saltID){
    case Salt.sapAuthorization:     return 'Хабаровск'; break;
    case Salt.offlineAuthorization: return 'Уссурийск'; break;
    default: return '';
  }
};

/// Identifiers of salt for pickling of appropriate hash is used in
/// [getAuthorizationString]
enum Salt{
  /// Salt identifier for credentials upon opening a connection
  sapAuthorization,

  /// Salt identifier for credentials for offline access<br>
  /// received hash is kept on the device
  offlineAuthorization,
}

/// Return hash from login + password + salt; sha1 -> base64
String getAuthorizationString(String login, String password, Salt saltID){
  if (login == null || login.isEmpty) return null;

  String salt = '';
  if (kSalter != null) salt = kSalter(saltID);

  final String strForEncode = "${login.toUpperCase()}:${password??""}-$salt";
  return base64.encode(sha1.convert(utf8.encode(strForEncode)).bytes);
}

/// Opening a connection and making requests to the SAP server.
///
/// Connection opening is performed by calling the static method [SapConnect.sapEntry]
/// then server requests are performed using the 
/// [SapConnect.fetchPostWS] or [SapConnect.fetchPost] methods
library sap_connect;

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:device_id/device_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sap_authorization_utils.dart';
import 'wait_screen.dart';
import 'sap_internationalization.dart';

/// To register fake handlers [SapConnect.registerFakeHandler]
typedef FetchPost = Post Function(String handlerType, String handlerID, String action, String actionData);

// fake handlers are called instead of sending a request to the server for
// corresponding handlerType
final _fakeHandlers = Map<String, FetchPost>();

/// Standard statuses are usually returned as a result of the request.
class PostStatus{
  /// Error - for this status, the response body always contains a string describing the error
  static const String Error = "ERR";

  /// Request completed successfully
  static const String OK    = "OK";
}

/// The types of handlers on the SAP server side
class HandlerType{
  static const String Form   = "PROG";
  static const String Method = "CLAS";
  static const String System = "SYS";
}

/// SAP handler data
class SapHandler{
  /// server handler type
  final String type;

  /// server handler id
  final String id;

  SapHandler(this.type, this.id);

  String get key => "$type&$id";

  Map<String, dynamic> toJson(){
    return {
      "type" : type,
      "id"   : id,
    };
  }
}

/// The result of processing the request to the SAP server
class Post {
  /// Server response data/body
  final String returnData;

  /// Server response status, usually values correspond to [PostStatus]
  final String returnStatus;

  Post(this.returnData, this.returnStatus);
}

/// Callback with the result of the request
typedef void PostCallback(Post post);

/// Callback to check for the presence and handling of errors as a result of the request
typedef PostErrorCheckCallback = Future<FutureMessage> Function(Post post);

/// Default error handler
/// for `SapConnect().fetchPostWS(errorCheckCallback:...)` look [PostErrorCheckCallback]
Future<FutureMessage> defaultErrorCheck(Post post) async {
  if (post.returnStatus == PostStatus.Error) return FutureMessage(title: sapTranslate("Error"), titleColor: Colors.red, msg: post.returnData);
  return null;
}

/// Opening a connection and making requests to the server
///
/// singleton, instance created by calling a static method [sapEntry]<br>
/// factory [SapConnect] always returns a reference to the same instance
class SapConnect {
  static SapConnect _instance;

  /// Opening a server connection
  /// * [host] required, server address
  /// * [mandant] required, mandant
  /// * [sapLogin] required, SAP login account
  /// * [sapPassword] required, SAP login password
  /// * [personLogin] Secondary user account
  /// * [personPassword] Password for secondary user account
  /// * [personAuthString] hash for secondary user account 
  /// used to entry without input a user password,
  /// the hash is stored on the device
  /// * [languageID] required, Login language ID
  /// * [context] required, Context
  /// * [errorCheckCallback2] Callback for error handling<br>
  /// The WaitScreen still stands.<br>
  /// if there is an error, it returns [FutureMessage], which is then displayed on the WaitScreen.<br>
  /// Here you can launch secondary/additional server requests using [fetchPost]
  static Future<bool> sapEntry({
    String host,
    String mandant,
    String sapLogin,
    String sapPassword,
    String personLogin,
    String personPassword,
    String personAuthString,
    String languageID,
    BuildContext context,
    PostErrorCheckCallback errorCheckCallback2,
  }) async {
    assert(host != null);
    assert(mandant != null);
    assert(sapLogin != null);
    assert(sapPassword != null);
    assert(languageID != null);
    assert(context != null);

    String sapAuthString  = base64.encode(utf8.encode("$sapLogin:$sapPassword"));

    _instance = null;
    final completer = Completer<bool>();

    if (personLogin == null) personLogin = "";
    personLogin = personLogin.toUpperCase();

    if (personAuthString == null || personAuthString.isEmpty) personAuthString = getAuthorizationString(personLogin, personPassword, Salt.sapAuthorization);

    final query = json.encode({
      "deviceID": await DeviceId.getID,
      "persAuthString": personAuthString,
    });

    final cookie = CookieJar();
    final uri = Uri.parse('http://$host/sap/bc/ydkwebs?sap-client=$mandant');

    _fetchPostWS(
        cookie       : cookie,
        uri          : uri,
        sapAuthString: sapAuthString,
        languageID   : languageID,
        handlerType  : "SYS",
        handlerID    : "SYS",
        action       : "ENTRY",
        actionData   : query,
        context      : context,
        title        : sapTranslate('EntryToSap'),
        errorCheckCallback2: (post) async {
          final ret = await errorCheckCallback2(post);
          if (ret!= null && ret.onBuildMessage == null && ret.startNextFuture == null){
            _instance.logoff();
          }
          return ret;
        },
        errorCheckCallback : (post) async {
          var ret = await defaultErrorCheck(post);
          if (ret != null) {
            if (ret.msg.substring(0,0) == "\$") ret = FutureMessage(msg: sapTranslate(ret.msg));
            return ret;
          }
          if (_instance  == null) {
            _instance = SapConnect._constructor(cookie, uri, sapLogin, languageID, personLogin);
          }
        },
        postCallback : (Post post) {
          if (post.returnStatus != PostStatus.OK) {
            if (_instance != null){
              _instance.logoff();
            }
            completer.complete(false);
            return;
          }

          completer.complete(true);
        }
    );

    return completer.future;
  }

  /// Instance created by calling static method [sapEntry]<br>
  /// factory `SapConnect` always returns a reference to the same instance
  factory SapConnect(){
    assert(SapConnect._instance != null, 'SAP connection is not open yet');
    return SapConnect._instance;
  }

  /// SAP login account
  final String sapLogin;

  /// Secondary user account
  final String personLogin;

  /// Language Id is logged in
  final String languageID;

  final Uri _uri;
  final CookieJar _cookie;

  /// Default handler type
  /// used in [fetchPost] and [fetchPostWS] if parameter `handlerType` is not specified
  String defaultHandlerType = HandlerType.Method;

  /// Default handler ID
  /// used in [fetchPost] and [fetchPostWS] if parameter `handlerID` is not specified
  String defaultHandlerID;

  SapConnect._constructor(this._cookie, this._uri, this.sapLogin, this.languageID, this.personLogin);

  /// Making a request to the server with a blocking screen output ("WaitScreen" look [startWaitScreen])<br>
  /// the WaitScreen obscures the program screen during the execution and processing of the request
  /// * [handlerType] server handler type
  /// * [handlerID] server handler id
  /// * [action] required, ID of the action/command transmitted to the server
  /// * [actionData] data to perform action/command transmitted to the server
  /// * [context] required, context
  /// * [title] the inscription is displayed on WaitScreen
  /// * [errorCheckCallback] Callback for error handling - stage 1,<br>
  /// if not specified, [defaultErrorCheck] is performed<br>
  /// if there is an error, it returns [FutureMessage], which is then displayed on the WaitScreen
  /// * [errorCheckCallback2] Callback for error handling - stage 2<br>
  /// executed after `errorCheckCallback` if he returned null<br>
  /// if there is an error, it returns [FutureMessage], which is then displayed on the WaitScreen.<br>
  /// The WaitScreen still stands.<br>
  /// Convenient to use to process query results.<br>
  /// Here you can launch secondary/additional server requests using [fetchPost]
  /// * [postCallback] Callback to handle the request.<br>
  /// WaitScreen removed.<br>
  /// It is always executed, regardless of the presence of errors.<br>
  /// Runs after executing  `errorCheckCallback`
  /// and `errorCheckCallback2`
  /// * [timeoutSec] maximum duration of the operation in seconds
  void fetchPostWS({
    String handlerType,
    String handlerID,
    String action,
    String actionData = "",
    BuildContext context,
    String title,
    PostErrorCheckCallback errorCheckCallback,
    PostErrorCheckCallback errorCheckCallback2,
    PostCallback postCallback,
    int timeoutSec = 25
  }) async {
    assert(action != null);
    assert(context != null);

    if (errorCheckCallback == null) errorCheckCallback = defaultErrorCheck;
    if (handlerType == null) handlerType = defaultHandlerType;
    if (handlerID   == null) handlerID   = defaultHandlerID;

    assert(handlerType != null);
    assert(handlerID != null);

    _fetchPostWS(
        postCallback : postCallback,
        errorCheckCallback : errorCheckCallback,
        errorCheckCallback2 : errorCheckCallback2,
        cookie       : _cookie,
        uri          : _uri,
        languageID   : languageID,
        handlerType  : handlerType,
        handlerID    : handlerID,
        action       : action,
        actionData   : actionData,
        context      : context,
        title        : title,
        timeOut      : timeoutSec,
    );
  }

  /// Making a request to the server
  /// * [handlerType] server handler type
  /// * [handlerID] server handler id
  /// * [action] required, ID of the action/command transmitted to the server
  /// * [actionData] data to perform action/command transmitted to the server
  /// * [timeoutSec] maximum duration of the operation in seconds
  Future<Post> fetchPost({
    String handlerType,
    String handlerID,
    String action,
    String actionData,
    int timeoutSec = 25
  }) async {
    assert(action != null);

    if (handlerType == null) handlerType = defaultHandlerType;
    if (handlerID == null) handlerID = defaultHandlerID;
    if (actionData == null) actionData = "";

    assert(handlerType != null);
    assert(handlerID != null);

    return _fetchPost(
        cookie      : _cookie,
        uri         : _uri,
        languageID  : languageID,
        handlerType : handlerType,
        handlerID   : handlerID,
        action      : action,
        actionData  : actionData,
        timeOut     : timeoutSec
    );
  }

  /// Closing server connection
  void logoff(){
    _instance = null;
    if (this._cookie == null) return;

    fetchPost(
      handlerType: "SYS",
      handlerID  : "LOGOFF",
      action     : "LOGOFF",
    );
  }

  /// True = Connection is open
  static bool get entryOk =>_instance != null;

  /// Register fake handler<br>
  /// may be needed for testing and debugging and not only
  static void registerFakeHandler(String handlerType, FetchPost fetchPost){
    _fakeHandlers[handlerType] = fetchPost;
  }

  /// Creates an instance without connecting to the server<br>
  /// must be logged in without connecting to the server, look [OfflineLogin]<br>
  /// and registered fakeHandler, look [registerFakeHandler]
  static void offlineEntry(){
     assert(OfflineLogin.entryOk);
     assert(_fakeHandlers.isNotEmpty);
     _instance = SapConnect._constructor(null, null, null, null, null);
  }
}

Future<Post> _fetchPost({
  CookieJar cookie,
  Uri uri,
  String sapAuthString,
  String languageID,
  String handlerType,
  String handlerID,
  String action,
  String actionData,
  int timeOut
}) async {
  print("action: $action; actiondata: $actionData");

  final fakeHandler = _fakeHandlers[handlerType];
  if (fakeHandler != null) {
    final post = fakeHandler(handlerType, handlerID, action, actionData);
    print("returStatus: ${post.returnStatus}; returnData: ${post.returnData}");
    return post;
  }

  String returnData = sapTranslate("UnspecifiedError"); // Unspecified error
  String returnStatus = PostStatus.Error;

  final client = new HttpClient();
  if (timeOut != null) client.connectionTimeout = Duration(seconds: timeOut);
  try {
    final body = utf8.encode(actionData);

    final request = await client.getUrl(uri);
    request.headers.add("Content-Length", body.length);
    if (sapAuthString != null && sapAuthString.isNotEmpty) request.headers.add("Authorization", "Basic $sapAuthString");
    request.headers.add("Accept-Language", languageID);
    request.headers.add("X-YDK-PROC_TYPE", handlerType);
    request.headers.add("X-YDK-PROC_ID", handlerID);
    request.headers.add("X-YDK-ACTION", action);
    request.cookies.addAll(cookie.loadForRequest(uri)); // Must be before filling the body - otherwise it does not work
    request.add(body);

    final response = await request.close();

    cookie.saveFromResponse(uri, response.cookies);

    if (response.statusCode >= 400){
      switch (response.statusCode){
        case 401:
          returnData = sapTranslate("Msg3"); // The username or password you entered is incorrect
          break;
        case 403:
          returnData = sapTranslate("Msg4"); // User can not be logged in
          break;
        default:
          if (response.statusCode < 500)
            returnData = sapTranslate("Msg5"); // Error in the data on the side of the mobile application
          else
            returnData = sapTranslate("Msg6"); // Internal server error
          break;
      }
    }
    else {
      returnStatus = response.headers.value('X-YDK-STATUS');
      returnData   =  await response.transform(Utf8Decoder()).join();
//      print("server answer: $str");

      if (returnStatus == null || returnStatus.isEmpty) {
        returnStatus = PostStatus.Error;
        returnData = sapTranslate("Msg7"); // Invalid answer from server
      }
    }
  } catch(e) {
    print("_fetchPost error processing");
    String msg;
//    msg = e.message;
    try {
      msg = e.message;
    }
    catch(me) {
      msg = "";
    }
    if (msg == null || msg.isEmpty){
      if (e is SocketException) msg = sapTranslate("ConnectionError"); // Connection error
      else msg = e.toString();
    }
    returnData = msg;
  }

  print("returStatus: $returnStatus; returnData: $returnData");
  return new Post(returnData, returnStatus);
}

void _fetchPostWS({
  PostCallback postCallback,
  CookieJar cookie, Uri uri,
  String sapAuthString,
  String languageID,
  String handlerType,
  String handlerID,
  String action,
  String actionData,
  int timeOut,
  BuildContext context,
  String title,
  PostErrorCheckCallback errorCheckCallback,
  PostErrorCheckCallback errorCheckCallback2
}) async {
  Post topPost;

  startWaitScreen(
      context : context,
      title : title,
      futureStartCallback: () async {
        final post = await _fetchPost(
            cookie        : cookie,
            uri           : uri,
            sapAuthString : sapAuthString,
            languageID    : languageID,
            handlerType   : handlerType,
            handlerID     : handlerID,
            action        : action,
            actionData    : actionData,
            timeOut       : timeOut
        );

        if (errorCheckCallback != null) {
          final msg = await errorCheckCallback(post);
          if (msg != null) return msg;
        }

        if (errorCheckCallback2 != null) {
          final msg = await errorCheckCallback2(post);
          if (msg != null) return msg;
        }

        topPost = post;
      },
      canceled: (){
        if (postCallback != null) postCallback(Post(sapTranslate("CanceledByUser", context : context), PostStatus.Error));
      },
      performed: (){
        if (postCallback != null) postCallback(topPost);
      }
  );
}

/// For log on to the app without logging on to SAP
class OfflineLogin {
  static Map<String, dynamic> _loginData;
  static const String _loginDataStrID = 'OffLineLoginData';
  static String _login;

  /// Login used to entry
  static String get login => _login;

  /// Data registration for the subsequent login without connecting to the server<br>
  /// data hash is stored on the device
  static void setLoginData(String login, String password) async {
    await _loadLoginData();
    _loginData[login.toUpperCase()] =
        getAuthorizationString(login, password, Salt.offlineAuthorization);

    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_loginDataStrID, json.encode(_loginData));
  }

  /// Validation of data for entering without connecting to the server
  static Future<bool> checkLoginData(String login, String password) async {
    await _loadLoginData();
    final hash = _loginData[login.toUpperCase()];

    if (hash == null) return false;

    if (hash ==
        getAuthorizationString(login, password, Salt.offlineAuthorization)) {
      _login = login;
      return true;
    }

    return false;
  }

  static void _loadLoginData() async {
    if (_loginData != null) return;

    final prefs = await SharedPreferences.getInstance();
    _loginData = json.decode(prefs.getString(_loginDataStrID) ?? "{}");
  }

  /// True = Entry without connecting to the server is executed.
  static bool get entryOk =>_login.isNotEmpty;
}
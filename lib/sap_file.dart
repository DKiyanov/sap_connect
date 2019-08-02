/// Download files from SAP + check self update
library sap_file;

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info/package_info.dart';

import 'sap_connect.dart';
import 'wait_screen.dart';
import 'sap_internationalization.dart';

/// Check self update in SAP server, in SAP look transactions SMW0<br>
/// in SMW0 searches file with name <prefix + packageName> then compares SMW0 file version with <version+"+"+buildNumber> of package<br>
/// default prefix is "YDKWEBS."
Future<FutureMessage> checkSelfUpdate({String packageName, String prefix = "YDKWEBS."}) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  if (packageName == null) packageName = packageInfo.packageName;
  if (prefix != null && prefix.isNotEmpty) packageName = prefix + packageName;

  final version = "${packageInfo.version}+${packageInfo.buildNumber}";

  final post = await SapConnect().fetchPost(
      handlerType : HandlerType.Method,
      handlerID   : "YDK_CL_WEBS_FILE",
      action      : "GET_INFO",
      actionData  : packageName,
  );

  if (post.returnStatus == PostStatus.Error) {
    return FutureMessage(msg: post.returnData);
  }

  if (post.returnStatus != PostStatus.OK) {
    return null;
  }

  final Map<String, dynamic> parsedJson = json.decode(post.returnData);

  if (parsedJson["EXTENSION"] != "APK") {
    return FutureMessage(msg: 'file extension mast by ".apk"');
  }

  final String fileVersion = parsedJson["VERSION"] ?? "";
  if (fileVersion.isEmpty){
    return FutureMessage(msg: 'file version on server is empty');
  }

  final String fileName = parsedJson["NAME"] ?? "";
  if (fileName.isEmpty){
    return FutureMessage(msg: 'file name on server is empty');
  }

  if  (fileVersion == version) return null;

  print("APK version saved in SAP $fileVersion != this app version $version");

  final String dir = (await getExternalStorageDirectory()).path;
  final String savePath = "$dir/$fileName";

  return FutureMessage(
      msg: sapTranslate("Msg8"),
      onBuildMessage: (context, msg, drawer){
        return Column( children: <Widget>[
            Text(msg.msg),
            Container(height: 8,),
            RaisedButton(
              child: Text(sapTranslate("Install")),
              onPressed: () {
                drawer.setMessage(
                    futureMessage : FutureMessage(
                        startNextFuture: ()=> downloadFile(packageName, savePath, doOpen: true)
                    )
                );
              },
            )
        ],);
      }
  );
}

/// Download file from SAP server, in SAP look transactions SMW0
Future<FutureMessage> downloadFile(String fileID, String savePath, {bool doOpen = false, bool doExit = false}) async {
  final post = await SapConnect().fetchPost(
    handlerType: HandlerType.Method,
    handlerID: "YDK_CL_WEBS_FILE",
    action: "GET_CONTENT",
    actionData: fileID,
  );

  if (post.returnStatus == PostStatus.Error) {
    return FutureMessage(msg: post.returnData);
  }

  try {
    await createFileFromBase64String(post.returnData, savePath);

    if (doOpen) await OpenFile.open(savePath);

    if (doExit) exit(0);
  } catch(e) {
    String msg;

    msg = e.message;
    if (msg == null || msg.isEmpty){
      msg = e.toString();
    }

    return FutureMessage(msg: msg);
  }

  return null;
}

/// Saves line fileContent into the file, it is supposed that fileContent has
/// data encoded in Base64 code, decoding performs before save
Future<void> createFileFromBase64String(String fileContent, String savePath) async {
  final bytes = base64.decode(fileContent);
  final file = File(savePath);
  await file.writeAsBytes(bytes);
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:sap_connect/sap_application.dart';
import 'package:sap_connect/sap_authorization.dart';

import 'package:flutter/services.dart';

import 'dart:io';
import 'package:mockito/mockito.dart';
import 'dart:convert';

class TestPage extends StatefulWidget {
  @override
  TestPageState createState() => TestPageState();
}

class TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text("test"), ),
      body: Container( child: Text('EntryOk')),
    );
  }
}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {
  final cookies = List<Cookie>();

  String handlerType;
  String handlerID;
  String action;
  String actionData;

  void add(List<int> data){
    final String str = utf8.decode(data);

    int pos;
    int prev;

    pos = str.indexOf("|");
    handlerType = str.substring(0, pos);

    prev = pos + 1;
    pos = str.indexOf("|", prev);
    handlerID = str.substring(prev, pos);

    prev = pos + 1;
    pos = str.indexOf("|", prev);
    action = str.substring(prev, pos);

    prev = pos + 1;
    actionData = str.substring(prev);

    print('$handlerType $handlerID $action $actionData');
  }
}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  final cookies = List<Cookie>();
}

class MockHttpHeaders extends Mock implements HttpHeaders {}

MockHttpClient createMockHttpClient(SecurityContext _) {
  final MockHttpClient client = MockHttpClient();
  final MockHttpClientRequest request = MockHttpClientRequest();
  final MockHttpClientResponse response = MockHttpClientResponse();
  final MockHttpHeaders headers = MockHttpHeaders();

  Stream<String> getBodyStream(){
    final bodyStr = request2Response(request);
    return Stream<String>.fromIterable([bodyStr]);
  }

  when(client.getUrl(any)).thenAnswer((_) => Future<HttpClientRequest>.value(request));
  when(request.headers).thenReturn(headers);
  when(request.close()).thenAnswer((_) => Future<HttpClientResponse>.value(response));
  when(response.statusCode).thenReturn(HttpStatus.ok);
  when(response.transform(any)).thenAnswer((_) => getBodyStream());

  return client;
}

String request2Response(MockHttpClientRequest request){
  print('request.data ${request.handlerID} ${request.action} ${request.actionData}');

  final str = '${request.handlerID}|${request.action}';
  switch(str){
    case 'SYS|ENTRY':
      return 'OK|';
    case 'YDK_CL_WEBS_UTILS|GET_PROG_TEXTS':
      return 'OK|[]';
  }

  return '';
}

void main() {
  testWidgets('authorization screen test', (WidgetTester tester) async {

    Route _getRoute(RouteSettings settings) {
      switch (settings.name){
        case '/offline' :
          return MaterialPageRoute(
              builder: (BuildContext context) {
                return TestPage();
              }
          );
          break;
        case '/online' :
          return MaterialPageRoute(
              builder: (BuildContext context) {
                return TestPage();
              }
          );
          break;
        default :
          return null;
      }
    }

    final sapApplicationParams = SapApplicationParams(
      title: 'test sap application',
      onGenerateRoute: _getRoute,
    );

    final sapStartParams = SapStartParams(
      nextRouteName: "/online",
      useSecondaryLogin: true,
    );

    const MethodChannel('plugins.flutter.io/shared_preferences')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        final String pref = 'flutter.';
        return <String, dynamic>{
          pref + 'LanguageCode' : 'en',
          pref + SharedPreferencesName.sapHost     : 'SAPDEV.Atommash.ru:8000',
          pref + SharedPreferencesName.sapMandant  : '040',
          pref + SharedPreferencesName.sapLogin    : 'VYGordeev',
          pref + SharedPreferencesName.sapPassword : '87654321',
        };
      }
      return null;
    });

    const MethodChannel('device_id')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getID') {
        return 'fakeDevID';
      }
      return null;
    });

    HttpOverrides.runZoned(() async {
      final app = SapApplication(sapApplicationParams, sapStartParams);
      await tester.pumpWidget( app );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Login'), findsOneWidget);
      expect(find.widgetWithText(RaisedButton, 'Login'), findsOneWidget);
      expect(find.byKey(Key('loginButton')), findsOneWidget);

      Iterable<Widget> listOfWidgets = tester.allWidgets;
      listOfWidgets.forEach((widget){
        if (widget is TextFormField) {
          TextFormField tff = widget;
          print(tff.controller.text);
          if (tff.key != null && tff.key is ValueKey) {
            ValueKey vk = tff.key;
            print(vk.value);
            if (vk.value == 'inputLogin') {
              tff.controller.text = 'usrtest';
            }
            if (vk.value == 'inputPassword') {
              tff.controller.text = 'qazwsxedc';
            }
          }
        }
      });

      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle();

      expect(find.text('EntryOk'), findsOneWidget);

    }, createHttpClient: createMockHttpClient);

  });
}

### sap_connect - the package is designed to establish a connection and then execute queries to the SAP system

Visually represents a screen for setting up a connection and logging to SAP system
![GIF showing / hiding connection settings and switching input language](https://raw.githubusercontent.com/DKiyanov/sap_connect/master/Login2SAPdemo.gif)

Connection settings are saved on the device<br>
Provides connection and work in the language chosen by the user (internationalization)<br>
After the connection is established, it allows you to perform queries to the SAP server

**To make this package work, you must install to the SAP server package [YDK_WEBS](https://github.com/DKiyanov/YDK_WEBS).**

The package comes with a simple but fully working example, see the folder [example\sap_flights_simplest_demo](https://github.com/DKiyanov/sap_connect/tree/master/example/sap_flights_simplest_demo)

To simplify the creation of the application and all the necessary settings, you can use the class [SapApplication](https://pub.dev/documentation/sap_connect/latest/sap_application/SapApplication-class.html)<br>
The main settings of the application are stored in the class [SapStartParams](https://pub.dev/documentation/sap_connect/latest/sap_authorization/SapStartParams-class.html)<br>
Application debugging can be performed without the SAP server, but with simulating server interaction, see global variable [kFakeHandler] in sap_connect.dart<br>
Use the methods to execute server requests: [SapConnect().fetchPostWS(...)](https://pub.dev/documentation/sap_connect/latest/sap_connect/SapConnect/fetchPostWS.html) or [SapConnect().fetchPost(...)](https://pub.dev/documentation/sap_connect/latest/sap_connect/SapConnect/fetchPost.html).<br>
Difference between [SapConnect().fetchPostWS(...)](https://pub.dev/documentation/sap_connect/latest/sap_connect/SapConnect/fetchPostWS.html) and [SapConnect().fetchPost(...)](https://pub.dev/documentation/sap_connect/latest/sap_connect/SapConnect/fetchPost.html) methods:
* SapConnect().fetchPostWS(...) Making a request to the server with a blocking screen output, the WaitScreen obscures the program screen during the execution and processing of the request. During execution of the processing of query results, additional requests to the server can be executed using fetchPost.
* SapConnect().fetchPost(...) Just executes a request to the server, returns Future on the result of execution

**general development approach:**

on the SAP server, create the class inherited from class YDK_CL_WEBS_ACTION
and make a class-method in it class:<br>
ABAP
``` ABAP
CLASS <name of class> DEFINITION inheriting from YDK_CL_WEBS_ACTION....   
PUBLIC SECTION.  
  CLASS-METHODS <name of method>
    IMPORTING
      !action_data TYPE string   " incaming query, usually a string JSON 
    EXPORTING
      !return_status TYPE string " return status of processing result
      !return_data TYPE string.  " returned data, most often a string JSON
ENDCLASS.

CLASS <name of class> IMPLEMENTATION.
  METHOD <name of method>.
* In order to make it easier to work with request data, load the request into the variable with a structure corresponding to the request structure (query)
    from_json( EXPORTING json = action_data CHANGING data = query ).

* Process the request, fill in the structure for returning data (ret_data)

* Return the processing result (ret_data)
    get_json( EXPORTING data = ret_data IMPORTING return_status = return_status return_data = return_data ).	
  ENDMETHOD.
ENDCLASS.  
```

Call the created method from the mobile application:<br>
Dart
``` dart
    SapConnect().fetchPostWS(
      handlerType  : HandlerType.Method,
      handlerID    : <name of class>,
      action       : <name of method>,
      actionData   : query, // usually a string JSON 
      context      : context,
      postCallback : (Post post) {
        if (post.returnStatus != PostStatus.OK) return;
        setState(() {
// processing query results saved in post.returnData
        });
      },
    );
```

the status returned by the SAP server (return_status) is a string, two values are reserved
* "OK" - in dart constant PostStatus.OK; in abap constant YDK_CL_WEBS_ACTION=>STATUS_OK - request processing was successful
* "ERR" - in dart constant PostStatus.Error; in abap constant YDK_CL_WEBS_ACTION=>STATUS_ERR - the processing was NOT successful, in this case the description of the error is in post.returnData, simple string not JSON

any other values can be used by the programmer as he pleases









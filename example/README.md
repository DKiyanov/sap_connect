# sap_connect examples
at the moment there is only one example

## "[sap_flights_simplest_demo](https://github.com/DKiyanov/sap_connect/tree/master/example/sap_flights_simplest_demo)"
Displays the connection screen to SAP server<br>
After connecting to the SAP server, displays data from the sflights DB
![GIF showing / hiding connection settings and switching input language](https://raw.githubusercontent.com/DKiyanov/sap_connect/master/Login2SAPdemo.gif)

**By default, example works with a simulated SAP server.**

To configure working with a real SAP server, you must:
* In main.dart, uncomment the line starting with "// kFakeSapServer = false;..."
* Install the [YDK_WEBS](https://github.com/DKiyanov/YDK_WEBS) package on the SAP server
* In the YDK_WEBS_ACT table using transaction SM30, add entry:
  - processor name = YDK_CL_WEBS_FLIGHTS
  - action name = GET_FLIGHTS
* Configure user to login through a mobile application using a transaction YDK_WEBS_USR  
* If sflights DB is empty in your SAP server, it can by filled by the run programms SAPBC_DATA_GENERATOR and SFLIGHT_DATA_GEN

main parts:<br>
ABAP
``` ABAP
CLASS YDK_CL_WEBS_FLIGHTS IMPLEMENTATION.
  METHOD get_flights.
*    importing
*      !ACTION_DATA type STRING
*    exporting
*      !RETURN_STATUS type STRING
*      !RETURN_DATA type STRING .

* The sflight DB can be filled with test data by running the programs SAPBC_DATA_GENERATOR and SFLIGHT_DATA_GEN

    TYPES: BEGIN OF ty_query,
             carrid TYPE RANGE OF sflight-carrid,
             connid TYPE RANGE OF sflight-connid,
             fldate TYPE RANGE OF sflight-fldate,
           END   OF ty_query.

    DATA: query TYPE ty_query.

* to simplify the work with the request data, they are loaded into the corresponding structure
    from_json( EXPORTING json = action_data CHANGING data = query ). 

    DATA: lt_sflight TYPE STANDARD TABLE OF sflight.

    SELECT * INTO TABLE lt_sflight
      FROM sflight
     WHERE carrid IN query-carrid
       AND connid IN query-connid
       AND fldate IN query-fldate.
	
    IF lt_sflight IS INITIAL.
* return error message	
      return_data = 'No flights found by query criteria'.
      return_status = status_err.
      RETURN.
    ENDIF.
	
* return query results, return_status is set to STATUS_OK
    get_json( EXPORTING data = lt_sflight IMPORTING return_status = return_status return_data = return_data ).
  ENDMETHOD.
ENDCLASS.
```

Dart (reduced)
```
void main() {
  Route _getRoute(RouteSettings settings) {
    switch (settings.name){
      case '/flights' :
        return MaterialPageRoute( builder: (context) => FlightsPage() );
      default :
        return null;
    }
  }

  final sapApplicationParams = SapApplicationParams(
    title: 'Flights',
    onGenerateRoute: _getRoute,
  );

  final sapStartParams = SapStartParams(
    nextRouteName: "/flights", // the route that will be launched after a successful connection to the server
    useSecondaryLogin: true,
  );

  runApp( SapApplication(sapApplicationParams, sapStartParams) );
}

class FlightsPageState extends State<FlightsPage> {
  final _flightList = List<Flight>();

  void _queryFlights(){
    final query = json.encode({
      'carrid'  : [SapRange( low : 'AA')],
    });

    SapConnect().fetchPostWS(
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
}
```
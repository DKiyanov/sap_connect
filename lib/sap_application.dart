/// Classes to simplify apps creating
library sap_application;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'sap_authorization.dart';
import 'sap_internationalization.dart';

/// Parameters for build SapApplication
///
/// Parameters are copied from MaterialApp,<br>
/// the part of parameters had to be removed because there was an assert (... != null)<br>
/// that makes impossible not to specify optional parameter. To tell the truth - it's pretty strange.<br>
/// It is used as one of parameters enter class [SapApplication]
class SapApplicationParams{
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget home;
  final Map<String, WidgetBuilder> routes;
  final String initialRoute;
  final RouteFactory onGenerateRoute;
  final RouteFactory onUnknownRoute;
//  final List<NavigatorObserver> navigatorObservers;
  final TransitionBuilder builder;
  final String title;
  final GenerateAppTitle onGenerateTitle;
  final ThemeData theme;
  final Color color;
//  final bool showPerformanceOverlay;
//  final bool checkerboardRasterCacheImages;
//  final bool checkerboardOffscreenLayers;
//  final bool showSemanticsDebugger;
//  final bool debugShowCheckedModeBanner;
//  final bool debugShowMaterialGrid;

  SapApplicationParams({
    this.navigatorKey,
    this.home,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
//    this.navigatorObservers,
    this.builder,
    this.title,
    this.onGenerateTitle,
    this.theme,
    this.color,
//    this.showPerformanceOverlay,
//    this.checkerboardRasterCacheImages,
//    this.checkerboardOffscreenLayers,
//    this.showSemanticsDebugger,
//    this.debugShowCheckedModeBanner,
//    this.debugShowMaterialGrid,
  });
}

/// Class to simplify apps creating and tuning
///
/// This class starts predefined route `'/sap_login'`
/// containing a screen with connection options and parameters for authorization in SAP
/// ```` dart
/// void main() {
///   final sapApplicationParams = SapApplicationParams(
///     title: 'test',
///   );
///
///   final sapStartParams = SapStartParams(
///     nextRouteName: "/test",
///   );
///
///   runApp( SapApplication(sapApplicationParams, sapStartParams) );
/// }
/// ````
class SapApplication extends StatefulWidget {
  final SapApplicationParams sapApplicationParams;
  final SapStartParams sapStartParams;

  SapApplication(this.sapApplicationParams, this.sapStartParams);

  @override
  _SapApplicationState createState() => _SapApplicationState();
}

class _SapApplicationState extends State<SapApplication> {
  @override
  void initState() {
    super.initState();
    SapLanguages().registerLocaleChangeCallback(onLocaleChange);
  }

  @override
  Widget build(BuildContext context) {
    if (SapLanguages().initialization) {
      return CircularProgressIndicator();
    }

    return MaterialApp(
      locale: SapLanguages().currentLocale,
      localeResolutionCallback: SapLanguages().localeResolutionCallback,
      localizationsDelegates: [
        SapLanguages().delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: SapLanguages().localeList,

      onGenerateRoute: _getRoute,

      navigatorKey                  : widget.sapApplicationParams.navigatorKey,
      home                          : widget.sapApplicationParams.home,
      initialRoute                  : widget.sapApplicationParams.initialRoute,
      onUnknownRoute                : widget.sapApplicationParams.onUnknownRoute,
//      navigatorObservers            : widget.sapApplicationParams.navigatorObservers,
      builder                       : widget.sapApplicationParams.builder,
      title                         : widget.sapApplicationParams.title,
      onGenerateTitle               : widget.sapApplicationParams.onGenerateTitle,
      theme                         : widget.sapApplicationParams.theme,
      color                         : widget.sapApplicationParams.color,
//      showPerformanceOverlay        : widget.sapApplicationParams.showPerformanceOverlay,
//      checkerboardRasterCacheImages : widget.sapApplicationParams.checkerboardRasterCacheImages,
//      checkerboardOffscreenLayers   : widget.sapApplicationParams.checkerboardOffscreenLayers,
//      showSemanticsDebugger         : widget.sapApplicationParams.showSemanticsDebugger,
//      debugShowCheckedModeBanner    : widget.sapApplicationParams.debugShowCheckedModeBanner,
//      debugShowMaterialGrid         : widget.sapApplicationParams.debugShowMaterialGrid,
    );
  }

  onLocaleChange(Locale newLocale) {
    setState(() {});
  }

  Route _getRoute(RouteSettings settings) {
    if (widget.sapApplicationParams.routes != null) {
      final widgetBuilder = widget.sapApplicationParams.routes[settings.name];
      if (widgetBuilder != null) {
        return MaterialPageRoute(
          settings: settings,
          builder: widgetBuilder,
        );
      }
    }

    if (widget.sapApplicationParams.onGenerateRoute != null) {
      final route = widget.sapApplicationParams.onGenerateRoute(settings);
      if (route != null) return route;
    }

    if (settings.name == '/' || settings.name == '/sap_login') {
      return MaterialPageRoute(
        settings: settings,
        builder: (BuildContext context) => LoginPage(params: widget.sapStartParams),
      );
    }

    return null;
  }
}
/// Internationalization
library sap_internationalization;

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'sap_connect.dart';
import 'wait_screen.dart';

part 'sap_internationalization_languages.dart';

/// look [SapLanguages.registerLocaleChangeCallback]
typedef void LocaleChangeCallback(Locale locale);

/// Support of available language list + the choice of the language<br>
/// look the example of use is source code [sap_application._SapApplicationState]<br>
/// singleton
class SapLanguages {
  static SapLanguages _instance;

  SapLanguages._constructor(){
    _loadLanguages();
  }

  factory SapLanguages(){
    if (_instance == null) _instance = SapLanguages._constructor();
    return _instance;
  }


  /// True = initialization of internationalization system in progress
  bool get initialization => _initialization;
  bool _initialization = true;

  /// Look [MaterialApp.localizationsDelegates]
  final delegate = SapLocalizationsDelegate();

  /// Map of available languages
  /// * Key - language id
  /// * Value - language name
  final languageList = Map<String, String>();

  /// List of available languages, look [MaterialApp.supportedLocales]
  final localeList = List<Locale>();
  Locale _locale;

  Future _loadLanguages() async {
    languageList.addAll(_getLanguageList());

    languageList.forEach((key, value) {
      localeList.add(Locale(key));
    });

    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('LanguageCode');
    if (languageCode != null) _locale = Locale(languageCode);

    _initialization = false;

    if (_onLocaleChanged != null) _onLocaleChanged(_locale);
  }

  /// To register in [MaterialApp.localeResolutionCallback]
  Locale localeResolutionCallback(Locale deviceLocale, Iterable<Locale> supportedLocales){
    if (this._locale == null) return deviceLocale;
    return _locale;
  }

  LocaleChangeCallback _onLocaleChanged;

  /// Register callback to notify about change locale
  void registerLocaleChangeCallback(LocaleChangeCallback localeChangeCallback){
    _onLocaleChanged = localeChangeCallback;
  }

  /// To change current locale
  void setLocale(Locale newLocale){
    _locale = newLocale;

    SharedPreferences.getInstance().then((prefs){
      prefs.setString('LanguageCode', _locale.languageCode);
    });

    _onLocaleChanged(newLocale);
  }

  /// Current locale
  Locale get currentLocale => _locale;
}

/// Download of localized texts<br>
/// look example of use is source code [sap_application._SapApplicationState]
class SapLocalizations {
  final Locale _locale;

  static final _localizedValues = Map<String, dynamic>();
  static final _sapHandlerList = List<String>();

  /// SAP handler ID is used, when calling [sapTranslate], the `handlerID` parameter was not specified<br>
  /// look [loadFromSAP] parameter `setAsDefault`
  static String get defaultHandlerID => _defaultHandlerID;
  static String _defaultHandlerID;

  SapLocalizations(this._locale);

  String _translate(String handlerID, String key) {
    return _staticTranslate(handlerID, key);
  }

  static String _staticTranslate(String handlerID, String key) {
    if (handlerID == null) handlerID = "";
    var ret = _localizedValues["$handlerID|$key"];
    if (ret == null){
      if (handlerID.isNotEmpty) {
        if (!_sapHandlerList.contains(handlerID)) {
          throw StateError("translate texts for $handlerID not loaded");
        }
      }
      ret = key;
    }
    return ret;
  }

  static Future<SapLocalizations> _load(Locale locale) async {
    final String localeName =
    locale.countryCode == null || locale.countryCode.isEmpty
        ? locale.languageCode
        : locale.toString();

    Intl.defaultLocale = Intl.canonicalizedLocale(localeName);

    _localizedValues.clear();

    final languageStrings = _getLocaleStrings(locale);
    languageStrings.forEach((key, value){
      _localizedValues["|$key"] = value;
    });

    loadingFromSAP();

    return SapLocalizations(locale);
  }

  /// Register SAP handler as text provider
  static void loadFromSAP(String handlerID, {bool setAsDefault = false, bool startLoad = true}){
    if (handlerID != null) {
      if (!_sapHandlerList.contains(handlerID)) _sapHandlerList.add(handlerID);

      if (setAsDefault) _defaultHandlerID = handlerID;
    }

    if (startLoad) loadingFromSAP();
  }

  /// Start process to download text from registered SAP handlers
  static Future<FutureMessage> loadingFromSAP({bool showErrorToast = true, List<String> handlerList}) async {
    if (handlerList != null) {
      handlerList.forEach((newHandlerID){
        if (!_sapHandlerList.contains(newHandlerID)) _sapHandlerList.add(newHandlerID);
      });
    }

    if (_sapHandlerList.isEmpty) return null;

    final String query = json.encode(_sapHandlerList);

    final post = await SapConnect().fetchPost(
        handlerID: "YDK_CL_WEBS_UTILS",
        action: "GET_PROG_TEXTS",
        actionData: query
    );

    if (post.returnStatus != PostStatus.OK) {
      if (showErrorToast)
        Fluttertoast.showToast(
          msg: "Text downloading " + post.returnData,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );

      return FutureMessage(msg: "Text downloading " + post.returnData);
    }

    (json.decode(post.returnData) as List).forEach((subJson){
      _localizedValues[subJson["KEY"]] = subJson["VALUE"];
    });

    return null;
  }
}

/// Translation of text identifier according to current locale
/// * [key] text identifier
/// * [context] context<br>
/// when the context is unavailable it is possible to call without it, there will be problems only in case of
/// dynamic change of language - sometimes redrawing can be done before texts download
/// as a result text on the screen won't change, because we have a dynamic change of language only on start page
/// I don't think it is a problem  
/// * [handlerID] identifier of SAP's handler from which text was downloaded
String sapTranslate(String key, {BuildContext context, String handlerID}){
  if (context == null) {
    if (handlerID != null) {
      return SapLocalizations._staticTranslate(handlerID, key);
    }

    return SapLocalizations._staticTranslate(SapLocalizations._defaultHandlerID,  key);
  }

  final sapLocalizations = Localizations.of<SapLocalizations>(context, SapLocalizations);

  if (handlerID != null) {
    return sapLocalizations._translate(handlerID, key);
  }

  return sapLocalizations._translate(SapLocalizations._defaultHandlerID,  key);
}

/// Look [MaterialApp.localizationsDelegates]<br>
/// Look the example of use is source code [sap_application._SapApplicationState]
class SapLocalizationsDelegate extends LocalizationsDelegate<SapLocalizations> {
  SapLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return SapLanguages().languageList.keys.contains(locale.languageCode);
  }

  @override
  Future<SapLocalizations> load(Locale locale) => SapLocalizations._load(locale);

  @override
  bool shouldReload(SapLocalizationsDelegate old) => false;
}
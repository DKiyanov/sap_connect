/// SAP login screen
library sap_authorization;

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sap_connect.dart';
import 'sap_authorization_utils.dart';
import 'wait_screen.dart';
import 'sap_internationalization.dart';
import 'sap_file.dart';

String _translate(BuildContext context, String key) {
  return sapTranslate(key, context: context);
}

enum _LoginSubmitMode {
  SavePassword,
  ChangePassword,
}

class _LoginMode {
  static const String UseSavedPassword = 'X';
  static const String BiometricControl = 'B';

  /// Entry without waiting on the login screen
  static const String FastEntry = 'K';
}

/// Used constants strings for SharedPreferences
class SharedPreferencesName {
  static const String sapHost = 'SAP_host';
  static const String sapMandant = 'SAP_mandant';
  static const String sapLogin = 'SAP_Login';
  static const String sapPassword = 'SAP_Password';
  static const String PasswordData = 'PasswordData';
  static const String LoginList = 'LoginList';
}

/// Look [SapStartParams.onBiometricControlCallback]
typedef bool BiometricControlCallback(String login);

/// Class for SAP start parameters
class SapStartParams {
 ///Display on the screen input field to choose language
  final bool showLanguage;

  /// Display on the screen SAP login and SAP password
  final bool showSapLogin;

  /// Server address and port
  String host;

  /// Mandant
  String mandant;

  /// SAP login account
  String sapLogin;

  /// SAP login password
  String sapPassword;

  /// Store parameters of connection to the server on the device
  final bool opLoadSave;

  /// Possibility of editing parameters of connecting to the server
  final bool opEdit;

  /// Display parameters of connecting to the server on the screen
  final bool opVisible;

  /// Start show parameters of connecting to the server from menu item
  final bool opShowFromMenu;

  /// Using a secondary account
  final bool useSecondaryLogin;

  /// Possibility of entry without connection to SAP server - password's hash is saved upon successful login
  /// than entry without connection with sap server is possible
  final bool offLineLoginCan;

  /// display login button for entry without connection with SAP server on the authorization screen
  final bool offLineLoginButton;

  /// list of SAP handlers for whom localized texts will be downloaded
  final List<SapHandler> translateHandlerList;

  /// Check for updates at login
  final bool checkAppUpdate;

  /// Callback in which can take place an additional treatment which can work under login WaitScreen
  final FutureStartCallback onLoginProcess;

  /// Callback for biometric confirm user's data.<br>
  /// Is used if SAP server has an option of biometric identification. In that case there is no need to enter the password
  final BiometricControlCallback onBiometricControlCallback;

  /// rout which will be launched after successful entrance into SAP
  final String nextRouteName;

  /// rout which will be launched after successful entrance without connection with server
  final String offLineNextRouteName;

  /// Default handler type, look [SapConnect.defaultHandlerType]
  final String defaultHandlerType;

  /// Default handler ID, look [SapConnect.defaultHandlerID]
  final String defaultHandlerID;

  SapStartParams({
    this.showSapLogin = true,
    this.showLanguage = true,
    this.host = "",
    this.mandant = "",
    this.sapLogin = "",
    this.sapPassword = "",
    this.nextRouteName,
    this.offLineNextRouteName,
    this.opLoadSave = true,
    this.opEdit = true,
    this.opVisible = true,
    this.opShowFromMenu = false,
    this.useSecondaryLogin = false,
    this.offLineLoginCan = false,
    this.offLineLoginButton = false,
    this.translateHandlerList,
    this.checkAppUpdate = false,
    this.onLoginProcess,
    this.onBiometricControlCallback,
    this.defaultHandlerType,
    this.defaultHandlerID,
  });
}

/// The screen for setting up the connection to the server and the entrance to the server
class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.params}) : super(key: key);

  final SapStartParams params;

  @override
  State<StatefulWidget> createState() => _LoginPageState(params: this.params);
}

class _LoginPageState extends State<LoginPage> {
  _LoginPageState({this.params});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final SapStartParams params;

  Map<String, dynamic> _savedPasswordData;
  String _loginMode = "";
  bool _passwordChanged = false;
  List<dynamic> _loginList;

  String _login;
  String _password;

  bool _isStarting = true;
  bool _connectOptionsExpanded = false;

  bool _passwordObscure = true;

  final _languageList = List<DropdownMenuItem<Locale>>();
  final TextEditingController _tecHost = TextEditingController();
  final TextEditingController _tecMandant = TextEditingController();
  final TextEditingController _tecSapLogin = TextEditingController();
  final TextEditingController _tecSapPassword = TextEditingController();
  final TextEditingController _tecLogin = TextEditingController();
  final TextEditingController _tecPassword = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConnectOptions();

      _languageList.clear();
      _languageList.addAll(SapLanguages().localeList
          .map((locale) => DropdownMenuItem<Locale>(
                value: locale,
                child: Text(SapLanguages().languageList[locale.languageCode]),
              ))
          .toList()
      );
    });
  }

  void _loadConnectOptions() {
    if (!params.opLoadSave) return;
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      setState(() {
        if (params.host.isEmpty) params.host = prefs.getString(SharedPreferencesName.sapHost) ?? "";
        if (params.mandant.isEmpty) params.mandant = prefs.getString(SharedPreferencesName.sapMandant) ?? "";

        if (params.useSecondaryLogin) {
          if (params.sapLogin.isEmpty) params.sapLogin = prefs.getString(SharedPreferencesName.sapLogin) ?? "";
          if (params.sapPassword.isEmpty) params.sapPassword = prefs.getString(SharedPreferencesName.sapPassword) ?? "";
        }

        _savedPasswordData = json.decode(prefs.getString(SharedPreferencesName.PasswordData) ?? "{}");
        _loginList = json.decode(prefs.getString(SharedPreferencesName.LoginList) ?? "[]");

        if (_loginList.isNotEmpty) {
          _setLogin(_loginList[0]);
        }

        _tecHost.text = params.host;
        _tecMandant.text = params.mandant;
        _tecSapLogin.text = params.sapLogin;
        _tecSapPassword.text = params.sapPassword;

        if (!params.useSecondaryLogin) {
          if (params.host.isNotEmpty && params.mandant.isNotEmpty)
            _connectOptionsExpanded = false;
        } else {
          if (params.host.isNotEmpty &&
              params.mandant.isNotEmpty &&
              params.sapLogin.isNotEmpty &&
              params.sapPassword.isNotEmpty
          ) _connectOptionsExpanded = false;
        }

        _tecPassword.addListener(_onPasswordChange);

        _isStarting = false;
      });
    });
  }

  void _onPasswordChange() {
    _passwordChanged = true;
  }

  void _setLogin(String xLogin) {
    if (_tecLogin.text == xLogin) return;
    _tecLogin.text = xLogin;
    _loginMode = "";
    if (_savedPasswordData.isEmpty || xLogin.isEmpty) return;
    if (_savedPasswordData["login"] != xLogin.toUpperCase()) return;

    _loginMode = _savedPasswordData["loginMode"];
    if (_loginMode == _LoginMode.UseSavedPassword) {
      _tecPassword.text = "********";
      _loginMode = _LoginMode.UseSavedPassword;
    }
    if (_loginMode == _LoginMode.BiometricControl) {
      if (params.onBiometricControlCallback != null) {
        _tecPassword.text = "";
        _loginMode = _LoginMode.BiometricControl;
      } else {
        _loginMode = '';
      }
    }
    if (_loginMode == _LoginMode.FastEntry) {
      _login = xLogin;
      _runLogin();
    }
  }

  void _saveConnectOptions() async {
    if (!params.opLoadSave) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(SharedPreferencesName.sapHost, params.host);
    prefs.setString(SharedPreferencesName.sapMandant, params.mandant);

    if (params.useSecondaryLogin) {
      prefs.setString(SharedPreferencesName.sapLogin, params.sapLogin);
      prefs.setString(SharedPreferencesName.sapPassword, params.sapPassword);
    }

    _loginList.removeWhere((str) => str.toUpperCase() == _login.toUpperCase());
    _loginList.insert(0, _login);
    prefs.setString(SharedPreferencesName.LoginList, json.encode(_loginList));

    if (params.offLineLoginCan && _passwordChanged) {
      OfflineLogin.setLoginData(_login, getAuthorizationString(_login, _password, Salt.sapAuthorization));
    }
  }

  Future<FutureMessage> _savePasswordQuery() async {
    final post = await SapConnect().fetchPost(
        handlerType: "SYS",
        handlerID: "",
        action: "QUERY",
        actionData: "SAVE_PASS");

    if (post.returnStatus == PostStatus.Error) {
      return FutureMessage(msg: post.returnData);
    }

    if (post.returnData.isEmpty) {
      return FutureMessage( msg: _translate(context, "Msg1")); // The storage password on the device is denied
    }

    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      prefs.setString(SharedPreferencesName.PasswordData,
          _getSavedPasswordString(post.returnData));
      Fluttertoast.showToast(
        msg: _translate(context, "PasswordSaved"),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    });

    return null;
  }

  String _getSavedPasswordString(String loginMode) {
    return json.encode({
      "loginMode": loginMode,
      "login": _login.toUpperCase(),
      "hash": getAuthorizationString(_login, _password, Salt.sapAuthorization)
    });
  }

  Future<FutureMessage> _checkSavePasswordQuery() async {
    // проверка изменения режима хранения пароля
    final post = await SapConnect().fetchPost(
      handlerType: "SYS",
      handlerID: "",
      action: "QUERY",
      actionData: "SAVE_PASS",
    );

    if (post.returnStatus == PostStatus.Error) {
      return FutureMessage(msg: post.returnData);
    }

    if (post.returnData != _loginMode) {
      SharedPreferences.getInstance().then((SharedPreferences prefs) {
        String savedPasswordJsonStr = "";
        String msg = _translate(
            context, "Msg1"); // The storage password on the device is denied
        if (post.returnData.isNotEmpty) {
          savedPasswordJsonStr = _getSavedPasswordString(post.returnData);
          msg = _translate(context, "Msg2"); // The password storage mode on the device is changed
        }
        prefs.setString(SharedPreferencesName.PasswordData, savedPasswordJsonStr);
        Fluttertoast.showToast(
          msg: msg,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 4,
        );
      });
    }

    return null;
  }

  void _submit([_LoginSubmitMode loginSubmitMode]) {
    final form = this._formKey.currentState;
    if (form.validate()) {
      form.save();

      if (_loginMode == _LoginMode.BiometricControl &&
          params.onBiometricControlCallback != null
      ){
        if (!params.onBiometricControlCallback(_login)) return;
      }

      _runLogin(loginSubmitMode);
    }
  }

  void _runLogin([_LoginSubmitMode loginSubmitMode]) {
    String personAuthString;
    if (_loginMode.isNotEmpty && !_passwordChanged)
      personAuthString = _savedPasswordData["hash"];

    String passwordValidation;

    SapConnect.sapEntry(
      host: params.host,
      mandant: params.mandant,
      sapLogin: params.sapLogin,
      sapPassword: params.sapPassword,
      personLogin: _login,
      personPassword: _password,
      personAuthString: personAuthString,
      languageID: SapLanguages().currentLocale.languageCode,
      context: context,
      errorCheckCallback2: (post) async {
        FutureMessage msg;

        if (params.checkAppUpdate) {
          msg = await checkSelfUpdate();
          if (msg != null) return msg;
        }

        if (loginSubmitMode == _LoginSubmitMode.SavePassword) {
          msg = await _savePasswordQuery();
          if (msg != null) return msg;
        }

        if (loginSubmitMode == _LoginSubmitMode.ChangePassword) {
          final post = await SapConnect().fetchPost(
            handlerType: "SYS",
            handlerID: "SYS",
            action: "GET_PASSWORD_VALIDATION",
          );

          if (post.returnStatus == PostStatus.Error) {
            return FutureMessage(msg: post.returnData);
          }

          passwordValidation = post.returnData;
        }

        if (_loginMode.isNotEmpty) {
          msg = await _checkSavePasswordQuery();
          if (msg != null) return msg;
        }

        msg = await SapLocalizations.loadingFromSAP(
            handlerList: params.translateHandlerList,
            showErrorToast: false
        );
        if (msg != null) return msg;

        if (params.onLoginProcess != null) {
          msg = await params.onLoginProcess();
          if (msg != null) return msg;
        }
      },
    ).then((entry) {
      if (entry) {
        _saveConnectOptions();

        final sapConnect = SapConnect();
        if (sapConnect.defaultHandlerType == null) sapConnect.defaultHandlerType = params.defaultHandlerType;
        if (sapConnect.defaultHandlerID   == null) sapConnect.defaultHandlerID   = params.defaultHandlerID;

        if (loginSubmitMode == null) {
          Navigator.pushReplacementNamed(context, params.nextRouteName)
              .then((_) {
            if (SapConnect() != null) SapConnect().logoff();
          });
        } else {
          if (loginSubmitMode == _LoginSubmitMode.ChangePassword) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => _ChangePasswordPage(
                        login: _login,
                        passwordValidation: passwordValidation
                    )
                )
            ).then( (_){
              if (SapConnect() != null) SapConnect().logoff();
            });
          }
          if (loginSubmitMode == _LoginSubmitMode.SavePassword) {
            if (SapConnect() != null) SapConnect().logoff();
          }
        }
      }
    });
  }

  void _offLineLoginSubmit() async {
    final form = this._formKey.currentState;
    if (form.validate()) {
      form.save();

      String personAuthString;
      if (_loginMode.isNotEmpty && !_passwordChanged)
        personAuthString = _savedPasswordData["hash"];
      else
        personAuthString = getAuthorizationString(_login, _password, Salt.sapAuthorization);

      if (await OfflineLogin.checkLoginData(_login, personAuthString)) {
        String routeName;
        routeName = params.nextRouteName;
        if (params.offLineNextRouteName != null)
          routeName = params.offLineNextRouteName;

        Navigator.pushReplacementNamed(context, routeName);
      } else {
        Fluttertoast.showToast(
          msg: _translate(context, "Msg3"),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_translate(context, "Starting")),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    if (!params.useSecondaryLogin) {
        if (_tecHost.text.isEmpty ||
            _tecMandant.text.isEmpty
        ) _connectOptionsExpanded = true;
    } else {
        if (_tecHost.text.isEmpty ||
            _tecMandant.text.isEmpty ||
            _tecSapLogin.text.isEmpty ||
            _tecSapPassword.text.isEmpty
        ) _connectOptionsExpanded = true;
    }

    final languageLabel = Text(
      _translate(context, "Language"),
      style: theme.textTheme.caption.copyWith(color: params.opEdit ? null : theme.disabledColor),
    );

    final selectLanguage = DropdownButton<Locale>(
      key: Key('selectLanguage'),
      style: params.opEdit ? null : theme.textTheme.caption.copyWith(color: theme.disabledColor),
      value: SapLanguages().currentLocale,
      items: _languageList,
      onChanged: (newValue) {
        if (!params.opEdit) return;

        setState(() {
          SapLanguages().setLocale(newValue);
        });
      },
      isDense: true,
      isExpanded: true,
    );

    final inputHost = TextFormField(
        key: Key('inputHost'),
        enabled: params.opEdit,
        style: params.opEdit ? null : TextStyle(color: theme.disabledColor),
        controller: _tecHost,
        decoration: InputDecoration(
          hintText: _translate(context, "HostHint"),
          labelText: _translate(context, "Host"),
        ),
        onSaved: (String value) {
          params.host = value;
        });

    final inputMandant = TextFormField(
        key: Key('inputMandant'),
        enabled: params.opEdit,
        style: params.opEdit ? null : TextStyle(color: theme.disabledColor),
        controller: _tecMandant,
        decoration: InputDecoration(
          hintText: _translate(context, "MandantHint"),
          labelText: _translate(context, "Mandant"),
        ),
        onSaved: (String value) {
          params.mandant = value;
        });

    final inputSapLogin = TextFormField(
        key: Key('inputSapLogin'),
        enabled: params.opEdit,
        style: params.opEdit ? null : TextStyle(color: theme.disabledColor),
        controller: _tecSapLogin,
        decoration: InputDecoration(
          hintText: _translate(context, "SapLoginHint"),
          labelText: _translate(context, "SapLogin"),
        ),
        onSaved: (String value) {
          params.sapLogin = value;
        });

    final inputSapPassword = TextFormField(
        key: Key('inputSapPassword'),
        enabled: params.opEdit,
        style: params.opEdit ? null : TextStyle(color: theme.disabledColor),
        controller: _tecSapPassword,
        obscureText: true,
        decoration: InputDecoration(
          hintText: _translate(context, "SapPasswordHint"),
          labelText: _translate(context, "SapPassword"),
        ),
        onSaved: (String value) {
          params.sapPassword = value;
        });

    Widget loginListButton;
    if (_loginList.isNotEmpty) {
      loginListButton = PopupMenuButton(itemBuilder: (BuildContext context) {
        return _loginList.map((str) {
          return PopupMenuItem<String>(child: Text(str), value: str);
        }).toList();
      }, onSelected: (String value) {
        setState(() {
          _setLogin(value);
        });
      });
    }

    final inputLogin = TextFormField(
        key: Key('inputLogin'),
        controller: _tecLogin,
        decoration: InputDecoration(
          hintText: _translate(context, "UserLoginHint"),
          labelText: _translate(context, "UserLogin"),
          suffix: loginListButton,
        ),
        onSaved: (String value) {
          this._login = value;
          if (!params.useSecondaryLogin) params.sapLogin = value;
        });

    final inputPassword = TextFormField(
      key: Key('inputPassword'),
      controller: _tecPassword,
      obscureText: _passwordObscure,
      decoration: InputDecoration(
        hintText: _translate(context, "UserPasswordHint"),
        labelText: _translate(context, "UserPassword"),
        suffix: IconButton(
          icon: Icon(_passwordObscure ? Icons.lock : Icons.lock_open),
          onPressed: () {
            setState(() {
              _passwordObscure = !_passwordObscure;
            });
          },
        ),
      ),
      onSaved: (String value) {
        if (params.useSecondaryLogin)
          this._password = value;
        else
          params.sapPassword = value;
      },
    );

    final expandWidgetList = List<Widget>();
    final popupMenuItemList = List<PopupMenuItem<VoidCallback>>();
    List<Widget> actionList;

    if (params.showLanguage) {
      expandWidgetList.add(languageLabel);
      expandWidgetList.add(selectLanguage);
    }

    expandWidgetList.add(inputHost);
    expandWidgetList.add(inputMandant);

    final expansionPanel = ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _connectOptionsExpanded = !_connectOptionsExpanded;
        });
      },
      children: <ExpansionPanel>[
        ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile( title: Text(
              _translate(context, "ConnectionOptions"),
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w400,
              ),
            ));
          },
          body: Padding(
              padding: EdgeInsets.only(left: 10, right: 10, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: expandWidgetList,
              )
          ),
          isExpanded: _connectOptionsExpanded,
        ),
      ],
    );

    if (params.opShowFromMenu){
      popupMenuItemList.add(PopupMenuItem<VoidCallback>(
          child: Text(_translate(context, "ConnectionOptions")),
          value: () {
            setState(() {
              _connectOptionsExpanded = true;
            });
          })
      );
    }

    if (params.useSecondaryLogin) {
      if (params.showSapLogin) {
        expandWidgetList.add(inputSapLogin);
        expandWidgetList.add(inputSapPassword);
      }
      popupMenuItemList.add(PopupMenuItem<VoidCallback>(
          child: Text(_translate(context, "ChangePassword")),
          value: () => _submit(_LoginSubmitMode.ChangePassword))
      );
      popupMenuItemList.add(PopupMenuItem<VoidCallback>(
          child: Text(_translate(context, "SavePassword")),
          value: () => _submit(_LoginSubmitMode.SavePassword))
      );
    }

    if (popupMenuItemList.isNotEmpty) {
      actionList = List<Widget>();
      actionList.add(PopupMenuButton(
          itemBuilder: (BuildContext context) => popupMenuItemList,
          onSelected: (callBack) => callBack()
      ));
    }

    final loginButton = Row( children: <Widget>[ Expanded( child: RaisedButton(
      key: Key('loginButton'),
      child: Text(
          _translate(context, "LoginButton"),
          style: TextStyle(color: Colors.white)
      ),
      onPressed: this._submit,
      color: Colors.blue,
    ))]);

    final offLineLoginButton = Row( children: <Widget>[ Expanded( child: RaisedButton(
      key: Key('offLineLoginButton'),
      child: Text(
          _translate(context, "OffLineLoginButton"),
          style: TextStyle(color: Colors.white)
      ),
      onPressed: this._offLineLoginSubmit,
      color: Colors.blue,
    ))]);

    final outWidgetList = List<Widget>();
    if (params.opVisible && (_connectOptionsExpanded || !params.opShowFromMenu)) outWidgetList.add(expansionPanel);
    outWidgetList.add(inputLogin);
    outWidgetList.add(inputPassword);
    outWidgetList.add(Container( height: 20 ));
    outWidgetList.add(loginButton);
    if (params.offLineLoginButton) {
      outWidgetList.add(Container( height: 5 ));
      outWidgetList.add(offLineLoginButton);
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          title: Text(_translate(context, "LoginPageTitle")),
          actions: actionList,
      ),
      body: Container(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: this._formKey,
            child: ListView(
              children: outWidgetList,
            ),
          )
      ),
    );
  }
}

class _ChangePasswordPage extends StatefulWidget {
  _ChangePasswordPage({Key key, this.login, this.passwordValidation})
      : super(key: key);

  final String login;
  final String passwordValidation;

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _password;
  bool _passwordObscure = true;

  void _submit() {
    final form = this._formKey.currentState;
    if (form.validate()) {
      form.save();

      String personAuthString = getAuthorizationString(
          widget.login, _password, Salt.sapAuthorization);

      SapConnect().fetchPostWS(
          handlerType: "SYS",
          handlerID: "",
          action: "CHANGE_PASSWORD",
          actionData: personAuthString,
          context: context,
          postCallback: (Post post) {
              Fluttertoast.showToast(
                  msg: _translate(context, "PasswordChanged"),
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
              );

              Navigator.pop(context);
          }
      );
    }
  }

  void _cancel() {
    Navigator.pop(context);
  }

  String _validatePassword(String value) {
    if (widget.passwordValidation == null || widget.passwordValidation.isEmpty)
      return null;

    final parsedJson = json.decode(widget.passwordValidation);
    final String msg = parsedJson["MESSAGE"];
    if (msg == null) return null;

    final int minLength = parsedJson["MIN_LENGTH"];
    final int minDigits = parsedJson["DIGITS"];
    final int minSymbols = parsedJson["SYMBOLS"];

    if ((minLength != null && value.length < minLength) ||
        (minDigits != null &&
            RegExp('\\d').allMatches(value).length < minDigits) ||
        (minSymbols != null &&
            RegExp('[\$-/:-?{-~!"^_`\\[\\]]').allMatches(value).length <
                minSymbols)) {
      return msg;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          title: Text(_translate(context, "ChangePassword")),
      ),
      body: Container(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: this._formKey,
            child: ListView(
              children: <Widget>[
                TextFormField(
                    initialValue: widget.login,
                    decoration: InputDecoration(
                        labelText: _translate(context, "UserLogin"),
                    ),
                    style: TextStyle(color: Colors.grey),
                    enabled: false,
                ),
                TextFormField(
                    obscureText: _passwordObscure,
                    decoration: InputDecoration(
                        hintText: _translate(context, "NewPasswordHint"),
                        labelText: _translate(context, "NewPassword"),
                        suffix: IconButton(
                          icon: Icon(
                              _passwordObscure ? Icons.lock : Icons.lock_open),
                          onPressed: () {
                            setState(() {
                              _passwordObscure = !_passwordObscure;
                            });
                          },
                        ),
                    ),
                    validator: _validatePassword,
                    onSaved: (String value) {
                        this._password = value;
                    }
                ),
                Container(height: 20),
                Row(children: <Widget>[
                    Expanded( child: RaisedButton(
                        child: Text(
                            _translate(context, "Cancel"),
                            style: TextStyle(color: Colors.white)
                        ),
                        onPressed: this._cancel,
                        color: Colors.blue,
                    )),
                    Container(
                        width: 8,
                        height: 1,
                    ),
                    Expanded( child: RaisedButton(
                        child: Text(
                            _translate(context, "Change"),
                            style: TextStyle(color: Colors.white)
                        ),
                        onPressed: this._submit,
                        color: Colors.blue,
                    )),
                ])
              ],
            ),
          )),
      );
  }
}

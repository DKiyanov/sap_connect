part of 'sap_internationalization.dart';

/// Look [kGetLanguageList]<br>
/// returned map:
/// * key - language id string, two chars
/// * value - language name: <language name on english> <name of the language in the national alphabet>
typedef GetLanguageList = Map<String, String> Function();

/// Look [kGetLocaleStrings]<br>
/// returned map:
/// * key - text ID
/// * value - text string in the appropriate locale
typedef GetLocaleStrings = Map<String, String> Function(Locale locale);

/// Global link to the function of available languages list's extension
GetLanguageList kGetLanguageList;

/// Global link to extend/change translation of already added languages and add new languages of interface
GetLocaleStrings kGetLocaleStrings;

Map<String, String> _getLanguageList(){
  final ret = {
    'en' :'English',
    'ru' :'Russian Русский',
  };

  if (kGetLanguageList != null) ret.addAll(kGetLanguageList());

  return ret;
}

Map<String, String> _getLocaleStrings(Locale locale){
  final ret = Map<String, String>();

  switch(locale.languageCode){
    case 'en': ret.addAll(_getLocaleStringsEN()); break;
    case 'ru': ret.addAll(_getLocaleStringsRU()); break;
  }

  if (kGetLocaleStrings != null) ret.addAll(kGetLocaleStrings(locale));

  return ret;
}

Map<String, String> _getLocaleStringsEN(){
  return {
    "Language": "Language",
    "Host": "Host",
    "HostHint": "Enter host addres to connect to SAP",
    "Mandant": "Client",
    "MandantHint": "Enter client number",
    "SapLogin": "SAP Login",
    "SapLoginHint": "Enter SAP login",
    "SapPassword": "SAP Password",
    "SapPasswordHint": "Enter SAP Password",
    "UserLogin": "Login",
    "UserLoginHint": "Enter your login",
    "UserPassword": "Password",
    "UserPasswordHint": "Enter your Password",
    "LoginButton": "Login",
    "OffLineLoginButton": "Offline login",
    "ConnectionOptions": "Connection options",
    "LoginPageTitle": "Login",
    "Starting": "Starting",
    "ChangePassword" : "Change password",
    "NewPasswordHint" : "Enter your new password",
    "NewPassword" : "New password",
    "SavePassword" : "Save password",
    "EntryToSap" : "Entry to SAP system",
    "Cancel" : "Cancel",
    "Change" : "Change",
    "PasswordChanged" : "Password changed",
    "Msg1" : "The storage password on the device is denied",
    "Msg2" : "The password storage mode on the device is changed",
    "PasswordSaved" : "Password saved",
    "Error" : "Error",
    "UnspecifiedError" : "Unspecified error",
    "Msg3" : "The username or password you entered is incorrect",
    "Msg4" : "User can not be logged in",
    "Msg5" : "Error in the data on the side of the mobile application",
    "Msg6" : "Internal server error",
    "Msg7" : "Invalid answer from server",
    "ConnectionError" : "Connection error",
    "CanceledByUser" : "Canceled by user",
    "Install" : "Install",
    "Msg8" : "There is an update, you need to install",
    "\$UnknownLanguageCode" : "\$Selected incorrect language code",
    "\$ErrOnSessionOpening" : "\$Error on session opening"
  };
}

Map<String, String> _getLocaleStringsRU(){
  return {
    "Language": "Язык",
    "Host": "Адрес сервера",
    "HostHint": "Введите адрес сервера SAP",
    "Mandant": "Мандант",
    "MandantHint": "Введите номер манданта",
    "SapLogin": "Имя пользователя SAP",
    "SapLoginHint": "Введите имя пользователя SAP",
    "SapPassword": "Пароль SAP",
    "SapPasswordHint": "Введите пароль SAP",
    "UserLogin": "Имя пользователя",
    "UserLoginHint": "Введите ваше имя пользователя",
    "UserPassword": "Пароль",
    "UserPasswordHint": "Введите ваш пароль",
    "LoginButton": "Вход",
    "OffLineLoginButton": "Вход без подключения к серверу",
    "ConnectionOptions": "Настройки соединения",
    "LoginPageTitle": "Вход",
    "Starting": "Запуск",
    "ChangePassword" : "Изменить пароль",
    "NewPasswordHint" : "Введитье свой новый пароль",
    "NewPassword" : "Новый пароль",
    "SavePassword" : "Сохранить пароль",
    "EntryToSap" : "Вход в систему SAP",
    "Cancel" : "Отмена",
    "Change" : "Изменить",
    "PasswordChanged" : "Пароль изменён",
    "Msg1" : "В хранении пароля на устройстве отказано",
    "Msg2" : "Режим хранения пароля на устройстве изменён",
    "PasswordSaved" : "Пароль сохранён",
    "Error" : "Ошибка",
    "UnspecifiedError" : "Не определённая ошибка",
    "Msg3" : "Не верное имя пользователя или пароль",
    "Msg4" : "Пользователь не может быть авторизован в системе",
    "Msg5" : "Ошибка в данных на стороне мобильного приложения",
    "Msg6" : "Внутренняя ошибка сервера",
    "Msg7" : "Не корректный ответ сервера",
    "ConnectionError" : "Ошибка соединения",
    "CanceledByUser" : "Отменено пользователем",
    "Install" : "Установить",
    "Msg8" : "Есть обновление, необходимо установить",
    "\$UnknownLanguageCode" : "\$Выбран не корректный код языка",
    "\$ErrOnSessionOpening" : "\$Ошибка при открытии сесии"
  };
}



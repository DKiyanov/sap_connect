/// Obscure screen shading for controls of the program for the duration of the process
library wait_screen;

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:async/async.dart';

import 'sap_internationalization.dart';

/// Callback for start Future, look [startWaitScreen.futureStartCallback]
typedef FutureStartCallback = Future<FutureMessage> Function();

/// Opens a obscure screen ("WaitScreen") shading program controls, while the "Future" is performed and processed
/// This "Future" is launched with parameter [futureStartCallback]
/// * [context] context
/// * [title] process description, displayed on WaitScreen
/// * [futureStartCallback] is a Callback for launching "Future"
/// upon completion "Future" can return:
///   - null - it means that "Future" is performed
/// WaitScreen is removed, work of startWaitScreen is over<br>
///   - [FutureMessage] - appropriate message will be display on WaitScreen
/// * [canceled] Callback - is performed when user cancels the operation<br>
/// WaitScreen is removed
/// * [performed] Callback - is performed upon the end "Future" processing<br>
/// WaitScreen is removed
void startWaitScreen({
  BuildContext context,
  String title,
  FutureStartCallback futureStartCallback,
  VoidCallback canceled,
  VoidCallback performed
}){
  Navigator.of(context).push<bool>(_WaitScreen(title, futureStartCallback)).then((ret){
    if (!ret && canceled != null) canceled();
    if (ret && performed != null) performed();
  });
}

/// Is back as a possible result of "Future" launching from WaitScreen
/// look [FutureStartCallback]
class FutureMessage {
  FutureMessage({this.hideMainTitle = false, this.title, this.titleColor, this.msg, this.onBuildMessage, this.startNextFuture});

  /// Do not show main title, look [startWaitScreen]( `title: ...`)
  final bool hideMainTitle;

  /// Message title
  final String title;

  /// Color of message title
  final Color titleColor;

  /// Message
  final String msg;

  /// Callback to form message interface,
  /// this is for cases if you need some special message interface
  /// for example, see source code [sap_file.checkSelfUpdate]
  final OnWaitScreenMessage onBuildMessage;

  /// Launch next Future, as a result there can be built a chain of Futures performing one by one
  /// for example, see source code [sap_file.checkSelfUpdate]  
  final FutureStartCallback startNextFuture;
}

/// look [FutureMessage.onBuildMessage]
typedef Widget OnWaitScreenMessage(BuildContext context, FutureMessage msg, WaitScreenDrawer drawer);

/// look [OnWaitScreenMessage]
// is necessary to hide class _waitScreenContentState from caller
class WaitScreenDrawer{
  final _WaitScreenContentState _waitScreenContentState;
  WaitScreenDrawer(this._waitScreenContentState);

  /// set new [FutureMessage] to display/perform it in WaitScreen
  void setMessage({FutureMessage futureMessage}){
    _waitScreenContentState.setMessage(futureMessage);
  }
}

class _WaitScreen extends ModalRoute<bool> {
  _WaitScreen(this.title, this.futureStartCallback):super();

  final String title;
  final FutureStartCallback futureStartCallback;

  @override
  Duration get transitionDuration => Duration(milliseconds: 0);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => null; //Colors.black.withOpacity(0);

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      ) {

    // This makes sure that text and other content follows the material style
    return Material(
      type: MaterialType.transparency,
      // make sure that the overlay content is not cut off
      child: SafeArea(
        child: _WaitScreenContent(waitScreen : this),
      ),
    );
  }
}

class _WaitScreenContent extends StatefulWidget {
  _WaitScreenContent({@required this.waitScreen}):super();

  final _WaitScreen waitScreen;

  @override
  _WaitScreenContentState createState() => _WaitScreenContentState();
}

class _WaitScreenContentState extends State<_WaitScreenContent> {
  Future future;
  Timer _timer;
  int _mode = -1;
  CancelableOperation _cancelableOperation;
  FutureMessage msg;

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  void setMessage(FutureMessage newMessage){
    msg = newMessage;

    if (msg != null) {
      if (msg.startNextFuture != null) {
        futureStart( msg.startNextFuture );
      }
      else {
        setState(() {
          _mode = 3;
        });
      }
    }

    if (msg == null) {
      Navigator.pop(context, true);
    }
  }

  void futureStart(FutureStartCallback futureStartCallback){
    final future  = futureStartCallback();
    _cancelableOperation = CancelableOperation.fromFuture( future );
    future.then( futureThen );

    setState(() {
      _mode = 1;
    });
  }

  void futureThen(FutureMessage futureMessage){
    if (_mode < 2) {
      _timer.cancel();
      _mode = 2;

      setMessage( futureMessage );
    }
  }

  Widget waitWidget(BuildContext context){
    final widgetList = List<Widget>();

    if (widget.waitScreen.title != null){
      widgetList.add(
        Container(
          margin: const EdgeInsets.all(10.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 2 ),
            borderRadius: BorderRadius.all( Radius.circular(10.0)),
          ),
          child: Text(widget.waitScreen.title),
        ),
      );
    }

    widgetList.add(Center(child : CircularProgressIndicator()));
    widgetList.add(Container(height: 5,),);

    widgetList.add(
        RaisedButton(
          onPressed: () {
            if (_mode == 1) {
              _timer.cancel();
              _mode = 2;
              _cancelableOperation.cancel();
              Navigator.pop(context, false);
            }
          },
          child: Text(sapTranslate("Cancel")),
        )
    );

    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widgetList,
        ),
      ),
    );
  }

  Widget messageWidget(BuildContext context){
    final widgetList = List<Widget>();

    if (widget.waitScreen.title != null && !msg.hideMainTitle){
      widgetList.add( Text( widget.waitScreen.title ) );
    }

    if (msg.title != null){
      widgetList.add(
          Text(
              msg.title,
              style: msg.titleColor == null ? null : TextStyle(color: msg.titleColor)
          )
      );
    }

    Widget msgWidget;
    if (msg.onBuildMessage !=null) {
      msgWidget = msg.onBuildMessage(context, msg, WaitScreenDrawer(this));
    }
    else {
      msgWidget = Text(
          msg.msg,
          style: TextStyle(fontSize: 20.0),
          softWrap: true
      );
    }

    widgetList.add(msgWidget);

    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.all(10.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 2 ),
                borderRadius: BorderRadius.all( Radius.circular(10.0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widgetList,
              ),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(sapTranslate("Cancel")),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // _mode:
    // -1 - запускает: timer задержки отображения блокирующего экрана, future, переключает _mode в 0
    //  0 - ничего не отображает - ожидание срабатывания таймера
    //  1 - включается таймером - отображает блокирующий экран с ожиданием завершения выполнянеия операции
    //  2 - ничего не отображает - включается при завершении future - переключает:
    //      в 3 если есть ошибка
    //      в 1 если есть следующий future
    //      выход из ws если всё хорошо
    //  3 - отображение блокирующего экрана с ошибкой

    if (_mode == -1) {
      _mode = 0;

      // Задержка сделана чтоб исключить моргание при выполнении быстрых запросов
      _timer = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _mode = 1;
        });
      });

      futureStart(widget.waitScreen.futureStartCallback);
    }

    if (_mode == 0){
      return Container();
    }

    if (_mode == 1) {
      return waitWidget(context);
    }

    if (_mode == 2){
      return Container();
    }

    if (_mode == 3) {
      return messageWidget(context);
    }

    return Container(); // по идее сюда код попадать не должен, но студия ругается...
  }
}
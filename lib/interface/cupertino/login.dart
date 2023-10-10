// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:dio/dio.dart';
import 'package:event/event.dart';
import 'package:flutter/cupertino.dart';
import 'package:ogaku/interface/cupertino/base_app.dart';
import 'package:ogaku/share/share.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Boiler: returned to the main application
StatefulWidget get loginPage => LoginPage();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController loginController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: true,
          trailing: CupertinoButton(
              padding: EdgeInsets.all(10),
              child: Text('Next',
                  style: TextStyle(
                      color: (loginController.text.isNotEmpty && passwordController.text.isNotEmpty)
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.inactiveGray)),
              onPressed: () => (loginController.text.isNotEmpty && passwordController.text.isNotEmpty)
                  ? tryLogin(login: loginController.text, pass: passwordController.text)
                  : null),
          middle: FittedBox(
              fit: BoxFit.fitWidth,
              child: Container(
                margin: EdgeInsets.only(right: 25),
                child: Text('Log in - ${Share.currentProvider?.providerName}'),
              )),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Opacity(
                  opacity: 0.7,
                  child: Container(
                      margin: EdgeInsets.only(top: 60, left: 20, right: 20),
                      child: Text(Share.currentProvider?.providerDescription ?? '', style: TextStyle(fontSize: 14)))),
              Container(
                  margin: EdgeInsets.only(top: 20),
                  child: CupertinoFormSection.insetGrouped(children: [
                    CupertinoFormRow(
                        prefix: Text('Username'),
                        child: CupertinoTextFormFieldRow(
                          textAlign: TextAlign.end,
                          placeholder: 'Librus\u00AE Synergia username',
                          controller: loginController,
                          onChanged: (s) => setState(() {}),
                        )),
                    CupertinoFormRow(
                        prefix: Text('Password'),
                        child: CupertinoTextFormFieldRow(
                          obscureText: true,
                          textAlign: TextAlign.end,
                          placeholder: 'Librus\u00AE Synergia password',
                          controller: passwordController,
                          onChanged: (s) => setState(() {}),
                        ))
                  ])),
              Expanded(
                  child: Align(
                alignment: Alignment.bottomCenter,
                child: Opacity(
                    opacity: 0.5,
                    child: Container(
                        margin: EdgeInsets.only(right: 20, left: 20, bottom: 20),
                        child: Text(
                          "Any login credentials won't be kept by the app, although they may be locally saved by the e-register service provider, either as encoded text or an access token. This data is not, and will never be shared with neither us nor any third-parties.",
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.justify,
                        ))),
              )),
            ]),
      ),
    );
  }

  void tryLogin({required String login, required String pass}) async {
    try {
      var result = await Share.currentProvider!
          .login(session: '81C59CC9-AA58-4FF4-BE69-91B1028F1C04', username: login, password: pass);

      if (!result.success && result.message != null) {
        throw result.message!;
      } else {
        Share.changeBase.broadcast(Value(() => baseApp));
      }
    } on DioException catch (e) {
      Fluttertoast.showToast(
        msg: e.message ?? '$e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
      );
    } on Exception catch (e) {
      Fluttertoast.showToast(
        msg: '$e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
      );
    }
  }
}

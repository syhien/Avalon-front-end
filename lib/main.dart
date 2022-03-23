import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_verification_box/verification_box.dart';
import 'package:dio/dio.dart';

const String baseURL = "http://81.69.23.94:5001";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avalon',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const WelcomePage(),
    );
  }
}

class StoreName extends StatefulWidget {
  const StoreName({Key? key}) : super(key: key);

  @override
  State<StoreName> createState() => _StoreNameState();
}

class _StoreNameState extends State<StoreName> {
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('需要一些信息以继续')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              '我们需要您的昵称',
              style: TextStyle(fontSize: 26),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: '选取易于称呼的昵称有助于游戏时的沟通交流')))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '确认昵称',
        child: const Icon(Icons.done),
        onPressed: () {
          Navigator.pop(context, nameController.text);
        },
      ),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String name = "";
  var barTitle = "欢迎回来";

  @override
  void initState() {
    super.initState();
    barTitle = "欢迎回来，$name";
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString('name') ?? "null";
    setState(() {
      barTitle = "欢迎回来，$name";
    });
    if (name == "null") {
      Navigator.push(context,
              MaterialPageRoute(builder: (context) => const StoreName()))
          .then((value) {
        name = value;
        print(name);
        setState(() {
          barTitle = "欢迎回来，$name";
        });
        prefs.setString('name', name);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(barTitle),
      ),
      body: Image.asset('images/The_Death_of_King_Arthur.jpg'),
      floatingActionButton: FloatingActionButton(
        tooltip: '下一步',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const JoinPage())),
        child: const Icon(Icons.arrow_right_alt),
      ),
    );
  }
}

class JoinPage extends StatefulWidget {
  const JoinPage({Key? key}) : super(key: key);

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  Timer? timer;
  var _onPressed;
  List<String> _players = [];
  List<String> _readyPlayers = [];

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _readyForGame() async {
    var prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    final room = prefs.getString('game');
    var dio = Dio();
    try {
      var response = await dio.post(baseURL + '/readyGame',
          queryParameters: {'game': room, 'name': name});
      _players = response.data['players'].cast<String>();
      _readyPlayers = response.data['readyPlayers'].cast<String>();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _joinGame(room) async {
    var prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    prefs.setString('game', room);
    var dio = Dio();
    try {
      var response = await dio.post(baseURL + '/join',
          queryParameters: {'game': room, 'name': name});
      _players = response.data['players'].cast<String>();
      _readyPlayers = response.data['readyPlayers'].cast<String>();
      timer = timer ??
          Timer.periodic(
              const Duration(seconds: 1), (Timer t) => _joinGame(room));
      if (_players.isNotEmpty) {
        setState(() {
          _onPressed = () => _readyForGame();
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('集结伙伴')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '与玩伴输入同样的4位数字',
                style: TextStyle(fontSize: 26),
              ),
            ),
            SizedBox(
              height: 45,
              child: VerificationBox(
                count: 4,
                focusBorderColor: Colors.lightBlue,
                onSubmitted: (value) => _joinGame(value),
              ),
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: _readyPlayers.contains(_players[index])
                            ? const Icon(Icons.verified)
                            : const Icon(Icons.pending),
                        title: Text(
                          _players[index],
                          style: const TextStyle(fontSize: 20),
                        ),
                      );
                    }))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: '我已就绪',
          onPressed: _onPressed,
          child: const Icon(Icons.check_circle),
        ));
  }
}

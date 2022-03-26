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
  var _buttonIcon = const Icon(Icons.check_circle);
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
    final game = prefs.getString('game');
    var dio = Dio();
    try {
      final response = await dio.post(baseURL + '/readyGame',
          queryParameters: {'game': game, 'name': name});
      _players = response.data['players'].cast<String>();
      _readyPlayers = response.data['readyPlayers'].cast<String>();
      if (_readyPlayers.contains(name)) {
        setState(() {
          _onPressed = null;
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _refresh() async {
    var prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    final game = prefs.getString('game');
    try {
      var response = await Dio().get(baseURL + '/players',
          queryParameters: {'game': game, 'name': name});
      setState(() {
        _players = response.data['players'].cast<String>();
        _readyPlayers = response.data['readyPlayers'].cast<String>();
      });
    } catch (e) {
      print(e.toString());
    }
    if (!_readyPlayers.contains(name)) {
      setState(() {
        _onPressed = () => _readyForGame();
      });
    }
    if (_players.length == _readyPlayers.length &&
        _players.length >= 5 &&
        _players.length <= 10) {
      setState(() {
        _buttonIcon = const Icon(Icons.arrow_right_alt);
        _onPressed = () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const IdentityPage()));
      });
    }
  }

  Future<void> _joinGame(game) async {
    _players = [];
    _readyPlayers = [];
    var prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    prefs.setString('game', game);
    var dio = Dio();
    try {
      var response = await dio.post(baseURL + '/join',
          queryParameters: {'game': game, 'name': name});
      setState(() {
        _players = response.data['players'].cast<String>();
        _readyPlayers = response.data['readyPlayers'].cast<String>();
      });
      timer =
          Timer.periodic(const Duration(seconds: 1), (Timer t) => _refresh());
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
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '所有玩伴集结并就绪后，即可出发进行任务',
                style: TextStyle(fontSize: 24),
              ),
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      return Card(
                          child: ListTile(
                        leading: _readyPlayers.contains(_players[index])
                            ? const Icon(
                                Icons.verified,
                                color: Colors.green,
                              )
                            : const Icon(Icons.pending),
                        title: Text(
                          _players[index],
                          style: const TextStyle(fontSize: 20),
                        ),
                      ));
                    })),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: '我已就绪',
          onPressed: _onPressed,
          child: _buttonIcon,
        ));
  }
}

class IdentityPage extends StatefulWidget {
  const IdentityPage({Key? key}) : super(key: key);

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  String _identity = "";
  List<String> _seenPlayers = [];

  Future<void> _getIdentity() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      final game = prefs.getString('game');
      final response = await Dio().get(baseURL + '/identity',
          queryParameters: {'game': game, 'name': name});
      _identity = response.data['identity'];
      _seenPlayers = response.data['seenPlayers'].cast<String>();
      prefs.setString('identity', _identity);
      prefs.setStringList('seenPlayers', _seenPlayers);
      setState(() {});
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _getIdentity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('确认身份及情报'),
      ),
      body: Text('你是 $_identity，你看到 $_seenPlayers'),
      floatingActionButton: FloatingActionButton(
        tooltip: '我已就绪',
        onPressed: () => {},
        child: const Icon(Icons.arrow_right_alt),
      ),
    );
  }
}

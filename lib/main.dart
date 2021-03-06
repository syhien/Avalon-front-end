import 'dart:async';
import 'dart:js_util';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_verification_box/verification_box.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
      body: Container(
        alignment: Alignment.center,
        child: Image.asset(
          'images/The_Death_of_King_Arthur.jpg',
          width: window.physicalSize.width * 0.6,
        ),
      ),
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
        timer?.cancel();
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
    prefs.setInt('job', 1);
    prefs.setInt('leaderCount', 1);
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
                            : const CircularProgressIndicator(
                                backgroundColor: Colors.white,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.green),
                              ),
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

Future<bool> isLeader() async {
  var prefs = await SharedPreferences.getInstance();
  final name = prefs.getString('name');
  final game = prefs.getString('game');
  final job = prefs.getInt('job')!;
  final leaderCount = prefs.getInt('leaderCount')!;
  final response = await Dio().get(baseURL + '/formTeam', queryParameters: {
    'game': game,
    'name': name,
    'job': job,
    'leaderCount': leaderCount
  });
  final leader = response.data['leader'];
  final players = response.data['players'].cast<String>();
  if (players[leader] == name) {
    print("I am leader");
  } else {
    print("I am not leader");
  }
  return players[leader] == name;
}

class IdentityPage extends StatefulWidget {
  const IdentityPage({Key? key}) : super(key: key);

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  bool amLeader = false;
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
      amLeader = await isLeader();
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

  static const Map<String, String> identitiesChineseMap = {
    'Merlin': '🧙梅林🧙',
    'Percival': '🔍派西维尔🔍',
    'Loyal Servant of Arthur': '⛨亚瑟的忠臣⛨',
    'Morgana': '🎭莫甘娜🎭',
    'Assassin': '🔪刺客🔪',
    'Oberon': '🤪奥伯伦🤪',
    'Minion of Mordred': '👿莫德雷德的爪牙👿',
    'Mordred': '😈莫德雷德😈'
  };

  static const Map<String, Icon> identitiesSeenIconMap = {
    'Merlin': Icon(
      Icons.gpp_bad,
      color: Colors.redAccent,
    ),
    'Percival': Icon(
      Icons.contact_support,
      color: Colors.grey,
    ),
    'Morgana': Icon(
      Icons.gpp_bad,
      color: Colors.black,
    ),
    'Assassin': Icon(
      Icons.gpp_bad,
      color: Colors.black,
    ),
    'Minion of Mordred': Icon(
      Icons.gpp_bad,
      color: Colors.black,
    ),
    'Mordred': Icon(
      Icons.gpp_bad,
      color: Colors.black,
    )
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('确认身份及情报'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                alignment: Alignment.topLeft,
                child: Text(
                    '你的身份是: ' +
                        (_identity.isNotEmpty
                            ? identitiesChineseMap[_identity]!
                            : ''),
                    style: const TextStyle(fontSize: 24)),
              )),
          Container(
              alignment: Alignment.topCenter,
              child: _identity.isNotEmpty
                  ? Image.asset('images/$_identity.jpg',
                      width: window.physicalSize.width * 0.4)
                  : null),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                alignment: Alignment.topLeft,
                child: const Text('朦胧之中你看到了: ', style: TextStyle(fontSize: 22)),
              )),
          Expanded(
              child: ListView.builder(
                  itemCount: _seenPlayers.length,
                  itemBuilder: (context, index) {
                    return Card(
                        child: ListTile(
                      leading: identitiesSeenIconMap[_identity]!,
                      title: Text(
                        _seenPlayers[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ));
                  })),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '我已就绪',
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    amLeader ? const ChooseTeamPage() : const VoteTeamPage())),
        child: const Icon(Icons.arrow_right_alt),
      ),
    );
  }
}

Map teamNumbersDict = <int, List<int>>{
  5: [0, 2, 3, 2, 3, 3],
  6: [0, 2, 3, 4, 3, 4],
  7: [0, 2, 3, 4, 4, 4],
  8: [0, 3, 4, 4, 5, 5],
  9: [0, 3, 4, 4, 5, 5],
  10: [0, 3, 4, 4, 5, 5]
};

class ChooseTeamPage extends StatefulWidget {
  const ChooseTeamPage({Key? key}) : super(key: key);

  @override
  State<ChooseTeamPage> createState() => _ChooseTeamPageState();
}

class _ChooseTeamPageState extends State<ChooseTeamPage> {
  int job = 0;
  int leaderCount = 0;
  List<String> _players = [];
  List<String> _pickedPlayers = [];
  var _onPressed;
  void getJob() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      final game = prefs.getString('game');
      final response = await Dio().get(baseURL + '/status',
          queryParameters: {'game': game, 'name': name});
      job = prefs.getInt('job')!;
      leaderCount = prefs.getInt('leaderCount')!;
      _players = response.data['players'].cast<String>();
      setState(() {});
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> formTeam() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      final game = prefs.getString('game');
      final response = await Dio().post(baseURL + '/formTeam',
          queryParameters: {
            'game': game,
            'name': name,
            'team': _pickedPlayers
          });
      if (response.statusCode == 200) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const VoteTeamPage()));
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    getJob();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择任务成员'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                alignment: Alignment.topLeft,
                child: Text(
                    '任务' +
                        job.toString() +
                        '第' +
                        leaderCount.toString() +
                        '次选拔',
                    style: const TextStyle(fontSize: 24)),
              )),
          Expanded(
              child: ListView.builder(
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                        title: Text(_players[index]),
                        value: _pickedPlayers.contains(_players[index]),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _pickedPlayers.add(_players[index]);
                            } else {
                              _pickedPlayers.remove(_players[index]);
                            }
                            if (_pickedPlayers.length ==
                                teamNumbersDict[_players.length][job]) {
                              _onPressed = () => formTeam();
                            } else {
                              _onPressed = null;
                            }
                          });
                        });
                  }))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '确认选择',
        onPressed: _onPressed,
        child: const Icon(Icons.arrow_right_alt),
      ),
    );
  }
}

class VoteTeamPage extends StatefulWidget {
  const VoteTeamPage({Key? key}) : super(key: key);

  @override
  State<VoteTeamPage> createState() => _VoteTeamPageState();
}

class _VoteTeamPageState extends State<VoteTeamPage> {
  Timer? timer;
  int job = 0;
  int leaderCount = 0;
  List<String> _players = [];
  List<String> _team = [];
  int leader = 0;
  var _onPressed;

  void getJob() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      job = prefs.getInt('job')!;
      leaderCount = prefs.getInt('leaderCount')!;
      final name = prefs.getString('name');
      final game = prefs.getString('game');
      final response = await Dio().get(baseURL + '/voteTeam', queryParameters: {
        'game': game,
        'name': name,
        'job': job,
        'leaderCount': leaderCount
      });
      setState(() {
        leader = response.data['leader'];
        _players = response.data['players'].cast<String>();
        _team = response.data['team'].cast<String>();
      });
      if (_team.length == teamNumbersDict[job][leaderCount]) {
        timer?.cancel();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      getJob();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> postVoteTeam(bool agree) async {
    try {
      var prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      final game = prefs.getString('game');
      Dio().post(baseURL + '/voteTeam', queryParameters: {
        'game': game,
        'name': name,
        'job': job,
        'leaderCount': leaderCount,
        'vote': agree ? 'agree' : 'disagree'
      });
      timer = Timer.periodic(
          const Duration(seconds: 1), (Timer t) => checkVoteTeam());
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> checkVoteTeam() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      final game = prefs.getString('game');
      final gameStatus = await Dio().get(baseURL + '/status',
          queryParameters: {'game': game, 'name': name});
      final players = gameStatus.data['players'].cast<String>();
      final response = await Dio().get(baseURL + '/voteTeam', queryParameters: {
        'game': game,
        'name': name,
        'job': job,
        'leaderCount': leaderCount
      });
      final team = response.data['team'].cast<String>();
      final agrees = response.data['voteTeamMap'][job.toString()]
              [leaderCount.toString()]['agree']
          .cast<String>();
      final disagrees = response.data['voteTeamMap'][job.toString()]
              [leaderCount.toString()]['disagree']
          .cast<String>();
      if (agrees.length + disagrees.length == players.length) {
        timer?.cancel();
        setState(() {
          //如玩家为任务成员，跳转到任务页面，否则跳转到等待页面
          if (agrees.length > disagrees.length) {
            if (team.contains(name)) {
              Fluttertoast.showToast(msg: '投票通过，点击执行任务');
              _onPressed = () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const VoteJobPage()));
              };
            } else {
              Fluttertoast.showToast(msg: '投票通过，点击查看任务结果');
              _onPressed = () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const WaitJobPage()));
            }
          }
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务成员投票'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                alignment: Alignment.topLeft,
                child: Text(
                    '任务' +
                        job.toString() +
                        '第' +
                        leaderCount.toString() +
                        '次选拔',
                    style: const TextStyle(fontSize: 24)),
              )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              alignment: Alignment.topLeft,
              child: Text(
                  '本次选拔的队长为' + (_players.isNotEmpty ? _players[leader] : ""),
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  return Card(
                      child: ListTile(
                    leading: _team.contains(_players[index])
                        ? const Icon(Icons.check)
                        : const Icon(Icons.check_box_outline_blank),
                    title: Text(_players[index],
                        style: const TextStyle(fontSize: 20)),
                  ));
                }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  child: const Text('赞成'),
                  onPressed: () => postVoteTeam(true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  child: const Text('反对'),
                  onPressed: () => postVoteTeam(false),
                ),
              )
            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '确认投票结果',
        onPressed: _onPressed,
        child: const Icon(Icons.arrow_right_alt),
      ),
    );
  }
}

class WaitJobPage extends StatefulWidget {
  const WaitJobPage({Key? key}) : super(key: key);

  @override
  State<WaitJobPage> createState() => _WaitJobPageState();
}

class _WaitJobPageState extends State<WaitJobPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
      title: const Text('等待任务执行完毕'),
    ));
  }
}

class VoteJobPage extends StatefulWidget {
  const VoteJobPage({Key? key}) : super(key: key);

  @override
  State<VoteJobPage> createState() => _VoteJobPageState();
}

class _VoteJobPageState extends State<VoteJobPage> {
  Timer? timer;
  var _onPressed;

  @override
  void initState() {
    super.initState();
    timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => checkVoteJob());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkVoteJob() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      final game = prefs.getString('game');
      final job = prefs.getInt('job');
      final response = await Dio().get(baseURL + '/voteJob',
          queryParameters: {'game': game, 'name': name, 'job': job});
      final team = response.data['team'].cast<String>();
      final passes = response.data['voteJobMap']['pass'].cast<String>();
      final fails = response.data['voteJobMap']['fail'].cast<String>();
      if (passes.length + fails.length == team.length) {
        timer?.cancel();
        Fluttertoast.showToast(msg: '任务完毕，点击查看任务结果');
        setState(() {
          _onPressed = () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ResultPage()));
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> postVoteJob(bool pass) async {
    try {
      var prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      final game = prefs.getString('game');
      final job = prefs.getInt('job');
      final vote = pass ? 'pass' : 'fail';
      final response = await Dio().post(baseURL + '/voteJob', queryParameters: {
        'game': game,
        'name': name,
        'job': job,
        'vote': vote
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('进行任务'),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              child: const Text('任务成功'),
              onPressed: () => postVoteJob(true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              child: const Text('任务失败'),
              onPressed: () => postVoteJob(false),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '确认投票结果',
        onPressed: _onPressed,
        child: const Icon(Icons.arrow_right_alt),
      ),
    );
  }
}

class ResultPage extends StatefulWidget {
  const ResultPage({Key? key}) : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool failed = false;
  var passes = null;
  var fails = null;

  @override
  void initState() {
    super.initState();
    getResult();
  }

  Future<void> getResult() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      final game = prefs.getString('game');
      final job = prefs.getInt('job');
      final response = await Dio().get(baseURL + '/voteJob',
          queryParameters: {'game': game, 'name': name, 'job': job});
      final team = response.data['team'].cast<String>();
      passes = response.data['voteJobMap']['pass'].cast<String>();
      fails = response.data['voteJobMap']['fail'].cast<String>();
      setState(() {
        failed = fails.isNotEmpty;
        if (job == 4 && team.length >= 7) {
          if (fails.length >= 2) {
            failed = true;
          } else {
            failed = false;
          }
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> nextJob() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      final job = prefs.getInt('job')! + 1;
      prefs.setInt('job', job);
      prefs.setInt('leaderCount', 1);
      if (await isLeader()) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => ChooseTeamPage()));
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => VoteTeamPage()));
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务结果'),
      ),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '任务成功：' + (passes == null ? ' ' : passes.length.toString()),
              style: const TextStyle(fontSize: 24),
            )),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '任务失败：' + (fails == null ? ' ' : fails.length.toString()),
              style: const TextStyle(fontSize: 24),
            )),
      ]),
      floatingActionButton: FloatingActionButton(
        tooltip: '进入下一任务',
        onPressed: () => nextJob(),
        child: const Icon(Icons.arrow_right_alt),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      home: WelcomePage(),
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
    );
  }
}

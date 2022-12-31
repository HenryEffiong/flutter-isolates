import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';

Future<void> countIsolate(int cycles) async {
  for (int i = 0; i < cycles; i++) {
    print("isolate: $i");
  }
}

void worker(SendPort parentPort) {
  final requestPort = ReceivePort();
  parentPort.send(requestPort.sendPort);
  requestPort.listen((message) {
    // Do something with message from parent
  });
}

int countCompute(int cycles) {
  int count = 0;
  for (int i = 0; i < cycles; i++) {
    count++;
    debugPrint("isolate: $i");
  }
  return count;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> myFirstIsolate() async {
    // 1. Create the main function receive port
    ReceivePort parentReceivePort = ReceivePort();

    // 2. Create an Isolate and pass the main function's SendPort
    Isolate.spawn(isolateFunction, parentReceivePort.sendPort);

    // 5. Get the SendPort from the Isolate
    SendPort childSendPortFromIsolate = await parentReceivePort.first;

    // 6. Create the receive port that is to get the information of the response from the isolate
    ReceivePort responsePort = ReceivePort();

    // 7. Pass the task to the Isolate for execution alongside the SendPort for the response
    childSendPortFromIsolate
        .send(["https://randomuser.me/api/", responsePort.sendPort]);

    // 10. Get the executed task from the Isolate.
    var myExecutedTaskFromIsolate = await responsePort.first;
    debugPrint(myExecutedTaskFromIsolate);
  }

  static void isolateFunction(SendPort parentReceivePortSendPort) async {
    // 3. Create the Isolate's ReceivePort
    ReceivePort childReceivePort = ReceivePort();

    //4. Send the Isolate's SendPort up to the main Function
    parentReceivePortSendPort.send(childReceivePort.sendPort);

    // 8. Get the task to be executed
    await for (var message in childReceivePort) {
      String url = message[0];
      SendPort replyPort = message[1];

      // 9. Execute task
      await countIsolate(1000);
      replyPort.send('Result from executed task');
    }

    childReceivePort.listen((message) {
      print("message received: $message");
    });
  }

  void foo() {
    final isoResponse = ReceivePort();
    SendPort isoRequest;
    Isolate.spawn<SendPort>(worker, isoResponse.sendPort);

    isoResponse.listen((message) {
      if (message is SendPort) {
        print(message);
        isoRequest = message;
      } else {
        // Do something with Isolates message
      }
    });
  }

  @override
  void initState() {
    // Isolate.spawn(countIsolate, 100);
    myFirstIsolate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

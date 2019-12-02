import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> appList;

  @override
  void initState(){
    appList = List<String>();

    super.initState();
  }

  void getData() async {
    bool isEnd = false;
    int startIndex = 0;
    var tempAppMap = Map<String, String>();

    do {
      await http.get(Uri.https(
        'pngweb.3g.qq.com', 
        '/KingSimCardFreeFlowAppListGet', 
        {'classId': "0", 'startIndex': '${startIndex.toString()}', 'pageSize': '100'},
      )).then((http.Response response) {
        if (response.statusCode == 200) {
          var responseData = json.decode(response.body);
          responseData['appList'].forEach((item) =>
            tempAppMap[item['appId'].toString()] = item['appName']
          );
          
          setState(() {
            appList = tempAppMap.values.toList();
          });

          startIndex += 100;
          isEnd = !responseData['isLastBatch'];
          print(responseData['isLastBatch']);
        } else {
          isEnd = false;
        }
      });
    } while (isEnd);

    // setState(() {
    //   appMap = tempAppMap;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'App Count: ${appList.length}',
          ),
          Expanded(
            child: ListView.builder(
              itemCount: appList.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Text(appList[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getData,
        tooltip: 'Get Data',
        child: Icon(Icons.refresh),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app.dart';
import 'appDao.dart';

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
  AppDao appDao;
  int appCount;

  @override
  void initState(){
    appList = List<String>();
    appDao = AppDao();

    super.initState();
  }

  void getData() async {
    bool isEnd = false;
    int startIndex = 0;
    var tempAppMap = Map<String, App>();

    do {
      await http.get(Uri.https(
        'pngweb.3g.qq.com', 
        '/KingSimCardFreeFlowAppListGet', 
        {'classId': "0", 'startIndex': '${startIndex.toString()}', 'pageSize': '100'},
      )).then((http.Response response) {
        if (response.statusCode == 200) {
          var responseData = json.decode(response.body);
          responseData['appList'].forEach((item) =>
            tempAppMap[item['appId'].toString()] = App(
              item['appId'],
              item['appName'],
              item['editorIntro'],
              item['iconUrl'],
              item['packageName'],
            )
          );
          
          // setState(() {
          //   appCount = tempAppMap.length;
          // });

          startIndex += 100;
          isEnd = !responseData['isLastBatch'];
          print(responseData['isLastBatch']);
        } else {
          isEnd = false;
        }
      });
    } while (isEnd);

    await appDao.insertMany(tempAppMap.values.toList());
    int tempCount = await appDao.getCount();
    setState(() {
      appCount = tempCount;
    });
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
            'App Count: ${appCount.toString()}',
          ),
          RaisedButton(
            onPressed: () async {
              await appDao.deleteAll();
            },
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

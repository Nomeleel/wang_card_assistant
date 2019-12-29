import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app.dart';
import 'appDao.dart';
import 'package:path_provider/path_provider.dart';

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
  List<App> appList;
  ScrollController controller;
  AppDao appDao;
  int appCount;

  final int showTopButtonHeightLimit = 200;

  bool _isLoadMore;

  @override
  void initState() {
    appList = List<App>();
    controller = ScrollController();
    appDao = AppDao()..initAndRun((value) => getMore());
    _isLoadMore = false;

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
        {'classId': "0", 'startIndex': '$startIndex', 'pageSize': '100'},
      )).then((http.Response response) {
        if (response.statusCode == 200) {
          var responseData = json.decode(response.body);
          responseData['appList'].forEach((item) =>
            tempAppMap[item['appId'].toString()] = App(
              item['appId'].toString(),
              item['appName'],
              item['editorIntro'],
              item['iconUrl'],
              item['packageName'],
              '7777777'
            )
          );

          startIndex += 100;
          isEnd = !responseData['isLastBatch'];
          print(responseData['isLastBatch']);
        } else {
          isEnd = false;
        }
      });
    } while (isEnd);

    await appDao.insertMany(tempAppMap.values.toList());
  }

  Future<int> getMore() async {
    var result = await appDao.findMany(appList.length, 10);
    if (result.length > 0) {
      setState(() {
        appList.addAll(result);
      });
    }

    return result.length;
  }  

  // TODO jump to top.

  @override
  Widget build(BuildContext context) {
    print('build');
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
            onPressed: () {
              appDao.deleteAll();
            },
            child: Text('Delete'),
          ),
          RaisedButton(
            onPressed: () {
              getMore();
            },
            child: Text('Get Data'),
          ),
          RaisedButton(
            onPressed: () async {
              var count = await appDao.getCount();

              setState(() {
                appCount = count;
              });
            },
            child: Text('Get Count'),
          ),
          RaisedButton(
            onPressed: () async {
              print('-----------------');
              if(Platform.isAndroid){
                Directory tempDir = await getTemporaryDirectory();
                print(tempDir.path);
                print('-----------------');
                Directory appDir = await getApplicationSupportDirectory();
                print(appDir.path);
                print('-----------------');
                Directory appDocDir = await getApplicationDocumentsDirectory();
                print(appDocDir.path);
                print('-----------------');
                await getExternalCacheDirectories()..forEach((item) {
                  print(item.path);
                });
                print('-----------------');
                await getExternalStorageDirectories()..forEach((item) {
                  print(item.path);
                });
                print('-----------------');
              }
              print('-----------------');
            },
            child: Text('Test Path'),
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                ListView.builder(
                  itemCount: appList.length,
                  physics: BouncingScrollPhysics(),
                  controller: controller
                    ..addListener((){
                      print(controller.position.pixels);
                      print(controller.hasClients);
                      if (!_isLoadMore && controller.position.pixels >= controller.position.maxScrollExtent) {
                        _isLoadMore = true;
                        getMore().then((value) {
                          if (value == 10) {
                            _isLoadMore = false;
                          } else{
                            print('no more data $value');
                            // TODO: No more data label.
                          }
                        });
                      }

                      // position on 200 up and down refresh view.
                      if ((controller.position.axisDirection == AxisDirection.down && controller.position.pixels >= showTopButtonHeightLimit) ||
                      (controller.position.axisDirection == AxisDirection.up && controller.position.pixels <= showTopButtonHeightLimit)) {
                        setState(() {
                          print('refresh');
                        });
                      }
                    }
                  ),
                  itemBuilder: (context, index) {
                    return Text(appList[index].name,
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: (controller.hasClients && controller.position.pixels > showTopButtonHeightLimit) ? 15 : -50,
                  right: 10,
                  child: ClipOval(
                    child: Container(
                      height: 40,
                      width: 40,
                      color: Theme.of(context).focusColor,
                      child: IconButton(
                        icon: Icon(Icons.arrow_upward),
                        onPressed: () => {
                          controller.animateTo(
                            0,
                            duration: Duration(
                              milliseconds: (controller.position.pixels * 0.3).toInt(),
                            ),
                            curve: Curves.easeInOut,
                          )
                        },
                      ),
                    ),
                  ),
                ),
              ],
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

  @override
  void dispose(){
    controller.dispose();

    super.dispose();
  }

}

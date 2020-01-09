import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
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
  final _listKey = GlobalKey<AnimatedListState>();
  List<App> appList;
  ScrollController controller;
  AppDao appDao;
  int appCount;

  final int showTopButtonHeightLimit = 200;

  bool _isLoadMore;
  List<String> _localInstalledAppList;
  Map<String, bool> _currentInstalledAppMap;

  @override
  void initState() {
    appList = List<App>();
    controller = ScrollController();
    appDao = AppDao()..initAndRun((value) => getMore());
    _isLoadMore = false;
    _localInstalledAppList = List<String>();
    _currentInstalledAppMap = Map<String, bool>();
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
    filter(result);
    checkInstallInfo(result);
    if (result.length > 0) {
      //setState(() {
        //appList.addAll(result);
      //});
      result.forEach((item) {
        appList.add(item);
        _listKey.currentState.insertItem(appList.length - 1, duration: Duration(milliseconds: 777));
      });
    }

    return result.length;
  }  

  void filter(List<App> appList) {
    appList.removeWhere((item) {
      if (Platform.isAndroid) {
        return item.packageName == null || item.packageName == '';
      } else if (Platform.isIOS) {
        return item.bundleId == null || item.bundleId == '';
      } else{
        // Nothing to do.
      }
      return false;
    });
  }

  void checkInstallInfo(List<App> appList) {
    appList.forEach((item) {
      _currentInstalledAppMap[item.packageName] = _localInstalledAppList.contains(item.packageName);
    });
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
                AnimatedList(
                  key: _listKey,
                  initialItemCount: appList.length,
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
                  itemBuilder: (context, index, animation) {
                    return SlideTransition(
                      position: animation.drive(
                        CurveTween(curve: Curves.elasticInOut)
                      ).drive(
                        Tween<Offset>(
                          begin: Offset(-1, 0),
                          end: Offset(0, 0),
                        )
                      ),
                      child: listItemBuilder(appList[index]),
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

  // TODO Find free slim font.
  Widget listItemBuilder(App app){
    return Row(
      children: <Widget> [
        Padding(
          padding: EdgeInsets.fromLTRB(15, 10, 10, 10),
          child: Image.network(
            app.iconUrl,
            width: 55,
            height: 55,
          ),
        ),
        Expanded(
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: Colors.black,
                  width: 0.1,
                ),
              )
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 11),
                        child: Text(
                          app.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18.5,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          app.description,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                (_currentInstalledAppMap[app.packageName]
                  ? actionButton("打开", () {
                    var appKey = Platform.isAndroid ? app.packageName : app.bundleId;
                    //openApp(appKey);
                  })
                  : actionButton("获取", () {

                  })
                ),
              ],
            ),
          ),
        ),
      ]
    );
  }

  Widget actionButton(String label, Function function) {
    return CupertinoButton(
      child: Container(
        width: 63,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.all(
            Radius.circular(15)
          )
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            color: Colors.white,
          ),
        ),
      ),
      onPressed: () {
        function();
      }
    );
  }

  @override
  void dispose(){
    controller.dispose();

    super.dispose();
  }

}

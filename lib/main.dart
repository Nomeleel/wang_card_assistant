import 'dart:io';
import 'dart:math';

import 'package:application_management/application_management.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'appDao.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: '王卡助手',
      theme: CupertinoThemeData(
        barBackgroundColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MyHomePage(title: '免流应用'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<App> appList;
  ScrollController controller;
  AppDao appDao;

  final int showTopButtonHeightLimit = 200;
  final int pageSize = 20;

  bool _isLoadMore;
  Map<String, bool> _currentInstalledAppMap;
  int pageNumber = 0;

  @override
  void initState() {
    appList = <App>[];
    controller = ScrollController();
    appDao = AppDao()..initAndRun(getMore);
    _isLoadMore = false;
    _currentInstalledAppMap = <String, bool>{};
    super.initState();
  }

  Future<int> getMore() async {
    final List<App> result =
        await appDao.findMany(pageNumber * pageSize, pageSize);
    final int dataCount = result.length;
    pageNumber++;
    filter(result);
    await checkInstallInfo(result);
    if (result.isNotEmpty) {
      final void Function(App) addApp = (App app) {
        appList.add(app);
        _listKey.currentState.insertItem(appList.length - 1,
            duration: const Duration(milliseconds: 777));
      };

      result.forEach(addApp);
    }

    return dataCount;
  }

  void filter(List<App> appList) {
    appList.removeWhere((App item) =>
        isNullorEmpty(Platform.isAndroid ? item.packageName : item.bundleId));
  }

  bool isNullorEmpty(String str) {
    return str == null || str.isEmpty;
  }

  Future<void> checkInstallInfo(List<App> appList) async {
    final List<String> appKeyList = appList
        .map<String>((App item) =>
            Platform.isAndroid ? item.packageName : item.urlScheme)
        .toList();
    appKeyList.removeWhere((String item) => item == null || item == '');
    final Map<String, bool> isInstallMap = await isInstalledMap(appKeyList);
    _currentInstalledAppMap.addAll(isInstallMap);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.title,
          style: TextStyle(
            fontSize: 18.5,
            fontWeight: FontWeight.w100,
          ),
        ),
        trailing: CupertinoButton(
          padding: const EdgeInsets.only(
            right: 19,
          ),
          child: Icon(
            Icons.refresh,
            size: 27,
            color: Colors.purple,
          ),
          onPressed: () {
            // TODO(Nomeleel): imp
          },
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.2,
          ),
        ),
      ),
      child: Stack(
        children: <Widget>[
          AnimatedList(
            key: _listKey,
            initialItemCount: appList.length,
            physics: const BouncingScrollPhysics(),
            controller: controller
              ..addListener(() {
                if (!_isLoadMore &&
                    controller.position.pixels >=
                        controller.position.maxScrollExtent) {
                  _isLoadMore = true;
                  getMore().then((int value) {
                    if (value == 20) {
                      _isLoadMore = false;
                    } else {
                      print('no more data $value');
                      // TODO(Nomeleel): No more data label.
                    }
                  });
                }
              }),
            itemBuilder:
                (BuildContext context, int index, Animation<double> animation) {
              return SlideTransition(
                position: animation
                    .drive(CurveTween(curve: Curves.elasticInOut))
                    .drive(Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: const Offset(0, 0),
                    )),
                child: listItemBuilder(appList[index]),
              );
            },
          ),
          Positioned(
            bottom: 15,
            right: 10,
            child: ClipOval(
              child: Container(
                height: 40,
                width: 40,
                color: Colors.purple.withOpacity(0.7),
                child: CupertinoButton(
                  padding: const EdgeInsets.only(
                    left: 1,
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    controller.animateTo(
                      0,
                      duration: Duration(
                        milliseconds:
                            (controller.position.pixels * 0.3).toInt(),
                      ),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TODO(Nomeleel): Find free slim font.
  Widget listItemBuilder(App app) {
    return Row(children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 10, 10, 10),
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/image/${Random().nextInt(7)}.png',
          image: app.iconUrl,
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
              )),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 11),
                      child: Text(
                        app.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
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
              actionButton(app),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget actionButton(App app) {
    final String appKey = Platform.isAndroid ? app.packageName : app.urlScheme;
    return _currentInstalledAppMap.keys.contains(appKey) &&
            _currentInstalledAppMap[appKey]
        ? actionButtonWidget('打开', () => openApp(appKey))
        : actionButtonWidget('获取', () {
            if (Platform.isAndroid) {
              // open in tencent qqdownloader.
              openInSpecifyAppStore(appKey, 'com.tencent.android.qqdownloader',
                  'com.tencent.pangu.link.LinkProxyActivity');
            } else {
              openInAppStore(app.bundleId);
            }
          });
  }

  Widget actionButtonWidget(String label, Function function) {
    return CupertinoButton(
      child: Container(
        width: 63,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: const BorderRadius.all(Radius.circular(15))),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            color: Colors.white,
          ),
        ),
      ),
      onPressed: () => function(),
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }
}

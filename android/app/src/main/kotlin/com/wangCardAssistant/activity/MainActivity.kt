package com.wangCardAssistant.activity

import android.os.Bundle

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    getWindow().setStatusBarColor(0)
    GeneratedPluginRegistrant.registerWith(this)
  }
}

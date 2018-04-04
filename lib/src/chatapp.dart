library chatapp;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'dart:io';

// Authentication
part 'util/authentication.dart';

// Pages
part 'pages/chat_page.dart';

// Firebase
final analytics = new FirebaseAnalytics();

// App
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Chit Chat',
      home: new ChatScreen(),
      theme: defaultTargetPlatform == TargetPlatform.iOS ? iOSTheme : androidTheme,
    );
  }
}

// Themes
final ThemeData iOSTheme = new ThemeData(
  brightness: Brightness.dark,
  accentColor: Colors.grey[300],
);

final ThemeData androidTheme = new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);

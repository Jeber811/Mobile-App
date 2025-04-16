import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'login.dart';
import 'signup.dart';
import 'change_password.dart';
import 'cards.dart';
import 'models/goal.dart';

void main() => runApp(MaterialApp(
  theme: ThemeData(
    fontFamily: 'Roboto',
    primaryColor: Colors.blue[800],
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Colors.blueAccent,
    ),
  ),
  home: Login(),
));
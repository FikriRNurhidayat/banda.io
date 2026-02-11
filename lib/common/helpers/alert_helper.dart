import 'package:flutter/material.dart';

alert(ScaffoldMessengerState messenger, String text) {
  messenger.showSnackBar(
    SnackBar(content: Text(text, textAlign: TextAlign.center)),
  );
}

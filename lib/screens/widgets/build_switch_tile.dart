import 'package:flutter/material.dart';

Widget BuildSwitchTile({
  required String title,
  required bool value,
  required Function(bool) onChanged,
}) {
  return SwitchListTile(
    title: Text(
      title,
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    value: value,
    onChanged: onChanged,
    activeColor: Colors.blue, // Warna switch biru
    contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Atur padding di sini
  );
}
import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String text;

  const CustomFAB({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: Colors.blue,
      icon: Icon(icon, color: Colors.white),
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Atur padding
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
      tooltip: text,
    );
  }
}

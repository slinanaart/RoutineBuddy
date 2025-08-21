import 'package:flutter/material.dart';

class CasualPreviewScreen extends StatelessWidget {
  const CasualPreviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Casual Template'),
      ),
      body: const Center(
        child: Text('Casual Template Preview'),
      ),
    );
  }
}

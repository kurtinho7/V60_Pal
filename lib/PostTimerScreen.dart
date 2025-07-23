import 'package:flutter/material.dart';
import 'package:v60pal/models/Recipe.dart';

class PostTimerScreen extends StatefulWidget {
  final Recipe recipe;
  const PostTimerScreen({super.key, required this.recipe});
  @override
  State<PostTimerScreen> createState() => _PostTimerScreenState();
}

class _PostTimerScreenState extends State<PostTimerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: Icon(Icons.done),
            tooltip: 'Done',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Enjoy!')],
        ),
      ),
    );
  }
}

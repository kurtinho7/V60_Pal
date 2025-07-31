import 'package:flutter/material.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/persistence/JournalStorage.dart';



class PostTimerScreen extends StatefulWidget {
  final Recipe recipe;
  const PostTimerScreen({super.key, required this.recipe});
  @override
  State<PostTimerScreen> createState() => _PostTimerScreenState();
}

class _PostTimerScreenState extends State<PostTimerScreen> {
  Recipe get recipe => widget.recipe;



  Beans newBeans = Beans(
    id: "",
    name: "Johan",
    origin: "Columbua",
    roastLevel: "medium",
  );

  void onPressed(BuildContext context) {
    final journalEntry = JournalEntry(
      id: '',
      rating: "5",
      waterTemp: 100,
      timeTaken: 100,
      grindSetting: "5.2",
      notes: "Awesome",
      beans: newBeans,
      recipe: recipe,
    );

    Journal journal = Provider.of<Journal>(context);

    setState(() {
      journal.addEntry(journalEntry);
    });

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
                final journalEntry = JournalEntry(
                    id: '',
                    rating: "5",
                    waterTemp: 100,
                    timeTaken: 100,
                    grindSetting: "5.2",
                    notes: "Awesome",
                    beans: newBeans,
                    recipe: recipe,
                  );

                Journal journal = context.read<Journal>();

                await journal.addEntry(journalEntry);

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
          children: [Text('Enjoy!', style: TextStyle(color: Colors.white70))],
        ),
      ),
    );
  }
}

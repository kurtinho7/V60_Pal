import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/JournalEntry.dart';

class JournalEntryViewScreen extends StatefulWidget {
  final JournalEntry journalEntry;
  const JournalEntryViewScreen({super.key, required this.journalEntry});

  @override
  State<JournalEntryViewScreen> createState() => _JournalEntryViewScreenState();
}

class _JournalEntryViewScreenState extends State<JournalEntryViewScreen> {
  @override
  Widget build(BuildContext context) {
    final entry = widget.journalEntry;
    return Container(
      height: 670,
      width: 400,
      color: BACKGROUND_COLOR,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white10,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(4.0),
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  color: Colors.black12,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rating",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                    RatingBar(
                      ignoreGestures: true,
                      initialRating: double.parse(entry.rating),
                      minRating: 0.5,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                      ratingWidget: RatingWidget(
                        full: Icon(Icons.star, color: PRIMARY_COLOR),
                        half: Icon(Icons.star_half, color: PRIMARY_COLOR),
                        empty: Icon(Icons.star_border, color: PRIMARY_COLOR),
                      ),
                      onRatingUpdate: (rating) {},
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    hintText: entry.notes,
                    hintStyle: TextStyle(color: TEXT_COLOR),
                  ),
                  style: TextStyle(color: TEXT_COLOR),
                ),
              ],
            ),
          ),
          SizedBox(height: 10), // Spacing between fields
          Text("Recipe", style: TextStyle(color: TEXT_COLOR, fontSize: 20)),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white10,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(4.0),
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  color: Colors.black12,
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recipe",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                    Text(
                      entry.recipe.name,
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Dose",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                    Text(
                      entry.recipe.coffeeDose,
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Water",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                    Text(
                      "${entry.recipe.waterWeightGrams}g",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Time Taken",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                    Text(
                      "${entry.timeTaken}s",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Grind Setting",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                    Text(
                      entry.grindSetting,
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Water Temp",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                    Text(
                      "${entry.waterTemp}",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text("Beans", style: TextStyle(color: TEXT_COLOR, fontSize: 20)),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white10,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(4.0),
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  color: Colors.black12,
                ),
              ],
            ),
            child: (Column(
              children: [
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Beans",
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                    Text(
                      entry.beans.name,
                      style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                    ),
                  ],
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/BeansList.dart';

class BeansScreen extends StatelessWidget {
  const BeansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final beansList = Provider.of<BeansList>(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: GridView.builder(
          itemCount: beansList.entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemBuilder: (_, i) {
            final beans = beansList.entries[i];
            return Padding(
              padding: EdgeInsetsGeometry.all(10),
              child: GridTile(child: Text(beans.name, style: TextStyle(color: TEXT_COLOR),)),
            );
          },
        ),
      ),
    );
  }
}

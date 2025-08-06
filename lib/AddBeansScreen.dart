import 'package:flutter/material.dart';
import 'package:v60pal/Theme.dart';

class AddBeansScreen extends StatefulWidget{
  @override
  State<AddBeansScreen> createState() => _AddBeansScreenState();
}

class _AddBeansScreenState extends State<AddBeansScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('beans', style: TextStyle(color: TEXT_COLOR),),
    );
  }
}
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int counter=0;

  void incrementCounter(){
    setState(() {
      counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("COUNTER APP",style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
         ),
        ),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Center(
        child: Text(
            '$counter',
          style: const TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.bold,
          ),
        ),
        
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => incrementCounter(),
        ),
    );
  }
}

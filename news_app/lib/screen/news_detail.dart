import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final dynamic article;
  const DetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(article["title"] ?? ""),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              article["urlToImage"] ??
                  "https://via.placeholder.com/400x200",
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                article["description"] ?? "",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                article["content"] ?? "",
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
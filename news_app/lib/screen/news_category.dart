import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'news_detail.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  final String apiKey;

  const CategoryScreen({super.key, required this.category, required this.apiKey});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List articles = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCategoryNews();
  }

  Future<void> fetchCategoryNews() async {
    final url = Uri.parse(
        "https://newsapi.org/v2/top-headlines?country=us&category=${widget.category.toLowerCase()}&apiKey=${widget.apiKey}");
    try {
      final response = await http.get(url);
      setState(() {
        articles = jsonDecode(response.body)["articles"];
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("${widget.category} News"),
        backgroundColor: Colors.blueGrey,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, i) {
          final article = articles[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailScreen(article: article)));
            },
            child: Card(
              color: Colors.grey[900],
              margin:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ListTile(
                leading: Image.network(
                  article["urlToImage"] ??
                      "https://via.placeholder.com/80x80",
                  width: 80,
                  fit: BoxFit.cover,
                ),
                title: Text(
                  article["title"] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'news_category.dart';
import 'news_detail.dart';

class NewsApp extends StatefulWidget {
  const NewsApp({super.key});

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  final String apiKey = "d81fd2eec123443d9f90c8f492e3c8b0";

  List featured = [];
  List topNews = [];
  List popularNews = [];
  bool loading = true;
  int carouselIndex = 0;
  Timer? carouselTimer;

  final PageController carouselController =
  PageController(viewportFraction: 0.9);

  final List<String> categories = [
    "Business",
    "Entertainment",
    "Health",
    "Science",
    "Sports",
    "Technology",
  ];

  @override
  void initState() {
    super.initState();
    fetchAllNews();
    startAutoScroll();
  }

  void startAutoScroll() {
    carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (carouselController.hasClients && featured.isNotEmpty) {
        int next = (carouselIndex + 1) % featured.length;
        carouselController.animateToPage(next,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  Future<void> fetchAllNews() async {
    setState(() => loading = true);

    try {
      final topResp = await http.get(Uri.parse(
          "https://newsapi.org/v2/top-headlines?country=us&apiKey=$apiKey"));
      final popResp = await http.get(Uri.parse(
          "https://newsapi.org/v2/everything?q=popular&sortBy=popularity&apiKey=$apiKey"));

      final topData = jsonDecode(topResp.body);
      final popData = jsonDecode(popResp.body);

      setState(() {
        featured = topData["articles"];
        topNews = topData["articles"].take(5).toList();
        popularNews = popData["articles"];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    carouselTimer?.cancel();
    carouselController.dispose();
    super.dispose();
  }

  Widget buildCarousel() {
    if (featured.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: carouselController,
        itemCount: featured.length,
        onPageChanged: (i) {
          setState(() => carouselIndex = i);
        },
        itemBuilder: (context, index) {
          final article = featured[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailScreen(article: article)));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(article["urlToImage"] ??
                        "https://via.placeholder.com/400x200"),
                    fit: BoxFit.cover,
                  )),
              child: Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Text(
                  article["title"] ?? "",
                  style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildSection(String title, List list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            style: const TextStyle(
                color: Colors.pinkAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (context, i) {
              final article = list[i];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DetailScreen(article: article)));
                },
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyanAccent),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            article["urlToImage"] ??
                                "https://via.placeholder.com/200x100",
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          article["title"] ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("News App",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        ),
        backgroundColor: Colors.blueGrey,
        toolbarHeight: 70,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 20,
            ),
            buildCarousel(),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CategoryScreen(
                                    category: categories[i], apiKey: apiKey)));
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.cyanAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        categories[i],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            buildSection("Top News", topNews),
            const SizedBox(height: 12),
            buildSection("Popular News", popularNews),
          ],
        ),
      ),
    );
  }
}
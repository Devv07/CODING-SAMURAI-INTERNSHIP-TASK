import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _controller = TextEditingController();

  String city = "Kathmandu";
  double temperature = 0;
  int humidity = 0;
  String condition = "Loading...";
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchWeather(city);
  }

  Future<void> fetchWeather(String cityName) async {
    const apiKey = 'e33b8212b687074cc03fe4c3591465f3';
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          city = data['name'];
          temperature = data['main']['temp'];
          humidity = data['main']['humidity'];
          condition = data['weather'][0]['description'];
          errorMessage = "";
        });
      } else {
        setState(() {
          errorMessage = "City not found";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load weather data";
      });
    }
  }

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear sky':
        return Icons.wb_sunny;
      case 'few clouds':
      case 'scattered clouds':
      case 'broken clouds':
      case 'overcast clouds':
        return Icons.cloud;
      case 'shower rain':
      case 'rain':
      case 'thunderstorm':
      case 'snow':
        return Icons.grain;
      default:
        return Icons.wb_cloudy;
    }
  }

  Color getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear sky':
        return Colors.orangeAccent;
      case 'few clouds':
      case 'scattered clouds':
      case 'broken clouds':
      case 'overcast clouds':
        return Colors.blueGrey;
      case 'shower rain':
      case 'rain':
        return Colors.blue;
      case 'snow':
        return Colors.lightBlueAccent;
      default:
        return Colors.grey;
    }
  }

  void searchCity() {
    final input = _controller.text.trim();
    if (input.isNotEmpty) {
      fetchWeather(input);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              getWeatherColor(condition).withOpacity(0.6),
              Colors.blueAccent.withOpacity(0.9)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
        child: Column(
          children: [
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Search city...',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => searchCity(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: searchCity,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.white.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  child: Text(
                    'Go',
                    style: TextStyle(
                        color: getWeatherColor(condition),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Error message
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 20),

            // Weather card
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        city,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Icon(
                        getWeatherIcon(condition),
                        size: 120,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "${temperature.toStringAsFixed(1)}°C",
                        style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        condition,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Humidity: $humidity%",
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
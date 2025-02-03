import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:weather/secrete.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  double temp = 0;
  String currentSky = "Clear";
  int currentPressure = 0;
  int currentWindHumidity = 0;
  double currentWindSpeed = 0.0;
  bool isLoading = true;
  List<dynamic> dailyForecast = [];

  Future<void> getCurrentWeather() async {
    try {
      String cityName = 'London';
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$openWeatherAPIKey&units=metric'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          temp = data['main']['temp'];
          currentSky = data['weather'][0]['main'];
          currentPressure = data['main']['pressure'];
          currentWindHumidity = data['main']['humidity'];
          currentWindSpeed = data['wind']['speed'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load current weather data');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> get10DayForecast() async {
    try {
      String cityName = 'London';
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$openWeatherAPIKey&units=metric'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> forecastList = data['list'];

        // Aggregate data for each day
        Map<String, List<dynamic>> dailyData = {};
        for (var forecast in forecastList) {
          DateTime date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
          String day = "${date.year}-${date.month}-${date.day}";
          if (!dailyData.containsKey(day)) {
            dailyData[day] = [];
          }
          dailyData[day]!.add(forecast);
        }

        // Calculate average weather for each day
        List<dynamic> aggregatedForecast = [];
        dailyData.forEach((day, forecasts) {
          double avgTemp = 0;
          String mainCondition = forecasts[0]['weather'][0]['main']; // Most common condition
          for (var forecast in forecasts) {
            avgTemp += forecast['main']['temp'];
          }
          avgTemp = avgTemp / forecasts.length;
          aggregatedForecast.add({
            'date': day,
            'avgTemp': avgTemp,
            'condition': mainCondition,
          });
        });

        setState(() {
          dailyForecast = aggregatedForecast.take(10).toList(); // Take next 10 days
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentWeather();
    get10DayForecast();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background
      appBar: AppBar(
        title: const Text(
          "Weather App",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), // White text
        ),
        centerTitle: true,
        backgroundColor: Colors.black, // Black background
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              getCurrentWeather();
              get10DayForecast();
            },
            icon: const Icon(Icons.refresh, color: Colors.white), // White icon
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeatherCard(), // Current weather card
            const SizedBox(height: 20),
            const Text(
              '10-Day Weather Forecast',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white), // White text
            ),
            const SizedBox(height: 16),
            isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _build10DayForecast(),
            const SizedBox(height: 16),
            _buildAdditionalInfoCard(), // Additional info card
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900], // Dark grey background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2), // Light blue shadow
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity, // Full width
        height: 120, // Adjusted height
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${temp.toStringAsFixed(1)} °C',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white), // White text
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSky,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white), // White text
                  ),
                ],
              ),
              Icon(
                _getWeatherIcon(currentSky),
                size: 64,
                color: Colors.blue[300], // Light blue icon
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build10DayForecast() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dailyForecast.length,
        itemBuilder: (context, index) {
          final forecast = dailyForecast[index];
          final date = forecast['date'];
          final avgTemp = forecast['avgTemp'];
          final condition = forecast['condition'];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900], // Dark grey background
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2), // Light blue shadow
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date,
                    style: const TextStyle(fontSize: 16, color: Colors.white), // White text
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    _getWeatherIcon(condition),
                    size: 32,
                    color: Colors.blue[300], // Light blue icon
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${avgTemp.toStringAsFixed(1)} °C',
                    style: const TextStyle(fontSize: 16, color: Colors.white), // White text
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900], // Dark grey background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2), // Light blue shadow
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Additional Information",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white), // White text
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AdditionalInfoItem(
                  icon: Icons.thermostat,
                  label: 'Pressure',
                  value: '$currentPressure hPa',
                ),
                AdditionalInfoItem(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '$currentWindHumidity%',
                ),
                AdditionalInfoItem(
                  icon: Icons.air,
                  label: 'Wind Speed',
                  value: '${currentWindSpeed.toStringAsFixed(1)} m/s',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case "Clear":
        return Icons.wb_sunny;
      case "Clouds":
        return Icons.cloud;
      case "Rain":
        return Icons.beach_access;
      case "Snow":
        return Icons.ac_unit;
      case "Thunderstorm":
        return Icons.flash_on;
      default:
        return Icons.wb_cloudy;
    }
  }
}

class AdditionalInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AdditionalInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue[300]), // Light blue icon
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white), // White text
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.white), // White text
        ),
      ],
    );
  }
}
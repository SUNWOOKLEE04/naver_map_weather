import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NaverMapSdk.instance.initialize(
    clientId: 'xr56qxj41k',
    onAuthFailed: (ex) {
      debugPrint("네이버 지도 인증 오류: $ex");
    },
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NaverMapScreen(),
    );
  }
}

class NaverMapScreen extends StatefulWidget {
  const NaverMapScreen({super.key});

  @override
  State<NaverMapScreen> createState() => NaverMapScreenState();
}

class NaverMapScreenState extends State<NaverMapScreen> {
  late Position _currentPosition;
  bool _locationFetched = false;

  final List<NLatLng> locations = const [
    NLatLng(37.5665, 126.9780), // 서울
    NLatLng(35.1796, 129.0756), // 부산
    NLatLng(35.1601, 126.8514), // 광주
    NLatLng(35.8722, 128.6017), // 대구
    NLatLng(36.3504, 127.3845), // 대전
    NLatLng(37.4563, 126.7052), // 인천
    NLatLng(35.5384, 129.3114), // 울산
    NLatLng(33.4996, 126.5312), // 제주
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _locationFetched = true;
    });
  }

  static Future<String> getWeather(double lat, double lon,
      {http.Client? client}) async {
    client ??= http.Client();
    const apiKey = 'a84ed7250101a1a4cf1b67c7bd1dc1fd';
    final response = await client.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return '${data['weather'][0]['description']}, ${data['main']['temp']}°C';
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Set<NMarker> buildMarkers() {
    return locations.asMap().entries.map((entry) {
      int index = entry.key;
      NLatLng location = entry.value;
      var marker = NMarker(
        id: 'marker_${location.latitude}_${location.longitude}',
        position: location,
        caption: NOverlayCaption(text: 'Location $index'),
      );
      marker.setOnTapListener((overlay) async {
        var weather = await getWeather(location.latitude, location.longitude);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: Text('Weather: $weather'),
              );
            },
          );
        }
      });
      return marker;
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Naver Map with Weather')),
      body: _locationFetched
          ? NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(
                      _currentPosition.latitude, _currentPosition.longitude),
                  zoom: 12,
                ),
              ),
              onMapReady: (NaverMapController controller) {
                controller.addOverlayAll(buildMarkers());
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

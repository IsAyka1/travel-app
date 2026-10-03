import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class FoundPlace {
  const FoundPlace({
    required this.name,
    required this.details,
    required this.point,
  });

  final String name;
  final String details;
  final LatLng point;
}

class PlaceSearchService {
  const PlaceSearchService({this.client});

  final http.Client? client;

  static const _headers = {
    'User-Agent': 'TravelAtlas/1.0 (com.example.my_test)',
    'Accept': 'application/json',
  };

  Future<List<FoundPlace>> search(String query) async {
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query.trim(),
      'limit': '5',
    });
    final response =
        await (client?.get(uri, headers: _headers) ??
                http.get(uri, headers: _headers))
            .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Place search is unavailable (${response.statusCode}).');
    }
    return parseResults(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  static List<FoundPlace> parseResults(Object? data) {
    if (data is! Map<String, dynamic> || data['features'] is! List) {
      throw const FormatException('Invalid place search response');
    }
    final results = <FoundPlace>[];
    for (final feature in data['features'] as List) {
      if (feature is! Map ||
          feature['properties'] is! Map ||
          feature['geometry'] is! Map) {
        continue;
      }
      final properties = feature['properties'] as Map;
      final coordinates = (feature['geometry'] as Map)['coordinates'];
      if (coordinates is! List ||
          coordinates.length < 2 ||
          coordinates[0] is! num ||
          coordinates[1] is! num) {
        continue;
      }
      final name = properties['name']?.toString().trim() ?? '';
      final longitude = (coordinates[0] as num).toDouble();
      final latitude = (coordinates[1] as num).toDouble();
      if (name.isEmpty ||
          !latitude.isFinite ||
          !longitude.isFinite ||
          latitude.abs() > 90 ||
          longitude.abs() > 180) {
        continue;
      }
      final details = <String>[];
      for (final key in ['street', 'city', 'state', 'country']) {
        final value = properties[key]?.toString().trim() ?? '';
        if (value.isNotEmpty && value != name && !details.contains(value)) {
          details.add(value);
        }
      }
      results.add(
        FoundPlace(
          name: name,
          details: details.join(', '),
          point: LatLng(latitude, longitude),
        ),
      );
    }
    return results;
  }
}

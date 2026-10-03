import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test/features/map/place_search_service.dart';

void main() {
  test('search identifies the app to Photon and returns its results', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'photon.komoot.io');
      expect(request.url.path, '/api/');
      expect(request.url.queryParameters['q'], 'Berlin');
      expect(
        request.headers['User-Agent'],
        'TravelAtlas/1.0 (com.example.my_test)',
      );
      return http.Response('''{
        "features": [{
          "properties": {"name": "Berlin", "country": "Germany"},
          "geometry": {"coordinates": [13.405, 52.52]}
        }]
      }''', 200);
    });

    final results = await PlaceSearchService(client: client).search(' Berlin ');

    expect(results.single.name, 'Berlin');
    expect(results.single.point.latitude, 52.52);
  });

  test('Photon results preserve names and longitude-latitude order', () {
    final results = PlaceSearchService.parseResults({
      'features': [
        {
          'properties': {
            'name': 'Eiffel Tower',
            'city': 'Paris',
            'country': 'France',
          },
          'geometry': {
            'coordinates': [2.2945, 48.8584],
          },
        },
        {
          'properties': {'name': 'Invalid'},
          'geometry': {
            'coordinates': [200, 48],
          },
        },
      ],
    });

    expect(results, hasLength(1));
    expect(results.single.name, 'Eiffel Tower');
    expect(results.single.details, 'Paris, France');
    expect(results.single.point.latitude, 48.8584);
    expect(results.single.point.longitude, 2.2945);
  });
}

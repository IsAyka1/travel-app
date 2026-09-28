import 'package:flutter_test/flutter_test.dart';
import 'package:my_test/features/map/place_search_service.dart';

void main() {
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

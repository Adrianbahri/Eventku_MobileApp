import 'package:cloud_functions/cloud_functions.dart';
import '../Models/location_model.dart';

class GoogleMapsService {
  final FirebaseFunctions functions = FirebaseFunctions.instance;

  Future<List<dynamic>> searchPlaces(String input, String sessionToken) async {
    try {
      final HttpsCallable callable = functions.httpsCallable('searchPlaces');
      
      final result = await callable.call(<String, dynamic>{
        'input': input,
        'sessionToken': sessionToken,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['status'] == 'OK' && data.containsKey('predictions')) {
        return data['predictions'] as List<dynamic>;
      } else {
        // Tangani jika status bukan OK
        throw Exception(data['status'] ?? 'Unknown error from backend');
      }
    } on FirebaseFunctionsException catch (e) {
      // Tangani error khusus dari Firebase Functions
      throw Exception('Firebase Function Error: ${e.message}');
    } catch (e) {
      throw Exception('General Search Error: $e');
    }
  }

  Future<LocationSearchResult> getPlaceDetails(String placeId, String primaryText, String sessionToken) async {
    try {
      final HttpsCallable callable = functions.httpsCallable('getPlaceDetails');
      
      final result = await callable.call(<String, dynamic>{
        'placeId': placeId,
        'sessionToken': sessionToken,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['status'] == 'OK' && data.containsKey('result')) {
        final location = data['result']['geometry']['location'];
        
        return LocationSearchResult(
          addressName: primaryText, 
          latitude: location['lat'],
          longitude: location['lng'],
        );
      } else {
        throw Exception(data['status'] ?? 'Failed to get details from backend');
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Firebase Function Error: ${e.message}');
    } catch (e) {
      throw Exception('General Details Error: $e');
    }
  }
}
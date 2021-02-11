import 'keys.dart';
import 'state.dart';

import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_google_places/flutter_google_places.dart'
    as googlePlaces;
// ignore: import_of_legacy_library_into_null_safe
import 'package:google_maps_webservice/places.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:geodesy/geodesy.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
// ignore: import_of_legacy_library_into_null_safe
import 'package:geocoding/geocoding.dart' as geocoding;
// ignore: import_of_legacy_library_into_null_safe
import 'package:uuid/uuid.dart';
import 'dart:math';

final googlePlacesApi = GoogleMapsPlaces(apiKey: googlePlacesKey);
final geodesy = Geodesy();
const milesPerMeter = 0.000621371;
const distanceThreshold = 50.0;
final uuid = Uuid();

int calculateDistanceBetween(
    double lat1, double lng1, double lat2, double lng2) {
  return (geodesy.distanceBetweenTwoGeoPoints(
              LatLng(lat1, lng1), LatLng(lat2, lng2)) *
          milesPerMeter)
      .round();
}

// A cache is used for this method.
final Map<LatLng, String?> _placemarksCache = {};
Future<String?> coordToPlacemarkStringWithCache(double lat, double lng) async {
  // cache lookup
  final latlngInCache = LatLng(lat, lng);
  final cached = _placemarksCache[latlngInCache];
  if (cached == null) {
    final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
    final newCached = placemarks.length > 0
        ? '${placemarks[0].locality}, ${placemarks[0].postalCode}'
        : null;
    _placemarksCache[latlngInCache] = newCached;
    return newCached;
  } else {
    return cached;
  }
}

LatLng addRandomOffset(double lat, double lng) {
  return geodesy.destinationPointByDistanceAndBearing(LatLng(lat, lng),
      500.0 + Random().nextDouble() * 1000.0, Random().nextDouble() * 360.0);
}

Future<AddressInfo> getGPS() async {
  // in the docs they use forceAndroidLocationManager, but I think it's been deprecated
  final place = await geolocator.Geolocator.getCurrentPosition(
      desiredAccuracy: geolocator.LocationAccuracy.best);
  final roundedLatLng = addRandomOffset(place.latitude, place.longitude);
  // Note that there is no address.
  return AddressInfo()
    ..address = '[used GPS]'
    ..latCoord = roundedLatLng.latitude
    ..lngCoord = roundedLatLng.longitude;
}

Future<void> getAddress(
    BuildContext context, void Function(AddressInfo) didChange) async {
  final sessionToken = uuid.v4();
  final prediction = await googlePlaces.PlacesAutocomplete.show(
      context: context,
      sessionToken: sessionToken,
      apiKey: googlePlacesKey,
      mode: googlePlaces.Mode.overlay,
      language: "en",
      components: [new Component(Component.country, "us")]) as Prediction?;
  if (prediction != null) {
    final place = await googlePlacesApi.getDetailsByPlaceId(prediction.placeId,
        sessionToken: sessionToken, language: "en");
    // The rounding of the coordinates takes place here.
    final roundedLatLng = addRandomOffset(
        place.result.geometry.location.lat, place.result.geometry.location.lng);

    didChange(AddressInfo()
      ..address = place.result.formattedAddress
      ..latCoord = roundedLatLng.latitude
      ..lngCoord = roundedLatLng.longitude);
  }
}

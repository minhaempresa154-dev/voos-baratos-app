import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/flight_models.dart';

class SavedTripsRepository {
  static const _storageKey = 'saved_trips_v1';

  Future<List<SavedTrip>> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    final items = raw
        .map((entry) => SavedTrip.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => a.departureAt.compareTo(b.departureAt));
    return items;
  }

  Future<void> saveTrips(List<SavedTrip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      trips.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<List<SavedTrip>> addTrip(SavedTrip trip) async {
    final items = await loadTrips();
    items.removeWhere((item) => item.id == trip.id);
    items.add(trip);
    await saveTrips(items);
    return loadTrips();
  }

  Future<List<SavedTrip>> removeTrip(String tripId) async {
    final items = await loadTrips();
    items.removeWhere((item) => item.id == tripId);
    await saveTrips(items);
    return loadTrips();
  }
}

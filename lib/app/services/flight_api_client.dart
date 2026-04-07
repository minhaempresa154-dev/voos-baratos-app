import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/flight_models.dart';

class FlightApiClient {
  FlightApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _backendBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  bool get _hasBackend => _backendBaseUrl.trim().isNotEmpty;

  Future<List<AirportSuggestion>> searchLocations(String query) async {
    if (query.trim().length < 3) return const [];

    if (_hasBackend) {
      final uri = Uri.parse('$_backendBaseUrl/api/locations?q=${Uri.encodeQueryComponent(query.trim())}');
      final response = await _client.get(uri);
      final payload = _decode(response);
      return _readList(payload, 'data')
          .map((item) => AirportSuggestion.fromJson(item))
          .toList();
    }

    throw Exception(
      'Configure API_BASE_URL para ativar a busca real.',
    );
  }

  Future<List<FlightOffer>> searchFlights(SearchCriteria criteria) async {
    if (_hasBackend) {
      final response = await _client.post(
        Uri.parse('$_backendBaseUrl/api/flights/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'originCode': criteria.origin.iataCode,
          'destinationCode': criteria.destination.iataCode,
          'departureDate': _formatApiDate(criteria.departureDate),
          'returnDate': criteria.tripType == TripType.roundTrip
              ? _formatApiDate(criteria.returnDate!)
              : null,
          'adults': criteria.adults,
          'cabinClass': _cabinClassApiValue(criteria.cabinClass),
          'currency': 'BRL',
          'nonStop': criteria.nonStopOnly,
          'max': 25,
        }),
      );
      final payload = _decode(response);
      return _readList(payload, 'data')
          .map((item) => FlightOffer.fromJson(item))
          .toList();
    }

    throw Exception(
      'Configure API_BASE_URL para ativar a busca real.',
    );
  }

  List<Map<String, dynamic>> _readList(Map<String, dynamic> payload, String key) {
    return (payload[key] as List<dynamic>? ?? const [])
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  Map<String, dynamic> _decode(http.Response response) {
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(
        '${payload['error'] ?? payload['errors'] ?? 'Falha na comunicacao com a API.'}',
      );
    }
    return payload;
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _cabinClassApiValue(CabinClass value) {
    switch (value) {
      case CabinClass.economy:
        return 'ECONOMY';
      case CabinClass.premiumEconomy:
        return 'PREMIUM_ECONOMY';
      case CabinClass.business:
        return 'BUSINESS';
      case CabinClass.first:
        return 'FIRST';
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/flight_models.dart';
import '../utils/formatters.dart';

class FlightApiClient {
  FlightApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _backendBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const _amadeusClientId =
      String.fromEnvironment('AMADEUS_CLIENT_ID', defaultValue: '');
  static const _amadeusClientSecret =
      String.fromEnvironment('AMADEUS_CLIENT_SECRET', defaultValue: '');
  static const _amadeusEnvironment =
      String.fromEnvironment('AMADEUS_ENV', defaultValue: 'test');

  String? _accessToken;
  DateTime? _accessTokenExpiresAt;

  bool get _hasBackend => _backendBaseUrl.trim().isNotEmpty;
  bool get _hasDirectAmadeus =>
      _amadeusClientId.trim().isNotEmpty && _amadeusClientSecret.trim().isNotEmpty;

  String get _amadeusBaseUrl => _amadeusEnvironment == 'production'
      ? 'https://api.amadeus.com'
      : 'https://test.api.amadeus.com';

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

    if (_hasDirectAmadeus) {
      final uri = Uri.parse(
        '$_amadeusBaseUrl/v1/reference-data/locations'
        '?keyword=${Uri.encodeQueryComponent(query.trim())}'
        '&subType=CITY,AIRPORT&page[limit]=8&sort=analytics.travelers.score&view=FULL',
      );
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer ${await _getAccessToken()}'},
      );
      final payload = _decode(response);
      return _readList(payload, 'data').map(_mapDirectLocation).toList();
    }

    throw Exception(
      'Configure API_BASE_URL ou AMADEUS_CLIENT_ID/AMADEUS_CLIENT_SECRET para busca real.',
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

    if (_hasDirectAmadeus) {
      final query = {
        'originLocationCode': criteria.origin.iataCode,
        'destinationLocationCode': criteria.destination.iataCode,
        'departureDate': _formatApiDate(criteria.departureDate),
        'adults': '${criteria.adults}',
        'travelClass': _cabinClassApiValue(criteria.cabinClass),
        'currencyCode': 'BRL',
        'nonStop': '${criteria.nonStopOnly}',
        'max': '25',
        if (criteria.tripType == TripType.roundTrip && criteria.returnDate != null)
          'returnDate': _formatApiDate(criteria.returnDate!),
      };

      final uri = Uri.parse('$_amadeusBaseUrl/v2/shopping/flight-offers')
          .replace(queryParameters: query);
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer ${await _getAccessToken()}'},
      );
      final payload = _decode(response);
      return _readList(payload, 'data').map(_mapDirectOffer).toList();
    }

    throw Exception(
      'Configure API_BASE_URL ou AMADEUS_CLIENT_ID/AMADEUS_CLIENT_SECRET para busca real.',
    );
  }

  Future<String> _getAccessToken() async {
    if (_accessToken != null &&
        _accessTokenExpiresAt != null &&
        DateTime.now().isBefore(_accessTokenExpiresAt!)) {
      return _accessToken!;
    }

    final response = await _client.post(
      Uri.parse('$_amadeusBaseUrl/v1/security/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': _amadeusClientId,
        'client_secret': _amadeusClientSecret,
      },
    );

    final payload = _decode(response);
    _accessToken = '${payload['access_token']}';
    final expiresIn = (payload['expires_in'] as num?)?.toInt() ?? 1800;
    _accessTokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));
    return _accessToken!;
  }

  AirportSuggestion _mapDirectLocation(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>? ?? const {};
    return AirportSuggestion(
      id: '${item['id'] ?? item['iataCode']}',
      iataCode: '${item['iataCode'] ?? ''}',
      name: '${item['name'] ?? item['detailedName'] ?? ''}',
      city: '${address['cityName'] ?? ''}',
      country: '${address['countryName'] ?? ''}',
      subtitle: [
        '${address['cityName'] ?? ''}',
        '${address['countryName'] ?? ''}',
      ].where((item) => item.isNotEmpty).join(', '),
    );
  }

  FlightOffer _mapDirectOffer(Map<String, dynamic> item) {
    final itineraries = item['itineraries'] as List<dynamic>? ?? const [];
    final firstItinerary = itineraries.first as Map<String, dynamic>? ?? const {};
    final segmentsRaw =
        firstItinerary['segments'] as List<dynamic>? ?? const <dynamic>[];
    final segments = segmentsRaw
        .map((entry) => entry as Map<String, dynamic>)
        .map(
          (segment) => FlightSegment(
            carrierCode: '${segment['carrierCode'] ?? ''}',
            number: '${segment['number'] ?? ''}',
            originCode: '${(segment['departure'] as Map<String, dynamic>?)?['iataCode'] ?? ''}',
            destinationCode:
                '${(segment['arrival'] as Map<String, dynamic>?)?['iataCode'] ?? ''}',
            departureAt: DateTime.parse(
              '${(segment['departure'] as Map<String, dynamic>?)?['at']}',
            ),
            arrivalAt: DateTime.parse(
              '${(segment['arrival'] as Map<String, dynamic>?)?['at']}',
            ),
            duration: '${segment['duration'] ?? ''}',
          ),
        )
        .toList();

    final firstSegment = segments.first;
    final lastSegment = segments.last;
    final travelerPricings =
        item['travelerPricings'] as List<dynamic>? ?? const <dynamic>[];
    final baggageIncluded = travelerPricings.any((traveler) {
      final fareDetails = (traveler as Map<String, dynamic>)['fareDetailsBySegment']
              as List<dynamic>? ??
          const <dynamic>[];
      return fareDetails.any((detail) {
        final included = (detail as Map<String, dynamic>)['includedCheckedBags']
            as Map<String, dynamic>?;
        return (included?['quantity'] as num?)?.toInt() != null;
      });
    });

    final total = double.tryParse('${(item['price'] as Map<String, dynamic>?)?['total'] ?? 0}') ?? 0;
    final cashAndPointsTotal = (total * 0.55);
    final pointsEstimate = ((total * 100).round() * 8);

    return FlightOffer(
      id: '${item['id'] ?? ''}',
      airline: firstSegment.carrierCode,
      validatingAirlineCodes:
          ((item['validatingAirlineCodes'] as List<dynamic>?) ?? const [])
              .map((entry) => '$entry')
              .toList(),
      originCode: firstSegment.originCode,
      destinationCode: lastSegment.destinationCode,
      departureAt: firstSegment.departureAt,
      arrivalAt: lastSegment.arrivalAt,
      duration: '${firstItinerary['duration'] ?? ''}',
      stops: segments.length - 1,
      currency: (item['price'] as Map<String, dynamic>?)?['currency'] as String? ?? 'BRL',
      cashTotal: total,
      cashAndPointsTotal: cashAndPointsTotal,
      cashAndPointsEstimateLabel:
          '${formatCurrencyBrl(cashAndPointsTotal)} + $pointsEstimate pts (estimativa)',
      baggageIncluded: baggageIncluded,
      cabin: _firstCabin(travelerPricings) ?? 'ECONOMY',
      segments: segments,
    );
  }

  String? _firstCabin(List<dynamic> travelerPricings) {
    for (final traveler in travelerPricings) {
      final fareDetails =
          (traveler as Map<String, dynamic>)['fareDetailsBySegment'] as List<dynamic>? ??
              const <dynamic>[];
      if (fareDetails.isNotEmpty) {
        return '${(fareDetails.first as Map<String, dynamic>)['cabin']}';
      }
    }
    return null;
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

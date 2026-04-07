enum TripType { roundTrip, oneWay }

enum FareMode { cash, cashAndPoints }

enum CabinClass { economy, premiumEconomy, business, first }

class AirportSuggestion {
  const AirportSuggestion({
    required this.id,
    required this.iataCode,
    required this.name,
    required this.city,
    required this.country,
    required this.subtitle,
  });

  final String id;
  final String iataCode;
  final String name;
  final String city;
  final String country;
  final String subtitle;

  factory AirportSuggestion.fromJson(Map<String, dynamic> json) {
    return AirportSuggestion(
      id: '${json['id'] ?? json['iataCode'] ?? ''}',
      iataCode: '${json['iataCode'] ?? ''}',
      name: '${json['name'] ?? ''}',
      city: '${json['city'] ?? ''}',
      country: '${json['country'] ?? ''}',
      subtitle: '${json['subtitle'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iataCode': iataCode,
      'name': name,
      'city': city,
      'country': country,
      'subtitle': subtitle,
    };
  }

  String get displayLabel => '$iataCode - $name';
}

class SearchCriteria {
  SearchCriteria({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    required this.tripType,
    required this.adults,
    required this.cabinClass,
    required this.fareMode,
    this.nonStopOnly = false,
  });

  final AirportSuggestion origin;
  final AirportSuggestion destination;
  final DateTime departureDate;
  final DateTime? returnDate;
  final TripType tripType;
  final int adults;
  final CabinClass cabinClass;
  final FareMode fareMode;
  final bool nonStopOnly;
}

class FlightFilters {
  const FlightFilters({
    required this.maxPrice,
    required this.maxStops,
    required this.onlyBaggageIncluded,
    required this.onlyMorningDepartures,
    required this.selectedAirlines,
  });

  factory FlightFilters.initial() => const FlightFilters(
        maxPrice: 15000,
        maxStops: 2,
        onlyBaggageIncluded: false,
        onlyMorningDepartures: false,
        selectedAirlines: <String>{},
      );

  final double maxPrice;
  final int maxStops;
  final bool onlyBaggageIncluded;
  final bool onlyMorningDepartures;
  final Set<String> selectedAirlines;

  FlightFilters copyWith({
    double? maxPrice,
    int? maxStops,
    bool? onlyBaggageIncluded,
    bool? onlyMorningDepartures,
    Set<String>? selectedAirlines,
  }) {
    return FlightFilters(
      maxPrice: maxPrice ?? this.maxPrice,
      maxStops: maxStops ?? this.maxStops,
      onlyBaggageIncluded: onlyBaggageIncluded ?? this.onlyBaggageIncluded,
      onlyMorningDepartures:
          onlyMorningDepartures ?? this.onlyMorningDepartures,
      selectedAirlines: selectedAirlines ?? this.selectedAirlines,
    );
  }
}

class FlightSegment {
  const FlightSegment({
    required this.carrierCode,
    required this.number,
    required this.originCode,
    required this.destinationCode,
    required this.departureAt,
    required this.arrivalAt,
    required this.duration,
  });

  final String carrierCode;
  final String number;
  final String originCode;
  final String destinationCode;
  final DateTime departureAt;
  final DateTime arrivalAt;
  final String duration;

  factory FlightSegment.fromJson(Map<String, dynamic> json) {
    return FlightSegment(
      carrierCode: '${json['carrierCode'] ?? ''}',
      number: '${json['number'] ?? ''}',
      originCode: '${json['originCode'] ?? ''}',
      destinationCode: '${json['destinationCode'] ?? ''}',
      departureAt: DateTime.parse('${json['departureAt']}'),
      arrivalAt: DateTime.parse('${json['arrivalAt']}'),
      duration: '${json['duration'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carrierCode': carrierCode,
      'number': number,
      'originCode': originCode,
      'destinationCode': destinationCode,
      'departureAt': departureAt.toIso8601String(),
      'arrivalAt': arrivalAt.toIso8601String(),
      'duration': duration,
    };
  }
}

class FlightOffer {
  const FlightOffer({
    required this.id,
    required this.airline,
    required this.validatingAirlineCodes,
    required this.flightNumber,
    required this.originCode,
    required this.destinationCode,
    required this.departureAt,
    required this.arrivalAt,
    required this.duration,
    required this.stops,
    required this.currency,
    required this.cashTotal,
    required this.cashAndPointsTotal,
    required this.cashAndPointsEstimateLabel,
    required this.baggageIncluded,
    required this.cabin,
    required this.segments,
    this.buyUrl,
  });

  final String id;
  final String airline;
  final List<String> validatingAirlineCodes;
  final String flightNumber;
  final String originCode;
  final String destinationCode;
  final DateTime departureAt;
  final DateTime arrivalAt;
  final String duration;
  final int stops;
  final String currency;
  final double cashTotal;
  final double cashAndPointsTotal;
  final String cashAndPointsEstimateLabel;
  final bool baggageIncluded;
  final String cabin;
  final List<FlightSegment> segments;
  final String? buyUrl;

  factory FlightOffer.fromJson(Map<String, dynamic> json) {
    return FlightOffer(
      id: '${json['id'] ?? ''}',
      airline: '${json['airline'] ?? ''}',
      validatingAirlineCodes:
          (json['validatingAirlineCodes'] as List<dynamic>? ?? const [])
              .map((item) => '$item')
              .toList(),
      flightNumber: '${json['flightNumber'] ?? ''}',
      originCode: '${json['originCode'] ?? ''}',
      destinationCode: '${json['destinationCode'] ?? ''}',
      departureAt: DateTime.parse('${json['departureAt']}'),
      arrivalAt: DateTime.parse('${json['arrivalAt']}'),
      duration: '${json['duration'] ?? ''}',
      stops: (json['stops'] as num?)?.toInt() ?? 0,
      currency: '${json['currency'] ?? 'BRL'}',
      cashTotal: (json['cashTotal'] as num?)?.toDouble() ?? 0,
      cashAndPointsTotal:
          (json['cashAndPointsTotal'] as num?)?.toDouble() ?? 0,
      cashAndPointsEstimateLabel: '${json['cashAndPointsEstimateLabel'] ?? ''}',
      baggageIncluded: json['baggageIncluded'] == true,
      cabin: '${json['cabin'] ?? ''}',
      segments: (json['segments'] as List<dynamic>? ?? const [])
          .map((item) => FlightSegment.fromJson(item as Map<String, dynamic>))
          .toList(),
      buyUrl: json['buyUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airline': airline,
      'validatingAirlineCodes': validatingAirlineCodes,
      'flightNumber': flightNumber,
      'originCode': originCode,
      'destinationCode': destinationCode,
      'departureAt': departureAt.toIso8601String(),
      'arrivalAt': arrivalAt.toIso8601String(),
      'duration': duration,
      'stops': stops,
      'currency': currency,
      'cashTotal': cashTotal,
      'cashAndPointsTotal': cashAndPointsTotal,
      'cashAndPointsEstimateLabel': cashAndPointsEstimateLabel,
      'baggageIncluded': baggageIncluded,
      'cabin': cabin,
      'segments': segments.map((item) => item.toJson()).toList(),
      'buyUrl': buyUrl,
    };
  }
}

class SavedTrip {
  const SavedTrip({
    required this.id,
    required this.title,
    required this.airline,
    required this.originCode,
    required this.destinationCode,
    required this.flightNumber,
    required this.departureAt,
    required this.arrivalAt,
    required this.bookingCode,
    required this.statusLabel,
    required this.purchaseChannel,
    required this.notes,
    required this.priceLabel,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String airline;
  final String originCode;
  final String destinationCode;
  final String flightNumber;
  final DateTime departureAt;
  final DateTime arrivalAt;
  final String bookingCode;
  final String statusLabel;
  final String purchaseChannel;
  final String notes;
  final String priceLabel;
  final DateTime createdAt;

  factory SavedTrip.fromJson(Map<String, dynamic> json) {
    return SavedTrip(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      airline: '${json['airline'] ?? ''}',
      originCode: '${json['originCode'] ?? ''}',
      destinationCode: '${json['destinationCode'] ?? ''}',
      flightNumber: '${json['flightNumber'] ?? ''}',
      departureAt: DateTime.parse('${json['departureAt']}'),
      arrivalAt: DateTime.parse('${json['arrivalAt']}'),
      bookingCode: '${json['bookingCode'] ?? ''}',
      statusLabel: '${json['statusLabel'] ?? ''}',
      purchaseChannel: '${json['purchaseChannel'] ?? ''}',
      notes: '${json['notes'] ?? ''}',
      priceLabel: '${json['priceLabel'] ?? ''}',
      createdAt: DateTime.parse('${json['createdAt']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'airline': airline,
      'originCode': originCode,
      'destinationCode': destinationCode,
      'flightNumber': flightNumber,
      'departureAt': departureAt.toIso8601String(),
      'arrivalAt': arrivalAt.toIso8601String(),
      'bookingCode': bookingCode,
      'statusLabel': statusLabel,
      'purchaseChannel': purchaseChannel,
      'notes': notes,
      'priceLabel': priceLabel,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

import 'package:flutter/material.dart';

import 'repositories/saved_trips_repository.dart';
import 'services/flight_api_client.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

class FlightDealsApp extends StatelessWidget {
  const FlightDealsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voos Baratos',
      theme: AppTheme.light(),
      home: HomeScreen(
        apiClient: FlightApiClient(),
        savedTripsRepository: SavedTripsRepository(),
      ),
    );
  }
}

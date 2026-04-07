import 'package:flutter/material.dart';

import '../../models/flight_models.dart';
import '../../repositories/saved_trips_repository.dart';
import '../../services/flight_api_client.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../widgets/glass_panel.dart';
import '../widgets/location_autocomplete_field.dart';
import '../widgets/section_title.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.apiClient,
    required this.savedTripsRepository,
  });

  final FlightApiClient apiClient;
  final SavedTripsRepository savedTripsRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();

  AirportSuggestion? _selectedOrigin;
  AirportSuggestion? _selectedDestination;
  TripType _tripType = TripType.roundTrip;
  FareMode _fareMode = FareMode.cash;
  CabinClass _cabinClass = CabinClass.economy;
  int _adults = 1;
  bool _nonStopOnly = false;
  DateTime _departureDate = DateTime.now().add(const Duration(days: 30));
  DateTime _returnDate = DateTime.now().add(const Duration(days: 37));
  int _currentIndex = 0;
  bool _loadingTrips = true;
  List<SavedTrip> _savedTrips = const [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    final trips = await widget.savedTripsRepository.loadTrips();
    if (!mounted) return;
    setState(() {
      _savedTrips = trips;
      _loadingTrips = false;
    });
  }

  Future<void> _pickDate(bool isDeparture) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isDeparture ? _departureDate : _returnDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null) return;

    setState(() {
      if (isDeparture) {
        _departureDate = selected;
        if (_returnDate.isBefore(_departureDate)) {
          _returnDate = _departureDate.add(const Duration(days: 7));
        }
      } else {
        _returnDate = selected;
      }
    });
  }

  void _openResults() {
    if (_selectedOrigin == null || _selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione origem e destino usando o autocomplete.'),
        ),
      );
      return;
    }

    final criteria = SearchCriteria(
      origin: _selectedOrigin!,
      destination: _selectedDestination!,
      departureDate: _departureDate,
      returnDate: _tripType == TripType.roundTrip ? _returnDate : null,
      tripType: _tripType,
      adults: _adults,
      cabinClass: _cabinClass,
      fareMode: _fareMode,
      nonStopOnly: _nonStopOnly,
    );

    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          criteria: criteria,
          apiClient: widget.apiClient,
          savedTripsRepository: widget.savedTripsRepository,
        ),
      ),
    )
        .then((_) => _loadTrips());
  }

  Future<void> _showManualTripSheet() async {
    final airlineController = TextEditingController();
    final originController = TextEditingController();
    final destinationController = TextEditingController();
    final bookingCodeController = TextEditingController();
    final notesController = TextEditingController();
    DateTime departureDate = DateTime.now().add(const Duration(days: 15));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Adicionar viagem comprada',
                      subtitle:
                          'Salve uma reserva sua para acompanhar tudo em um lugar so.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: airlineController,
                      decoration: const InputDecoration(labelText: 'Companhia'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: originController,
                            decoration: const InputDecoration(labelText: 'Origem'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: destinationController,
                            decoration: const InputDecoration(labelText: 'Destino'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bookingCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Localizador / codigo da reserva',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observacoes',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: departureDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (selected != null) {
                          setModalState(() => departureDate = selected);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: Text('Data: ${formatLongDate(departureDate)}'),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final trip = SavedTrip(
                            id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
                            title:
                                '${originController.text.trim().toUpperCase()} -> ${destinationController.text.trim().toUpperCase()}',
                            airline: airlineController.text.trim().isEmpty
                                ? 'Viagem manual'
                                : airlineController.text.trim(),
                            originCode: originController.text.trim().toUpperCase(),
                            destinationCode:
                                destinationController.text.trim().toUpperCase(),
                            departureAt: departureDate,
                            arrivalAt: departureDate,
                            bookingCode: bookingCodeController.text.trim(),
                            notes: notesController.text.trim(),
                            priceLabel: 'Reserva adicionada manualmente',
                            createdAt: DateTime.now(),
                          );
                          await widget.savedTripsRepository.addTrip(trip);
                          navigator.pop();
                          _loadTrips();
                        },
                        child: const Text('Salvar viagem'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.navy, colors.cobalt, colors.cyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _SearchTab(
                originController: _originController,
                destinationController: _destinationController,
                apiClient: widget.apiClient,
                tripType: _tripType,
                fareMode: _fareMode,
                cabinClass: _cabinClass,
                adults: _adults,
                nonStopOnly: _nonStopOnly,
                departureDate: _departureDate,
                returnDate: _returnDate,
                onOriginSelected: (value) => _selectedOrigin = value,
                onDestinationSelected: (value) => _selectedDestination = value,
                onTripTypeChanged: (value) => setState(() => _tripType = value),
                onFareModeChanged: (value) => setState(() => _fareMode = value),
                onCabinClassChanged: (value) =>
                    setState(() => _cabinClass = value),
                onAdultsChanged: (value) => setState(() => _adults = value),
                onNonStopChanged: (value) =>
                    setState(() => _nonStopOnly = value),
                onPickDepartureDate: () => _pickDate(true),
                onPickReturnDate: () => _pickDate(false),
                onSearch: _openResults,
              ),
              _TripsTab(
                isLoading: _loadingTrips,
                trips: _savedTrips,
                onAddTrip: _showManualTripSheet,
                onRemoveTrip: (tripId) async {
                  await widget.savedTripsRepository.removeTrip(tripId);
                  _loadTrips();
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) => setState(() => _currentIndex = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Pesquisar',
          ),
          NavigationDestination(
            icon: Icon(Icons.luggage_rounded),
            label: 'Minhas viagens',
          ),
        ],
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab({
    required this.originController,
    required this.destinationController,
    required this.apiClient,
    required this.tripType,
    required this.fareMode,
    required this.cabinClass,
    required this.adults,
    required this.nonStopOnly,
    required this.departureDate,
    required this.returnDate,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onTripTypeChanged,
    required this.onFareModeChanged,
    required this.onCabinClassChanged,
    required this.onAdultsChanged,
    required this.onNonStopChanged,
    required this.onPickDepartureDate,
    required this.onPickReturnDate,
    required this.onSearch,
  });

  final TextEditingController originController;
  final TextEditingController destinationController;
  final FlightApiClient apiClient;
  final TripType tripType;
  final FareMode fareMode;
  final CabinClass cabinClass;
  final int adults;
  final bool nonStopOnly;
  final DateTime departureDate;
  final DateTime returnDate;
  final ValueChanged<AirportSuggestion?> onOriginSelected;
  final ValueChanged<AirportSuggestion?> onDestinationSelected;
  final ValueChanged<TripType> onTripTypeChanged;
  final ValueChanged<FareMode> onFareModeChanged;
  final ValueChanged<CabinClass> onCabinClassChanged;
  final ValueChanged<int> onAdultsChanged;
  final ValueChanged<bool> onNonStopChanged;
  final VoidCallback onPickDepartureDate;
  final VoidCallback onPickReturnDate;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Pesquise passagens de verdade, com fluxo rapido e visual premium.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Autocomplete para cidades, paises e aeroportos com 3 letras, busca real de tarifas e salvamento das viagens no app.',
            style: TextStyle(
              color: Color(0xDDF4F8FF),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          GlassPanel(
            child: Column(
              children: [
                SegmentedButton<TripType>(
                  segments: const [
                    ButtonSegment(
                      value: TripType.roundTrip,
                      label: Text('Ida e volta'),
                    ),
                    ButtonSegment(
                      value: TripType.oneWay,
                      label: Text('Somente ida'),
                    ),
                  ],
                  selected: {tripType},
                  onSelectionChanged: (value) => onTripTypeChanged(value.first),
                ),
                const SizedBox(height: 18),
                LocationAutocompleteField(
                  controller: originController,
                  label: 'Origem',
                  icon: Icons.flight_takeoff_rounded,
                  fetchSuggestions: apiClient.searchLocations,
                  onSelected: onOriginSelected,
                ),
                const SizedBox(height: 12),
                LocationAutocompleteField(
                  controller: destinationController,
                  label: 'Destino',
                  icon: Icons.flight_land_rounded,
                  fetchSuggestions: apiClient.searchLocations,
                  onSelected: onDestinationSelected,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionField(
                        label: 'Saida',
                        value: formatShortDate(departureDate),
                        icon: Icons.calendar_today_rounded,
                        onTap: onPickDepartureDate,
                      ),
                    ),
                    if (tripType == TripType.roundTrip) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionField(
                          label: 'Retorno',
                          value: formatShortDate(returnDate),
                          icon: Icons.event_repeat_rounded,
                          onTap: onPickReturnDate,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: adults,
                        decoration: const InputDecoration(
                          labelText: 'Adultos',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        items: List.generate(
                          8,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) onAdultsChanged(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<CabinClass>(
                        initialValue: cabinClass,
                        decoration: const InputDecoration(
                          labelText: 'Cabine',
                          prefixIcon: Icon(Icons.airline_seat_recline_normal),
                        ),
                        items: CabinClass.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(_cabinClassLabel(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onCabinClassChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  value: nonStopOnly,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Somente voos sem escala'),
                  onChanged: onNonStopChanged,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Forma de pagamento',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: FareMode.values
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: item == FareMode.cash ? 10 : 0,
                            ),
                            child: _FareModeButton(
                              label: _fareModeLabel(item),
                              selected: fareMode == item,
                              onTap: () => onFareModeChanged(item),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onSearch,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Buscar passagens'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fareModeLabel(FareMode mode) {
    switch (mode) {
      case FareMode.cash:
        return 'Real';
      case FareMode.cashAndPoints:
        return 'Real + pontos';
    }
  }

  String _cabinClassLabel(CabinClass cabin) {
    switch (cabin) {
      case CabinClass.economy:
        return 'Economica';
      case CabinClass.premiumEconomy:
        return 'Premium Economy';
      case CabinClass.business:
        return 'Executiva';
      case CabinClass.first:
        return 'Primeira classe';
    }
  }
}

class _TripsTab extends StatelessWidget {
  const _TripsTab({
    required this.isLoading,
    required this.trips,
    required this.onAddTrip,
    required this.onRemoveTrip,
  });

  final bool isLoading;
  final List<SavedTrip> trips;
  final VoidCallback onAddTrip;
  final ValueChanged<String> onRemoveTrip;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        GlassPanel(
          child: SectionTitle(
            title: 'Minhas viagens',
            subtitle:
                'Salve voos encontrados na busca ou adicione uma viagem ja comprada manualmente.',
            trailing: ElevatedButton.icon(
              onPressed: onAddTrip,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar'),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (trips.isEmpty)
          const GlassPanel(
            child: Text(
              'Nenhuma viagem salva ainda. Pesquise um voo e toque em salvar, ou adicione uma viagem comprada.',
            ),
          )
        else
          ...trips.map(
            (trip) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => onRemoveTrip(trip.id),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Companhia: ${trip.airline}'),
                    const SizedBox(height: 4),
                    Text('Saida: ${formatLongDate(trip.departureAt)}'),
                    if (trip.bookingCode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Localizador: ${trip.bookingCode}'),
                    ],
                    const SizedBox(height: 4),
                    Text(trip.priceLabel),
                    if (trip.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(trip.notes),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FareModeButton extends StatelessWidget {
  const _FareModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1464F4) : const Color(0xFFF2F6FF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF0B1F4D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF6A7590))),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

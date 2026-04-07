import 'package:flutter/material.dart';

import '../../models/flight_models.dart';
import '../../repositories/saved_trips_repository.dart';
import '../../services/flight_api_client.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../widgets/glass_panel.dart';
import '../widgets/section_title.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.criteria,
    required this.apiClient,
    required this.savedTripsRepository,
  });

  final SearchCriteria criteria;
  final FlightApiClient apiClient;
  final SavedTripsRepository savedTripsRepository;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  FlightFilters _filters = FlightFilters.initial();
  bool _loading = true;
  String? _error;
  List<FlightOffer> _offers = const [];

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final offers = await widget.apiClient.searchFlights(widget.criteria);
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  List<FlightOffer> get _visibleOffers {
    final items = _offers.where((offer) {
      final airlineAllowed = _filters.selectedAirlines.isEmpty ||
          _filters.selectedAirlines.contains(offer.airline);
      final morningAllowed =
          !_filters.onlyMorningDepartures || offer.departureAt.hour < 12;

      final visiblePrice = widget.criteria.fareMode == FareMode.cash
          ? offer.cashTotal
          : offer.cashAndPointsTotal;

      return visiblePrice <= _filters.maxPrice &&
          offer.stops <= _filters.maxStops &&
          airlineAllowed &&
          (!_filters.onlyBaggageIncluded || offer.baggageIncluded) &&
          morningAllowed;
    }).toList();

    items.sort((a, b) {
      final aPrice = widget.criteria.fareMode == FareMode.cash
          ? a.cashTotal
          : a.cashAndPointsTotal;
      final bPrice = widget.criteria.fareMode == FareMode.cash
          ? b.cashTotal
          : b.cashAndPointsTotal;
      return aPrice.compareTo(bPrice);
    });
    return items;
  }

  Future<void> _saveTrip(FlightOffer offer) async {
    final trip = SavedTrip(
      id: 'offer-${offer.id}-${offer.departureAt.toIso8601String()}',
      title: '${offer.originCode} -> ${offer.destinationCode}',
      airline: offer.airline,
      originCode: offer.originCode,
      destinationCode: offer.destinationCode,
      departureAt: offer.departureAt,
      arrivalAt: offer.arrivalAt,
      bookingCode: '',
      notes: 'Salvo a partir de uma busca real no app.',
      priceLabel: _priceLabel(offer),
      createdAt: DateTime.now(),
    );
    await widget.savedTripsRepository.addTrip(trip);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Viagem salva em Minhas viagens.')),
    );
  }

  Future<void> _showFilters() async {
    final airlines = _offers.map((item) => item.airline).toSet().toList()..sort();
    var draft = _filters;

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
                      title: 'Filtros',
                      subtitle:
                          'Refine por preco, companhia, bagagem e horario.',
                    ),
                    const SizedBox(height: 18),
                    Text('Preco maximo: ${formatCurrencyBrl(draft.maxPrice)}'),
                    Slider(
                      value: draft.maxPrice,
                      min: 200,
                      max: 15000,
                      divisions: 74,
                      onChanged: (value) => setModalState(
                        () => draft = draft.copyWith(maxPrice: value),
                      ),
                    ),
                    Text('Conexoes maximas: ${draft.maxStops}'),
                    Slider(
                      value: draft.maxStops.toDouble(),
                      min: 0,
                      max: 2,
                      divisions: 2,
                      onChanged: (value) => setModalState(
                        () => draft = draft.copyWith(maxStops: value.round()),
                      ),
                    ),
                    SwitchListTile(
                      value: draft.onlyBaggageIncluded,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Somente com bagagem inclusa'),
                      onChanged: (value) => setModalState(
                        () => draft = draft.copyWith(onlyBaggageIncluded: value),
                      ),
                    ),
                    SwitchListTile(
                      value: draft.onlyMorningDepartures,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Saidas pela manha'),
                      onChanged: (value) => setModalState(
                        () => draft =
                            draft.copyWith(onlyMorningDepartures: value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: airlines
                          .map(
                            (airline) => FilterChip(
                              label: Text(airline),
                              selected: draft.selectedAirlines.contains(airline),
                              onSelected: (selected) {
                                final updated = {...draft.selectedAirlines};
                                if (selected) {
                                  updated.add(airline);
                                } else {
                                  updated.remove(airline);
                                }
                                setModalState(
                                  () => draft =
                                      draft.copyWith(selectedAirlines: updated),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _filters = draft);
                          Navigator.pop(context);
                        },
                        child: const Text('Aplicar'),
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
    final offers = _visibleOffers;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.criteria.origin.iataCode} -> ${widget.criteria.destination.iataCode}',
        ),
        actions: [
          IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: 'Busca real de passagens',
                  subtitle:
                      '${widget.criteria.origin.name} para ${widget.criteria.destination.name}',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoPill(label: formatShortDate(widget.criteria.departureDate)),
                    if (widget.criteria.returnDate != null)
                      _InfoPill(label: formatShortDate(widget.criteria.returnDate!)),
                    _InfoPill(label: '${widget.criteria.adults} adulto(s)'),
                    _InfoPill(
                      label: widget.criteria.fareMode == FareMode.cash
                          ? 'Real'
                          : 'Real + pontos',
                    ),
                  ],
                ),
                if (widget.criteria.fareMode == FareMode.cashAndPoints) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Real + pontos aparece como estimativa baseada na tarifa em dinheiro. Busca real de pontos depende de integracao com programas de fidelidade/companhias.',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const GlassPanel(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nao foi possivel buscar os voos agora.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _loadOffers,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          else if (offers.isEmpty)
            const GlassPanel(
              child: Text(
                'Nenhum voo encontrado para os filtros atuais.',
              ),
            )
          else ...[
            Text(
              '${offers.length} opcoes encontradas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...offers.map(
              (offer) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _FlightCard(
                  offer: offer,
                  fareMode: widget.criteria.fareMode,
                  onSave: () => _saveTrip(offer),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _priceLabel(FlightOffer offer) {
    if (widget.criteria.fareMode == FareMode.cash) {
      return formatCurrencyBrl(offer.cashTotal);
    }
    return offer.cashAndPointsEstimateLabel;
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({
    required this.offer,
    required this.fareMode,
    required this.onSave,
  });

  final FlightOffer offer;
  final FareMode fareMode;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.airline,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (offer.validatingAirlineCodes.isNotEmpty)
                _InfoPill(label: offer.validatingAirlineCodes.join(', ')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AirportTime(
                  code: offer.originCode,
                  time: formatHourMinute(offer.departureAt),
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.flight_rounded, color: Color(0xFF1464F4)),
                    const SizedBox(height: 6),
                    Text(
                      formatDurationIso(offer.duration),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5D6B8A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.stops == 0
                          ? 'Sem escalas'
                          : '${offer.stops} conexao(oes)',
                      style: const TextStyle(color: Color(0xFF5D6B8A)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _AirportTime(
                  code: offer.destinationCode,
                  time: formatHourMinute(offer.arrivalAt),
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: offer.cabin),
              if (offer.baggageIncluded) const _InfoPill(label: 'Bagagem inclusa'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fareMode == FareMode.cash ? 'Tarifa em real' : 'Real + pontos',
                      style: const TextStyle(color: Color(0xFF5D6B8A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fareMode == FareMode.cash
                          ? formatCurrencyBrl(offer.cashTotal)
                          : offer.cashAndPointsEstimateLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF1464F4),
                          ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AirportTime extends StatelessWidget {
  const _AirportTime({
    required this.code,
    required this.time,
    required this.alignment,
  });

  final String code;
  final String time;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(time, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          code,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5D6B8A),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x101464F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

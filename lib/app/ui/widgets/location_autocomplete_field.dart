import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/flight_models.dart';

class LocationAutocompleteField extends StatefulWidget {
  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.onSelected,
    required this.fetchSuggestions,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Future<List<AirportSuggestion>> Function(String query) fetchSuggestions;
  final ValueChanged<AirportSuggestion?> onSelected;

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  Timer? _debounce;
  List<AirportSuggestion> _items = const [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onSelected(null);
    _debounce?.cancel();

    if (value.trim().length < 3) {
      setState(() {
        _items = const [];
        _isLoading = false;
        _lastQuery = value;
      });
      return;
    }

    _lastQuery = value.trim();
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await widget.fetchSuggestions(_lastQuery);
        if (!mounted || widget.controller.text.trim() != _lastQuery) return;
        setState(() {
          _items = results;
          _isLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _items = const [];
          _isLoading = false;
        });
      }
    });
  }

  void _select(AirportSuggestion item) {
    widget.controller.text = '${item.iataCode} - ${item.name}';
    widget.onSelected(item);
    setState(() => _items = const []);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x140B1F4D)),
            ),
            child: Column(
              children: _items
                  .map(
                    (item) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(item.displayLabel),
                      subtitle: Text(item.subtitle),
                      onTap: () => _select(item),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

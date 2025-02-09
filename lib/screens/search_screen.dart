import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/models/restaurant.dart';
import 'package:restaurant_app/providers/restaurant_provider.dart';
import 'package:restaurant_app/widgets/loading_indicator.dart';
import 'package:restaurant_app/screens/restaurant_list_screen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  double _selectedRating = 0.0; // Range 0.0 - 5.0
  String _selectedCity = "All";
  final List<String> cities = ["All", "Medan", "Gorontalo", "Jakarta", "Bandung"];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    final query = _searchController.text;
    if (query.isNotEmpty || _selectedRating > 0.0 || _selectedCity.toLowerCase() != 'all') {
      context.read<RestaurantProvider>().searchRestaurants(
        query,
        minRating: _selectedRating,
        city: _selectedCity,
      );
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _triggerSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari restoran...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButton<String>(
                        value: _selectedCity,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCity = newValue!;
                          });
                          _triggerSearch();
                        },
                        items: cities.map<DropdownMenuItem<String>>((String city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          Expanded(
                            child: Slider(
                              value: _selectedRating,
                              min: 0.0,
                              max: 5.0,
                              divisions: 10,
                              label: _selectedRating.toStringAsFixed(1),
                              onChanged: (double value) {
                                setState(() {
                                  _selectedRating = value;
                                });
                                _triggerSearch();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<RestaurantProvider>(
              builder: (context, provider, _) {
                if (_searchController.text.isEmpty &&
                    _selectedRating == 0.0 &&
                    _selectedCity.toLowerCase() == 'all') {
                  return const Center(
                    child: Text('Masukkan kata kunci pencarian atau pilih filter'),
                  );
                }
                if (provider.searchState is Loading) {
                  return Center(child: loadingLottie());
                } else if (provider.searchState is Error) {
                  return const Center(child: Text('Error loading search results'));
                } else if (provider.searchState is Success<List<Restaurant>>) {
                  final restaurants = (provider.searchState as Success<List<Restaurant>>).data;
                  if (restaurants.isEmpty) {
                    return const Center(child: Text('No restaurants found'));
                  }
                  return ListView.builder(
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return RestaurantItem(restaurant: restaurant);
                    },
                  );
                } else {
                  return const Center(child: Text('Mulai pencarian'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
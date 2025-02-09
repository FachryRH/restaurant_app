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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<RestaurantProvider>().searchRestaurants(query);
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
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, _) {
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
            return const Center(child: Text('Start typing to search'));
          }
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/models/restaurant.dart';
import 'package:restaurant_app/providers/restaurant_provider.dart';
import 'package:restaurant_app/providers/theme_provider.dart';
import 'package:restaurant_app/screens/restaurant_detail_screen.dart';
import 'package:restaurant_app/screens/search_screen.dart';
import 'package:restaurant_app/widgets/loading_indicator.dart';
import 'package:restaurant_app/widgets/error_message.dart';

class RestaurantList extends StatefulWidget {
  const RestaurantList({super.key});

  @override
  RestaurantListState createState() => RestaurantListState();
}

class RestaurantListState extends State<RestaurantList> {
  late Future<void> _fetchFuture;

  @override
  void initState() {
    super.initState();
    _fetchFuture = Provider.of<RestaurantProvider>(context, listen: false)
        .fetchRestaurants();
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ErrorMessage(message: message),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _fetchFuture = Provider.of<RestaurantProvider>(context, listen: false)
                    .fetchRestaurants();
              });
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.wb_sunny
                      : Icons.nights_stay,
                  color: Colors.white,
                ),
                onPressed: () {
                  themeProvider.toggleTheme(themeProvider.themeMode != ThemeMode.dark);
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _fetchFuture,
        builder: (context, snapshot) {
          final provider = Provider.of<RestaurantProvider>(context);
          if (provider.restaurantsState is Loading) {
            return Center(child: loadingLottie());
          } else if (provider.restaurantsState is Success<List<Restaurant>>) {
            final restaurants = (provider.restaurantsState as Success<List<Restaurant>>).data;
            return ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return RestaurantItem(restaurant: restaurant);
              },
            );
          } else if (provider.restaurantsState is Error) {
            return _buildError((provider.restaurantsState as Error).message);
          } else {
            return const Center(child: Text('Unknown state'));
          }
        },
      ),
    );
  }
}

class RestaurantItem extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantItem({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: Hero(
          tag: 'image-${restaurant.id}',
          child: Image.network(
            'https://restaurant-api.dicoding.dev/images/medium/${restaurant.pictureId}',
            width: 100,
            fit: BoxFit.cover,
          ),
        ),
        title: Hero(
          tag: 'title-${restaurant.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Text(restaurant.name),
          ),
        ),
        subtitle: Text('${restaurant.city} • Rating: ${restaurant.rating}'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailPage(restaurant: restaurant),
            ),
          );
        },
      ),
    );
  }
}
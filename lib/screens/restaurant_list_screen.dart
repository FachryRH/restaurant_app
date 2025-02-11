import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/models/restaurant.dart';
import 'package:restaurant_app/providers/restaurant_provider.dart';
import 'package:restaurant_app/providers/theme_provider.dart';
import 'package:restaurant_app/screens/restaurant_detail_screen.dart';
import 'package:restaurant_app/screens/search_screen.dart';
import 'package:restaurant_app/widgets/loading_indicator.dart';
import 'package:restaurant_app/widgets/error_message.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  RestaurantListScreenState createState() => RestaurantListScreenState();
}

class RestaurantListScreenState extends State<RestaurantListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestaurantProvider>(context, listen: false)
          .fetchRestaurants();
    });
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
                MaterialPageRoute(builder: (context) => const SearchScreen()),
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
                  themeProvider
                      .toggleTheme(themeProvider.themeMode != ThemeMode.dark);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, _) {
          final state = provider.restaurantsState;
          if (state is Loading<List<Restaurant>>) {
            return Center(child: loadingLottie());
          } else if (state is Success<List<Restaurant>>) {
            final restaurants = state.data;
            return ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return RestaurantItem(restaurant: restaurant);
              },
            );
          } else if (state is Error<List<Restaurant>>) {
            return const ErrorMessage(
              message:
                  "Terjadi kesalahan saat memuat data restoran. Silakan coba lagi.",
            );
          } else {
            return const Center(child: Text("Data tidak tersedia."));
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
              builder: (context) =>
                  RestaurantDetailScreen(restaurant: restaurant),
            ),
          );
        },
      ),
    );
  }
}

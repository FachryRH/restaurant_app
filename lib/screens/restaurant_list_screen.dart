import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/models/restaurant.dart';
import 'package:restaurant_app/providers/restaurant_provider.dart';
import 'package:restaurant_app/providers/theme_provider.dart';
import 'package:restaurant_app/screens/restaurant_detail_screen.dart';
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
    _fetchFuture = Provider.of<RestaurantProvider>(context, listen: false).fetchRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant App'),
        actions: [
          // Tombol search atau lainnya bisa ditambahkan di sini
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                // Tampilkan ikon matahari jika mode saat ini adalah dark, dan sebaliknya
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark ? Icons.wb_sunny : Icons.nights_stay,
                  color: Colors.white,
                ),
                onPressed: () {
                  // Toggle mode berdasarkan mode saat ini
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
          } else if (provider.restaurantsState is Success) {
            final restaurants = (provider.restaurantsState as Success<List<Restaurant>>).data;
            return ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                return RestaurantItem(restaurant: restaurants[index]);
              },
            );
          } else if (provider.restaurantsState is Error) {
            return ErrorMessage(message: (provider.restaurantsState as Error).message);
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
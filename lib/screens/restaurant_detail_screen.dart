import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/models/restaurant.dart';
import 'package:restaurant_app/providers/restaurant_provider.dart';
import 'package:restaurant_app/widgets/loading_indicator.dart';
import 'package:restaurant_app/widgets/error_message.dart';

class RestaurantDetailPage extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailPage({super.key, required this.restaurant});

  @override
  RestaurantDetailPageState createState() => RestaurantDetailPageState();
}

class RestaurantDetailPageState extends State<RestaurantDetailPage> {
  late Future<void> _fetchDetailFuture;
  final _nameController = TextEditingController();
  final _reviewController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchDetailFuture = Provider.of<RestaurantProvider>(context, listen: false)
        .fetchRestaurantDetail(widget.restaurant.id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() {
    if (_formKey.currentState!.validate()) {
      Provider.of<RestaurantProvider>(context, listen: false).addReview(
        widget.restaurant.id,
        _nameController.text,
        _reviewController.text,
      );
      _nameController.clear();
      _reviewController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildReviewSection(List<CustomerReview> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Reviews',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...reviews.map((review) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(review.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(review.review),
                const SizedBox(height: 4),
                Text(
                  review.date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildReviewForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tulis Ulasan Anda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
            value == null || value.isEmpty ? 'Nama harus diisi' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reviewController,
            decoration: const InputDecoration(
              labelText: 'Ulasan',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) =>
            value == null || value.isEmpty ? 'Ulasan harus diisi' : null,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitReview,
            child: const Text('Kirim Ulasan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Restoran'),
      ),
      body: FutureBuilder(
        future: _fetchDetailFuture,
        builder: (context, snapshot) {
          final provider = Provider.of<RestaurantProvider>(context);
          if (provider.restaurantDetailState is Loading) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Hero(
                    tag: 'image-${widget.restaurant.id}',
                    child: Image.network(
                      'https://restaurant-api.dicoding.dev/images/large/${widget.restaurant.pictureId}',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(child: loadingLottie()),
                ],
              ),
            );
          } else if (provider.restaurantDetailState is Success) {
            final restaurant = (provider.restaurantDetailState as Success<RestaurantDetail>).data;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Hero(
                    tag: 'image-${widget.restaurant.id}',
                    child: Image.network(
                      'https://restaurant-api.dicoding.dev/images/large/${widget.restaurant.pictureId}',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'title-${widget.restaurant.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              restaurant.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Text('${restaurant.city} • ${restaurant.address}'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(restaurant.description),
                        const SizedBox(height: 16),
                        ExpansionTile(
                          title: const Text('Menu Makanan'),
                          children: restaurant.menus.foods
                              .map((food) => ListTile(title: Text(food.name)))
                              .toList(),
                        ),
                        ExpansionTile(
                          title: const Text('Menu Minuman'),
                          children: restaurant.menus.drinks
                              .map((drink) => ListTile(title: Text(drink.name)))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildReviewSection(restaurant.customerReviews),
                        const Divider(),
                        _buildReviewForm(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (provider.restaurantDetailState is Error) {
            return ErrorMessage(message: (provider.restaurantDetailState as Error).message);
          } else {
            return const Center(child: Text('Unknown state'));
          }
        },
      ),
    );
  }
}
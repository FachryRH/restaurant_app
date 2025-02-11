import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/models/restaurant.dart';
import 'package:restaurant_app/providers/restaurant_provider.dart';
import 'package:restaurant_app/widgets/loading_indicator.dart';
import 'package:restaurant_app/widgets/error_message.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  RestaurantDetailScreenState createState() => RestaurantDetailScreenState();
}

class RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestaurantProvider>(context, listen: false)
          .fetchRestaurantDetail(widget.restaurant.id);
    });
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
                (value == null || value.isEmpty) ? 'Nama harus diisi' : null,
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
                (value == null || value.isEmpty) ? 'Ulasan harus diisi' : null,
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
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, _) {
          final state = provider.restaurantDetailState;
          if (state is Loading<RestaurantDetail>) {
            return Center(child: loadingLottie());
          } else if (state is Success<RestaurantDetail>) {
            final detail = state.data;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isDesktop = constraints.maxWidth > 800;
                      final double maxImageHeight = isDesktop ? 400 : 600;
                      final double maxImageWidth =
                          isDesktop ? 800 : constraints.maxWidth;
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxImageWidth,
                            maxHeight: maxImageHeight,
                          ),
                          child: Hero(
                            tag: 'image-${widget.restaurant.id}',
                            child: Image.network(
                              'https://restaurant-api.dicoding.dev/images/large/${widget.restaurant.pictureId}',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
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
                              detail.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Text('${detail.city} • ${detail.address}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('Rating: ${detail.rating}',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          detail.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ExpansionTile(
                          title: const Text('Menu Makanan'),
                          children: detail.menus.foods
                              .map((food) => ListTile(title: Text(food.name)))
                              .toList(),
                        ),
                        ExpansionTile(
                          title: const Text('Menu Minuman'),
                          children: detail.menus.drinks
                              .map((drink) => ListTile(title: Text(drink.name)))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildReviewSection(detail.customerReviews),
                        const Divider(),
                        _buildReviewForm(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (state is Error<RestaurantDetail>) {
            return const ErrorMessage(
              message:
                  "Terjadi kesalahan saat memuat detail restoran. Silakan coba lagi.",
            );
          } else {
            return const Center(child: Text('Data tidak tersedia.'));
          }
        },
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:restaurant_app/models/restaurant.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:http/http.dart' as http;

sealed class ResultState<T> {}

class Loading<T> extends ResultState<T> {}

class Success<T> extends ResultState<T> {
  final T data;
  Success(this.data);
}

class Error<T> extends ResultState<T> {
  final String message;
  Error(this.message);
}

class RestaurantProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://restaurant-api.dicoding.dev/';
  final ApiService apiService;

  RestaurantProvider({required this.apiService});

  ResultState<List<Restaurant>> _restaurantsState = Loading();
  ResultState<List<Restaurant>> get restaurantsState => _restaurantsState;

  ResultState<RestaurantDetail> _restaurantDetailState = Loading();
  ResultState<RestaurantDetail> get restaurantDetailState =>
      _restaurantDetailState;

  ResultState<List<Restaurant>> _searchState = Loading();
  ResultState<List<Restaurant>> get searchState => _searchState;

  Future<void> fetchRestaurants() async {
    _restaurantsState = Loading();
    notifyListeners();
    try {
      final restaurants = await apiService.getRestaurants();
      _restaurantsState = Success(restaurants);
    } catch (e) {
      _restaurantsState = Error(e.toString());
    }
    notifyListeners();
  }

  Future<void> fetchRestaurantDetail(String id) async {
    _restaurantDetailState = Loading();
    notifyListeners();
    try {
      final restaurantDetail = await apiService.getRestaurantDetail(id);
      _restaurantDetailState = Success(restaurantDetail);
    } catch (e) {
      _restaurantDetailState = Error(e.toString());
    }
    notifyListeners();
  }

  Future<void> searchRestaurants(String query,
      {double? minRating, String? city}) async {
    _searchState = Loading();
    notifyListeners();
    try {
      List<Restaurant> restaurants;
      if (query.trim().isEmpty) {
        restaurants = await apiService.getRestaurants();
      } else {
        final response = await http.get(Uri.parse('$_baseUrl/search?q=$query'));
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          restaurants = (jsonData['restaurants'] as List)
              .map((data) => Restaurant.fromJson(data))
              .toList();
        } else {
          throw Exception('Failed to load restaurants');
        }
      }
      if (minRating != null) {
        restaurants = restaurants.where((r) => r.rating >= minRating).toList();
      }
      if (city != null && city.toLowerCase() != 'all') {
        restaurants = restaurants
            .where((r) => r.city.toLowerCase() == city.toLowerCase())
            .toList();
      }
      _searchState = Success(restaurants);
    } catch (e) {
      _searchState = Error(e.toString());
    }
    notifyListeners();
  }

  Future<void> addReview(String id, String name, String review) async {
    if (_restaurantDetailState is Success<RestaurantDetail>) {
      final currentDetail =
          (_restaurantDetailState as Success<RestaurantDetail>).data;

      final newReview = CustomerReview(
        name: name,
        review: review,
        date: DateTime.now().toString(),
      );

      final updatedReviews =
          List<CustomerReview>.from(currentDetail.customerReviews)
            ..insert(0, newReview);

      final updatedDetail = RestaurantDetail(
        id: currentDetail.id,
        name: currentDetail.name,
        description: currentDetail.description,
        city: currentDetail.city,
        address: currentDetail.address,
        pictureId: currentDetail.pictureId,
        rating: currentDetail.rating,
        categories: currentDetail.categories,
        menus: currentDetail.menus,
        customerReviews: updatedReviews,
      );
      _restaurantDetailState = Success(updatedDetail);
      notifyListeners();
    }

    try {
      final responseReviews = await apiService.addReview(id, name, review);
      if (_restaurantDetailState is Success<RestaurantDetail>) {
        final currentDetail =
            (_restaurantDetailState as Success<RestaurantDetail>).data;
        final updatedDetail = RestaurantDetail(
          id: currentDetail.id,
          name: currentDetail.name,
          description: currentDetail.description,
          city: currentDetail.city,
          address: currentDetail.address,
          pictureId: currentDetail.pictureId,
          rating: currentDetail.rating,
          categories: currentDetail.categories,
          menus: currentDetail.menus,
          customerReviews: responseReviews,
        );
        _restaurantDetailState = Success(updatedDetail);
      }
    } catch (e) {
      debugPrint('Error addReview: $e');
    }
    notifyListeners();
  }
}

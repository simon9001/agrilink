import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrilink/core/app_export.dart';
import 'package:agrilink/core/user_role.dart';

class DjangoApiService {
  static final DjangoApiService _instance = DjangoApiService._internal();
  factory DjangoApiService() => _instance;

  DjangoApiService._internal();

  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  UserData? _currentUser;
  SharedPreferences? _prefs;

  // API Configuration
  static const String _baseUrl = 'https://api.agrilink.com/api'; // Update with actual backend URL
  static const Duration _timeout = Duration(seconds: 10);

  // Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add request/response interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Try to restore user session
    await _restoreUserSession();
  }

  // Request interceptor
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add authentication header if token is available
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }

    // Add user agent
    options.headers['User-Agent'] = 'AgriLink-Flutter/1.0';

    handler.next(options);
  }

  // Response interceptor
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log responses for debugging
    if (kDebugMode) {
      print('API Response: ${response.statusCode} - ${response.requestOptions.path}');
    }

    handler.next(response);
  }

  // Error interceptor
  void _onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401) {
      // Token expired, try to refresh
      if (await _refreshToken()) {
        // Retry the original request with new token
        final originalRequest = error.requestOptions;
        originalRequest.headers['Authorization'] = 'Bearer $_accessToken';

        try {
          final response = await _dio.fetch(originalRequest);
          return handler.resolve(response);
        } catch (e) {
          // Refresh failed, user needs to login again
          await _clearSession();
        }
      }
    }

    // Log errors for debugging
    if (kDebugMode) {
      print('API Error: ${error.message}');
      if (error.response != null) {
        print('Error Response: ${error.response?.statusCode} - ${error.response?.data}');
      }
    }

    handler.next(error);
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login/',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Store tokens
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];

        // Store in shared preferences
        await _prefs?.setString('access_token', _accessToken!);
        await _prefs?.setString('refresh_token', _refreshToken!);

        // Store user data
        _currentUser = UserData.fromMap(data['user']);
        await _saveUserSession();

        return data;
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phone,
    Map<String, dynamic>? profileData,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/',
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
          'phone': phone,
          'profile_data': profileData,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data['data'];

        // Store tokens
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];

        // Store in shared preferences
        await _prefs?.setString('access_token', _accessToken!);
        await _prefs?.setString('refresh_token', _refreshToken!);

        // Store user data
        _currentUser = UserData.fromMap(data['user']);
        await _saveUserSession();

        return data;
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<bool> logout() async {
    try {
      if (_accessToken != null) {
        await _dio.post(
          '/auth/logout/',
          options: Options(
            headers: {'Authorization': 'Bearer $_accessToken'},
          ),
        );
      }

      await _clearSession();
      return true;
    } catch (e) {
      // Even if logout fails, clear local session
      await _clearSession();
      return false;
    }
  }

  // Profile methods
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile/');

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profilePicture,
    String? locationAddress,
    Map<String, dynamic>? profileData,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (phone != null) data['phone'] = phone;
      if (profilePicture != null) data['profile_picture'] = profilePicture;
      if (locationAddress != null) data['location_address'] = locationAddress;
      if (profileData != null) data['profile_data'] = profileData;

      final response = await _dio.put(
        '/users/profile/',
        data: data,
      );

      if (response.statusCode == 200) {
        // Update current user data
        _currentUser = UserData.fromMap(response.data['data']);
        await _saveUserSession();

        return response.data['data'];
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // Marketplace methods
  Future<List<dynamic>> getListings({
    String? category,
    String? search,
    String? minPrice,
    String? maxPrice,
    bool? organicOnly,
    String? qualityGrade,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (minPrice != null) queryParams['price_min'] = minPrice;
      if (maxPrice != null) queryParams['price_max'] = maxPrice;
      if (organicOnly != null) queryParams['organic_only'] = organicOnly;
      if (qualityGrade != null) queryParams['quality_grade'] = qualityGrade;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _dio.get(
        '/market/listings/',
        queryParameters: queryParams.isEmpty() ? null : queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Map<String, dynamic>> createListing({
    required String productName,
    required String category,
    required String quantity,
    required String unitPrice,
    required String qualityGrade,
    required String description,
    required List<String> primaryCrops,
    bool isOrganic = false,
    Map<String, dynamic>? certificationDetails,
    String? variety,
    String? images,
  }) async {
    try {
      final data = {
        'product_name': productName,
        'category': category,
        'quantity_available': quantity,
        'unit_price': unitPrice,
        'quality_grade': qualityGrade,
        'description': description,
        'primary_crops': primaryCrops,
        'is_organic': isOrganic,
        'certification_details': certificationDetails ?? {},
        'variety': variety,
        'images': images ?? [],
      };

      final response = await _dio.post(
        '/market/listings/',
        data: data,
      );

      if (response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // Order methods
  Future<List<dynamic>> getOrders({
    String? status,
    String? dateFrom,
    String? dateTo,
    String? minAmount,
    String? maxAmount,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (status != null) queryParams['status'] = status;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (minAmount != null) queryParams['min_amount'] = minAmount;
      if (maxAmount != null) queryParams['max_amount'] = maxAmount;

      final response = await _dio.get(
        '/orders/',
        queryParameters: queryParams.isEmpty() ? null : queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required String listingId,
    required String quantity,
    required String deliveryAddress,
    required String deliveryDate,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final data = {
        'listing_id': listingId,
        'quantity_ordered': quantity,
        'delivery_address': deliveryAddress,
        'delivery_date': deliveryDate,
        'payment_method': paymentMethod,
        'buyer_notes': notes,
      };

      final response = await _dio.post(
        '/orders/',
        data: data,
      );

      if (response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // Expert services methods
  Future<List<dynamic>> getAdvicePosts({
    String? category,
    String? search,
    String? targetAudience,
    bool? featuredOnly,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (targetAudience != null) queryParams['target_audience'] = targetAudience;
      if (featuredOnly != null) queryParams['featured_only'] = featuredOnly;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _dio.get(
        '/experts/advice/',
        queryParameters: queryParams.isEmpty() ? null : queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<dynamic>> getConsultations({
    String? status,
    String? expertId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (status != null) queryParams['status'] = status;
      if (expertId != null) queryParams['expert_id'] = expertId;

      final response = await _dio.get(
        '/experts/consultations/',
        queryParameters: queryParams.isEmpty() ? null : queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // Dashboard methods
  Future<Map<String, dynamic>> getDashboardData({required UserRole role}) async {
    try {
      final response = await _dio.get('/dashboard/${role.displayName.toLowerCase()}/');

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw _handleApiError(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // Get current user
  UserData? get currentUser => _currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => _accessToken != null && _currentUser != null;

  // Private methods
  Future<bool> _refreshToken() async {
    try {
      if (_refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/token/refresh/',
        data: {'refresh_token': _refreshToken},
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        _refreshToken = response.data['refresh_token'];

        // Update stored tokens
        await _prefs?.setString('access_token', _accessToken!);
        await _prefs?.setString('refresh_token', _refreshToken!);

        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }

    return false;
  }

  Future<void> _saveUserSession() async {
    if (_currentUser != null && _prefs != null) {
      await _prefs.setString('user_data', jsonEncode(_currentUser!.toMap()));
    }
  }

  Future<void> _restoreUserSession() async {
    try {
      _accessToken = _prefs?.getString('access_token');
      _refreshToken = _prefs?.getString('refresh_token');

      final userDataString = _prefs?.getString('user_data');
      if (userDataString != null) {
        _currentUser = UserData.fromMap(jsonDecode(userDataString));
      }
    } catch (e) {
      print('Failed to restore user session: $e');
    }
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;

    if (_prefs != null) {
      await _prefs.remove('access_token');
      await _prefs.remove('refresh_token');
      await _prefs.remove('user_data');
    }
  }

  // Error handling
  Exception _handleApiError(Response response) {
    final data = response.data;
    final message = data['error']['message'] ?? 'An unknown error occurred';

    return Exception(message);
  }

  Exception _handleDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout. Please check your internet connection.');
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return Exception('Request timeout. Please try again.');
    } else if (error.type == DioExceptionType.badResponse) {
      try {
        final response = error.response!;
        final data = response.data;
        final message = data['error']['message'] ?? 'Server error occurred';
        return Exception(message);
      } catch (e) {
        return Exception('Server error occurred: ${response.statusCode}');
      }
    } else {
      return Exception('Network error: ${error.message}');
    }
  }
}
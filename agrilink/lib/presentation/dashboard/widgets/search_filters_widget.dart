import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class SearchFiltersWidget extends StatefulWidget {
  final List<String> categories;
  final List<String> locations;
  final Function(Map<String, dynamic>) onFiltersChanged;
  final Map<String, dynamic> initialFilters;

  const SearchFiltersWidget({
    super.key,
    required this.categories,
    required this.locations,
    required this.onFiltersChanged,
    this.initialFilters = const {},
  });

  @override
  State<SearchFiltersWidget> createState() => _SearchFiltersWidgetState();
}

class _SearchFiltersWidgetState extends State<SearchFiltersWidget> {
  late Map<String, dynamic> _filters;
  RangeValues _priceRange = const RangeValues(0, 1000);
  double _minRating = 0;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.initialFilters);
    _priceRange = RangeValues(
      (_filters['min_price'] as double?) ?? 0,
      (_filters['max_price'] as double?) ?? 1000,
    );
    _minRating = (_filters['min_rating'] as double?) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 2.h),
          _buildSearchField(),
          SizedBox(height: 2.h),
          _buildCategoryFilter(),
          SizedBox(height: 2.h),
          _buildLocationFilter(),
          SizedBox(height: 2.h),
          _buildPriceRangeFilter(),
          SizedBox(height: 2.h),
          _buildRatingFilter(),
          SizedBox(height: 2.h),
          _buildAdditionalFilters(),
          SizedBox(height: 2.h),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Search Filters',
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: _clearAllFilters,
          child: Text(
            'Clear All',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      initialValue: _filters['search'] as String?,
      decoration: InputDecoration(
        hintText: 'Search products, farmers, or keywords...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      ),
      onChanged: (value) {
        _filters['search'] = value;
        _notifyFiltersChanged();
      },
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: widget.categories.map((category) {
            final isSelected = _filters['category'] == category;
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filters['category'] = selected ? category : null;
                });
                _notifyFiltersChanged();
              },
              backgroundColor: Colors.grey[100],
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          value: _filters['location'] as String?,
          decoration: InputDecoration(
            hintText: 'Select location',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          ),
          items: widget.locations.map((location) {
            return DropdownMenuItem(
              value: location,
              child: Text(location),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _filters['location'] = value;
            });
            _notifyFiltersChanged();
          },
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (\$${_priceRange.start.round()} - \$${_priceRange.end.round()})',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 1000,
          divisions: 20,
          labels: RangeLabels(
            '\$${_priceRange.start.round()}',
            '\$${_priceRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
              _filters['min_price'] = values.start;
              _filters['max_price'] = values.end;
            });
            _notifyFiltersChanged();
          },
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating: ${_minRating.toStringAsFixed(1)}',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Slider(
          value: _minRating,
          min: 0,
          max: 5,
          divisions: 10,
          label: _minRating.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _minRating = value;
              _filters['min_rating'] = value;
            });
            _notifyFiltersChanged();
          },
        ),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            return Icon(
              starValue <= _minRating ? Icons.star : Icons.star_border,
              color: Colors.orange,
              size: 4.w,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAdditionalFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Filters',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        CheckboxListTile(
          title: const Text('Organic Only'),
          value: _filters['organic_only'] as bool? ?? false,
          onChanged: (value) {
            setState(() {
              _filters['organic_only'] = value;
            });
            _notifyFiltersChanged();
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('In Stock Only'),
          value: _filters['in_stock_only'] as bool? ?? false,
          onChanged: (value) {
            setState(() {
              _filters['in_stock_only'] = value;
            });
            _notifyFiltersChanged();
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Verified Sellers Only'),
          value: _filters['verified_only'] as bool? ?? false,
          onChanged: (value) {
            setState(() {
              _filters['verified_only'] = value;
            });
            _notifyFiltersChanged();
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _clearAllFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.grey[700],
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
            ),
            child: Text('Reset'),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
            ),
            child: Text('Apply Filters'),
          ),
        ),
      ],
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filters.clear();
      _priceRange = const RangeValues(0, 1000);
      _minRating = 0;
    });
    _notifyFiltersChanged();
  }

  void _notifyFiltersChanged() {
    widget.onFiltersChanged(_filters);
  }
}
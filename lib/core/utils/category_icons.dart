import 'package:flutter/material.dart';

class CategoryIconInfo {
  final String key;
  final String label;
  final IconData icon;
  final String group;

  const CategoryIconInfo({
    required this.key,
    required this.label,
    required this.icon,
    required this.group,
  });
}

class CategoryIcons {
  static const List<CategoryIconInfo> allIcons = [
    // Living & Food
    CategoryIconInfo(
      key: 'fastfood_rounded',
      label: 'Food & Dining',
      icon: Icons.fastfood_rounded,
      group: 'Food & Living',
    ),
    CategoryIconInfo(
      key: 'restaurant_rounded',
      label: 'Restaurant',
      icon: Icons.restaurant_rounded,
      group: 'Food & Living',
    ),
    CategoryIconInfo(
      key: 'local_grocery_store_rounded',
      label: 'Groceries',
      icon: Icons.local_grocery_store_rounded,
      group: 'Food & Living',
    ),
    CategoryIconInfo(
      key: 'local_cafe_rounded',
      label: 'Coffee & Drinks',
      icon: Icons.local_cafe_rounded,
      group: 'Food & Living',
    ),
    CategoryIconInfo(
      key: 'home_work_rounded',
      label: 'Housing & Rent',
      icon: Icons.home_work_rounded,
      group: 'Food & Living',
    ),
    CategoryIconInfo(
      key: 'electric_bolt_rounded',
      label: 'Utilities & Power',
      icon: Icons.electric_bolt_rounded,
      group: 'Food & Living',
    ),
    CategoryIconInfo(
      key: 'water_drop_rounded',
      label: 'Water Bill',
      icon: Icons.water_drop_rounded,
      group: 'Food & Living',
    ),

    // Finance & Income
    CategoryIconInfo(
      key: 'payments_rounded',
      label: 'Salary & Income',
      icon: Icons.payments_rounded,
      group: 'Finance',
    ),
    CategoryIconInfo(
      key: 'account_balance_wallet_rounded',
      label: 'Wallet & Cash',
      icon: Icons.account_balance_wallet_rounded,
      group: 'Finance',
    ),
    CategoryIconInfo(
      key: 'savings_rounded',
      label: 'Savings & Goals',
      icon: Icons.savings_rounded,
      group: 'Finance',
    ),
    CategoryIconInfo(
      key: 'trending_up_rounded',
      label: 'Investments',
      icon: Icons.trending_up_rounded,
      group: 'Finance',
    ),
    CategoryIconInfo(
      key: 'credit_card_rounded',
      label: 'Credit Cards',
      icon: Icons.credit_card_rounded,
      group: 'Finance',
    ),
    CategoryIconInfo(
      key: 'receipt_long_rounded',
      label: 'Invoices & Taxes',
      icon: Icons.receipt_long_rounded,
      group: 'Finance',
    ),
    CategoryIconInfo(
      key: 'currency_exchange_rounded',
      label: 'Transfers',
      icon: Icons.currency_exchange_rounded,
      group: 'Finance',
    ),

    // Transportation & Travel
    CategoryIconInfo(
      key: 'directions_bus_rounded',
      label: 'Public Transit',
      icon: Icons.directions_bus_rounded,
      group: 'Transport',
    ),
    CategoryIconInfo(
      key: 'directions_car_rounded',
      label: 'Car & Fuel',
      icon: Icons.directions_car_rounded,
      group: 'Transport',
    ),
    CategoryIconInfo(
      key: 'local_taxi_rounded',
      label: 'Taxi & Rides',
      icon: Icons.local_taxi_rounded,
      group: 'Transport',
    ),
    CategoryIconInfo(
      key: 'flight_rounded',
      label: 'Travel & Flights',
      icon: Icons.flight_rounded,
      group: 'Transport',
    ),
    CategoryIconInfo(
      key: 'two_wheeler_rounded',
      label: 'Bike & Courier',
      icon: Icons.two_wheeler_rounded,
      group: 'Transport',
    ),

    // Lifestyle & Entertainment
    CategoryIconInfo(
      key: 'shopping_bag_rounded',
      label: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      group: 'Lifestyle',
    ),
    CategoryIconInfo(
      key: 'movie_rounded',
      label: 'Movies & Media',
      icon: Icons.movie_rounded,
      group: 'Lifestyle',
    ),
    CategoryIconInfo(
      key: 'sports_esports_rounded',
      label: 'Gaming',
      icon: Icons.sports_esports_rounded,
      group: 'Lifestyle',
    ),
    CategoryIconInfo(
      key: 'fitness_center_rounded',
      label: 'Gym & Fitness',
      icon: Icons.fitness_center_rounded,
      group: 'Lifestyle',
    ),
    CategoryIconInfo(
      key: 'favorite_rounded',
      label: 'Health & Medical',
      icon: Icons.favorite_rounded,
      group: 'Lifestyle',
    ),
    CategoryIconInfo(
      key: 'card_giftcard_rounded',
      label: 'Gifts & Charity',
      icon: Icons.card_giftcard_rounded,
      group: 'Lifestyle',
    ),
    CategoryIconInfo(
      key: 'pets_rounded',
      label: 'Pets & Animals',
      icon: Icons.pets_rounded,
      group: 'Lifestyle',
    ),

    // Learning & Education
    CategoryIconInfo(
      key: 'school_rounded',
      label: 'Education & Tuition',
      icon: Icons.school_rounded,
      group: 'Learning',
    ),
    CategoryIconInfo(
      key: 'menu_book_rounded',
      label: 'Books & Courses',
      icon: Icons.menu_book_rounded,
      group: 'Learning',
    ),
    CategoryIconInfo(
      key: 'laptop_chromebook_rounded',
      label: 'Tech & Software',
      icon: Icons.laptop_chromebook_rounded,
      group: 'Learning',
    ),
    CategoryIconInfo(
      key: 'phone_iphone_rounded',
      label: 'Phone & Internet',
      icon: Icons.phone_iphone_rounded,
      group: 'Learning',
    ),
    CategoryIconInfo(
      key: 'lightbulb_rounded',
      label: 'Ideas & Projects',
      icon: Icons.lightbulb_rounded,
      group: 'Learning',
    ),
  ];

  static final Map<String, IconData> _iconMap = {
    for (var item in allIcons) item.key: item.icon,
  };

  /// Returns the corresponding IconData for an icon key name with fallback
  static IconData getIconData(String? key) {
    if (key == null || key.isEmpty) {
      return Icons.category_rounded;
    }
    return _iconMap[key] ?? Icons.category_rounded;
  }
}

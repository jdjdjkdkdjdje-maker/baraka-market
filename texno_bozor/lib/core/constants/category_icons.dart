import 'package:flutter/material.dart';

/// Kategoriya icon-kalitlarini Material ikonlarga aylantirish.
const Map<String, IconData> categoryIcons = {
  'phone': Icons.smartphone,
  'laptop': Icons.laptop_mac,
  'desktop': Icons.computer,
  'gpu': Icons.videogame_asset,
  'cpu': Icons.memory,
  'motherboard': Icons.developer_board,
  'ram': Icons.sd_card,
  'ssd': Icons.storage,
  'hdd': Icons.album,
  'monitor': Icons.desktop_windows,
  'keyboard': Icons.keyboard,
  'mouse': Icons.mouse,
  'headphones': Icons.headphones,
  'tablet': Icons.tablet_mac,
  'watch': Icons.watch,
  'tv': Icons.tv,
  'camera': Icons.photo_camera,
  'printer': Icons.print,
  'router': Icons.router,
  'console': Icons.sports_esports,
  'gaming': Icons.games,
  'powerbank': Icons.battery_charging_full,
  'charger': Icons.power,
  'cable': Icons.cable,
  'home': Icons.home_filled,
  'other': Icons.devices_other,
  'device': Icons.devices,
};

IconData iconForCategory(String key) =>
    categoryIcons[key] ?? Icons.devices_other;

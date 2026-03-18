// Web stub — Isar is not available on web.
// This file is only imported on web via conditional import in species_loader.dart.
// loadAppData() is never called on web (species_loader handles it directly).

import 'app_data.dart';

class AppDataStore {
  static Future<AppData> loadAppData() {
    throw UnsupportedError('AppDataStore is not supported on web');
  }
}

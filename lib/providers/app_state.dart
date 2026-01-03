import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pixelshot_flutter/models/screenshot.dart';
import 'package:pixelshot_flutter/services/gemini_service.dart';
import 'package:pixelshot_flutter/services/gallery_service.dart';
import 'package:pixelshot_flutter/services/encryption_service.dart';
import 'package:pixelshot_flutter/services/background_service_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:photo_manager/photo_manager.dart';

class AppState extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final GalleryService _galleryService = GalleryService();

  List<Screenshot> _screenshots = [];
  List<Screenshot> get screenshots => _screenshots;

  // New Album State
  List<AssetPathEntity> _albums = [];
  List<AssetPathEntity> get albums => _albums;

  AssetPathEntity? _selectedAlbum;
  AssetPathEntity? get selectedAlbum => _selectedAlbum;

  // New Folder State (File Manager)
  String? _selectedFolderPath;
  String? get selectedFolderPath => _selectedFolderPath;

  int get pendingCount => _screenshots.where((s) => !s.analyzed).length;

  List<String> get uniqueTags {
    final tagCounts = <String, int>{};
    for (var s in _screenshots) {
      for (var tag in s.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final sortedTags = tagCounts.keys.toList()
      ..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));

    return sortedTags;
  }

  String _apiKey = '';
  String get apiKey => _apiKey;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic> _analysisCache = {};
  String? _savedAlbumId;

  late Future<void> _initFuture;

  AppState() {
    _initFuture = _loadSettings();
  }

  int _dailyRequestCount = 0;
  int get dailyRequestCount => _dailyRequestCount;

  // Models
  String _primaryModel = 'gemini-2.5-flash-lite';
  String get primaryModel => _primaryModel;

  String _fallbackModel = 'gemini-2.5-flash';
  String get fallbackModel => _fallbackModel;

  Future<void> setModels(String primary, String fallback) async {
    _primaryModel = primary;
    _fallbackModel = fallback;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_primary_model', primary);
    await prefs.setString('gemini_fallback_model', fallback);
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('gemini_api_key') ?? '';
    _savedAlbumId = prefs.getString('selected_album_id');
    _selectedFolderPath = prefs.getString('selected_folder_path');

    // Load models
    _primaryModel =
        prefs.getString('gemini_primary_model') ?? 'gemini-2.5-flash-lite';
    _fallbackModel =
        prefs.getString('gemini_fallback_model') ?? 'gemini-2.5-flash';

    // Daily Limit Logic
    final lastDate = prefs.getString('daily_usage_date');
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (lastDate != today) {
      _dailyRequestCount = 0;
      await prefs.setString('daily_usage_date', today);
      await prefs.setInt('daily_usage_count', 0);
    } else {
      _dailyRequestCount = prefs.getInt('daily_usage_count') ?? 0;
    }

    String? cacheString = prefs.getString('analysis_cache');
    if (cacheString != null) {
      cacheString = EncryptionService.decryptData(cacheString);
    }
    if (kDebugMode)
      print("Loaded cache string length: ${cacheString?.length ?? 0}");

    if (cacheString != null) {
      try {
        final decoded = json.decode(cacheString);
        if (decoded is Map) {
          _analysisCache = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        print("Error decoding cache: $e");
      }
    }

    notifyListeners();
  }

  Future<void> _incrementDailyUsage() async {
    _dailyRequestCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_usage_count', _dailyRequestCount);
    // Date is already set at load or reset
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    notifyListeners();
  }

  Future<void> selectAlbum(AssetPathEntity? album) async {
    _selectedFolderPath = null; // Clear folder selection if album is picked
    if (_selectedAlbum?.id == album?.id) return;

    _selectedAlbum = album;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_folder_path'); // Clear folder pref

    if (album != null) {
      await prefs.setString('selected_album_id', album.id);
    } else {
      await prefs.remove('selected_album_id');
    }
    notifyListeners();
    loadScreenshots();
  }

  Future<void> selectFolder(String? path) async {
    _selectedAlbum = null; // Clear album selection
    _selectedFolderPath = path;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_album_id'); // Clear album pref

    if (path != null) {
      await prefs.setString('selected_folder_path', path);
    } else {
      await prefs.remove('selected_folder_path');
    }
    notifyListeners();
    loadScreenshots();
  }

  Future<void> loadScreenshots() async {
    if (kDebugMode) print("Loading screenshots...");
    _isLoading = true;
    notifyListeners();

    try {
      await _initFuture; // Wait for settings/cache to load
    } catch (e) {
      print("Error awaiting init: $e");
    }

    try {
      List<Screenshot> newScreenshots = [];

      // Priority 1: Selected Folder (File Manager)
      if (_selectedFolderPath != null) {
        // File picker usually grants permission to the picked folder URI, but raw path access might need storage perm
        // Try to load
        newScreenshots = await _galleryService.getImagesFromDirectory(
          _selectedFolderPath!,
        );
      }
      // Priority 2: Photo Manager (Albums)
      else {
        final hasPerm = await _galleryService.requestPermission();
        if (hasPerm) {
          // Fetch albums first
          if (_albums.isEmpty) {
            _albums = await _galleryService.getAlbums();
          }

          // Restore selected album if needed
          if (_selectedAlbum == null && _savedAlbumId != null) {
            try {
              _selectedAlbum = _albums.firstWhere((a) => a.id == _savedAlbumId);
            } catch (_) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('selected_album_id');
              _savedAlbumId = null;
            }
          }

          newScreenshots = await _galleryService.getScreenshots(
            specificAlbum: _selectedAlbum,
          );
        }
      }

      int loadedFromCache = 0;
      // Merge with cache
      _screenshots = newScreenshots.map((s) {
        if (_analysisCache.containsKey(s.id)) {
          final cached = _analysisCache[s.id];
          // Check for bad cache (failures saved as success)
          if (cached['description'] == 'Analysis Failed') {
            // Treat as unanalyzed, trigger re-analysis
            return s;
          }

          loadedFromCache++;
          return s.copyWith(
            description: cached['description'],
            category: cached['category'],
            tags: List<String>.from(cached['tags'] ?? []),
            analyzed: true,
            note: cached['note'],
          );
        }
        return s;
      }).toList();

      if (kDebugMode)
        print("Loaded $loadedFromCache/${_screenshots.length} from cache");
    } catch (e) {
      print("Error loading screenshots: $e");
      // Fallback or error handling
    } finally {
      _isLoading = false;
      notifyListeners();
      analyzeAll().then((_) => retryFailed());
    }
  }

  // Retry logic
  final Map<String, int> _retryAttempts = {};

  Future<void> analyzeScreenshot(Screenshot screenshot) async {
    if (_apiKey.isEmpty) return;

    final index = _screenshots.indexWhere((s) => s.id == screenshot.id);
    if (index == -1) return;

    notifyListeners();

    try {
      final result = await _geminiService.analyzeScreenshot(
        screenshot.file,
        _apiKey,
        primaryModel: _primaryModel,
        fallbackModel: _fallbackModel,
      );

      // Verify success
      if (!result.analyzed) {
        throw Exception("Analysis failed (Service returned analyzed: false)");
      }

      final newIndex = _screenshots.indexWhere((s) => s.id == screenshot.id);
      if (newIndex != -1) {
        // Success
        _screenshots[newIndex] = result.copyWith(
          id: screenshot.id,
          timestamp: screenshot.timestamp,
          note: screenshot.note,
        );

        // Clear retry count on success
        _retryAttempts.remove(screenshot.id);

        // Save to cache
        _analysisCache[screenshot.id] = {
          'description': result.description,
          'category': result.category,
          'tags': result.tags,
          'note': screenshot.note,
        };
        await _saveAnalysisCache();
        await _incrementDailyUsage(); // Track usage

        notifyListeners();
      }
    } catch (e) {
      // Failure
      final newIndex = _screenshots.indexWhere((s) => s.id == screenshot.id);
      if (newIndex != -1) {
        _screenshots[newIndex] = screenshot.copyWith(
          category: 'Error',
          description: 'Failed',
        );
        notifyListeners();

        // Auto Retry Logic
        final currentRetries = _retryAttempts[screenshot.id] ?? 0;
        if (currentRetries < 3) {
          _retryAttempts[screenshot.id] = currentRetries + 1;
          if (kDebugMode)
            print(
              "Scheduling auto-retry for ${screenshot.id} (Attempt ${currentRetries + 1}/3)",
            );

          // Schedule retry after 10 seconds
          Future.delayed(const Duration(seconds: 10), () {
            if (kDebugMode) print("Executing auto-retry for ${screenshot.id}");
            analyzeScreenshot(screenshot);
          });
        }
      }
    }
  }

  Future<void> analyzeAll() async {
    final pending = _screenshots
        .where((s) => !s.analyzed && s.category != 'Error')
        .toList();

    if (pending.isNotEmpty) {
      await BackgroundServiceManager.startService();
      BackgroundServiceManager.updateNotificationContent(
        "Analyzing 1/${pending.length} images...",
      );
    }

    // 15 RPM = 1 request every 4 seconds
    for (var i = 0; i < pending.length; i++) {
      if (_apiKey.isEmpty) break;

      BackgroundServiceManager.updateNotificationContent(
        "Analyzing ${i + 1}/${pending.length} images...",
        progress: i + 1,
        max: pending.length,
      );

      await analyzeScreenshot(pending[i]);

      if (i < pending.length - 1) {
        await Future.delayed(const Duration(seconds: 30)); // 2 RPM (Strict)
      }
    }
    
    // Stop if only this method was running, but we might chain retry
    // Ideally we stop only if no retries pending, but for now stopping here is okay 
    // as retryFailed will restart it if called.
    // However, analyzeAll calls retryFailed at the end (in loadScreenshots chain).
    // Let's NOT stop here if we assume retryFailed might follow.
    // Actually, analyzeAll is called mainly from loadScreenshots...
    // Let's just stop it, retryFailed will ensure it's started if needed.
    await BackgroundServiceManager.stopService();
  }

  Future<void> _saveAnalysisCache() async {
    final prefs = await SharedPreferences.getInstance();
    final plainJson = json.encode(_analysisCache);
    final encrypted = EncryptionService.encryptData(plainJson);
    await prefs.setString('analysis_cache', encrypted);
  }

  bool _isRetrying = false;
  bool get isRetrying => _isRetrying;

  int _retryCurrent = 0;
  int get retryCurrent => _retryCurrent;

  int _retryTotalCount = 0;
  int get retryTotalCount => _retryTotalCount;

  Future<void> retryFailed() async {
    if (_isRetrying) return;
    _isRetrying = true;

    final failed = _screenshots.where((s) => s.category == 'Error').toList();
    _retryTotalCount = failed.length;
    _retryCurrent = 0;
    notifyListeners();

    if (failed.isNotEmpty && kDebugMode) {
      print("Retrying ${failed.length} failed items...");
    }

    if (failed.isNotEmpty) {
      await BackgroundServiceManager.startService();
      BackgroundServiceManager.updateNotificationContent(
        "Retrying 1/${failed.length} failed images...",
      );
    }

    for (var i = 0; i < failed.length; i++) {
      if (_apiKey.isEmpty) break;

      _retryCurrent = i + 1;
      notifyListeners();

      BackgroundServiceManager.updateNotificationContent(
        "Retrying ${i + 1}/${failed.length} failed images...",
        progress: i + 1,
        max: failed.length,
      );

      final s = failed[i];
      if (kDebugMode) print("Retrying ${s.id} (${i + 1}/${failed.length})...");

      await analyzeScreenshot(s);

      if (i < failed.length - 1) {
        await Future.delayed(const Duration(seconds: 30));
      }
    }
    _isRetrying = false;
    await BackgroundServiceManager.stopService();
    notifyListeners();
  }

  Future<void> updateScreenshotNote(String id, String note) async {
    final index = _screenshots.indexWhere((s) => s.id == id);
    if (index != -1) {
      final s = _screenshots[index];
      _screenshots[index] = s.copyWith(note: note);

      // Update cache
      if (_analysisCache.containsKey(id)) {
        _analysisCache[id] = {..._analysisCache[id], 'note': note};
      } else {
        // If not analyzed yet, create a partial cache entry or just wait?
        // Better to check if it exists or just force it.
        // If it's not analyzed, maybe we shouldn't cache the full object yet,
        // but 'note' should be meaningful.
        // For now, let's assume we only cache analyzed items OR we start caching pending items too?
        // Simpler: Just update the cache map if it exists, or create it.
        _analysisCache[id] = {
          'description': s.description,
          'category': s.category,
          'tags': s.tags,
          'note': note,
        };
      }
      await _saveAnalysisCache();
      notifyListeners();
    }
  }
}

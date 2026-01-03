import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:pixelshot_flutter/models/screenshot.dart';

import 'package:permission_handler/permission_handler.dart';

class GalleryService {
  Future<bool> requestPermission() async {
    // Request notification permission for background service (Android 13+)
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth;
  }

  Future<List<AssetPathEntity>> getAlbums() async {
    return await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
  }

  Future<List<Screenshot>> getScreenshots({
    int page = 0,
    int perPage = 3000,
    AssetPathEntity? specificAlbum,
  }) async {
    AssetPathEntity? targetPath = specificAlbum;

    if (targetPath == null) {
      print("Fetching albums for auto-detect...");
      final paths = await getAlbums();

      if (paths.isEmpty) {
        print("No albums found.");
        return [];
      }

      // debug print albums
      for (var p in paths) {
        final count = await p.assetCountAsync;
        print("Album found: ${p.name} ($count items)");
      }

      // 1. Try to find a dedicated Screenshot album
      try {
        // Sort paths to prioritize explicit "Screenshots" name
        paths.sort((a, b) {
          final aName = a.name.toLowerCase();
          final bName = b.name.toLowerCase();
          
          final aExact = aName == "screenshots" || aName == "screenshot";
          final bExact = bName == "screenshots" || bName == "screenshot";
          if (aExact && !bExact) return -1;
          if (!aExact && bExact) return 1;

          final aContains = aName.contains("screenshot");
          final bContains = bName.contains("screenshot");
          if (aContains && !bContains) return -1;
          if (!aContains && bContains) return 1;
          
          return 0;
        });

        targetPath = paths.firstWhere((p) {
          final name = p.name.toLowerCase();
          return name.contains("screenshot") ||
              name.contains("captur") ||
              name.contains("snip") ||
              name == "screen";
        });
        print("Using explicit Screenshot album: ${targetPath.name}");
      } catch (_) {
        // 2. Fallback to "Recent" (usually index 0)
        if (paths.isNotEmpty) {
          targetPath = paths[0];
          print(
            "Explicit Screenshot album not found. Using '${targetPath.name}' and filtering.",
          );
        }
      }
    } else {
      print("Using selected album: ${targetPath.name}");
    }

    if (targetPath == null) return [];

    // Get assets
    final List<AssetEntity> assets = await targetPath.getAssetListPaged(
      page: page,
      size: perPage,
    );

    print(
      "Fetching files for ${assets.length} assets from ${targetPath.name}...",
    );

    final List<Screenshot> screenshots = [];
    final lowerName = targetPath.name.toLowerCase();
    final isExplicitScreenshotAlbum =
        lowerName.contains("screenshot") ||
        lowerName.contains("captur") ||
        lowerName.contains("snip");

    // Process in batches
    const batchSize = 20;
    for (var i = 0; i < assets.length; i += batchSize) {
      final end = (i + batchSize < assets.length)
          ? i + batchSize
          : assets.length;
      final batch = assets.sublist(i, end);

      final results = await Future.wait(
        batch.map((asset) async {
          // 1. Filter non-images and Live Photos
          if (asset.type != AssetType.image) return null;
          if (asset.isLivePhoto) return null;

          // 2. Fast Filter using Relative Path & Title (No IO)
          // We want to skip OBVIOUS non-screenshots to save time, 
          // but we must be careful not to skip real screenshots that are just in weird folders (like DCIM/Screenshot).
          if (!isExplicitScreenshotAlbum) {
            final relPath = asset.relativePath?.toLowerCase();
            final title = asset.title?.toLowerCase() ?? '';

            if (relPath != null && relPath.isNotEmpty) {
              final isScreenshotFolder =
                  relPath.contains('screenshot') ||
                  relPath.contains('captur') ||
                  relPath.contains('snip');
              
              // Broaden search: Check DCIM/Pictures but exclude Camera to avoid massive scan
              // Many screenshots are in DCIM/Screenshots
              final isPotentialFolder = 
                  relPath.contains('dcim') || 
                  relPath.contains('pictures') ||
                  relPath.contains('images');
                  
              final isCamera = relPath.contains('camera') || relPath.contains('100andro');

              final looksLikeScreenshot =
                  isScreenshotFolder ||
                  (isPotentialFolder && !isCamera) ||
                  title.contains('screenshot') ||
                  title.contains('captur') ||
                  title.contains('screen');

              if (!looksLikeScreenshot) {
                return null; // Skip it
              }
            }
          }

          final File? file = await asset.file;
          if (file == null) return null;

          // 3. Strict File Extension Check
          final ext = file.path.split('.').last.toLowerCase();
          if (!['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext)) {
            return null;
          }

          bool isScreenshot = isExplicitScreenshotAlbum;
          if (!isScreenshot) {
            final path = file.path.toLowerCase();
            isScreenshot =
                path.contains("screenshot") ||
                path.contains("captur") ||
                path.contains("screen");
          }

          if (isScreenshot) {
            return Screenshot(
              id: asset.id,
              file: file,
              timestamp: asset.createDateTime,
              category: 'Pending',
              analyzed: false,
              tags: [], // Initialize empty
            );
          }
          return null;
        }),
      );

      for (var s in results) {
        if (s != null) screenshots.add(s);
      }
    }

    print("Found ${screenshots.length} screenshots.");
    return screenshots;
  }

  Future<List<Screenshot>> getImagesFromDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];

    final List<Screenshot> screenshots = [];

    // List files
    try {
      final files = dir.listSync().whereType<File>().where((file) {
        final ext = file.path.split('.').last.toLowerCase();
        return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
      }).toList();

      for (var file in files) {
        final stat = await file.stat();
        screenshots.add(
          Screenshot(
            id: file.path, // Use path as ID for local files
            file: file,
            timestamp: stat.modified,
            category: 'Pending',
            analyzed: false,
            tags: [],
          ),
        );
      }

      // Sort by date desc
      screenshots.sort((a, b) {
        final tA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });
    } catch (e) {
      print("Error scanning directory $path: $e");
    }

    return screenshots;
  }
}

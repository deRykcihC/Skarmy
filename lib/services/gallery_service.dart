import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:pixelshot_flutter/models/screenshot.dart';
import 'package:uuid/uuid.dart';

class GalleryService {
  Future<bool> requestPermission() async {
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

      // 1. Try "Screenshots" specifically
      try {
        targetPath = paths.firstWhere(
          (p) => p.name.toLowerCase().contains("screenshot"),
        );
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
    // Use a larger page size or just fetch a large chunk
    final List<AssetEntity> assets = await targetPath.getAssetListPaged(
      page: page,
      size: perPage,
    );

    print(
      "Fetching files for ${assets.length} assets from ${targetPath.name}...",
    );

    final List<Screenshot> screenshots = [];
    final isExplicitScreenshotAlbum = targetPath.name.toLowerCase().contains(
      "screenshot",
    );

    // Process in batches to avoid choking the UI thread or IO
    // But faster than sequential
    const batchSize = 20;
    for (var i = 0; i < assets.length; i += batchSize) {
      final end = (i + batchSize < assets.length)
          ? i + batchSize
          : assets.length;
      final batch = assets.sublist(i, end);

      final results = await Future.wait(
        batch.map((asset) async {
          // Optimization: If we are scanning "Recent", check title first before file IO
          if (!isExplicitScreenshotAlbum) {
            final title = asset.title?.toLowerCase() ?? '';
            if (!title.contains("screenshot")) {
              // If title doesn't look like a screenshot, calculate file path ONLY if necessary
              // But usually title is reliable for "Screenshot_..." files.
              // If you want to be super safe, you can't skip this, but it's slow.
              // Let's assume title check is good first filter.
              // If title matches, we load file.
              // If title doesn't match, we MIGHT skip, but let's be safe and check path if title fails?
              // Checking path requires `await asset.file` which is the bottleneck.
              // Let's rely on string check of title effectively filtering most non-screenshots.
            }
          }

          final File? file = await asset.file;
          if (file == null) return null;

          bool isScreenshot = isExplicitScreenshotAlbum;
          if (!isScreenshot) {
            final path = file.path.toLowerCase();
            final title = asset.title?.toLowerCase() ?? '';
            isScreenshot =
                title.contains("screenshot") ||
                path.contains("screenshot") ||
                path.contains("capture");
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

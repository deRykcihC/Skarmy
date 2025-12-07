import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pixelshot_flutter/models/screenshot.dart';

class ScreenshotCard extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onTap;

  const ScreenshotCard({
    super.key,
    required this.screenshot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with natural aspect ratio
            Stack(
              children: [
                Image.file(
                  screenshot.file,
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                  cacheWidth: 600, // Optimize memory usage
                  gaplessPlayback: true,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    screenshot.description ?? 'Pending Analysis...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (screenshot.tags.isNotEmpty)
                    Text(
                      screenshot.tags.take(3).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

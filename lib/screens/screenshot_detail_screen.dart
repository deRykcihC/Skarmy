import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelshot_flutter/models/screenshot.dart';
import 'package:pixelshot_flutter/providers/app_state.dart';

class ScreenshotDetailScreen extends StatefulWidget {
  final Screenshot screenshot;

  const ScreenshotDetailScreen({super.key, required this.screenshot});

  @override
  State<ScreenshotDetailScreen> createState() => _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState extends State<ScreenshotDetailScreen> {
  bool _isReanalyzing = false;
  late TextEditingController _noteController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.screenshot.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNoteChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      context.read<AppState>().updateScreenshotNote(widget.screenshot.id, text);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for updates to this specific screenshot
    final appState = context.watch<AppState>();
    final liveScreenshot = appState.screenshots.firstWhere(
      (s) => s.id == widget.screenshot.id,
      orElse: () => widget.screenshot,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          if (_isReanalyzing)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Reanalyzing...",
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            GestureDetector(
              onDoubleTap: () async {
                setState(() {
                  _isReanalyzing = true;
                });

                await context.read<AppState>().analyzeScreenshot(
                  liveScreenshot,
                );

                if (mounted) {
                  setState(() {
                    _isReanalyzing = false;
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: liveScreenshot.category == 'Error'
                      ? Colors.red.shade50
                      : (liveScreenshot.analyzed
                            ? Colors.green.shade50
                            : Colors.orange.shade50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    if (liveScreenshot.category == 'Error')
                      Icon(Icons.error, size: 14, color: Colors.red.shade700)
                    else if (liveScreenshot.analyzed)
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green.shade700,
                      )
                    else
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      liveScreenshot.category == 'Error'
                          ? "Failed"
                          : (liveScreenshot.analyzed ? "Done" : "Pending"),
                      style: TextStyle(
                        color: liveScreenshot.category == 'Error'
                            ? Colors.red.shade900
                            : (liveScreenshot.analyzed
                                  ? Colors.green.shade700
                                  : Colors.orange.shade900),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              width: double.infinity,
              color: Colors.black,
              constraints: const BoxConstraints(maxHeight: 500),
              child: Image.file(liveScreenshot.file, fit: BoxFit.contain),
            ),

            // Info Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Description
                  Text(
                    liveScreenshot.description ?? "No description available.",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Tags
                  Row(
                    children: [
                      Icon(Icons.label, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        "TAGS",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (liveScreenshot.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: liveScreenshot.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "#$tag",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    const Text(
                      "No tags available",
                      style: TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 24),

                  // 4. Note
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "NOTE",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    onChanged: _onNoteChanged,
                    maxLines: null,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0D1B2A),
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: "Add a note...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

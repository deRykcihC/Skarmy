import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelshot_flutter/providers/app_state.dart';
import 'package:pixelshot_flutter/widgets/screenshot_card.dart';
import 'package:pixelshot_flutter/screens/profile_screen.dart';
import 'package:pixelshot_flutter/screens/screenshot_detail_screen.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _selectedTag;
  String _searchHint = 'Search...';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _logoPath = 'assets/icon/app_icon.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadScreenshots();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // 1/100 Chance Easter Egg
    if (Random().nextInt(100) == 0) {
      const easterEggs = ["cream pound", "telegram seen", "i love skarm"];
      _searchHint = easterEggs[Random().nextInt(easterEggs.length)];
    }

    if (Random().nextInt(100) == 0) {
      _logoPath = 'assets/icon/app_icon_rare.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 1) {
      return const ProfileScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(_logoPath, width: 32, height: 32),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Skarmy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D1B2A), // Dark blue/black
                    ),
                  ),
                  const Spacer(),
                  Consumer<AppState>(
                    builder: (context, state, child) {
                      if (state.isLoading) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Loading...",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }

                      final failedCount = state.screenshots
                          .where((s) => s.category == 'Error')
                          .length;
                      final pendingReal = state.pendingCount - failedCount;

                      if (state.isRetrying) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Retrying ${state.retryCurrent}/${state.retryTotalCount}",
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Show Failed Badge if not retrying
                      if (failedCount > 0) {
                        return GestureDetector(
                          onTap: () => state.retryFailed(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: 14,
                                  color: Colors.red.shade900,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "$failedCount Failed (Tap to Retry)",
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (pendingReal == 0 && state.screenshots.isNotEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Done",
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (pendingReal == 0) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$pendingReal left",
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _searchHint,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            // Listener will update state
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Filter
            // Dynamic Tags Filter
            Consumer<AppState>(
              builder: (context, state, child) {
                final tags = state.uniqueTags;
                if (tags.isEmpty) return const SizedBox.shrink();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: tags.map((tag) {
                      final isSelected = _selectedTag == tag;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTag = null; // Toggle off
                            } else {
                              _selectedTag = tag;
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0D1B2A)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "#$tag", // visual style
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            // Content
            Expanded(
              child: Consumer<AppState>(
                builder: (context, state, child) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.screenshots.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.filter_alt_outlined,
                              size: 48,
                              color: Colors.blueGrey.shade200,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No Screenshots Yet",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              "Select the folder where your screenshots are stored.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter matching screenshots
                  final filteredScreenshots = state.screenshots.where((s) {
                    // 1. Tag Filter
                    if (_selectedTag != null &&
                        !s.tags.contains(_selectedTag)) {
                      return false;
                    }

                    // 2. Search Query Filter
                    if (_searchQuery.isNotEmpty) {
                      final descMatch =
                          s.description?.toLowerCase().contains(_searchQuery) ??
                          false;
                      final tagMatch = s.tags.any(
                        (t) => t.toLowerCase().contains(_searchQuery),
                      );
                      if (!descMatch && !tagMatch) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: MasonryGridView.count(
                      padding: const EdgeInsets.only(bottom: 100),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemCount: filteredScreenshots.length,
                      itemBuilder: (context, index) {
                        final screenshot = filteredScreenshots[index];
                        return ScreenshotCard(
                          screenshot: screenshot,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScreenshotDetailScreen(
                                  screenshot: screenshot,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        height: 60,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade100,
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF0D1B2A)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF0D1B2A)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

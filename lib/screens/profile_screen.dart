import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelshot_flutter/screens/home_screen.dart';

import '../providers/app_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = context.read<AppState>().apiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 32,
                      height: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Daily Quota (Est.)",
                      "${state.dailyRequestCount}",
                      Colors.blue,
                      isQuota: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "Total images",
                      state.screenshots.length.toString(),
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "APP SETTINGS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Source Folder Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.folder_open,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Source Folder",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Where to look for screenshots",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selection UI
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.selectedFolderPath ??
                                (state.selectedAlbum != null
                                    ? "Album: ${state.selectedAlbum!.name}"
                                    : "Auto-detect (Screenshots/Recent)"),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    String? selectedDirectory = await FilePicker
                                        .platform
                                        .getDirectoryPath();
                                    if (selectedDirectory != null) {
                                      state.selectFolder(selectedDirectory);
                                    }
                                  },
                                  icon: const Icon(Icons.folder, size: 16),
                                  label: const Text("Pick Folder"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.blue,
                                    elevation: 0,
                                    side: BorderSide(
                                      color: Colors.blue.shade200,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                              ),
                              if (state.selectedFolderPath != null ||
                                  state.selectedAlbum != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    state.selectFolder(null); // Reset to auto
                                  },
                                  icon: const Icon(Icons.restart_alt),
                                  tooltip: "Reset to Auto",
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                    foregroundColor: Colors.grey.shade700,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Model Selection Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.psychology,
                            color: Colors.purple.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI Models",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Choose primary & fallback",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Primary Model
                    _buildModelDropdown(
                      label: "Primary Model",
                      value: state.primaryModel,
                      items: [
                        'gemini-2.5-flash-lite',
                        'gemini-2.5-flash',
                        'gemini-2.0-flash',
                        'gemini-2.0-flash-lite',
                        'gemma-3-27b-it',
                        'gemma-3-12b-it',
                        'gemma-3-4b-it',
                        'gemma-3-2b-it',
                        'gemma-3-1b-it',
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          state.setModels(val, state.fallbackModel);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Fallback Model
                    _buildModelDropdown(
                      label: "Fallback Model",
                      value: state.fallbackModel,
                      items: [
                        'gemini-2.5-flash-lite',
                        'gemini-2.5-flash',
                        'gemini-2.0-flash',
                        'gemini-2.0-flash-lite',
                        'gemma-3-27b-it',
                        'gemma-3-12b-it',
                        'gemma-3-4b-it',
                        'gemma-3-2b-it',
                        'gemma-3-1b-it',
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          state.setModels(state.primaryModel, val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // API Key
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: state.apiKey.isNotEmpty
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.key,
                            color: state.apiKey.isNotEmpty
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Gemini API Key",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Required for analysis",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Paste your API Key here",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) => state.setApiKey(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Buy Me a Coffee
              GestureDetector(
                onTap: () {
                  _launchURL('https://buymeacoffee.com/derykcihc');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDD00), // BMC Yellow
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.coffee_rounded,
                        color: Colors.black87,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Buy me a coffee",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily:
                              "Cookie", // Fallback to normal if not available
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "If you appreciate the idea and want to help keep the app available on the Play Store, you can donate via Buy Me a Coffee. Otherwise, it's always free on GitHub!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            "Have bugs, feedback, or suggestions?\nLeave it in the ",
                      ),
                      TextSpan(
                        text: "GitHub repository!",
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launchURL('https://github.com/deRykcihC/Skarmy');
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const HomeScreen(),
                transitionDuration: Duration.zero,
              ),
            );
          }
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade100,
        surfaceTintColor: Colors.transparent,
        height: 60,
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

  Widget _buildStatCard(
    String label,
    String value,
    Color color, {
    bool isQuota = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isQuota ? Icons.pie_chart : Icons.bar_chart,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildModelDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey.shade900,
                fontWeight: FontWeight.w500,
              ),
              borderRadius: BorderRadius.circular(12),
              items: items.map((String item) {
                final is20Model = item.contains('gemini-2.0');
                return DropdownMenuItem<String>(
                  value: item,
                  child: is20Model
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.orange.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    "BILLED ONLY",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Cheapest",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }
}

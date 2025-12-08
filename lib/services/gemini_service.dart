import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pixelshot_flutter/models/screenshot.dart';

class GeminiService {
  Future<Screenshot> analyzeScreenshot(
    File file,
    String apiKey, {
    String primaryModel = 'gemini-2.5-flash-lite',
    String fallbackModel = 'gemini-2.5-flash',
  }) async {
    // Helper to perform analysis with a specific model
    Future<Screenshot> attemptAnalysis(String modelName) async {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final prompt = TextPart(
        "Analyze this screenshot. Return a JSON object with: 'description' (short summary), 'tags' (list of strings).",
      );
      final imageParts = [DataPart('image/jpeg', await file.readAsBytes())];

      final response = await model.generateContent([
        Content.multi([prompt, ...imageParts]),
      ]);

      final text = response.text;
      if (text == null) throw Exception("No response from Gemini");

      String jsonStr = text;
      final startIndex = jsonStr.indexOf('{');
      final endIndex = jsonStr.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1) {
        jsonStr = jsonStr.substring(startIndex, endIndex + 1);
      } else {
        jsonStr = text.replaceAll('```json', '').replaceAll('```', '').trim();
      }

      Map<String, dynamic> jsonMap = {};
      try {
        jsonMap = jsonDecode(jsonStr);
      } catch (e) {
        print("JSON Parse Error: $e");
      }

      return Screenshot(
        id: '', // Will be set by caller or kept from input
        file: file,
        description: jsonMap['description'] ?? 'No description',
        tags: List<String>.from(jsonMap['tags'] ?? []),
        analyzed: true,
      );
    }

    try {
      // 1. Try Primary
      try {
        return await attemptAnalysis(primaryModel);
      } catch (e) {
        print(
          'Primary Model ($primaryModel) failed: $e. Retrying with Fallback ($fallbackModel)...',
        );
        // 2. Try Fallback
        return await attemptAnalysis(fallbackModel);
      }
    } catch (e) {
      print('Gemini Analysis Error (All Models Failed): $e');
      return Screenshot(
        id: '',
        file: file,
        description: 'Analysis Failed',
        analyzed: false,
      );
    }
  }
}

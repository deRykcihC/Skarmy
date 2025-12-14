import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  // Using a fixed 32-character key for AES-256
  // Note: In a production app with sensitive user user data, consider using flutter_secure_storage
  // to generate and store a random key, or derive it from a user password.
  static final _key = encrypt.Key.fromUtf8('SkarmyPixelShotSecureKey32Bytes!');

  static String encryptData(String plainText) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Store IV with the data (iv:ciphertext)
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptData(String encryptedText) {
    try {
      // Check if it follows our format
      if (!encryptedText.contains(':')) {
        // Assume legacy plain text if logic permits, or just fail
        // But since we want to migrate, we can try to return as is if it looks like JSON
        if (encryptedText.trim().startsWith('{')) return encryptedText;
        throw Exception("Invalid format");
      }

      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        if (encryptedText.trim().startsWith('{')) return encryptedText;
        throw Exception("Invalid format");
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      // Fallback: if decryption fails, return original text.
      // This handles the migration case where data is currently plain JSON.
      return encryptedText;
    }
  }
}

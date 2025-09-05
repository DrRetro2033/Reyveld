import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:reyveld/extensions.dart';
import 'package:reyveld/skit/skit.dart';
import 'package:reyveld/skit/sobjects/author/author.dart';
import 'package:reyveld/user.dart';
import 'package:pointycastle/export.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:version/version.dart';
import 'package:talker/talker.dart';
import 'package:reyveld/version.dart' as versi;

part "reyveld.interface.dart";

/// Contains global functions for Reyveld, for example, settings, paths, etc.
class Reyveld {
  static Version get version => versi.currentVersion;
  static late String _currentPath;
  static String get currentPath => _currentPath;
  static set currentPath(String path) => _currentPath = path.resolvePath();
  static String get libraryPath => "$appDataPath/libraries";
  static late bool isInternal;
  static bool get isDev =>
      const bool.fromEnvironment('DEBUG', defaultValue: true);
  static bool verbose = false;

  static Talker? _logger;

  static SKit? _cachedAuthorsKit;

  static Future<SKit> get _trustedAuthorsKit async {
    _cachedAuthorsKit ??= SKit("$appDataPath/trusted_authors.skit");
    return _cachedAuthorsKit!;
  }

  static RSAPrivateKey? _cachedPrivateKey;
  static RSAPublicKey? _cachedPublicKey;

  static File get signatureFile => File("$appDataPath/me.keys");

  static Future<RSAPrivateKey> get privateKey async {
    if (_cachedPrivateKey == null) {
      if (!await signatureFile.exists()) {
        throw Exception(
            "Signature file not found! Please rerun Reyveld to generate it.");
      }
      final pem =
          (await signatureFile.readAsString()).split(String.fromCharCode(0))[0];
      _cachedPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(pem);
    }
    return _cachedPrivateKey!;
  }

  static Future<RSAPublicKey> get publicKey async {
    if (_cachedPublicKey == null) {
      if (!await signatureFile.exists()) {
        throw Exception(
            "Signature file not found! Please rerun Reyveld to generate it.");
      }
      final pem =
          (await signatureFile.readAsString()).split(String.fromCharCode(0))[1];
      _cachedPublicKey = CryptoUtils.rsaPublicKeyFromPem(pem);
    }
    return _cachedPublicKey!;
  }

  static Future<Author?> get author async => await Author.initialize();

  /// The logger for Reyveld.
  /// If the logger is not initialized, it will be initialized.
  static Talker get talker {
    _logger ??= Talker(
      logger: TalkerLogger(
          formatter: ReyveldLogFormatter(),
          output: ReyveldLogger(
                  "$appDataPath/logs/$version/reyveld-$version-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.log")
              .output,
          filter: ReyveldLogFilter()),
    );
    return _logger!;
  }

  static File get mostRecentLog => File(
      "$appDataPath/logs/$version/reyveld-$version-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.log");

  /// The path to the application data directory.
  static String get appDataPath {
    if (!Platform.environment.containsKey("APPDATA")) {
      return Directory.current.path;
    } else {
      return "${Platform.environment["APPDATA"]!.resolvePath()}/reyveld";
    }
  }

  /// Prints the message to console, only if Reyveld is a developer build.
  static void printToConsole(Object message) {
    print(message);
    // if (isDev) {
    //   print(message);
    // }
  }

  /// Verifies that the user has a signature.
  static Future<void> verifySignature() async {
    if (!await signatureFile.exists()) {
      final keys = await generateRSAKeys();
      await saveMe(keys);
      print(
          """me.keys was not found, so new keys were generated. This is normal on the first run.
Never share your keys file with anyone, as it contains your secret private key. Your private key is used to sign your kits to verify that it was created by you.
If you share your private key, anyone can create kits that appear to be created by you, which could lead to them injecting malicious code into your kits.

In the unlikely event that your private key is compromised, you can generate a new one by deleting the me.keys file and running Reyveld again.
""");
    }
  }

  /// Generates a new RSA key pair.
  /// [bitLength] defaults to 2048.
  static Future<SKitKeyPair> generateRSAKeys({int bitLength = 2048}) async {
    final keyParams =
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64);
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final generator = RSAKeyGenerator()
      ..init(ParametersWithRandom(keyParams, secureRandom));
    final pair = generator.generateKeyPair();
    return (
      private: pair.privateKey as RSAPrivateKey,
      public: pair.publicKey as RSAPublicKey
    );
  }

  /// Saves the private and public keys to the me.keys file.
  static Future<void> saveMe(SKitKeyPair keys) async {
    if (!signatureFile.existsSync()) {
      await signatureFile.create(recursive: true);
    }
    final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(keys.private!);
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(keys.public);
    await signatureFile.writeAsString("""$privateKeyPem
${String.fromCharCode(0)}
$publicKeyPem""");
  }

  static Future<bool> isTrustedAuthor(SAuthor author) async {
    /// If the author's public key is the same as the user's public key, then it is always trusted.
    if (author.publicKey == await publicKey) return true;

    /// Check if the trusted authors kit contains the author, which means trusted.

    if (!await (await _trustedAuthorsKit).exists()) {
      return false; // No trusted authors kit, so not trusted.
    }
    final kit = await _trustedAuthorsKit;
    final trustedAuthor = await kit.getRoot<SAuthor>(filterRoots: (t) {
      return t == author;
    });

    return trustedAuthor != null;
  }

  static Future<void> trustAuthor(SAuthor author) async {
    if (await isTrustedAuthor(author)) {
      Reyveld.talker.warning("Author was already trusted.");
      return;
    }
    final kit = await _trustedAuthorsKit;
    await kit.addRoot(author.copy());
    await kit.save();
  }
}

/// The log file is created in the application data directory.
/// Each message is appended to the file.
/// A new log file is created each day, and will log all of the messages for that day.
/// The reason for this behavior is so that if the log needs to be sent for debugging,
/// all the pertinent information is in one file and not spread across multiple logs.
class ReyveldLogger {
  final File logFile;

  ReyveldLogger(String path) : logFile = File(path) {
    if (!logFile.existsSync()) {
      logFile.createSync(recursive: true);
      logFile.writeAsStringSync("""
[Device Info]
  OS                    ${Platform.operatingSystemVersion}
  Number of Processors  ${Platform.numberOfProcessors}
  Locale                ${Platform.localeName}
  
[App Info]
  Version               ${Reyveld.version.toString()}

[Log]
  Date                  ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}
───────────────────────────────────────────────────────────────
""");
    }
    logFile.writeAsStringSync("""

Run at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")}:${DateTime.now().second.toString().padLeft(2, "0")}.${DateTime.now().millisecond.toString().padLeft(3, "0")}
Version ${Reyveld.version.toString()}
───────────────────────────────────────────────────────────────
""", mode: FileMode.append);
  }

  void output(String message) {
    logFile.writeAsStringSync("$message\n", mode: FileMode.append);
  }
}

class ReyveldLogFormatter extends LoggerFormatter {
  @override
  String fmt(LogDetails details, TalkerLoggerSettings settings) {
    return "${details.message}";
  }
}

class ReyveldLogFilter extends LoggerFilter {
  @override
  bool shouldLog(msg, LogLevel level) {
    if (!Reyveld.verbose && level == LogLevel.verbose) {
      return false;
    }
    return true;
  }
}

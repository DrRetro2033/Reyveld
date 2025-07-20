import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:arceus/extensions.dart';
import 'package:arceus/skit/skit.dart';
import 'package:arceus/skit/sobjects/author/author.dart';
import 'package:arceus/user.dart';
import 'package:pointycastle/export.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:version/version.dart';
import 'package:talker/talker.dart';
import 'package:arceus/version.dart' as version;

part "arceus.interface.dart";

/// Contains global functions for Arceus, for example, settings, paths, etc.
class Arceus {
  static Version get currentVersion => version.currentVersion;
  static late String _currentPath;
  static String get currentPath => _currentPath;
  static set currentPath(String path) => _currentPath = path.resolvePath();
  static String get libraryPath => "$appDataPath/libraries";
  static late bool isInternal;
  static bool get isDev =>
      const bool.fromEnvironment('DEBUG', defaultValue: true);

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
            "Signature file not found! Please rerun Arceus to generate it.");
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
            "Signature file not found! Please rerun Arceus to generate it.");
      }
      final pem =
          (await signatureFile.readAsString()).split(String.fromCharCode(0))[1];
      _cachedPublicKey = CryptoUtils.rsaPublicKeyFromPem(pem);
    }
    return _cachedPublicKey!;
  }

  static Future<Author?> get author async => await Author.initialize();

  /// The logger for Arceus.
  /// If the logger is not initialized, it will be initialized.
  static Talker get talker {
    _logger ??= Talker(
      logger: TalkerLogger(
          formatter: ArceusLogFormatter(),
          output: ArceusLogger(
                  "$appDataPath/logs/$currentVersion/arceus-$currentVersion-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.log")
              .output,
          filter: ArceusLogFilter()),
    );
    return _logger!;
  }

  static File get mostRecentLog => File(
      "$appDataPath/logs/$currentVersion/arceus-$currentVersion-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.log");

  /// The path to the application data directory.
  static String get appDataPath {
    if (!Platform.environment.containsKey("APPDATA")) {
      return Directory.current.path;
    } else {
      return "${Platform.environment["APPDATA"]!.resolvePath()}/arceus";
    }
  }

  /// Prints the message to console, only if Arceus is a developer build.
  static void printToConsole(Object message) {
    print(message);
    // if (isDev) {
    //   print(message);
    // }
  }

  /// Verifies that the user has a signature.
  static Future<void> verifySignature() async {
    if (!await signatureFile.exists()) {
      await generateRSAKeys();
      print(
          """me.keys was not found, so new keys were generated. This is normal on the first run.
Never share your keys file with anyone, as it contains your secret private key. Your private key is used to sign your kits to verify that it was created by you.
If you share your private key, anyone can create kits that appear to be created by you, which could lead to them injecting malicious code into your kits.

In the unlikely event that your private key is compromised, you can generate a new one by deleting the me.keys file and running Arceus again.
""");
    }
  }

  /// Generates a new RSA key pair and saves it to me.signature file.
  /// [bitLength] defaults to 2048.
  static Future<void> generateRSAKeys({int bitLength = 2048}) async {
    final keyParams =
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64);
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final generator = RSAKeyGenerator()
      ..init(ParametersWithRandom(keyParams, secureRandom));
    final pair = generator.generateKeyPair();

    pair.publicKey as RSAPublicKey;
    pair.privateKey as RSAPrivateKey;
    await saveMe(
        privateKey: pair.privateKey as RSAPrivateKey,
        publicKey: pair.publicKey as RSAPublicKey);
  }

  /// WAKE ME UP, WAKE ME UP INSIDE, CAN'T WAKE UP, SAVE ME!!!
  /// Saves the private and public keys to the me.signature file.
  static Future<void> saveMe(
      {required RSAPrivateKey privateKey,
      required RSAPublicKey publicKey}) async {
    if (!signatureFile.existsSync()) {
      await signatureFile.create(recursive: true);
    }
    final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(publicKey);
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
      Arceus.talker.warning("Author was already trusted.");
      return;
    }
    final kit = await _trustedAuthorsKit;
    await kit.addRoot(author.copy());
    await kit.save();
  }
}

/// # `class` ArceusLogger
/// ## A class that logs messages to a file.
/// The log file is created in the application data directory.
/// Each message is appended to the file.
/// A new log file is created each day, and will log all of the messages for that day.
/// The reason for this behavior is so that if the log needs to be sent for debugging,
/// all the pertinent information is in one file and not spread across multiple logs.
class ArceusLogger {
  final File logFile;

  ArceusLogger(String path) : logFile = File(path) {
    if (!logFile.existsSync()) {
      logFile.createSync(recursive: true);
      logFile.writeAsStringSync("""
[Device Info]
  OS                    ${Platform.operatingSystemVersion}
  Number of Processors  ${Platform.numberOfProcessors}
  Locale                ${Platform.localeName}
  
[App Info]
  Version               ${Arceus.currentVersion.toString()}

[Log]
  Date                  ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}
───────────────────────────────────────────────────────────────
""");
    }
    logFile.writeAsStringSync("""

Run at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")}:${DateTime.now().second.toString().padLeft(2, "0")}.${DateTime.now().millisecond.toString().padLeft(3, "0")}
Version ${Arceus.currentVersion.toString()}
───────────────────────────────────────────────────────────────
""", mode: FileMode.append);
  }

  void output(String message) {
    logFile.writeAsStringSync("$message\n", mode: FileMode.append);
  }
}

class ArceusLogFormatter extends LoggerFormatter {
  @override
  String fmt(LogDetails details, TalkerLoggerSettings settings) {
    return "${details.message}";
  }
}

class ArceusLogFilter extends LoggerFilter {
  @override
  bool shouldLog(msg, LogLevel level) {
    if (level == LogLevel.debug && !Arceus.isDev) {
      return false;
    }
    return true;
  }
}

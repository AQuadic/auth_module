import 'dart:io';

const _activityName =
    'com.aboutyou.dart_packages.sign_in_with_apple.SignInWithAppleCallback';
const _appleSignInEntitlementKey = 'com.apple.developer.applesignin';
const _codeSignEntitlementsSetting =
    'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;';

enum _EntitlementUpsertResult { updated, alreadyPresent, failed }

const _callbackActivity = '''        <activity
                android:name="com.aboutyou.dart_packages.sign_in_with_apple.SignInWithAppleCallback"
                android:exported="true"
        >
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>

                <data android:scheme="signinwithapple"/>
                <data android:path="callback"/>
            </intent-filter>
        </activity>
''';

const _appleSignInEntitlementBlock =
    '''	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
''';

const _newEntitlementsFile = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
</dict>
</plist>
''';

void main(List<String> args) {
  final androidInputPath =
      _readOption(args, '--android-path') ??
      '/android/app/src/main/AndroidManifest.xml';
  final iosInputPath =
      _readOption(args, '--ios-path') ?? '/ios/Runner/Runner.entitlements';

  final androidOk = _configureAndroidManifest(androidInputPath);
  final iosOk = _configureIosEntitlements(iosInputPath);

  if (!androidOk || !iosOk) {
    exitCode = 1;
  }
}

bool _configureAndroidManifest(String inputPath) {
  final manifestPath = _resolveProjectPath(
    inputPath,
    platformFolder: 'android',
  );
  final manifestFile = File(manifestPath);

  if (!manifestFile.existsSync()) {
    stderr.writeln('AndroidManifest.xml not found at: $inputPath');
    stderr.writeln('Resolved path: $manifestPath');
    return false;
  }

  final raw = manifestFile.readAsStringSync();
  if (raw.contains(_activityName)) {
    stdout.writeln(
      'Apple Sign-In callback activity already exists in Android manifest. No changes made.',
    );
    return true;
  }

  const closeTag = '</application>';
  final index = raw.lastIndexOf(closeTag);
  if (index < 0) {
    stderr.writeln('Invalid AndroidManifest.xml: missing </application> tag.');
    return false;
  }

  var before = raw.substring(0, index);
  final after = raw.substring(index);
  if (!before.endsWith('\n')) {
    before = '$before\n';
  }

  final updated = '$before$_callbackActivity\n$after';
  manifestFile.writeAsStringSync(updated);

  stdout.writeln('Added Apple Sign-In callback activity to: $manifestPath');
  return true;
}

bool _configureIosEntitlements(String inputPath) {
  final entitlementsPath = _resolveProjectPath(
    inputPath,
    platformFolder: 'ios',
  );
  final entitlementsFile = File(entitlementsPath);

  if (!entitlementsFile.existsSync()) {
    entitlementsFile.parent.createSync(recursive: true);
    entitlementsFile.writeAsStringSync(_newEntitlementsFile);
    stdout.writeln(
      'Created Runner.entitlements with Apple Sign-In key at: $entitlementsPath',
    );
    return _ensureEntitlementsAssignedInXcodeProject();
  }

  final raw = entitlementsFile.readAsStringSync();
  if (raw.contains(_appleSignInEntitlementKey)) {
    stdout.writeln(
      'Apple Sign-In entitlement already exists in Runner.entitlements. No changes made.',
    );
    return _ensureEntitlementsAssignedInXcodeProject();
  }

  const closeDictTag = '</dict>';
  final index = raw.lastIndexOf(closeDictTag);
  if (index < 0) {
    stderr.writeln('Invalid Runner.entitlements: missing </dict> tag.');
    stderr.writeln('Path: $entitlementsPath');
    return false;
  }

  var before = raw.substring(0, index);
  final after = raw.substring(index);
  if (!before.endsWith('\n')) {
    before = '$before\n';
  }

  final updated = '$before$_appleSignInEntitlementBlock\n$after';
  entitlementsFile.writeAsStringSync(updated);

  stdout.writeln('Added Apple Sign-In entitlement key to: $entitlementsPath');
  return _ensureEntitlementsAssignedInXcodeProject();
}

bool _ensureEntitlementsAssignedInXcodeProject() {
  final pbxprojPath = _resolveProjectPath(
    '/ios/Runner.xcodeproj/project.pbxproj',
    platformFolder: 'ios',
  );
  final pbxprojFile = File(pbxprojPath);

  if (!pbxprojFile.existsSync()) {
    stderr.writeln('Xcode project file not found: $pbxprojPath');
    return false;
  }

  final raw = pbxprojFile.readAsStringSync();
  final eol = raw.contains('\r\n') ? '\r\n' : '\n';
  final hadTrailingNewline = raw.endsWith('\n');
  final lines = raw.split(RegExp(r'\r?\n'));

  final runnerConfigListId = _findRunnerBuildConfigurationListId(lines);
  if (runnerConfigListId == null) {
    stderr.writeln(
      'Failed to locate Runner target build configuration list in: $pbxprojPath',
    );
    return false;
  }

  final runnerConfigIds = _findConfigIdsForConfigurationList(
    lines,
    runnerConfigListId,
  );
  if (runnerConfigIds.isEmpty) {
    stderr.writeln(
      'Failed to locate Runner build configuration IDs in: $pbxprojPath',
    );
    return false;
  }

  final foundNames = <String>{};
  var didUpdate = false;
  var hasFailure = false;
  var hasProfile = false;

  for (final entry in runnerConfigIds.entries) {
    final configId = entry.key;
    final configName = entry.value;
    if (configName != 'Debug' &&
        configName != 'Release' &&
        configName != 'Profile') {
      continue;
    }

    foundNames.add(configName);
    if (configName == 'Profile') {
      hasProfile = true;
    }

    final result = _upsertEntitlementInConfiguration(lines, configId);
    if (result == _EntitlementUpsertResult.updated) {
      didUpdate = true;
    } else if (result == _EntitlementUpsertResult.failed) {
      hasFailure = true;
    }
  }

  if (!foundNames.contains('Debug') || !foundNames.contains('Release')) {
    stderr.writeln(
      'Runner target is missing Debug/Release build configurations in: $pbxprojPath',
    );
    return false;
  }
  if (hasFailure) {
    stderr.writeln(
      'Failed to update CODE_SIGN_ENTITLEMENTS in one or more Runner buildSettings blocks.',
    );
    return false;
  }

  final requiredNames = <String>{'Debug', 'Release'};
  if (hasProfile) {
    requiredNames.add('Profile');
  }

  final missingAfterUpdate = <String>[];
  for (final name in requiredNames) {
    final configId = _configIdByName(runnerConfigIds, name);
    if (configId == null || !_hasEntitlementInConfiguration(lines, configId)) {
      missingAfterUpdate.add(name);
    }
  }

  if (missingAfterUpdate.isNotEmpty) {
    stderr.writeln(
      'CODE_SIGN_ENTITLEMENTS is still missing in Runner build settings for: ${missingAfterUpdate.join(', ')}',
    );
    return false;
  }

  if (didUpdate) {
    var updatedRaw = lines.join(eol);
    if (hadTrailingNewline && !updatedRaw.endsWith(eol)) {
      updatedRaw = '$updatedRaw$eol';
    }
    pbxprojFile.writeAsStringSync(updatedRaw);
    stdout.writeln(
      'Ensured CODE_SIGN_ENTITLEMENTS for Runner target build configs in: $pbxprojPath',
    );
  } else {
    stdout.writeln(
      'CODE_SIGN_ENTITLEMENTS already configured for Runner target build configs in: $pbxprojPath',
    );
  }

  return true;
}

String? _findRunnerBuildConfigurationListId(List<String> lines) {
  for (var i = 0; i < lines.length; i++) {
    if (!lines[i].contains('/* Runner */ = {')) {
      continue;
    }

    final blockEnd = _findBlockEnd(lines, i);
    if (blockEnd == -1) {
      continue;
    }

    var isNativeTarget = false;
    String? configListId;

    for (var j = i + 1; j < blockEnd; j++) {
      final trimmed = lines[j].trim();
      if (trimmed == 'isa = PBXNativeTarget;') {
        isNativeTarget = true;
      }

      if (trimmed.startsWith('buildConfigurationList = ')) {
        final match = RegExp(
          r'buildConfigurationList = ([A-Fa-f0-9]+) ',
        ).firstMatch(trimmed);
        if (match != null) {
          configListId = match.group(1);
        }
      }
    }

    if (isNativeTarget && configListId != null) {
      return configListId;
    }
  }

  return null;
}

Map<String, String> _findConfigIdsForConfigurationList(
  List<String> lines,
  String configListId,
) {
  final result = <String, String>{};
  final escapedId = RegExp.escape(configListId);

  for (var i = 0; i < lines.length; i++) {
    if (!RegExp('^\\s*$escapedId\\s+/\\*').hasMatch(lines[i])) {
      continue;
    }

    final blockEnd = _findBlockEnd(lines, i);
    if (blockEnd == -1) {
      continue;
    }

    var insideConfigs = false;
    for (var j = i + 1; j < blockEnd; j++) {
      final trimmed = lines[j].trim();
      if (trimmed == 'buildConfigurations = (') {
        insideConfigs = true;
        continue;
      }

      if (insideConfigs && trimmed == ');') {
        break;
      }

      if (!insideConfigs) {
        continue;
      }

      final match = RegExp(
        r'^([A-Fa-f0-9]+) /\* (.+) \*/,$',
      ).firstMatch(trimmed);
      if (match == null) {
        continue;
      }

      final id = match.group(1)!;
      final name = match.group(2)!;
      result[id] = name;
    }

    if (result.isNotEmpty) {
      return result;
    }
  }

  return result;
}

_EntitlementUpsertResult _upsertEntitlementInConfiguration(
  List<String> lines,
  String configId,
) {
  final escapedId = RegExp.escape(configId);
  final startRegex = RegExp('^\\s*$escapedId\\s+/\\*');

  for (var i = 0; i < lines.length; i++) {
    if (!startRegex.hasMatch(lines[i])) {
      continue;
    }

    final blockEnd = _findBlockEnd(lines, i);
    if (blockEnd == -1) {
      return _EntitlementUpsertResult.failed;
    }

    var buildSettingsStart = -1;
    for (var j = i + 1; j < blockEnd; j++) {
      if (lines[j].contains('buildSettings = {')) {
        buildSettingsStart = j;
        break;
      }
    }
    if (buildSettingsStart == -1) {
      return _EntitlementUpsertResult.failed;
    }

    var buildSettingsEnd = -1;
    for (var j = buildSettingsStart + 1; j < blockEnd; j++) {
      if (lines[j].trim() == '};') {
        buildSettingsEnd = j;
        break;
      }
    }
    if (buildSettingsEnd == -1) {
      return _EntitlementUpsertResult.failed;
    }

    var settingLineIndex = -1;
    for (var j = buildSettingsStart + 1; j < buildSettingsEnd; j++) {
      if (lines[j].contains('CODE_SIGN_ENTITLEMENTS')) {
        settingLineIndex = j;
        break;
      }
    }

    if (settingLineIndex == -1) {
      final indent = '${_leadingWhitespace(lines[buildSettingsEnd])}\t';
      lines.insert(buildSettingsEnd, '$indent$_codeSignEntitlementsSetting');
      return _EntitlementUpsertResult.updated;
    }

    final currentIndent = _leadingWhitespace(lines[settingLineIndex]);
    final desiredLine = '$currentIndent$_codeSignEntitlementsSetting';
    if (lines[settingLineIndex].trim() != _codeSignEntitlementsSetting) {
      lines[settingLineIndex] = desiredLine;
      return _EntitlementUpsertResult.updated;
    }

    return _EntitlementUpsertResult.alreadyPresent;
  }

  return _EntitlementUpsertResult.failed;
}

bool _hasEntitlementInConfiguration(List<String> lines, String configId) {
  final escapedId = RegExp.escape(configId);
  final startRegex = RegExp('^\\s*$escapedId\\s+/\\*');

  for (var i = 0; i < lines.length; i++) {
    if (!startRegex.hasMatch(lines[i])) {
      continue;
    }

    final blockEnd = _findBlockEnd(lines, i);
    if (blockEnd == -1) {
      return false;
    }

    var buildSettingsStart = -1;
    for (var j = i + 1; j < blockEnd; j++) {
      if (lines[j].contains('buildSettings = {')) {
        buildSettingsStart = j;
        break;
      }
    }
    if (buildSettingsStart == -1) {
      return false;
    }

    var buildSettingsEnd = -1;
    for (var j = buildSettingsStart + 1; j < blockEnd; j++) {
      if (lines[j].trim() == '};') {
        buildSettingsEnd = j;
        break;
      }
    }
    if (buildSettingsEnd == -1) {
      return false;
    }

    for (var j = buildSettingsStart + 1; j < buildSettingsEnd; j++) {
      if (lines[j].trim() == _codeSignEntitlementsSetting) {
        return true;
      }
    }
    return false;
  }

  return false;
}

String? _configIdByName(Map<String, String> configIdsByName, String name) {
  for (final entry in configIdsByName.entries) {
    if (entry.value == name) {
      return entry.key;
    }
  }
  return null;
}

int _findBlockEnd(List<String> lines, int start) {
  var depth = 0;
  var started = false;

  for (var i = start; i < lines.length; i++) {
    final line = lines[i];
    final openCount = _countChar(line, '{');
    final closeCount = _countChar(line, '}');

    if (!started && openCount > 0) {
      started = true;
    }

    if (started) {
      depth += openCount;
      depth -= closeCount;

      if (depth == 0 && line.trim().endsWith('};')) {
        return i;
      }
    }
  }

  return -1;
}

int _countChar(String value, String char) {
  var count = 0;
  for (var i = 0; i < value.length; i++) {
    if (value[i] == char) {
      count++;
    }
  }
  return count;
}

String _resolveProjectPath(String inputPath, {required String platformFolder}) {
  final trimmed = inputPath.trim();

  if (trimmed.startsWith('/$platformFolder/')) {
    final rel = trimmed.substring(1).replaceAll('/', Platform.pathSeparator);
    return '.${Platform.pathSeparator}$rel';
  }

  if (trimmed.startsWith('$platformFolder/')) {
    final rel = trimmed.replaceAll('/', Platform.pathSeparator);
    return '.${Platform.pathSeparator}$rel';
  }

  return Platform.isWindows
      ? trimmed.replaceAll('/', Platform.pathSeparator)
      : trimmed;
}

String? _readOption(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == name && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

String _leadingWhitespace(String value) {
  final match = RegExp(r'^\s*').firstMatch(value);
  return match?.group(0) ?? '';
}

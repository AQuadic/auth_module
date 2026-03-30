param(
  [Parameter(Mandatory = $true)]
  [string]$ManifestPath
)

function Resolve-ManifestPath {
  param([string]$InputPath)

  if ([string]::IsNullOrWhiteSpace($InputPath)) {
    return $InputPath
  }

  $trimmed = $InputPath.Trim()

  # Allow Linux-style project rooted input like /android/app/src/main/AndroidManifest.xml.
  if ($trimmed.StartsWith('/android/')) {
    return "." + $trimmed.Replace('/', '\\')
  }

  return $trimmed
}

$resolvedManifestPath = Resolve-ManifestPath -InputPath $ManifestPath

if (-not (Test-Path -Path $resolvedManifestPath)) {
  Write-Error "AndroidManifest.xml not found at: $ManifestPath"
  exit 1
}

$raw = Get-Content -Path $resolvedManifestPath -Raw -Encoding UTF8

$activityName = 'com.aboutyou.dart_packages.sign_in_with_apple.SignInWithAppleCallback'
if ($raw -match [regex]::Escape($activityName)) {
  Write-Output "Apple Sign-In callback activity already exists. No changes made."
  exit 0
}

$callbackActivity = @"
        <activity
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
"@

$closeTag = '</application>'
$index = $raw.LastIndexOf($closeTag)
if ($index -lt 0) {
  Write-Error "Invalid AndroidManifest.xml: missing </application> tag."
  exit 1
}

$before = $raw.Substring(0, $index)
$after = $raw.Substring($index)

if (-not $before.EndsWith("`r`n")) {
  $before += "`r`n"
}

$updated = $before + $callbackActivity + "`r`n" + $after
Set-Content -Path $resolvedManifestPath -Value $updated -Encoding UTF8

Write-Output "Added Apple Sign-In callback activity to: $resolvedManifestPath"

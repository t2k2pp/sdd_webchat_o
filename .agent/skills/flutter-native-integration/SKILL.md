---
name: flutter-native-integration
description: Flutterネイティブ連携スキル。Platform Channel、Method Channel、EventChannel、Dart FFI、Pigeon自動生成を支援。カメラ、センサー等のネイティブ機能連携時に使用。
---

# Flutter ネイティブ連携スキル

## 連携方式の選択

| 方式 | 用途 | 推奨度 |
|------|------|--------|
| **Pigeon** | 型安全なメソッド呼び出し | ★★★ 推奨 |
| **Method Channel** | シンプルなメソッド呼び出し | ★★ |
| **Event Channel** | ネイティブからのストリーム | ★★ |
| **Dart FFI** | C/C++ライブラリ直接呼び出し | 特殊用途 |

---

## Pigeon（推奨）

### セットアップ
```yaml
dev_dependencies:
  pigeon: ^17.0.0
```

### Pigeon定義
```dart
// pigeons/messages.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/com/example/Messages.g.kt',
  swiftOut: 'ios/Runner/Messages.g.swift',
))

class DeviceInfo {
  String? model;
  String? osVersion;
  int? batteryLevel;
}

@HostApi()
abstract class DeviceApi {
  DeviceInfo getDeviceInfo();
  @async
  bool requestPermission(String permission);
}

@FlutterApi()
abstract class DeviceEventApi {
  void onBatteryLevelChanged(int level);
}
```

### コード生成
```bash
dart run pigeon --input pigeons/messages.dart
```

### Kotlin実装
```kotlin
// android/app/src/main/kotlin/.../Messages.g.kt から実装
class DeviceApiImpl(private val context: Context) : DeviceApi {
    override fun getDeviceInfo(): DeviceInfo {
        return DeviceInfo(
            model = Build.MODEL,
            osVersion = Build.VERSION.RELEASE,
            batteryLevel = getBatteryLevel()
        )
    }

    override fun requestPermission(permission: String, callback: (Result<Boolean>) -> Unit) {
        // 非同期処理
        callback(Result.success(true))
    }
}
```

### Swift実装
```swift
// ios/Runner/Messages.g.swift から実装
class DeviceApiImpl: DeviceApi {
    func getDeviceInfo() throws -> DeviceInfo {
        return DeviceInfo(
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            batteryLevel: Int64(UIDevice.current.batteryLevel * 100)
        )
    }
    
    func requestPermission(permission: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
}
```

### Dart使用
```dart
final deviceApi = DeviceApi();
final info = await deviceApi.getDeviceInfo();
print('Model: ${info.model}');
```

---

## Method Channel

### Dart側
```dart
class NativeBridge {
  static const _channel = MethodChannel('com.example.app/native');

  Future<String> getPlatformVersion() async {
    final version = await _channel.invokeMethod<String>('getPlatformVersion');
    return version ?? 'Unknown';
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
    return result ?? {};
  }
}
```

### Kotlin側
```kotlin
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
                    "getDeviceInfo" -> result.success(mapOf(
                        "model" to Build.MODEL,
                        "brand" to Build.BRAND
                    ))
                    else -> result.notImplemented()
                }
            }
    }
}
```

### Swift側
```swift
@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.example.app/native",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getPlatformVersion":
                result("iOS \(UIDevice.current.systemVersion)")
            case "getDeviceInfo":
                result([
                    "model": UIDevice.current.model,
                    "name": UIDevice.current.name
                ])
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

---

## Event Channel

### Dart側
```dart
class BatteryMonitor {
  static const _eventChannel = EventChannel('com.example.app/battery');

  Stream<int> get batteryLevel {
    return _eventChannel.receiveBroadcastStream().map((event) => event as int);
  }
}
```

### Kotlin側
```kotlin
class BatteryStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    private var receiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                events?.success(level)
            }
        }
        context.registerReceiver(receiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    }

    override fun onCancel(arguments: Any?) {
        receiver?.let { context.unregisterReceiver(it) }
        receiver = null
    }
}
```

---

## iOS固有API連携

### Sign in with Apple
```yaml
# pubspec.yaml
dependencies:
  sign_in_with_apple: ^5.0.0
```

```dart
// Dart実装
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

Future<void> signInWithApple() async {
  final credential = await SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
  );

  // バックエンドに送信
  await authRepository.signInWithApple(
    identityToken: credential.identityToken!,
    authorizationCode: credential.authorizationCode,
  );
}
```

**設定必須:**
1. Xcode → Signing & Capabilities → + Sign in with Apple
2. Apple Developer Portal → App ID → Sign in with Apple有効化
3. プロビジョニングプロファイル再生成

### HealthKit
```yaml
dependencies:
  health: ^10.0.0
```

```dart
import 'package:health/health.dart';

class HealthService {
  final _health = HealthFactory();

  Future<bool> requestPermissions() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_IN_BED,
    ];
    return await _health.requestAuthorization(types);
  }

  Future<int> getStepsToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    
    final steps = await _health.getTotalStepsInInterval(midnight, now);
    return steps ?? 0;
  }
}
```

**Info.plist必須:**
```xml
<key>NSHealthShareUsageDescription</key>
<string>歩数データを表示するためにヘルスケアデータを読み取ります</string>
<key>NSHealthUpdateUsageDescription</key>
<string>ワークアウトデータを記録するためにヘルスケアに書き込みます</string>
```

### Push通知（APNs）
```yaml
dependencies:
  firebase_messaging: ^14.7.0
```

```dart
// APNsトークン取得
final apnsToken = await FirebaseMessaging.instance.getAPNSToken();

// FCMトークン（iOS/Android共通）
final fcmToken = await FirebaseMessaging.instance.getToken();
```

**設定:**
1. Xcode → Signing & Capabilities → Push Notifications
2. Apple Developer → Keys → APNs Key作成
3. Firebase Console → Project Settings → Cloud Messaging → APNs Key登録

### App Clips
```dart
// App Clip Experience URL処理
// ios/Runner (App Clip)/AppDelegate.swift
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard let url = userActivity.webpageURL else { return }
    // URLパラメータを処理
}
```

### Widget（iOS 14+ WidgetKit）
```swift
// ios/Widget/Widget.swift
import WidgetKit
import SwiftUI

struct FlutterDataProvider: TimelineProvider {
    // UserDefaultsでFlutterアプリとデータ共有
    // App Groups必須
}

@main
struct AppWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "widget", provider: FlutterDataProvider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

**Flutterからデータ共有:**
```dart
// App Groupsでデータ共有
import 'package:shared_preferences/shared_preferences.dart';

// iOS専用: suite名指定
final prefs = await SharedPreferences.getInstance();
// home_widget パッケージ推奨
```

---

## Dart FFI

### セットアップ
```yaml
dependencies:
  ffi: ^2.1.0
  
# native_add.cではなくDynamic Libraryをロード
```

### C関数呼び出し
```dart
import 'dart:ffi';

typedef NativeAdd = Int32 Function(Int32, Int32);
typedef DartAdd = int Function(int, int);

void main() {
  final dylib = DynamicLibrary.open('libnative.so');
  final add = dylib.lookupFunction<NativeAdd, DartAdd>('add');
  print(add(1, 2)); // 3
}
```

---

## ベストプラクティス

### 1. Pigeon優先
- 型安全
- ボイラープレート削減
- ドキュメント自動生成

### 2. エラーハンドリング
```dart
try {
  final result = await channel.invokeMethod('method');
} on PlatformException catch (e) {
  // ネイティブ側エラー
  print('Error: ${e.code} - ${e.message}');
} on MissingPluginException {
  // チャンネル未登録
  print('Plugin not available');
}
```

### 3. テスト
```dart
// モック
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(channel, (call) async {
  if (call.method == 'getPlatformVersion') {
    return 'Mock Platform';
  }
  return null;
});
```

---

## チェックリスト

ネイティブ連携実装時:
- [ ] Pigeon使用を優先検討
- [ ] 両プラットフォーム（iOS/Android）実装
- [ ] エラーハンドリング実装
- [ ] null安全性考慮
- [ ] バックグラウンド処理の考慮
- [ ] テスト（モック）実装

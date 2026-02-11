---
description: 設計から実装への移行フロー。設計書の解釈、コード生成、初期実装のガイド。
---

# 設計→実装フロー

## フロー概要

```
設計書完成
    ↓
1. 設計書の理解・確認
    ↓
2. ファイル構造の作成
    ↓
3. データモデル実装
    ↓
4. Repository実装
    ↓
5. Provider実装
    ↓
6. UI実装
    ↓
実装完了
```

---

## Step 1: 設計書の理解

### 確認事項
- [ ] 機能要件を理解
- [ ] データモデルを確認
- [ ] API仕様を確認
- [ ] UI仕様を確認
- [ ] 依存関係を確認

---

## Step 2: ファイル構造作成

```bash
# Feature構造を作成
mkdir -p lib/features/{feature_name}/{data,domain,presentation}
mkdir -p lib/features/{feature_name}/data/{datasources,models,repositories}
mkdir -p lib/features/{feature_name}/domain/{entities,repositories,usecases}
mkdir -p lib/features/{feature_name}/presentation/{providers,screens,widgets}
```

### 作成ファイル
```
lib/features/{feature}/
├── data/
│   ├── datasources/{feature}_remote_datasource.dart
│   ├── models/{entity}_model.dart
│   └── repositories/{feature}_repository_impl.dart
├── domain/
│   ├── entities/{entity}.dart
│   ├── repositories/{feature}_repository.dart
│   └── usecases/{usecase}.dart
└── presentation/
    ├── providers/{feature}_provider.dart
    ├── screens/{screen}_screen.dart
    └── widgets/{widget}.dart
```

---

## Step 3: データモデル実装

### Entity（ドメイン層）
```dart
// lib/features/{feature}/domain/entities/{entity}.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{entity}.freezed.dart';
part '{entity}.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### Model（データ層）
```dart
// lib/features/{feature}/data/models/{entity}_model.dart
// APIレスポンスのマッピング用
```

---

## Step 4: Repository実装

### Interface（ドメイン層）
```dart
// lib/features/{feature}/domain/repositories/{feature}_repository.dart
abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
}
```

### Implementation（データ層）
```dart
// lib/features/{feature}/data/repositories/{feature}_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._dio, this._storage);

  @override
  Future<User> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return User.fromJson(response.data);
  }
}
```

---

## Step 5: Provider実装

```dart
// lib/features/{feature}/presentation/providers/{feature}_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{feature}_provider.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(dio, storage);
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<User?> build() async {
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).login(email, password);
    });
  }
}
```

---

## Step 6: UI実装

```dart
// lib/features/{feature}/presentation/screens/{screen}_screen.dart
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: authState.when(
        data: (user) => user != null 
            ? const HomeScreen() 
            : const LoginForm(),
        loading: () => const LoadingIndicator(),
        error: (e, s) => ErrorDisplay(error: e),
      ),
    );
  }
}
```

---

## 実装チェックリスト

- [ ] 全Entityが定義されている
- [ ] Repository Interfaceが定義されている
- [ ] Repository Implementationが実装されている
- [ ] Providerが定義されている
- [ ] UIが実装されている
- [ ] エラーハンドリングが実装されている
- [ ] ローディング状態が表示される
- [ ] `flutter analyze` がエラーなし

// lib/models/user.dart

import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final String email;

  // ▼▼▼ ИЗМЕНЕНИЕ: Добавляем displayName ▼▼▼
  @HiveField(1)
  final String displayName;

  @HiveField(2)
  late final bool isAdmin;

  // ▼▼▼ ИЗМЕНЕНИЕ: Убираем пароль, добавляем displayName ▼▼▼
  User({
    required this.email,
    required this.displayName,
    this.isAdmin = false,
  });

  // Метод copyWith тоже нужно обновить
  User copyWith({
    String? email,
    String? displayName,
    bool? isAdmin,
  }) {
    return User(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
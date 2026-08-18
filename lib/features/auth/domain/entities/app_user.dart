import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final bool isPro;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.isPro = false,
  });

  AppUser copyWith({String? name, String? email, bool? isPro}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      isPro: isPro ?? this.isPro,
    );
  }

  factory AppUser.fromFirebase(User user) {
    return AppUser(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {required String id}) {
    return AppUser(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      isPro: map['isPro'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, email, isPro];
}

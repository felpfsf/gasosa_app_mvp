import 'package:faker/faker.dart';
import 'package:gasosa_app/domain/entities/user.dart';

/// Factory para criar UserEntity fake nos testes
class UserFactory {
  static final _faker = Faker();

  /// Cria um UserEntity com valores fake ou customizados
  static UserEntity create({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
  }) {
    return UserEntity(
      id: id ?? _faker.guid.guid(),
      name: name ?? _faker.person.name(),
      email: email ?? _faker.internet.email(),
      photoUrl: photoUrl ?? _faker.internet.httpsUrl(),
    );
  }

  /// Cria um UserEntity sem photoUrl
  static UserEntity createWithoutPhoto({
    String? id,
    String? name,
    String? email,
  }) {
    return UserEntity(
      id: id ?? _faker.guid.guid(),
      name: name ?? _faker.person.name(),
      email: email ?? _faker.internet.email(),
      photoUrl: null,
    );
  }

  /// Cria uma lista de UserEntity fake
  static List<UserEntity> createList(int count) {
    return List.generate(count, (_) => create());
  }

  /// Cria um UserEntity válido para testes específicos
  static UserEntity createValid({
    String id = 'valid-user-id',
    String name = 'João Silva',
    String email = 'joao@example.com',
    String? photoUrl,
  }) {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      photoUrl: photoUrl,
    );
  }
}

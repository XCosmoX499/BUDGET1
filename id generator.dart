import 'package:uuid/uuid.dart';

/// Generatore di ID univoci per entità persistite.
///
/// Usa UUID v4. Centralizzato per poter cambiare strategia in futuro
/// (es. ULID per ordinamento lessicografico) senza toccare i repository.
class IdGenerator {
  IdGenerator({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  String generate() => _uuid.v4();
}

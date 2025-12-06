// lib/widgets/rutube_player.dart

// 1. Импортируем заглушку по умолчанию
import 'rutube_player_stub.dart'
// 2. Если это Android/iOS - берем мобильный файл
if (dart.library.io) 'rutube_player_mobile.dart'
// 3. Если это Web - берем веб файл
if (dart.library.html) 'rutube_player_web.dart';

// Экспортируем тот класс, который выбрался выше
export 'rutube_player_stub.dart'
if (dart.library.io) 'rutube_player_mobile.dart'
if (dart.library.html) 'rutube_player_web.dart';
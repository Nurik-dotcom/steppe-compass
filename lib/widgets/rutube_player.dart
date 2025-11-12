// lib/widgets/rutube_player.dart

// Эта строка говорит: "По умолчанию используй 'rutube_player_mobile.dart',
// но если компилируешь для веба (dart.library.html),
// то вместо него используй 'rutube_player_web.dart'".

export 'rutube_player_mobile.dart'
if (dart.library.html) 'rutube_player_web.dart';
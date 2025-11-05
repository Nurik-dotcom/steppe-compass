// lib/widgets/connectivity_wrapper.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../screens/no_internet_screen.dart';

// lib/widgets/connectivity_wrapper.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../screens/no_internet_screen.dart';

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  const ConnectivityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ▼▼▼ ИЗМЕНЕНИЕ: Тип StreamBuilder теперь List<ConnectivityResult> ▼▼▼
    return StreamBuilder<List<ConnectivityResult>>(
      // ▲▲▲ КОНЕЦ ИЗМЕНЕНИЯ ▲▲▲
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const NoInternetScreen();
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final results = snapshot.data!;
        if (results.contains(ConnectivityResult.none)) return const NoInternetScreen();
        return child;
        // ▲▲▲ КОНЕЦ ИЗМЕНЕНИЯ ▲▲▲

        return child;
      },
    );
  }
}
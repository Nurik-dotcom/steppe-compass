import 'package:flutter/material.dart';
import '../screens/root_shell.dart';

class RootShellHost extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const RootShellHost({
    super.key,
    required this.child,
    this.enabled = true,
  });
  static const double bottomGap =
      kBottomNavigationBarHeight + 24; // ≈ 56 + 24 = 80
  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Stack(
      children: [
        child,
        
        
          
          
          
        

        
         Positioned.fill(
           child: IgnorePointer(
             ignoring: true, 
             child: RootShell(),
           ),
         ),
      ],
    );
  }
}

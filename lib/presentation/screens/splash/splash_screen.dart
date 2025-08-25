import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slide =
        Tween<double>(
          begin: 0.20,
          end: 0,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
          ),
        );

    _fade =
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.35, curve: Curves.easeOut),
          ),
        );

    unawaited(playAndNavigate());
    // _controller.forward();
  }

  Future<void> playAndNavigate() async {
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (!mounted) {
      return;
    }
    context.go(user != null ? RoutePaths.dashboard : RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _fade.value,
              child: Transform.translate(
                offset: Offset(0, _slide.value * height),
                child: Hero(
                  tag: 'app-logo',
                  child: Image.asset(
                    'assets/images/app_logo_novo.png',
                    width: 256,
                    height: 256,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

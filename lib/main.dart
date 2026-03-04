import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:kuryl_kz/features/auth/screens/auth_gate.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/core/widgets/offline_overlay.dart';

/// =======================
/// DEBUG DIAGNOSTIC SWITCHES
/// =======================
/// 1) Overlay-ларды уақытша өшіру:
const bool kDebugDisableOverlays = false;

/// 2) Semantics-ті уақытша толық өшіру (диагноз үшін ғана!):
const bool kDebugDisableSemantics = false;

/// 3) Custom ErrorWidget-ті өшіру (қызыл экранды қайтару):
const bool kDebugUseDefaultErrorWidget = true;

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      /// 1) Flutter framework ішіндегі қателер (build/layout/render, assert, т.б.)
      FlutterError.onError = (FlutterErrorDetails details) {
        // Flutter-дің стандартты толық логын шығарады (көбіне "relevant error-causing widget" осы жерде болады)
        FlutterError.presentError(details);

        // Қосымша: өзіміз де толықтырып шығарамыз (ақпарат жинаушыларды қоса)
        debugPrint(
          "\n================ FLUTTER ERROR (onError) ================",
        );
        debugPrint("Exception: ${details.exceptionAsString()}");
        debugPrint("Library  : ${details.library}");
        debugPrint("Context  : ${details.context}");
        if (details.stack != null) {
          debugPrint("Stack:\n${details.stack}");
        }

        // Бұл өте маңызды: кейде "relevant widget" infoCollector ішінде болады
        final collector = details.informationCollector;
        if (collector != null) {
          debugPrint("---- informationCollector ----");
          for (final line in collector()) {
            debugPrint(line.toString());
          }
          debugPrint("------------------------------");
        }
        debugPrint(
          "=========================================================\n",
        );
      };

      /// 2) Асинхронды/платформа қателері (Future, Timer, PlatformDispatcher)
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint(
          "\n================ ASYNC/PLATFORM ERROR ===================",
        );
        debugPrint("Error: $error");
        debugPrint("Stack:\n$stack");
        debugPrint(
          "=========================================================\n",
        );
        return true; // handled
      };

      /// 3) Қызыл экранды қайтару (debug-та өте пайдалы)
      if (kDebugMode && kDebugUseDefaultErrorWidget) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          // default error widget (Flutter red screen)
          return ErrorWidget(details.exception);
        };
      }

      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint("\n================ ZONE ERROR (runZonedGuarded) ===========");
      debugPrint("Error: $error");
      debugPrint("Stack:\n$stackTrace");
      debugPrint("=========================================================\n");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String? _platformFontFamily() {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'SF Pro Text';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return 'Roboto';
      case TargetPlatform.windows:
        return 'Segoe UI';
      case TargetPlatform.linux:
        return 'Ubuntu';
    }
  }

  List<String>? _platformFontFallback() {
    if (kIsWeb) return const ['Roboto', 'Noto Sans', 'Arial'];
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const ['SF Pro Display', 'Helvetica Neue', 'Arial'];
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return const ['Noto Sans', 'Arial'];
      case TargetPlatform.windows:
        return const ['Segoe UI', 'Arial'];
      case TargetPlatform.linux:
        return const ['Ubuntu', 'DejaVu Sans', 'Arial'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformFontFamily = _platformFontFamily();
    final platformFontFallback = _platformFontFallback();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quryl',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        primarySwatch: Colors.amber,
        useMaterial3: true,
        fontFamily: platformFontFamily,
        fontFamilyFallback: platformFontFallback,
      ),

      /// МІНЕ ОСЫ builder — сенің қатеңді "қайдан" екенін табуға ең керек жер.
      /// Біз мұнда:
      /// - Overlay-ларды debug-та уақытша өшіре аламыз
      /// - Semantics-ті debug-та уақытша өшіре аламыз (диагноз үшін)
      builder: (context, child) {
        Widget safeChild = child ?? const SizedBox.shrink();

        // 1) Диагноз: Semantics толық өшіріп көр
        if (kDebugMode && kDebugDisableSemantics) {
          safeChild = ExcludeSemantics(child: safeChild);
        }

        // 2) Диагноз: Overlay-ларды өшіріп көр
        if (kDebugMode && kDebugDisableOverlays) {
          return safeChild;
        }

        // 3) Әдеттегі overlay-лар
        return OfflineBannerOverlay(child: AppLoadingOverlay(child: safeChild));
      },

      home: const AuthGate(),
    );
  }
}

import 'package:app_links/app_links.dart';
import 'package:banda/features/main/handlers/notification_handler.dart';
import 'package:banda/provider.dart';
import 'package:banda/routes.dart';
import 'package:flutter/material.dart' hide Router;

final navigator = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationHandler = NotificationHandler(navigator);
  runApp(
    await makeProvider(
      child: const Main(),
      notificationHandler: notificationHandler,
    ),
  );
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => MainState();
}

class MainState extends State<Main> {
  @override
  void initState() {
    super.initState();

    initLink();
  }

  Future<void> initLink() async {
    final appLinks = AppLinks();
    final uri = await appLinks.getInitialLink();

    if (uri != null) navigate(uri);
    appLinks.uriLinkStream.listen((uri) {
      navigate(uri);
    });
  }

  void navigate(Uri uri) {
    if (uri.scheme == 'app' && uri.host == 'bandha.id') {
      final path = '/${uri.pathSegments.join('/')}';
      Navigator.of(context).pushNamed(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final light = ThemeData.light(useMaterial3: true);
    final dark = ThemeData.dark(useMaterial3: true);

    return MaterialApp(
      navigatorKey: navigator,
      title: 'Bandha.io',
      debugShowCheckedModeBanner: false,
      theme: light.copyWith(
        colorScheme: light.colorScheme.copyWith(
          surfaceTint: light.colorScheme.surface,
          primary: light.colorScheme.onSurface,
          primaryFixed: light.colorScheme.onSurface,
          primaryFixedDim: light.colorScheme.onSurface,
          primaryContainer: light.colorScheme.onSurface,
          onPrimaryContainer: light.colorScheme.surface,
          onPrimary: light.colorScheme.surface,
          onPrimaryFixed: light.colorScheme.surface,
          onPrimaryFixedVariant: light.colorScheme.surface,
          secondary: light.colorScheme.onSurface,
          secondaryFixed: light.colorScheme.onSurface,
          secondaryFixedDim: light.colorScheme.onSurface,
          secondaryContainer: light.colorScheme.onSurface,
          onSecondaryContainer: light.colorScheme.surface,
          onSecondary: light.colorScheme.surface,
          onSecondaryFixed: light.colorScheme.surface,
          onSecondaryFixedVariant: light.colorScheme.surface,
          tertiary: light.colorScheme.onSurface,
          tertiaryFixed: light.colorScheme.onSurface,
          tertiaryFixedDim: light.colorScheme.onSurface,
          tertiaryContainer: light.colorScheme.onSurface,
          onTertiaryContainer: light.colorScheme.surface,
          onTertiary: light.colorScheme.surface,
          onTertiaryFixed: light.colorScheme.surface,
          onTertiaryFixedVariant: light.colorScheme.surface,
          inversePrimary: light.colorScheme.surface,
        ),
        textTheme: light.textTheme.apply(fontFamily: 'Eczar'),
      ),
      darkTheme: dark.copyWith(
        colorScheme: dark.colorScheme.copyWith(
          surfaceTint: dark.colorScheme.surface,
          primary: dark.colorScheme.onSurface,
          primaryFixed: dark.colorScheme.onSurface,
          primaryFixedDim: dark.colorScheme.onSurface,
          primaryContainer: dark.colorScheme.onSurface,
          onPrimaryContainer: dark.colorScheme.surface,
          onPrimary: dark.colorScheme.surface,
          onPrimaryFixed: dark.colorScheme.surface,
          onPrimaryFixedVariant: dark.colorScheme.surface,
          secondary: dark.colorScheme.onSurface,
          secondaryFixed: dark.colorScheme.onSurface,
          secondaryFixedDim: dark.colorScheme.onSurface,
          secondaryContainer: dark.colorScheme.onSurface,
          onSecondaryContainer: dark.colorScheme.surface,
          onSecondary: dark.colorScheme.surface,
          onSecondaryFixed: dark.colorScheme.surface,
          onSecondaryFixedVariant: dark.colorScheme.surface,
          tertiary: dark.colorScheme.onSurface,
          tertiaryFixed: dark.colorScheme.onSurface,
          tertiaryFixedDim: dark.colorScheme.onSurface,
          tertiaryContainer: dark.colorScheme.onSurface,
          onTertiaryContainer: dark.colorScheme.surface,
          onTertiary: dark.colorScheme.surface,
          onTertiaryFixed: dark.colorScheme.surface,
          onTertiaryFixedVariant: dark.colorScheme.surface,
          inversePrimary: dark.colorScheme.surface,
        ),
        textTheme: dark.textTheme.apply(fontFamily: 'Eczar'),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      onGenerateRoute: Routes.makeRoutes,
    );
  }
}

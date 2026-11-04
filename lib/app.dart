import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'injection.dart';
import 'l10n/app_localizations.dart';
import 'presentation/cubit/import_cubit.dart';
import 'presentation/pages/import_page.dart';

class CamaleonDbPortApp extends StatelessWidget {
  const CamaleonDbPortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ImportCubit>(),
      child: BlocBuilder<ImportCubit, ImportState>(
        buildWhen: (p, c) => p.localeCode != c.localeCode,
        builder: (context, state) {
          final locale = Locale(state.localeCode);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Camaleon DB Importer',
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1F6F5B),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: const ImportPage(),
          );
        },
      ),
    );
  }
}

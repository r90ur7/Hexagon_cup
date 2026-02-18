import 'package:admissao_app/core/di/injection.dart' as di;
import 'package:admissao_app/features/tournament/presentation/bloc/tournament_cubit.dart';
import 'package:admissao_app/features/tournament/presentation/pages/tournament_list_page.dart';
import 'package:admissao_app/core/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => di.sl<TournamentCubit>())],
      child: MaterialApp(
        title: 'Hexagon Cup Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const TournamentListPage(),
      ),
    );
  }
}

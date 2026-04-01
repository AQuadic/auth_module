import 'package:auth_module/src/presentation/cubit/auth_ui_cubit.dart';
import 'package:auth_module/src/core/auth_module_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthModuleUiProvider extends StatelessWidget {
  const AuthModuleUiProvider({super.key, required this.child, this.module});

  final Widget child;
  final AuthModule? module;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthUiCubit>(
      create: (_) => AuthUiCubit(module: module),
      child: child,
    );
  }
}

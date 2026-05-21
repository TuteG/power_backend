import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/shared.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuario = TextEditingController();
  final _clave   = TextEditingController();
  final _focus   = FocusNode();
  bool _verClave = false;

  Future<void> _login() async {
    final state = context.read<AppState>();
    state.limpiarError();
    final ok = await state.login(_usuario.text.trim(), _clave.text);
    if (!ok && mounted) {
      AlertaSnack.error(context, state.error ?? 'Error al iniciar sesión');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cargando = context.watch<AppState>().cargando;
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 600;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/logo.jpg', width: 110, height: 110, fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                Text('PowerPrints OS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: kPrimario)),
                const SizedBox(height: 4),
                Text('Gestión Integral de Flota',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 32),

                // Usuario
                TextField(
                  controller: _usuario,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _focus.requestFocus(),
                ),
                const SizedBox(height: 14),

                // Clave
                TextField(
                  controller: _clave,
                  focusNode: _focus,
                  obscureText: !_verClave,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _verClave = !_verClave),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),

                // Botón
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: cargando ? null : _login,
                    icon: cargando
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.login_rounded),
                    label: Text(cargando ? 'Ingresando…' : 'Iniciar sesión'),
                  ),
                ),
                const SizedBox(height: 24),
                Text('PowerPrints OS v2.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

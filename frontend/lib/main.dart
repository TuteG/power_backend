import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'widgets/shared.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/maquinas_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/admin_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PowerPrintsApp(),
    ),
  );
}

class PowerPrintsApp extends StatefulWidget {
  const PowerPrintsApp({super.key});
  @override
  State<PowerPrintsApp> createState() => _PowerPrintsAppState();
}

class _PowerPrintsAppState extends State<PowerPrintsApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() => setState(() =>
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerPrints OS',
      debugShowCheckedModeBanner: false,
      theme:      temaClaro(),
      darkTheme:  temaOscuro(),
      themeMode:  _themeMode,
      home: _Root(toggleTheme: _toggleTheme, themeMode: _themeMode),
    );
  }
}

class _Root extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;
  const _Root({required this.toggleTheme, required this.themeMode});
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _restaurando = true;

  @override
  void initState() {
    super.initState();
    _restaurarSesion();
  }

  Future<void> _restaurarSesion() async {
    await context.read<AppState>().restaurarSesion();
    if (mounted) setState(() => _restaurando = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_restaurando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final logueado = context.watch<AppState>().logueado;
    return logueado
        ? AppShell(toggleTheme: widget.toggleTheme, themeMode: widget.themeMode)
        : const LoginScreen();
  }
}

// ── SHELL PRINCIPAL ───────────────────────────────────────────────────────────
class AppShell extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;
  const AppShell({super.key, required this.toggleTheme, required this.themeMode});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indice = 0;

  List<_Destino> _destinos(bool esAdmin) => [
    _Destino(Icons.dashboard_outlined,  Icons.dashboard_rounded,  'Inicio',   const DashboardScreen()),
    _Destino(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Stock',  const StockScreen()),
    _Destino(Icons.print_outlined,       Icons.print_rounded,      'Equipos', const MaquinasScreen()),
    _Destino(Icons.history_outlined,     Icons.history_rounded,    'Historial', const HistorialScreen()),
    if (esAdmin)
      _Destino(Icons.people_outlined,  Icons.people_rounded, 'Admin', const AdminScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final state     = context.watch<AppState>();
    final destinos  = _destinos(state.esAdmin);
    final esMovil   = MediaQuery.of(context).size.width < 600;
    final idx       = _indice.clamp(0, destinos.length - 1);

    // AppBar
    final appBar = AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/logo.jpg', width: 36, height: 36, fit: BoxFit.contain),
        ),
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PowerPrints OS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        Text('${state.usuario}  ·  ${state.rol}',
          style: const TextStyle(fontSize: 10, color: Color(0xBBFFFFFF))),
      ]),
      actions: [
        IconButton(
          icon: Icon(widget.themeMode == ThemeMode.light
              ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined),
          tooltip: 'Cambiar tema',
          onPressed: widget.toggleTheme,
        ),
        if (state.cargando)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
          ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Cerrar sesión',
          onPressed: state.logout,
        ),
      ],
    );

    if (esMovil) {
      // ── MÓVIL: bottom navigation bar ─────────────────────────────────────
      return Scaffold(
        appBar: appBar,
        body: destinos[idx].pantalla,
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) => setState(() => _indice = i),
          destinations: destinos.map((d) => NavigationDestination(
            icon: Icon(d.icono), selectedIcon: Icon(d.iconoActivo), label: d.label,
          )).toList(),
        ),
      );
    } else {
      // ── PC: navigation rail lateral ──────────────────────────────────────
      return Scaffold(
        appBar: appBar,
        body: Row(children: [
          NavigationRail(
            selectedIndex: idx,
            onDestinationSelected: (i) => setState(() => _indice = i),
            labelType: NavigationRailLabelType.all,
            destinations: destinos.map((d) => NavigationRailDestination(
              icon: Icon(d.icono), selectedIcon: Icon(d.iconoActivo), label: Text(d.label),
            )).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: destinos[idx].pantalla),
        ]),
      );
    }
  }
}

class _Destino {
  final IconData icono, iconoActivo;
  final String label;
  final Widget pantalla;
  _Destino(this.icono, this.iconoActivo, this.label, this.pantalla);
}

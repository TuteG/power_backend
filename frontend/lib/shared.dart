import 'package:flutter/material.dart';

// ── COLORES ───────────────────────────────────────────────────────────────────
const kPrimario = Color(0xFF1565C0);
const kAcento   = Color(0xFF0288D1);
const kAlerta   = Color(0xFFE53935);
const kOk       = Color(0xFF43A047);
const kWarn     = Color(0xFFFB8C00);

// ── TEMA ─────────────────────────────────────────────────────────────────────
ThemeData temaClaro() => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: kPrimario,
  brightness: Brightness.light,
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    color: const Color(0xFFF0F4FF),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimario,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: kPrimario,
    selectedIconTheme: IconThemeData(color: Colors.white),
    unselectedIconTheme: IconThemeData(color: Color(0xAAFFFFFF)),
    selectedLabelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    unselectedLabelTextStyle: TextStyle(color: Color(0xAAFFFFFF)),
    indicatorColor: Color(0x44FFFFFF),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: kPrimario,
    indicatorColor: Color(0x44FFFFFF),
    iconTheme: WidgetStatePropertyAll(IconThemeData(color: Colors.white)),
    labelTextStyle: WidgetStatePropertyAll(TextStyle(color: Colors.white, fontSize: 11)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    filled: true,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kPrimario,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  ),
);

ThemeData temaOscuro() => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: kPrimario,
  brightness: Brightness.dark,
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    color: const Color(0xFF1E2A3A),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0D1B2A),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Color(0xFF0D1B2A),
    selectedIconTheme: IconThemeData(color: Colors.white),
    unselectedIconTheme: IconThemeData(color: Color(0xAAFFFFFF)),
    indicatorColor: Color(0x44FFFFFF),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Color(0xFF0D1B2A),
    indicatorColor: Color(0x44FFFFFF),
    iconTheme: WidgetStatePropertyAll(IconThemeData(color: Colors.white)),
    labelTextStyle: WidgetStatePropertyAll(TextStyle(color: Colors.white, fontSize: 11)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    filled: true,
  ),
);

// ── WIDGETS COMPARTIDOS ───────────────────────────────────────────────────────
class PPCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const PPCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    ),
  );
}

class SeccionTitulo extends StatelessWidget {
  final String texto;
  final IconData icono;
  const SeccionTitulo({super.key, required this.texto, required this.icono});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icono, color: kPrimario, size: 22),
    const SizedBox(width: 8),
    Text(texto, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
  ]);
}

class BadgeEstado extends StatelessWidget {
  final String label;
  final Color color;
  const BadgeEstado({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

class ConfirmDialog extends StatelessWidget {
  final String mensaje;
  final VoidCallback onConfirm;
  const ConfirmDialog({super.key, required this.mensaje, required this.onConfirm});

  static Future<void> show(BuildContext context, String mensaje, VoidCallback onConfirm) =>
    showDialog(context: context, builder: (_) => ConfirmDialog(mensaje: mensaje, onConfirm: onConfirm));

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    title: Row(children: [
      Icon(Icons.warning_amber_rounded, color: kWarn),
      const SizedBox(width: 8),
      const Text('Confirmar acción'),
    ]),
    content: Text(mensaje),
    actions: [
      OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: kAlerta),
        onPressed: () { Navigator.pop(context); onConfirm(); },
        child: const Text('Eliminar'),
      ),
    ],
  );
}

class AlertaSnack {
  static void ok(BuildContext context, String msg) => _show(context, msg, kOk, Icons.check_circle_outline);
  static void error(BuildContext context, String msg) => _show(context, msg, kAlerta, Icons.error_outline);

  static void _show(BuildContext context, String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

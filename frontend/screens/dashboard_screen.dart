import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/shared.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _maquinaSeleccionada;
  String? _insumoSeleccionado;
  final _contCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();

  Future<void> _guardar() async {
    final state = context.read<AppState>();
    if (_maquinaSeleccionada == null || _insumoSeleccionado == null || _contCtrl.text.isEmpty) {
      AlertaSnack.error(context, 'Completá todos los campos.');
      return;
    }
    final val = int.tryParse(_contCtrl.text);
    if (val == null) { AlertaSnack.error(context, 'El contador debe ser un número.'); return; }
    try {
      await state.registrarCambio(_maquinaSeleccionada!, _insumoSeleccionado!, val, _notaCtrl.text);
      _contCtrl.clear(); _notaCtrl.clear();
      if (mounted) AlertaSnack.ok(context, 'Registro guardado correctamente.');
    } on Exception catch (e) {
      if (mounted) AlertaSnack.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final esMovil = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SeccionTitulo(texto: 'Dashboard', icono: Icons.dashboard_rounded),
        const SizedBox(height: 16),

        // KPI Cards
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.maquinas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _KpiCard(maquina: state.maquinas[i]),
          ),
        ),
        const SizedBox(height: 20),

        // Panel registro + gráfica
        esMovil
            ? Column(children: [_panelRegistro(state), const SizedBox(height: 16), _panelGrafica(state)])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _panelRegistro(state)),
                const SizedBox(width: 16),
                Expanded(child: _panelGrafica(state)),
              ]),
      ]),
    );
  }

  Widget _panelRegistro(AppState state) => PPCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SeccionTitulo(texto: 'Registrar cambio', icono: Icons.add_task_rounded),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _maquinaSeleccionada,
        decoration: const InputDecoration(labelText: 'Máquina'),
        items: state.maquinas.map<DropdownMenuItem<String>>((m) =>
          DropdownMenuItem(value: m['nombre'], child: Text(m['nombre']))).toList(),
        onChanged: (v) => setState(() => _maquinaSeleccionada = v),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _insumoSeleccionado,
        decoration: const InputDecoration(labelText: 'Insumo'),
        items: state.stock.map<DropdownMenuItem<String>>((s) =>
          DropdownMenuItem(value: s['item'], child: Text(s['item']))).toList(),
        onChanged: (v) => setState(() => _insumoSeleccionado = v),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _contCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Lectura del contador'),
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _notaCtrl,
        decoration: const InputDecoration(labelText: 'Directiva / Nota'),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _guardar(),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: state.cargando ? null : _guardar,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Guardar registro'),
        ),
      ),
    ]),
  );

  Widget _panelGrafica(AppState state) {
    final maxVal = state.maquinas.fold<int>(1, (m, e) => e['contador'] > m ? e['contador'] : m);
    return PPCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SeccionTitulo(texto: 'Carga de trabajo', icono: Icons.bar_chart_rounded),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: state.maquinas.map<Widget>((m) {
              final pct = maxVal > 0 ? (m['contador'] as int) / maxVal : 0.0;
              final lim = (m['limite_mantenimiento'] as int);
              final uso = lim > 0 ? (m['contador'] as int) / lim : 0.0;
              final color = uso >= 0.8 ? kAlerta : uso >= 0.6 ? kWarn : kPrimario;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('${(uso * 100).toInt()}%', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: 120 * pct + 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(m['nombre'].toString().length > 6
                      ? m['nombre'].toString().substring(0, 6)
                      : m['nombre'].toString(),
                    style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                ]),
              ));
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final dynamic maquina;
  const _KpiCard({required this.maquina});

  @override
  Widget build(BuildContext context) {
    final contador = maquina['contador'] as int;
    final limite   = maquina['limite_mantenimiento'] as int;
    final pct      = limite > 0 ? contador / limite : 0.0;
    final alerta   = pct >= 0.8;
    final color    = alerta ? kAlerta : pct >= 0.6 ? kWarn : kPrimario;

    return SizedBox(
      width: 150,
      child: PPCard(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.print_rounded, color: color, size: 28),
          const SizedBox(height: 6),
          Text(maquina['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${contador.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: pct.clamp(0.0, 1.0), color: color,
            backgroundColor: color.withOpacity(0.2), borderRadius: BorderRadius.circular(3)),
          const SizedBox(height: 4),
          Text('${(pct * 100).toInt()}% uso', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          if (alerta) ...[
            const SizedBox(height: 4),
            BadgeEstado(label: '⚠ REVISAR', color: kAlerta),
          ],
        ]),
      ),
    );
  }
}

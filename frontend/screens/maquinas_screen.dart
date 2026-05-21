import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/shared.dart';

class MaquinasScreen extends StatelessWidget {
  const MaquinasScreen({super.key});

  void _abrirModal(BuildContext context, AppState state, {dynamic maquina}) {
    final nombreCtrl  = TextEditingController(text: maquina?['nombre'] ?? '');
    final contCtrl    = TextEditingController(text: maquina?['contador']?.toString() ?? '0');
    final limiteCtrl  = TextEditingController(
        text: maquina?['limite_mantenimiento']?.toString() ?? '50000');
    final editando    = maquina != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          Icon(Icons.print_rounded, color: kPrimario),
          const SizedBox(width: 8),
          Text(editando ? 'Editar máquina' : 'Agregar máquina'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!editando) TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre de la máquina'),
            autofocus: true,
          ),
          if (!editando) const SizedBox(height: 10),
          TextField(
            controller: contCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Contador actual'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: limiteCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Límite de mantenimiento'),
          ),
        ]),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (editando) {
                  await state.editarMaquina(maquina!['nombre'],
                    contador: int.tryParse(contCtrl.text),
                    limite:   int.tryParse(limiteCtrl.text));
                } else {
                  await state.agregarMaquina(
                    nombreCtrl.text.trim(),
                    int.tryParse(contCtrl.text)   ?? 0,
                    int.tryParse(limiteCtrl.text) ?? 50000,
                  );
                }
                if (context.mounted) AlertaSnack.ok(context, 'Guardado correctamente.');
              } catch (e) {
                if (context.mounted) AlertaSnack.error(context, e.toString());
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SeccionTitulo(texto: 'Equipos registrados', icono: Icons.print_rounded),
          const Spacer(),
          if (state.esAdmin)
            FilledButton.icon(
              onPressed: () => _abrirModal(context, state),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar'),
            ),
        ]),
        const SizedBox(height: 16),

        if (state.maquinas.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Text('Sin máquinas registradas.', style: TextStyle(color: Colors.grey)),
          ))
        else
          Expanded(
            child: ListView.separated(
              itemCount: state.maquinas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m      = state.maquinas[i];
                final cont   = m['contador'] as int;
                final lim    = m['limite_mantenimiento'] as int;
                final pct    = lim > 0 ? cont / lim : 0.0;
                final alerta = pct >= 0.8;
                final color  = alerta ? kAlerta : pct >= 0.6 ? kWarn : kOk;

                return PPCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.print_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Contador: $cont  |  Límite: $lim',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        color: color,
                        backgroundColor: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ])),
                    const SizedBox(width: 8),
                    if (alerta) BadgeEstado(label: '⚠ REVISAR', color: kAlerta),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      color: kAcento,
                      onPressed: () => _abrirModal(context, state, maquina: m),
                    ),
                    if (state.esAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, size: 20),
                        color: kAlerta,
                        onPressed: () => ConfirmDialog.show(
                          context, '¿Borrar "${m['nombre']}"?',
                          () => state.borrarMaquina(m['nombre']),
                        ),
                      ),
                  ]),
                );
              },
            ),
          ),
      ]),
    );
  }
}

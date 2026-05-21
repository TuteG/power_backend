import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/shared.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  void _abrirModal(BuildContext context, AppState state, {dynamic item}) {
    final nombreCtrl   = TextEditingController(text: item?['item'] ?? '');
    final cantidadCtrl = TextEditingController(text: item?['cantidad']?.toString() ?? '');
    final minimoCtrl   = TextEditingController(text: item?['minimo']?.toString() ?? '2');
    final editando     = item != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          Icon(Icons.inventory_2_rounded, color: kPrimario),
          const SizedBox(width: 8),
          Text(editando ? 'Editar insumo' : 'Agregar insumo'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!editando) TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre del insumo'),
            autofocus: true,
          ),
          if (!editando) const SizedBox(height: 10),
          TextField(
            controller: cantidadCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cantidad'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: minimoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Mínimo'),
          ),
        ]),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (editando) {
                  await state.editarStock(item!['item'],
                    cantidad: int.tryParse(cantidadCtrl.text),
                    minimo:   int.tryParse(minimoCtrl.text));
                } else {
                  await state.agregarStock(
                    nombreCtrl.text.trim(),
                    int.tryParse(cantidadCtrl.text) ?? 0,
                    int.tryParse(minimoCtrl.text)   ?? 2,
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
          const SeccionTitulo(texto: 'Inventario de insumos', icono: Icons.inventory_2_rounded),
          const Spacer(),
          if (state.esAdmin)
            FilledButton.icon(
              onPressed: () => _abrirModal(context, state),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar'),
            ),
        ]),
        const SizedBox(height: 16),

        if (state.stock.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Text('Sin insumos registrados.', style: TextStyle(color: Colors.grey)),
          ))
        else
          Expanded(
            child: ListView.separated(
              itemCount: state.stock.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s    = state.stock[i];
                final bajo = (s['cantidad'] as int) <= (s['minimo'] as int);
                return PPCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bajo ? kAlerta : kOk,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['item'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Stock: ${s['cantidad']}  |  Mínimo: ${s['minimo']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ])),
                    BadgeEstado(label: bajo ? 'BAJO' : 'OK', color: bajo ? kAlerta : kOk),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      color: kAcento,
                      onPressed: () => _abrirModal(context, state, item: s),
                    ),
                    if (state.esAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, size: 20),
                        color: kAlerta,
                        onPressed: () => ConfirmDialog.show(
                          context, '¿Borrar "${s['item']}"?',
                          () => state.borrarStock(s['item']),
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

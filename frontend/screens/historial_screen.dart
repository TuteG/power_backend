import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/shared.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});
  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _busqCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SeccionTitulo(texto: 'Historial de operaciones', icono: Icons.history_rounded),
        const SizedBox(height: 16),

        // Barra búsqueda
        Row(children: [
          Expanded(
            child: TextField(
              controller: _busqCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar en historial…',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => state.buscarLog(v),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: kPrimario),
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => state.buscarLog(_busqCtrl.text),
          ),
          if (state.esAdmin) ...[
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: kAlerta),
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              tooltip: 'Vaciar historial',
              onPressed: () => ConfirmDialog.show(
                context, '¿Vaciar todo el historial?', state.vaciarLog),
            ),
          ],
        ]),
        const SizedBox(height: 16),

        if (state.log.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Text('Sin registros.', style: TextStyle(color: Colors.grey)),
          ))
        else
          Expanded(
            child: ListView.separated(
              itemCount: state.log.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final e = state.log[i];
                return PPCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.history_rounded, color: kAcento, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(
                        '${e['maquina']}  ›  ${e['insumo']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                      Text(e['fecha'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      if (state.esAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: kAlerta,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => ConfirmDialog.show(
                            context, '¿Borrar este registro?',
                            () => state.borrarLog(e['id'] as int),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      BadgeEstado(
                        label: '▲ ${e['rendimiento']} copias',
                        color: kPrimario,
                      ),
                      const SizedBox(width: 8),
                      if ((e['nota'] ?? '').isNotEmpty)
                        Expanded(child: Text(
                          'Nota: ${e['nota']}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        )),
                    ]),
                  ]),
                );
              },
            ),
          ),
      ]),
    );
  }
}

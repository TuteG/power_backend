import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/shared.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _abrirModal(BuildContext context, AppState state) {
    final userCtrl  = TextEditingController();
    final claveCtrl = TextEditingController();
    String rol      = 'Operador';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(children: [
            Icon(Icons.person_add_rounded, color: kPrimario),
            const SizedBox(width: 8),
            const Text('Agregar usuario'),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de usuario'),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: claveCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: rol,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: const [
                DropdownMenuItem(value: 'Operador', child: Text('Operador')),
                DropdownMenuItem(value: 'Admin',    child: Text('Admin')),
              ],
              onChanged: (v) => setModalState(() => rol = v!),
            ),
          ]),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await state.agregarUsuario(userCtrl.text.trim(), claveCtrl.text, rol);
                  if (context.mounted) AlertaSnack.ok(context, 'Usuario creado correctamente.');
                } catch (e) {
                  if (context.mounted) AlertaSnack.error(context, e.toString());
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
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
          const SeccionTitulo(texto: 'Gestión de usuarios', icono: Icons.people_rounded),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _abrirModal(context, state),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Agregar'),
          ),
        ]),
        const SizedBox(height: 16),

        if (state.usuarios.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Text('Sin usuarios.', style: TextStyle(color: Colors.grey)),
          ))
        else
          Expanded(
            child: ListView.separated(
              itemCount: state.usuarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final u      = state.usuarios[i];
                final esAdm  = u['rol'] == 'Admin';
                return PPCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: esAdm ? kPrimario : kAcento,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u['usuario'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(u['rol'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ])),
                    BadgeEstado(label: u['rol'], color: esAdm ? kPrimario : kAcento),
                    if (u['usuario'] != 'admin')
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, size: 20),
                        color: kAlerta,
                        onPressed: () => ConfirmDialog.show(
                          context, '¿Borrar usuario "${u['usuario']}"?',
                          () => state.borrarUsuario(u['usuario']),
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

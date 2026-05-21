import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  String? usuario;
  String? rol;
  bool cargando = false;
  String? error;

  List<dynamic> maquinas = [];
  List<dynamic> stock    = [];
  List<dynamic> log      = [];
  List<dynamic> usuarios = [];

  bool get esAdmin => rol == 'Admin';
  bool get logueado => usuario != null;

  // ── AUTH ──────────────────────────────────────────────────────────────────
  Future<bool> login(String u, String c) async {
    _setCargando(true);
    try {
      final data = await ApiService.login(u, c);
      usuario = data['usuario'];
      rol     = data['rol'];
      await cargarTodo();
      return true;
    } on ApiException catch (e) {
      error = e.mensaje;
      notifyListeners();
      return false;
    } finally {
      _setCargando(false);
    }
  }

  Future<void> logout() async {
    await ApiService.borrarToken();
    usuario  = null;
    rol      = null;
    maquinas = [];
    stock    = [];
    log      = [];
    usuarios = [];
    notifyListeners();
  }

  Future<bool> restaurarSesion() async {
    final token = await ApiService.cargarToken();
    if (token == null) return false;
    try {
      final data = await ApiService.get('/me');
      usuario = data['usuario'];
      rol     = data['rol'];
      await cargarTodo();
      return true;
    } catch (_) {
      await ApiService.borrarToken();
      return false;
    }
  }

  // ── CARGA ─────────────────────────────────────────────────────────────────
  Future<void> cargarTodo() async {
    _setCargando(true);
    try {
      final results = await Future.wait([
        ApiService.getMaquinas(),
        ApiService.getStock(),
        ApiService.getLog(),
        if (esAdmin) ApiService.getUsuarios(),
      ]);
      maquinas = results[0];
      stock    = results[1];
      log      = results[2];
      if (esAdmin) usuarios = results[3];
      error = null;
    } on ApiException catch (e) {
      error = e.mensaje;
    } finally {
      _setCargando(false);
    }
  }

  Future<void> buscarLog(String termino) async {
    try {
      log = await ApiService.getLog(buscar: termino);
      notifyListeners();
    } catch (_) {}
  }

  // ── MÁQUINAS ──────────────────────────────────────────────────────────────
  Future<void> agregarMaquina(String nombre, int contador, int limite) async {
    await _accion(() => ApiService.crearMaquina(nombre, contador, limite));
  }

  Future<void> editarMaquina(String nombre, {int? contador, int? limite}) async {
    await _accion(() => ApiService.editarMaquina(nombre, contador: contador, limite: limite));
  }

  Future<void> borrarMaquina(String nombre) async {
    await _accion(() => ApiService.borrarMaquina(nombre));
  }

  // ── STOCK ─────────────────────────────────────────────────────────────────
  Future<void> agregarStock(String item, int cantidad, int minimo) async {
    await _accion(() => ApiService.crearStock(item, cantidad, minimo));
  }

  Future<void> editarStock(String item, {int? cantidad, int? minimo}) async {
    await _accion(() => ApiService.editarStock(item, cantidad: cantidad, minimo: minimo));
  }

  Future<void> borrarStock(String item) async {
    await _accion(() => ApiService.borrarStock(item));
  }

  // ── LOG ───────────────────────────────────────────────────────────────────
  Future<void> registrarCambio(String maquina, String insumo, int contador, String nota) async {
    await _accion(() => ApiService.crearLog(maquina, insumo, contador, nota));
  }

  Future<void> borrarLog(int id) async {
    await _accion(() => ApiService.borrarLog(id));
  }

  Future<void> vaciarLog() async {
    await _accion(() => ApiService.vaciarLog());
  }

  // ── USUARIOS ──────────────────────────────────────────────────────────────
  Future<void> agregarUsuario(String u, String c, String r) async {
    await _accion(() => ApiService.crearUsuario(u, c, r));
  }

  Future<void> borrarUsuario(String u) async {
    await _accion(() => ApiService.borrarUsuario(u));
  }

  // ── HELPER ────────────────────────────────────────────────────────────────
  Future<void> _accion(Future Function() fn) async {
    try {
      await fn();
      await cargarTodo();
    } on ApiException catch (e) {
      error = e.mensaje;
      notifyListeners();
      rethrow;
    }
  }

  void _setCargando(bool v) {
    cargando = v;
    notifyListeners();
  }

  void limpiarError() {
    error = null;
    notifyListeners();
  }
}

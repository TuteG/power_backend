import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ⚠️ Cambiá esta URL por la que te da Railway al hacer el deploy
const String BASE_URL = 'https://TU-APP.up.railway.app';

class ApiService {
  static String? _token;

  // ── TOKEN ──────────────────────────────────────────────────────────────────
  static Future<void> guardarToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> cargarToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  static Future<void> borrarToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ── HEADERS ───────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await cargarToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── HTTP HELPERS ──────────────────────────────────────────────────────────
  static Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$BASE_URL$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers());
    _check(res);
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$BASE_URL$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _check(res);
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$BASE_URL$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _check(res);
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$BASE_URL$path'),
      headers: await _headers(),
    );
    _check(res);
  }

  static void _check(http.Response res) {
    if (res.statusCode == 401) throw ApiException('Sesión expirada. Volvé a iniciar sesión.');
    if (res.statusCode == 403) throw ApiException('Sin permisos para esta acción.');
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw ApiException(body['detail'] ?? 'Error del servidor');
    }
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String usuario, String clave) async {
    final data = await post('/login', {'usuario': usuario, 'clave': clave});
    await guardarToken(data['token']);
    return data;
  }

  // ── MÁQUINAS ──────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getMaquinas() => get('/maquinas');
  static Future<dynamic> crearMaquina(String nombre, int contador, int limite) =>
      post('/maquinas', {'nombre': nombre, 'contador': contador, 'limite_mantenimiento': limite});
  static Future<dynamic> editarMaquina(String nombre, {int? contador, int? limite}) =>
      put('/maquinas/$nombre', {
        if (contador != null) 'contador': contador,
        if (limite != null) 'limite_mantenimiento': limite,
      });
  static Future<void> borrarMaquina(String nombre) => delete('/maquinas/$nombre');

  // ── STOCK ─────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getStock() => get('/stock');
  static Future<dynamic> crearStock(String item, int cantidad, int minimo) =>
      post('/stock', {'item': item, 'cantidad': cantidad, 'minimo': minimo});
  static Future<dynamic> editarStock(String item, {int? cantidad, int? minimo}) =>
      put('/stock/$item', {
        if (cantidad != null) 'cantidad': cantidad,
        if (minimo != null) 'minimo': minimo,
      });
  static Future<void> borrarStock(String item) => delete('/stock/$item');

  // ── LOG ───────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getLog({String buscar = ''}) =>
      get('/log', query: buscar.isNotEmpty ? {'buscar': buscar} : null);
  static Future<dynamic> crearLog(String maquina, String insumo, int contador, String nota) =>
      post('/log', {'maquina': maquina, 'insumo': insumo, 'contador': contador, 'nota': nota});
  static Future<void> borrarLog(int id) => delete('/log/$id');
  static Future<void> vaciarLog() => delete('/log');

  // ── USUARIOS ──────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getUsuarios() => get('/usuarios');
  static Future<dynamic> crearUsuario(String usuario, String clave, String rol) =>
      post('/usuarios', {'usuario': usuario, 'clave': clave, 'rol': rol});
  static Future<void> borrarUsuario(String usuario) => delete('/usuarios/$usuario');
}

class ApiException implements Exception {
  final String mensaje;
  ApiException(this.mensaje);
  @override
  String toString() => mensaje;
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'constants.dart';
import 'drawable.dart';

const streamingModel = 'granite4:3b';
const functionCallingModel = 'granite4:3b';
const jsonFixModel = 'granite4:3b';

class AppData extends ChangeNotifier {
  String _responseText = '';
  bool _isLoading = false;
  bool _isInitial = true;
  int _idCounter = 0;

  http.Client? _client;
  IOClient? _ioClient;
  HttpClient? _httpClient;
  StreamSubscription<String>? _streamSubscription;

  final List<Drawable> drawables = [];
  Size canvasSize = const Size(900, 600);
  String? selectedId;

  String get responseText => _isInitial
      ? 'Escriu una ordre per començar. Per exemple: dibuixa un cercle blau amb contorn negre al centre.'
      : (_isLoading ? 'Esperant resposta de la IA...' : _responseText);

  bool get isLoading => _isLoading;
  Drawable? get selectedDrawable => _findById(selectedId);

  AppData() {
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
  }

  String _nextId(String prefix) {
    _idCounter++;
    return '$prefix$_idCounter';
  }

  void setCanvasSize(Size size) {
    if (size.width > 0 && size.height > 0 && canvasSize != size) {
      canvasSize = size;
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addDrawable(Drawable drawable) {
    drawables.add(drawable);
    selectDrawable(drawable.id);
    _addInfo('Creat ${drawable.id}');
  }

  void clearCanvas() {
    drawables.clear();
    selectedId = null;
    _addInfo('Dibuix esborrat');
    notifyListeners();
  }

  void selectDrawable(String? id) {
    selectedId = id;
    for (final drawable in drawables) {
      drawable.selected = drawable.id == id;
    }
    notifyListeners();
  }

  void selectAt(Offset point) {
    for (final drawable in drawables.reversed) {
      if (drawable.containsPoint(point)) {
        selectDrawable(drawable.id);
        _addInfo('Seleccionat ${drawable.id}');
        return;
      }
    }
    selectDrawable(null);
  }

  void deleteSelected() {
    if (selectedId == null) return;
    deleteDrawable(selectedId!);
  }

  void deleteDrawable(String id) {
    drawables.removeWhere((drawable) => drawable.id == id);
    if (selectedId == id) selectedId = null;
    _addInfo('Esborrat $id');
    notifyListeners();
  }

  Drawable? _findById(String? id) {
    if (id == null) return null;
    for (final drawable in drawables) {
      if (drawable.id == id) return drawable;
    }
    return null;
  }

  void _addInfo(String text) {
    _isInitial = false;
    _responseText = '$_responseText\n$text'.trim();
  }

  Future<void> callStream({required String question}) async {
    _isInitial = false;
    setLoading(true);

    try {
      final request = http.Request(
        'POST',
        Uri.parse('http://localhost:11434/api/generate'),
      );

      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = jsonEncode({
        'model': streamingModel,
        'prompt': question,
        'stream': true,
      });

      final streamedResponse = await _client!.send(request);
      _streamSubscription = streamedResponse.stream.transform(utf8.decoder).listen(
        (value) {
          final jsonResponse = jsonDecode(value);
          final jsonResponseStr = jsonResponse['response'];
          _responseText = '$_responseText\n$jsonResponseStr';
          notifyListeners();
        },
        onError: (error) {
          _addInfo('Error durant el streaming: $error');
          setLoading(false);
        },
        onDone: () {
          setLoading(false);
        },
      );
    } catch (e) {
      _addInfo('Error durant el streaming. Revisa que Ollama estigui obert.');
      setLoading(false);
    }
  }

  Future<void> callWithCustomTools({required String userPrompt}) async {
    const apiUrl = 'http://localhost:11434/api/chat';
    _isInitial = false;
    setLoading(true);

    final body = {
      'model': functionCallingModel,
      'stream': false,
      'messages': [
        {
          'role': 'system',
          'content': '''
Ets una IA que controla una eina de dibuix vectorial Flutter.
Has de respondre fent servir function calls sempre que l'usuari demani dibuixar, seleccionar, esborrar o modificar figures.
El canvas fa aproximadament ${canvasSize.width.toStringAsFixed(0)} x ${canvasSize.height.toStringAsFixed(0)} píxels.
Pots usar ids de figures com circle1, line2, rect3, text4.
Si l'usuari diu centre, meitat o 50%, calcula coordenades aproximades segons la mida del canvas.
'''
        },
        {'role': 'user', 'content': userPrompt}
      ],
      'tools': tools,
    };

    try {
      final response = await _client!.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final toolCalls = jsonResponse['message']?['tool_calls'];

        if (toolCalls is List && toolCalls.isNotEmpty) {
          for (final tc in toolCalls) {
            final cleanedCall = cleanKeys(tc);
            if (cleanedCall['function'] != null) {
              await _processFunctionCall(cleanedCall['function']);
            }
          }
        } else {
          final message = jsonResponse['message']?['content']?.toString();
          _addInfo(message?.isNotEmpty == true ? message! : 'La IA no ha retornat cap acció.');
        }
      } else {
        _addInfo('Error Ollama ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _addInfo('Error durant la crida a Ollama: $e');
    } finally {
      setLoading(false);
    }
  }

  void cancelRequests() {
    _streamSubscription?.cancel();
    _httpClient?.close(force: true);
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
    _addInfo('Petició cancel·lada.');
    setLoading(false);
  }

  dynamic cleanKeys(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((k, v) {
        result[k.toString().trim()] = cleanKeys(v);
      });
      return result;
    }
    if (value is List) return value.map(cleanKeys).toList();
    return value;
  }

  Future<dynamic> fixJsonInStrings(dynamic data) async {
    if (data is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in data.entries) {
        result[entry.key] = await fixJsonInStrings(entry.value);
      }
      return result;
    } else if (data is List) {
      return Future.wait(data.map((value) => fixJsonInStrings(value)));
    } else if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return data;

      try {
        final parsed = jsonDecode(data);
        return fixJsonInStrings(parsed);
      } catch (_) {
        if (_looksLikeJsonCandidate(trimmed)) {
          final repairedJson = await _repairJsonWithAi(trimmed);
          if (repairedJson != null) return fixJsonInStrings(repairedJson);
        }
        return data;
      }
    }
    return data;
  }

  bool _looksLikeJsonCandidate(String value) {
    return value.startsWith('{') ||
        value.startsWith('[') ||
        ((value.contains('{') || value.contains('[')) && value.contains(':'));
  }

  Future<dynamic> _repairJsonWithAi(String rawJson) async {
    const apiUrl = 'http://localhost:11434/api/chat';
    final body = {
      'model': jsonFixModel,
      'stream': false,
      'format': 'json',
      'messages': [
        {
          'role': 'system',
          'content': 'Repair malformed JSON. Return only valid JSON.'
        },
        {'role': 'user', 'content': 'Repair this JSON:\n$rawJson'}
      ]
    };

    try {
      final response = await _client!.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) return null;
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['message']?['content'];
      if (content is! String || content.trim().isEmpty) return null;
      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  double parseDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();

    final text = value.toString().trim().toLowerCase().replaceAll(',', '.');
    final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(text);
    if (percentMatch != null) {
      return double.parse(percentMatch.group(1)!) / 100;
    }

    return double.tryParse(text) ?? fallback;
  }

  double parsePosition(dynamic value, {required bool isX, double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();

    final dimension = isX ? canvasSize.width : canvasSize.height;
    final text = value.toString().trim().toLowerCase().replaceAll(',', '.');

    final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(text);
    if (percentMatch != null) {
      return dimension * (double.parse(percentMatch.group(1)!) / 100);
    }

    if (text.contains('centre') || text.contains('centro') || text.contains('center') || text.contains('meitat') || text.contains('mitad')) {
      return dimension / 2;
    }
    if (text.contains('dreta') || text.contains('derecha') || text.contains('right')) return dimension * 0.8;
    if (text.contains('esquerra') || text.contains('izquierda') || text.contains('left')) return dimension * 0.2;
    if (text.contains('baix') || text.contains('abajo') || text.contains('bottom')) return dimension * 0.8;
    if (text.contains('dalt') || text.contains('arriba') || text.contains('top')) return dimension * 0.2;

    return double.tryParse(text) ?? fallback;
  }

  Color parseColor(dynamic value, Color fallback) {
    return parseDrawableColor(value) ?? fallback;
  }

  Color? parseOptionalColor(dynamic value) {
    return parseDrawableColor(value);
  }

  double _randomBetween(double min, double max) {
    return min + Random().nextDouble() * (max - min);
  }

  Future<void> _processFunctionCall(Map<String, dynamic> functionCall) async {
    final fixedJson = await fixJsonInStrings(functionCall);
    final parametersData = fixedJson['arguments'];
    final parameters = parametersData is Map<String, dynamic>
        ? parametersData
        : <String, dynamic>{};

    final name = fixedJson['name'].toString();
    _addInfo('Acció $name: $parameters');

    switch (name) {
      case 'draw_circle':
        _drawCircle(parameters);
        break;
      case 'draw_line':
        _drawLine(parameters);
        break;
      case 'draw_rectangle':
        _drawRectangle(parameters);
        break;
      case 'draw_square':
        _drawSquare(parameters);
        break;
      case 'draw_text':
        _drawText(parameters);
        break;
      case 'select_shape':
        _selectShape(parameters);
        break;
      case 'delete_shape':
        _deleteShape(parameters);
        break;
      case 'update_shape':
        _updateShape(parameters);
        break;
      case 'clear_canvas':
        clearCanvas();
        break;
      default:
        _addInfo('Funció desconeguda: $name');
    }
  }

  void _drawCircle(Map<String, dynamic> p) {
    final x = parsePosition(p['x'] ?? p['centerX'], isX: true, fallback: canvasSize.width / 2);
    final y = parsePosition(p['y'] ?? p['centerY'], isX: false, fallback: canvasSize.height / 2);
    final radius = parseDouble(p['radius'], fallback: 40);

    addDrawable(
      CircleShape(
        id: _nextId('circle'),
        center: Offset(x, y),
        radius: max(1, radius),
        fillColor: parseOptionalColor(p['fillColor']),
        strokeColor: parseColor(p['strokeColor'] ?? p['color'], Colors.black),
        strokeWidth: max(1, parseDouble(p['strokeWidth'], fallback: 2)),
      ),
    );
  }

  void _drawLine(Map<String, dynamic> p) {
    final start = Offset(
      parsePosition(p['startX'] ?? p['x1'], isX: true, fallback: _randomBetween(30, 160)),
      parsePosition(p['startY'] ?? p['y1'], isX: false, fallback: _randomBetween(30, 160)),
    );
    final end = Offset(
      parsePosition(p['endX'] ?? p['x2'], isX: true, fallback: _randomBetween(200, 500)),
      parsePosition(p['endY'] ?? p['y2'], isX: false, fallback: _randomBetween(200, 400)),
    );

    addDrawable(
      Line(
        id: _nextId('line'),
        start: start,
        end: end,
        color: parseColor(p['color'] ?? p['strokeColor'], Colors.black),
        strokeWidth: max(1, parseDouble(p['strokeWidth'], fallback: 2)),
      ),
    );
  }

  void _drawRectangle(Map<String, dynamic> p) {
    final x = parsePosition(p['topLeftX'] ?? p['x'], isX: true, fallback: 80);
    final y = parsePosition(p['topLeftY'] ?? p['y'], isX: false, fallback: 80);
    final width = parseDouble(p['width'], fallback: 180);
    final height = parseDouble(p['height'], fallback: 110);
    final bottomRightX = parsePosition(p['bottomRightX'], isX: true, fallback: x + width);
    final bottomRightY = parsePosition(p['bottomRightY'], isX: false, fallback: y + height);

    addDrawable(
      RectangleShape(
        id: _nextId('rect'),
        topLeft: Offset(x, y),
        bottomRight: Offset(bottomRightX, bottomRightY),
        fillColor: parseOptionalColor(p['fillColor']),
        strokeColor: parseColor(p['strokeColor'] ?? p['borderColor'] ?? p['color'], Colors.black),
        strokeWidth: max(1, parseDouble(p['strokeWidth'], fallback: 2)),
        gradientStartColor: parseOptionalColor(p['gradientStartColor'] ?? p['gradientStart']),
        gradientEndColor: parseOptionalColor(p['gradientEndColor'] ?? p['gradientEnd']),
      ),
    );
  }

  void _drawSquare(Map<String, dynamic> p) {
    final x = parsePosition(p['x'], isX: true, fallback: 120);
    final y = parsePosition(p['y'], isX: false, fallback: 120);
    final size = parseDouble(p['size'], fallback: 120);

    addDrawable(
      RectangleShape(
        id: _nextId('square'),
        topLeft: Offset(x, y),
        bottomRight: Offset(x + size, y + size),
        fillColor: parseOptionalColor(p['fillColor']),
        strokeColor: parseColor(p['strokeColor'] ?? p['borderColor'] ?? p['color'], Colors.black),
        strokeWidth: max(1, parseDouble(p['strokeWidth'], fallback: 2)),
        gradientStartColor: parseOptionalColor(p['gradientStartColor'] ?? p['gradientStart']),
        gradientEndColor: parseOptionalColor(p['gradientEndColor'] ?? p['gradientEnd']),
      ),
    );
  }

  void _drawText(Map<String, dynamic> p) {
    final text = (p['text'] ?? p['content'] ?? 'Text').toString();
    final x = parsePosition(p['x'], isX: true, fallback: 100);
    final y = parsePosition(p['y'], isX: false, fallback: 100);

    addDrawable(
      TextElement(
        id: _nextId('text'),
        text: text,
        position: Offset(x, y),
        color: parseColor(p['color'], Colors.black),
        fontSize: max(6, parseDouble(p['fontSize'] ?? p['size'], fallback: 24)),
        bold: p['bold'] == true || p['style']?.toString().toLowerCase().contains('bold') == true || p['style']?.toString().toLowerCase().contains('negreta') == true,
        fontFamily: p['fontFamily']?.toString(),
      ),
    );
  }

  void _selectShape(Map<String, dynamic> p) {
    final id = p['id']?.toString();
    if (id != null && _findById(id) != null) {
      selectDrawable(id);
      _addInfo('Seleccionat $id');
      return;
    }

    if (drawables.isNotEmpty) {
      selectDrawable(drawables.last.id);
      _addInfo('Seleccionada la darrera figura: ${drawables.last.id}');
    }
  }

  void _deleteShape(Map<String, dynamic> p) {
    final id = p['id']?.toString() ?? selectedId;
    if (id == null) {
      _addInfo('No hi ha cap figura seleccionada per esborrar.');
      return;
    }
    deleteDrawable(id);
  }

  void _updateShape(Map<String, dynamic> p) {
    final id = p['id']?.toString() ?? selectedId;
    final drawable = _findById(id);
    if (drawable == null) {
      _addInfo('No s’ha trobat cap figura per modificar.');
      return;
    }

    final normalized = Map<String, dynamic>.from(p);
    if (normalized.containsKey('x')) {
      normalized['x'] = parsePosition(normalized['x'], isX: true, fallback: 0);
    }
    if (normalized.containsKey('y')) {
      normalized['y'] = parsePosition(normalized['y'], isX: false, fallback: 0);
    }

    drawable.updateFromMap(normalized);
    selectDrawable(drawable.id);
    _addInfo('Modificat ${drawable.id}');
    notifyListeners();
  }
}

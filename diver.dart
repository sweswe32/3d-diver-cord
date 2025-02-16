import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(DiverMapApp());

class DiverMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3D Diver Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => DiverMapScreen(),
        '/coordinates': (context) => CoordinatesScreen(
              diver: ModalRoute.of(context)!.settings.arguments as Diver,
            ),
      },
    );
  }
}

class Position {
  double x;
  double y;
  double z;

  Position({this.x = 0, this.y = 0, this.z = 0});

  Offset toOffset(Size screenSize) => Offset(
        screenSize.width / 2 + x,
        screenSize.height / 2 - y, // Инвертируем Y для декартовой системы
      );
}

class Diver with ChangeNotifier {
  Position _position = Position();
  double _depth = 0;
  final List<Map<String, dynamic>> _movementHistory = [];
  final List<MapMarker> _markers = [];

  Position get position => _position;
  double get depth => _depth;
  List<Map<String, dynamic>> get movementHistory => _movementHistory;
  List<MapMarker> get markers => _markers;

  void updatePosition(double dx, double dy) {
    _movementHistory.add({
      'position': Position(x: _position.x, y: _position.y, z: _position.z),
      'time': DateTime.now(),
    });
    _position.x += dx;
    _position.y += dy;
    notifyListeners();
  }

  void updateDepth(double delta) {
    _position.z += delta;
    _depth = _position.z;
    notifyListeners();
  }

  void addMarker(MapMarker marker) {
    _markers.add(marker);
    notifyListeners();
  }

  void reset() {
    _position = Position();
    _depth = 0;
    _movementHistory.clear();
    _markers.clear();
    notifyListeners();
  }
}

class MapMarker {
  final String type;
  final Position position;
  final DateTime date;
  final Color color;

  const MapMarker({
    required this.type,
    required this.position,
    required this.date,
    this.color = Colors.red,
  });
}

class DiverMapScreen extends StatefulWidget {
  @override
  _DiverMapScreenState createState() => _DiverMapScreenState();
}

class _DiverMapScreenState extends State<DiverMapScreen> {
  late Diver _diver;
  bool _sortAscending = true;
  Matrix4 _transform = Matrix4.identity();
  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;
  late Size _screenSize;

  @override
  void initState() {
    super.initState();
    _diver = Diver();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenSize = MediaQuery.of(context).size;
    });
  }

  void _addMarker(String type) {
    _diver.addMarker(MapMarker(
      type: type,
      position: Position(
        x: _diver.position.x,
        y: _diver.position.y,
        z: _diver.position.z,
      ),
      date: DateTime.now(),
      color:
          type == 'Communication' ? Colors.green.shade700 : Colors.red.shade700,
    ));
  }

  void _sortMarkers() {
    setState(() {
      _diver.markers.sort((a, b) =>
          _sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
      _sortAscending = !_sortAscending;
    });
  }

  void _clearMap() => _diver.reset();

  void _navigateToCoordinates() {
    Navigator.pushNamed(context, '/coordinates', arguments: _diver);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _currentOffset = details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.scale != 1.0) {
        _currentScale = (_currentScale * details.scale).clamp(0.5, 3.0);
        _transform = Matrix4.identity()
          ..translate(_currentOffset.dx, _currentOffset.dy)
          ..scale(_currentScale)
          ..translate(-_currentOffset.dx, -_currentOffset.dy);
      }

      if (details.pointerCount == 1 && details.scale == 1.0) {
        final offset = details.focalPointDelta;
        _diver.updatePosition(
          offset.dx / _currentScale,
          -offset.dy / _currentScale, // Инверсия для декартовой системы
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Diver Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearMap,
            tooltip: 'Clear Map',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _navigateToCoordinates,
            tooltip: 'Show Coordinates',
          ),
          IconButton(
            icon: Icon(
                _sortAscending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: _sortMarkers,
            tooltip: 'Sort by Date',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            child: Transform(
              transform: _transform,
              child: Stack(
                children: [
                  CustomPaint(
                    painter: MapPainter(
                      diver: _diver,
                      screenSize: _screenSize,
                      scale: _currentScale,
                    ),
                    size: _screenSize,
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: _buildCoordinatePanel(),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildScaleIndicator(),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: _buildDepthControls(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'comm_marker',
            backgroundColor: Colors.green.shade700,
            onPressed: () => _addMarker('Communication'),
            child: const Icon(Icons.comment),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'control_marker',
            backgroundColor: Colors.red.shade700,
            onPressed: () => _addMarker('Control'),
            child: const Icon(Icons.control_camera),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatePanel() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DIVER STATUS',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStatusRow('X:', _diver.position.x),
            _buildStatusRow('Y:', _diver.position.y),
            _buildStatusRow('Z:', _diver.position.z),
            const SizedBox(height: 8),
            Text(
              'Last update: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
              style: TextStyle(color: Colors.grey.shade600),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDepthControls() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_drop_up),
              onPressed: () => _diver.updateDepth(1),
            ),
            Text('Depth\n${_diver.depth.toStringAsFixed(1)}m',
                textAlign: TextAlign.center),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down),
              onPressed: () => _diver.updateDepth(-1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(
            value.toStringAsFixed(1),
          )
        ],
      ),
    );
  }

  Widget _buildScaleIndicator() {
    return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Zoom: ${(_currentScale * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ));
  }
}

class CoordinatesScreen extends StatelessWidget {
  final Diver diver;

  const CoordinatesScreen({required this.diver, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Coordinates History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: diver.movementHistory.length,
        itemBuilder: (context, index) {
          final entry = diver.movementHistory[index];
          final pos = entry['position'] as Position;
          final time = entry['time'] as DateTime;

          return ListTile(
            title: Text('Position ${index + 1}'),
            subtitle: Text(
              'X: ${pos.x.toStringAsFixed(2)}\n'
              'Y: ${pos.y.toStringAsFixed(2)}\n'
              'Z: ${pos.z.toStringAsFixed(2)}m',
            ),
            trailing: Text(DateFormat('HH:mm:ss').format(time)),
          );
        },
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final Diver diver;
  final Size screenSize;
  final double scale;

  const MapPainter({
    required this.diver,
    required this.screenSize,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas);
    _drawPath(canvas);
    _drawMarkers(canvas);
    _drawDiver(canvas);
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    final center = screenSize.center(Offset.zero);
    // Горизонтальные линии
    for (double y = -200; y <= 200; y += 50) {
      final yPos = center.dy - y;
      canvas.drawLine(Offset(0, yPos), Offset(screenSize.width, yPos), paint);
    }
    // Вертикальные линии
    for (double x = -200; x <= 200; x += 50) {
      final xPos = center.dx + x;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, screenSize.height), paint);
    }
  }

  void _drawPath(Canvas canvas) {
    if (diver.movementHistory.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final firstPos = diver.movementHistory.first['position'] as Position;
    path.moveTo(
        firstPos.toOffset(screenSize).dx, firstPos.toOffset(screenSize).dy);

    for (final entry in diver.movementHistory.skip(1)) {
      final pos = entry['position'] as Position;
      path.lineTo(pos.toOffset(screenSize).dx, pos.toOffset(screenSize).dy);
    }
    path.lineTo(
      diver.position.toOffset(screenSize).dx,
      diver.position.toOffset(screenSize).dy,
    );
    canvas.drawPath(path, paint);
  }

  void _drawMarkers(Canvas canvas) {
    for (final marker in diver.markers) {
      final paint = Paint()
        ..color = marker.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

      final pos = marker.position.toOffset(screenSize);
      canvas.drawCircle(pos, 8, paint);
    }
  }

  void _drawDiver(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue.shade700
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    final pos = diver.position.toOffset(screenSize);
    canvas.drawCircle(pos, 12, paint);
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.diver.position != diver.position ||
        oldDelegate.diver.markers.length != diver.markers.length;
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key, required this.connection});

  final BluetoothConnection connection;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  StreamSubscription? _readSubscription;
  int? _lastPercentage;

  @override
  void initState() {
    super.initState();
    _readSubscription = widget.connection.input?.listen((event) {
      try {
        final input = utf8.decode(event).trim();
        final percentage = int.tryParse(input);
        if (percentage != null && mounted) {
          setState(() => _lastPercentage = percentage);
        }
      } catch (e) {
        if (kDebugMode) print("Error decoding input: $e");
      }
    });
  }

  @override
  void dispose() {
    widget.connection.dispose();
    _readSubscription?.cancel();
    super.dispose();
  }

  String getStatusText(int percent) {
    if (percent >= 70) return "Estado: Lleno";
    if (percent >= 35) return "Estado: Casi lleno";
    return "Estado: Vacío";
  }

  String getImagePath(int percent) {
    if (percent >= 70) return 'assets/full.png';
    if (percent >= 35) return 'assets/almost_full.png';
    return 'assets/empty.png';
  }

  @override
  Widget build(BuildContext context) {
    final int? percent = _lastPercentage;

    return Scaffold(
      appBar: AppBar(title: Text("Conectado a ${widget.connection.address}")),
      body: Center(
        child:
            percent == null
                ? const Text("Esperando datos del dispositivo...")
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      getImagePath(percent),
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "$percent%",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getStatusText(percent),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
      ),
    );
  }
}

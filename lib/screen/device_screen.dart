import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:trash_monitor/screen/service/mqtt_service.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late MqttService _mqttService;
  StreamSubscription<String>? _mqttSubscription;
  int? _lastPercentage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupMqtt();
  }

  Future<void> _setupMqtt() async {
    _mqttService = MqttService(
      server: '0e64cd1612f14fb3b01dc31c444586de.s1.eu.hivemq.cloud',
      port: 8883,
      clientId: 'trash_monitor_app',
      topic: 'esp32/datos',
    );

    try {
      await _mqttService.connect();
      _mqttSubscription = _mqttService.messages.listen((payload) {
        try {
          final jsonData = jsonDecode(payload);
          final int? receivedValue = jsonData['almacenamiento']?.toInt();
          if (receivedValue != null) {
            setState(() {
              _lastPercentage = receivedValue;
              _errorMessage = null;
            });
          }
        } catch (e) {
          print("Error al procesar el mensaje MQTT: $e");
          setState(() {
            _errorMessage = "Error al procesar los datos.";
          });
        }
      });
    } catch (e) {
      print('Error connecting to MQTT: $e');
      setState(() {
        _errorMessage = "Error al conectar con el servidor MQTT.";
      });
    }
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();
    _mqttService.disconnect();
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
      appBar: AppBar(title: const Text("Monitor de basurero")),
      body: Center(
        child:
            _errorMessage != null
                ? Text(_errorMessage!, style: TextStyle(color: Colors.red))
                : percent == null
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

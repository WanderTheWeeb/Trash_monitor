import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String server;
  final int port;
  final String clientId;
  final String topic;

  late MqttServerClient _client;
  StreamController<String> _messageStreamController =
      StreamController.broadcast();

  Stream<String> get messages => _messageStreamController.stream;

  MqttService({
    required this.server,
    required this.port,
    required this.clientId,
    required this.topic,
  });

  Future<void> connect() async {
    _client = MqttServerClient(server, clientId);
    _client.port = port;
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;
    _client.secure = true;
    _client.securityContext = SecurityContext.defaultContext;
    _client.logging(on: true); // Activa true si quieres ver logs
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;
    _client.setProtocolV311();

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .authenticateAs('Santes_33', 'Santes170819\$') // 🚨 Agrega esto
        .withWillQos(MqttQos.atMostOnce);
    _client.connectionMessage = connMess;

    try {
      await _client.connect();
    } catch (e) {
      _client.disconnect();
      rethrow;
    }

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _client.subscribe(topic, MqttQos.atMostOnce);

      _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        _messageStreamController.add(payload);
      });
    } else {
      _client.disconnect();
      throw Exception('Failed to connect to MQTT broker');
    }
  }

  void _onDisconnected() {
    print('MQTT Disconnected');
  }

  void _onConnected() {
    print('MQTT Connected');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void disconnect() {
    _client.disconnect();
    _messageStreamController.close();
  }
}

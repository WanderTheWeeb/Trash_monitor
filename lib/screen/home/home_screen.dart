import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:trash_monitor/screen/device_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _flutterBlueClassicPlugin = FlutterBlueClassic();

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  StreamSubscription? _adapterStateSubscription;

  final Set<BluetoothDevice> _scanResults = {};
  StreamSubscription? _scanSubscription;

  bool _isScanning = false;
  int? _connectingToIndex;
  StreamSubscription? _scanningStateSubscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    BluetoothAdapterState adapterState = _adapterState;

    try {
      adapterState = await _flutterBlueClassicPlugin.adapterStateNow;
      _adapterStateSubscription = _flutterBlueClassicPlugin.adapterState.listen(
        (current) {
          if (mounted) setState(() => _adapterState = current);
        },
      );
      _scanSubscription = _flutterBlueClassicPlugin.scanResults.listen((
        device,
      ) {
        if (mounted) setState(() => _scanResults.add(device));
      });
      _scanningStateSubscription = _flutterBlueClassicPlugin.isScanning.listen((
        isScanning,
      ) {
        if (mounted) setState(() => _isScanning = isScanning);
      });
    } catch (e) {
      if (kDebugMode) print(e);
    }

    if (!mounted) return;

    setState(() {
      _adapterState = adapterState;
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanSubscription?.cancel();
    _scanningStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<BluetoothDevice> scanResults = _scanResults.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSolution'),
        actions: [
          IconButton(
            onPressed: scanDevice,
            icon: Icon(
              _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Estado del adaptador Bluetooth"),
            subtitle: const Text("Toca para encender"),
            trailing: Text(_adapterState.name),
            leading: const Icon(Icons.settings_bluetooth),
            onTap: () => _flutterBlueClassicPlugin.turnOn(),
          ),
          const Divider(),
          if (scanResults.isEmpty)
            const Center(child: Text("No se han encontrado dispositivos aún"))
          else
            for (var (index, result) in scanResults.indexed)
              ListTile(
                title: Text(result.name ?? "??? (${result.address})"),
                subtitle: Text(
                  "Estado de vínculo: ${result.bondState.name}\nTipo: ${result.type.name}",
                ),
                trailing:
                    index == _connectingToIndex
                        ? const CircularProgressIndicator()
                        : Text("${result.rssi} dBm"),
                onTap: () async {
                  BluetoothConnection? connection;
                  setState(() => _connectingToIndex = index);
                  try {
                    connection = await _flutterBlueClassicPlugin.connect(
                      result.address,
                    );
                    if (!this.context.mounted) return;
                    if (connection != null && connection.isConnected) {
                      if (mounted) setState(() => _connectingToIndex = null);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  DeviceScreen(connection: connection!),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) setState(() => _connectingToIndex = null);
                    if (kDebugMode) print(e);
                    connection?.dispose();
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(
                        content: Text("Error connecting to device"),
                      ),
                    );
                  }
                },
              ),
        ],
      ),
    );
  }

  void scanDevice() {
    if (_isScanning) {
      _flutterBlueClassicPlugin.stopScan();
    } else {
      _scanResults.clear();
      _flutterBlueClassicPlugin.startScan();
    }
  }
}

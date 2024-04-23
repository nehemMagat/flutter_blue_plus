import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_screen.dart';
import '../utils/snackbar.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
import '../utils/extra.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      _systemDevices = await FlutterBluePlus.systemDevices;
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
  device.connectAndUpdateStream().then((_) {
    print('Successfully connected to device with MAC address: ${device.remoteId}');
  }).catchError((e) {
    Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
  });

  // Find the second device by its MAC address
  final String secondDeviceMac = "DC:DA:0C:16:C8:AD"; // Replace with the actual MAC address of the second device
  final ScanResult secondDeviceResult = _scanResults.firstWhere(
    (result) => result.device.remoteId == secondDeviceMac,
    orElse: () => ScanResult(
      device: BluetoothDevice(remoteId: DeviceIdentifier(secondDeviceMac)),
      advertisementData: AdvertisementData(
        advName: '',
        txPowerLevel: 0,
        appearance: 0,
        connectable: false,
        manufacturerData: {},
        serviceData: {},
        serviceUuids: [],
      ),
      rssi: 0,
      timeStamp: DateTime.now(),
    ),
  );

  secondDeviceResult.device.connectAndUpdateStream().then((_) {
    print('Successfully connected to device with MAC address: $secondDeviceMac');
    MaterialPageRoute route = MaterialPageRoute(
      builder: (context) => DeviceScreen(devices: [device, secondDeviceResult.device]),
      settings: RouteSettings(name: '/DeviceScreen'),
    );
    Navigator.of(context).push(route);
  }).catchError((e) {
    Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
  });
}


//   void onConnectPressed(BluetoothDevice device) { initial function for connecting device
//   device.connectAndUpdateStream().then((_) {
//     print('Successfully connected to device with MAC address: ${device.remoteId}');
//   }).catchError((e) {
//     Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
//   });

//   final macAddresses = ["84:FC:E6:6A:C0:BD", "DC:DA:0C:16:C8:AD"];
  
//    Connect to the second ESP32 device
//   var secondDevice = _scanResults.firstWhere(
//     (result) => result.device.remoteId != device.remoteId,
//     orElse: () => ScanResult(
//       device: BluetoothDevice(remoteId: DeviceIdentifier('')),
//       advertisementData: AdvertisementData(
//         advName: '',
//         txPowerLevel: 0,
//         appearance: 0,
//         connectable: false,
//         manufacturerData: {},
//         serviceData: {},
//         serviceUuids: [],
//       ),
//       rssi: 0,
//       timeStamp: DateTime.now(),
//     ),
//   );

//   if (secondDevice.device.remoteId != DeviceIdentifier('')) {
//   secondDevice.device.connectAndUpdateStream().then((_) {
//     print('Successfully connected to device with MAC address: ${secondDevice.device.remoteId}');
//   }).catchError((e) {
//     Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
//   });
// }

//   MaterialPageRoute route = MaterialPageRoute(
//     builder: (context) => DeviceScreen(devices: [device, secondDevice.device]), // new method of rerouting, previously kase one device lang, now list na bali 2 device
//     settings: RouteSettings(name: '/DeviceScreen'),
//   );
//   Navigator.of(context).push(route);
// }





  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
        child: const Icon(Icons.stop),
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
      );
    } else {
      return FloatingActionButton(child: const Text("SCAN"), onPressed: onScanPressed);
    }
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices
        .map(
          (d) => SystemDeviceTile(
            device: d,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DeviceScreen(devices: [d]), // new method of rerouting, previously kase one device lang, now list na
                settings: RouteSettings(name: '/DeviceScreen'),
              ),
            ),
            onConnect: () => onConnectPressed(d),
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () => onConnectPressed(r.device),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Find Devices'),
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              ..._buildSystemDeviceTiles(context),
              ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
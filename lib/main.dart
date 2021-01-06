import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'dart:io' show Platform;

const String STA_DEFAULT_SSID = "STA_SSID";
const String STA_DEFAULT_PASSWORD = "STA_PASSWORD";
const NetworkSecurity STA_DEFAULT_SECURITY = NetworkSecurity.WPA;

const String AP_DEFAULT_SSID = "AP_SSID";
const String AP_DEFAULT_PASSWORD = "AP_PASSWORD";

void main() => runApp(FlutterWifiIoT());

class FlutterWifiIoT extends StatefulWidget {
  @override
  _FlutterWifiIoTState createState() => _FlutterWifiIoTState();
}

class _FlutterWifiIoTState extends State<FlutterWifiIoT> {
  String _sPreviousAPSSID = "";
  String _sPreviousPreSharedKey = "";

  List<WifiNetwork> _htResultNetwork;
  Map<String, bool> _htIsNetworkRegistered = Map();

  bool _isEnabled = false;
  bool _isConnected = false;
  //bool _isWiFiAPEnabled = false;
  //bool _isWiFiAPSSIDHidden = false;
  //bool _isWifiAPSupported = true;

  @override
  initState() {
    WiFiForIoTPlugin.isEnabled().then((val) {
      if (val != null) {
        _isEnabled = val;
      }
    });

    WiFiForIoTPlugin.isConnected().then((val) {
      if (val != null) {
        _isConnected = val;
      }
    });

    super.initState();
  }

  storeAndConnect(String psSSID, String psKey) async {
    await storeAPInfos();
    await WiFiForIoTPlugin.setWiFiAPSSID(psSSID);
    await WiFiForIoTPlugin.setWiFiAPPreSharedKey(psKey);
  }

  storeAPInfos() async {
    String sAPSSID;
    String sPreSharedKey;
    try {
      sAPSSID = await WiFiForIoTPlugin.getWiFiAPSSID();
    } on PlatformException {
      sAPSSID = "";
    }

    try {
      sPreSharedKey = await WiFiForIoTPlugin.getWiFiAPPreSharedKey();
    } on PlatformException {
      sPreSharedKey = "";
    }

    setState(() {
      _sPreviousAPSSID = sAPSSID;
      _sPreviousPreSharedKey = sPreSharedKey;
    });
  }

  restoreAPInfos() async {
    WiFiForIoTPlugin.setWiFiAPSSID(_sPreviousAPSSID);
    WiFiForIoTPlugin.setWiFiAPPreSharedKey(_sPreviousPreSharedKey);
  }

  // [sAPSSID, sPreSharedKey]
  Future<List<String>> getWiFiAPInfos() async {
    String sAPSSID;
    String sPreSharedKey;
    try {
      sAPSSID = await WiFiForIoTPlugin.getWiFiAPSSID();
    } on Exception {
      sAPSSID = "";
    }

    try {
      sPreSharedKey = await WiFiForIoTPlugin.getWiFiAPPreSharedKey();
    } on Exception {
      sPreSharedKey = "";
    }

    return [sAPSSID, sPreSharedKey];
  }

  Future<List<APClient>> getClientList(
      bool onlyReachables, int reachableTimeout) async {
    List<APClient> htResultClient;
    try {
      htResultClient = await WiFiForIoTPlugin.getClientList(
          onlyReachables, reachableTimeout);
    } on PlatformException {
      htResultClient = List<APClient>();
    }

    return htResultClient;
  }

  Future<List<WifiNetwork>> loadWifiList() async {
    List<WifiNetwork> htResultNetwork;
    try {
      htResultNetwork = await WiFiForIoTPlugin.loadWifiList();
    } on PlatformException {
      htResultNetwork = List<WifiNetwork>();
    }

    return htResultNetwork;
  }

  isRegisteredWifiNetwork(String ssid) async {
    bool bIsRegistered;
    try {
      bIsRegistered = await WiFiForIoTPlugin.isRegisteredWifiNetwork(ssid);
    } on PlatformException {
      bIsRegistered = false;
    }

    setState(() {
      _htIsNetworkRegistered[ssid] = bIsRegistered;
    });
  }

  void showClientList() async {
    /// Refresh the list and show in console
    getClientList(false, 300).then((val) => val.forEach((oClient) {
          print("************************");
          print("Client :");
          print("ipAddr = '${oClient.ipAddr}'");
          print("hwAddr = '${oClient.hwAddr}'");
          print("device = '${oClient.device}'");
          print("isReachable = '${oClient.isReachable}'");
          print("************************");
        }));
  }

  Widget getWidgets() {
    WiFiForIoTPlugin.isConnected().then((val) => setState(() {
          _isConnected = val;
        }));

    // disable scanning for ios as not supported
    if (_isConnected || Platform.isIOS) {
      _htResultNetwork = null;
    }

    if (_htResultNetwork != null && _htResultNetwork.length > 0) {
      List<ListTile> htNetworks = List();

      _htResultNetwork.forEach((oNetwork) {
        PopupCommand oCmdConnect = PopupCommand("Connect", oNetwork.ssid);

        List<PopupMenuItem<PopupCommand>> htPopupMenuItems = List();
        htPopupMenuItems.add(
          PopupMenuItem<PopupCommand>(
            value: oCmdConnect,
            child: const Text('Connect'),
          ),
        );

        setState(() {
          isRegisteredWifiNetwork(oNetwork.ssid);
          if (_htIsNetworkRegistered.containsKey(oNetwork.ssid) &&
              _htIsNetworkRegistered[oNetwork.ssid]) {}

          htNetworks.add(
            ListTile(
              title: Text("" +
                  oNetwork.ssid +
                  ((_htIsNetworkRegistered.containsKey(oNetwork.ssid) &&
                          _htIsNetworkRegistered[oNetwork.ssid])
                      ? " *"
                      : "")),
              trailing: PopupMenuButton<PopupCommand>(
                padding: EdgeInsets.zero,
                itemBuilder: (BuildContext context) => htPopupMenuItems,
              ),
            ),
          );
        });
      });

      return ListView(
        padding: kMaterialListPadding,
        children: htNetworks,
      );
    } else {
      return SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: Platform.isIOS
                ? getButtonWidgetsForiOS()
                : getButtonWidgetsForAndroid(),
          ),
        ),
      );
    }
  }

  List<Widget> getButtonWidgetsForAndroid() {
    List<Widget> htPrimaryWidgets = List();

    WiFiForIoTPlugin.isEnabled().then((val) => setState(() {
          _isEnabled = val;
        }));

    if (_isEnabled) {
      htPrimaryWidgets.addAll([
        SizedBox(height: 10),
        Text("Wifi Enabled"),
        RaisedButton(
          child: Text("Disable"),
          onPressed: () {
            WiFiForIoTPlugin.setEnabled(false);
          },
        ),
        RaisedButton(
          child: Text("Scan"),
          onPressed: () async {
            _htResultNetwork = await loadWifiList();
            setState(() {});
          },
        ),
      ]);

      WiFiForIoTPlugin.isConnected().then((val) {
        if (val != null) {
          setState(() {
            _isConnected = val;
          });
        }
      });

      if (_isConnected) {
        htPrimaryWidgets.addAll(<Widget>[
          Text("Connected"),
          FutureBuilder(
              future: WiFiForIoTPlugin.getSSID(),
              initialData: "Loading..",
              builder: (BuildContext context, AsyncSnapshot<String> ssid) {
                return Text("SSID: ${ssid.data}");
              }),
          FutureBuilder(
              future: WiFiForIoTPlugin.getBSSID(),
              initialData: "Loading..",
              builder: (BuildContext context, AsyncSnapshot<String> bssid) {
                return Text("BSSID: ${bssid.data}");
              }),
          FutureBuilder(
              future: WiFiForIoTPlugin.getCurrentSignalStrength(),
              initialData: 0,
              builder: (BuildContext context, AsyncSnapshot<int> signal) {
                return Text("Signal: ${signal.data}");
              }),
          FutureBuilder(
              future: WiFiForIoTPlugin.getFrequency(),
              initialData: 0,
              builder: (BuildContext context, AsyncSnapshot<int> freq) {
                return Text("Frequency : ${freq.data}");
              }),
          FutureBuilder(
              future: WiFiForIoTPlugin.getIP(),
              initialData: "Loading..",
              builder: (BuildContext context, AsyncSnapshot<String> ip) {
                return Text("IP : ${ip.data}");
              }),
        ]);
      } else {
        htPrimaryWidgets.addAll(<Widget>[
          Text("Disconnected"),
          RaisedButton(
            child: Text("Scan"),
            onPressed: () async {
              _htResultNetwork = await loadWifiList();
              setState(() {});
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: Text("Use WiFi"),
                onPressed: () {
                  WiFiForIoTPlugin.forceWifiUsage(true);
                },
              ),
              RaisedButton(
                child: Text("Use 3G/4G"),
                onPressed: () {
                  WiFiForIoTPlugin.forceWifiUsage(false);
                },
              ),
            ],
          )
        ]);
      }
    } else {
      htPrimaryWidgets.addAll(<Widget>[
        SizedBox(height: 10),
        Text("Wifi Disabled"),
        RaisedButton(
          child: Text("Enable"),
          onPressed: () {
            setState(() {
              WiFiForIoTPlugin.setEnabled(true);
            });
          },
        ),
      ]);
    }

    htPrimaryWidgets.add(Divider(
      height: 32.0,
    ));

    return htPrimaryWidgets;
  }

  List<Widget> getButtonWidgetsForiOS() {
    List<Widget> htPrimaryWidgets = List();

    WiFiForIoTPlugin.isEnabled().then((val) => setState(() {
          _isEnabled = val;
        }));

    if (_isEnabled) {
      htPrimaryWidgets.add(Text("Wifi Enabled"));
      WiFiForIoTPlugin.isConnected().then((val) => setState(() {
            _isConnected = val;
          }));

      String _sSSID;
      if (_isConnected) {
        htPrimaryWidgets.addAll(<Widget>[
          Text("Connected"),
          FutureBuilder(
              future: WiFiForIoTPlugin.getSSID(),
              initialData: "Loading..",
              builder: (BuildContext context, AsyncSnapshot<String> ssid) {
                _sSSID = ssid.data;
                return Text("SSID: ${ssid.data}");
              }),
        ]);

        if (_sSSID == STA_DEFAULT_SSID) {
          htPrimaryWidgets.addAll(<Widget>[]);
        } else {
          htPrimaryWidgets.addAll(<Widget>[
            RaisedButton(
              child: Text("Connect to '$AP_DEFAULT_SSID'"),
              onPressed: () {
                WiFiForIoTPlugin.connect(STA_DEFAULT_SSID,
                    password: STA_DEFAULT_PASSWORD,
                    joinOnce: true,
                    security: NetworkSecurity.WPA);
              },
            ),
          ]);
        }
      } else {
        htPrimaryWidgets.addAll(<Widget>[
          Text("Disconnected"),
          RaisedButton(
            child: Text("Connect to '$AP_DEFAULT_SSID'"),
            onPressed: () {
              WiFiForIoTPlugin.connect(STA_DEFAULT_SSID,
                  password: STA_DEFAULT_PASSWORD,
                  joinOnce: true,
                  security: NetworkSecurity.WPA);
            },
          ),
        ]);
      }
    } else {
      htPrimaryWidgets.addAll(<Widget>[
        Text("Wifi Disabled?"),
        RaisedButton(
          child: Text("Connect to '$AP_DEFAULT_SSID'"),
          onPressed: () {
            WiFiForIoTPlugin.connect(STA_DEFAULT_SSID,
                password: STA_DEFAULT_PASSWORD,
                joinOnce: true,
                security: NetworkSecurity.WPA);
          },
        ),
      ]);
    }

    return htPrimaryWidgets;
  }

  @override
  Widget build(BuildContext poContext) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Platform.isIOS
              ? Text('WifiFlutter Example iOS')
              : Text('WifiFlutter Example Android'),
          actions: _isConnected
              ? <Widget>[
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case "disconnect":
                          WiFiForIoTPlugin.disconnect();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuItem<String>>[
                      PopupMenuItem<String>(
                        value: "disconnect",
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ]
              : null,
        ),
        body: getWidgets(),
      ),
    );
  }
}

class PopupCommand {
  String command;
  String argument;

  PopupCommand(this.command, this.argument);
}

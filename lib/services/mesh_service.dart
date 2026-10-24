import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'store.dart';

/// Peer-to-peer mesh over Bluetooth / Wi-Fi Direct using Nearby Connections.
///
/// Every device both advertises and discovers (P2P_CLUSTER), so any two
/// phones in range connect automatically. Messages are flooded: when a packet
/// arrives it is stored (deduplicated by id) and re-sent to every other
/// connected peer, so a message can hop across devices that are not in
/// direct range of each other.
class MeshService extends ChangeNotifier {
  MeshService(this.store);

  final Store store;
  final Nearby _nearby = Nearby();
  static const _serviceId = 'com.example.mesh_app';
  static const Strategy _strategy = Strategy.P2P_CLUSTER;
  static const int _maxHops = 6;

  final Map<String, Peer> peers = {};
  final Set<String> _seenPacketIds = {};
  bool running = false;
  String? lastError;

  List<Peer> get connectedPeers =>
      peers.values.where((p) => p.connected).toList();

  // ---------------------------------------------------------------- lifecycle

  Future<bool> ensurePermissions() async {
    final wanted = <Permission>[
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ];
    final results = await wanted.request();
    // Some permissions don't exist on older Android versions; treat those as ok.
    final denied = results.entries
        .where((e) => e.value.isDenied || e.value.isPermanentlyDenied)
        .where((e) => e.key != Permission.nearbyWifiDevices &&
            e.key != Permission.bluetooth)
        .toList();
    if (denied.isNotEmpty) {
      lastError = 'Missing permissions: ${denied.map((e) => e.key).join(', ')}';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> start() async {
    if (running) return;
    if (!await ensurePermissions()) return;
    lastError = null;
    try {
      final name = store.profile.name.isEmpty ? 'Mesh user' : store.profile.name;
      await _nearby.startAdvertising(
        name,
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      await _nearby.startDiscovery(
        name,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
      );
      running = true;
    } catch (e) {
      lastError = 'Could not start mesh: $e';
    }
    notifyListeners();
  }

  Future<void> stop() async {
    running = false;
    try {
      await _nearby.stopAdvertising();
      await _nearby.stopDiscovery();
      await _nearby.stopAllEndpoints();
    } catch (_) {}
    peers.clear();
    notifyListeners();
  }

  // --------------------------------------------------------------- discovery

  void _onEndpointFound(String id, String name, String serviceId) {
    peers.putIfAbsent(id, () => Peer(endpointId: id, advertisedName: name));
    notifyListeners();
    // Tie-break so both sides don't request simultaneously: lower id requests.
    // (Nearby handles the race anyway, this just reduces failed attempts.)
    _nearby.requestConnection(
      store.profile.name.isEmpty ? 'Mesh user' : store.profile.name,
      id,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    ).catchError((_) => false);
  }

  void _onEndpointLost(String? id) {
    if (id == null) return;
    final p = peers[id];
    if (p != null && !p.connected) peers.remove(id);
    notifyListeners();
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    peers.putIfAbsent(
        id, () => Peer(endpointId: id, advertisedName: info.endpointName));
    // Auto-accept: this is an open mesh. Add a confirm dialog here if you want
    // the user to approve each peer.
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: _onPayload,
      onPayloadTransferUpdate: (_, __) {},
    );
  }

  void _onConnectionResult(String id, Status status) {
    final p = peers[id];
    if (p == null) return;
    if (status == Status.CONNECTED) {
      p.connected = true;
      _sendTo(id, Packet(Packet.typeHello, store.profile.toJson()));
    } else {
      p.connected = false;
    }
    notifyListeners();
  }

  void _onDisconnected(String id) {
    peers.remove(id);
    notifyListeners();
  }

  // ---------------------------------------------------------------- payloads

  void _onPayload(String fromEndpoint, Payload payload) {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;
    final raw = utf8.decode(payload.bytes!);
    final packet = Packet.tryDecode(raw);
    if (packet == null) return;

    switch (packet.type) {
      case Packet.typeHello:
        final profile = Profile.fromJson(packet.body);
        peers[fromEndpoint]?.profile = profile;
        notifyListeners();
        break;

      case Packet.typeMessage:
        final msg = Message.fromJson(packet.body);
        if (!_seenPacketIds.add(msg.id) || store.hasMessage(msg.id)) return;

        final forMe = msg.isBroadcast || msg.toId == store.profile.id;
        if (forMe) {
          store.addMessage(msg);
          if (!msg.isBroadcast) {
            _sendTo(fromEndpoint, Packet(Packet.typeAck, {'id': msg.id}));
          }
        }
        // Relay to everyone else (store-and-forward flooding).
        if (msg.hops < _maxHops) {
          msg.hops += 1;
          _broadcast(Packet(Packet.typeMessage, msg.toJson()),
              except: fromEndpoint);
        }
        break;

      case Packet.typeAck:
        final id = packet.body['id'] as String?;
        if (id == null) return;
        if (store.messages.any((m) => m.id == id)) {
          store.markDelivered(id);
        } else {
          // Not our message; pass the ack along.
          _broadcast(packet, except: fromEndpoint);
        }
        break;
    }
  }

  // ----------------------------------------------------------------- sending

  Future<Message> sendText(String text, {String toId = '*'}) async {
    final msg = Message(
      id: const Uuid().v4(),
      fromId: store.profile.id,
      fromName: store.profile.name,
      toId: toId,
      text: text,
      sentAt: DateTime.now(),
      delivered: toId == '*', // broadcasts have no ack
    );
    _seenPacketIds.add(msg.id);
    await store.addMessage(msg);
    _broadcast(Packet(Packet.typeMessage, msg.toJson()));
    return msg;
  }

  /// Send my profile card explicitly (e.g. "Share my card" button).
  void shareMyProfile(String endpointId) {
    _sendTo(endpointId, Packet(Packet.typeHello, store.profile.toJson()));
  }

  void _broadcast(Packet packet, {String? except}) {
    for (final p in connectedPeers) {
      if (p.endpointId == except) continue;
      _sendTo(p.endpointId, packet);
    }
  }

  void _sendTo(String endpointId, Packet packet) {
    final bytes = Uint8List.fromList(utf8.encode(packet.encode()));
    _nearby.sendBytesPayload(endpointId, bytes).catchError((_) {});
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

/// Local persistence for profile, contacts and message history.
class Store extends ChangeNotifier {
  static const _kProfile = 'profile';
  static const _kContacts = 'contacts';
  static const _kMessages = 'messages';

  late SharedPreferences _prefs;
  late Profile profile;
  final List<Contact> contacts = [];
  final List<Message> messages = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final p = _prefs.getString(_kProfile);
    profile = p != null ? Profile.decode(p) : Profile(id: const Uuid().v4());

    final c = _prefs.getStringList(_kContacts) ?? [];
    contacts.addAll(c.map((s) => Contact.fromJson(jsonDecode(s))));

    final m = _prefs.getStringList(_kMessages) ?? [];
    messages.addAll(m.map((s) => Message.fromJson(jsonDecode(s))));
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    notifyListeners();
  }

  Future<void> saveProfile(Profile p) async {
    profile = p;
    await _prefs.setString(_kProfile, p.encode());
    notifyListeners();
  }

  Future<void> addContact(Profile other, {String note = ''}) async {
    if (other.id == profile.id) return;
    final i = contacts.indexWhere((c) => c.profile.id == other.id);
    if (i >= 0) {
      contacts[i] = Contact(profile: other, metAt: contacts[i].metAt, note: contacts[i].note);
    } else {
      contacts.add(Contact(profile: other, metAt: DateTime.now(), note: note));
    }
    await _persistContacts();
  }

  Future<void> updateContactNote(String id, String note) async {
    final c = contacts.where((c) => c.profile.id == id).firstOrNull;
    if (c == null) return;
    c.note = note;
    await _persistContacts();
  }

  Future<void> removeContact(String id) async {
    contacts.removeWhere((c) => c.profile.id == id);
    await _persistContacts();
  }

  Future<void> _persistContacts() async {
    await _prefs.setStringList(
        _kContacts, contacts.map((c) => jsonEncode(c.toJson())).toList());
    notifyListeners();
  }

  bool hasMessage(String id) => messages.any((m) => m.id == id);

  Future<void> addMessage(Message m) async {
    if (hasMessage(m.id)) return;
    messages.add(m);
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    await _persistMessages();
  }

  Future<void> markDelivered(String id) async {
    final m = messages.where((m) => m.id == id).firstOrNull;
    if (m == null || m.delivered) return;
    m.delivered = true;
    await _persistMessages();
  }

  Future<void> _persistMessages() async {
    // Keep the last 500 messages to bound storage.
    final keep = messages.length > 500
        ? messages.sublist(messages.length - 500)
        : messages;
    await _prefs.setStringList(
        _kMessages, keep.map((m) => jsonEncode(m.toJson())).toList());
    notifyListeners();
  }

  /// Messages in a 1:1 conversation with [otherId], or the broadcast room if '*'.
  List<Message> conversation(String otherId) {
    if (otherId == '*') return messages.where((m) => m.isBroadcast).toList();
    return messages
        .where((m) =>
            !m.isBroadcast &&
            ((m.fromId == otherId && m.toId == profile.id) ||
                (m.fromId == profile.id && m.toId == otherId)))
        .toList();
  }

  /// Distinct conversation partner ids, most recent first.
  List<String> conversationIds() {
    final seen = <String>{};
    final out = <String>[];
    for (final m in messages.reversed) {
      final other = m.isBroadcast
          ? '*'
          : (m.fromId == profile.id ? m.toId : m.fromId);
      if (seen.add(other)) out.add(other);
    }
    return out;
  }

  String nameFor(String id) {
    if (id == '*') return 'Everyone nearby';
    if (id == profile.id) return 'You';
    final c = contacts.where((c) => c.profile.id == id).firstOrNull;
    if (c != null) return c.profile.name;
    final m = messages.where((m) => m.fromId == id).firstOrNull;
    return m?.fromName.isNotEmpty == true ? m!.fromName : 'Unknown';
  }
}

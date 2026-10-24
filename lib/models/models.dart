import 'dart:convert';

/// The user's own profile (also what gets shared with people you meet).
class Profile {
  final String id;
  String name;
  String headline; // e.g. "Flutter dev @ Acme"
  String company;
  String phone;
  String email;
  String website;
  String bio;

  Profile({
    required this.id,
    this.name = '',
    this.headline = '',
    this.company = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.bio = '',
  });

  bool get isComplete => name.trim().isNotEmpty;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'headline': headline,
        'company': company,
        'phone': phone,
        'email': email,
        'website': website,
        'bio': bio,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        headline: (j['headline'] ?? '') as String,
        company: (j['company'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        website: (j['website'] ?? '') as String,
        bio: (j['bio'] ?? '') as String,
      );

  String encode() => jsonEncode(toJson());
  static Profile decode(String s) =>
      Profile.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// A saved contact = someone else's profile + when/where you met.
class Contact {
  final Profile profile;
  final DateTime metAt;
  String note;

  Contact({required this.profile, required this.metAt, this.note = ''});

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'metAt': metAt.toIso8601String(),
        'note': note,
      };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        profile: Profile.fromJson(j['profile'] as Map<String, dynamic>),
        metAt: DateTime.parse(j['metAt'] as String),
        note: (j['note'] ?? '') as String,
      );
}

/// A chat message that travels over the mesh.
class Message {
  final String id;
  final String fromId;
  final String fromName;
  final String toId; // '*' = broadcast to everyone
  final String text;
  final DateTime sentAt;
  int hops; // how many devices relayed it
  bool delivered;

  Message({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.text,
    required this.sentAt,
    this.hops = 0,
    this.delivered = false,
  });

  bool get isBroadcast => toId == '*';

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromId': fromId,
        'fromName': fromName,
        'toId': toId,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        'hops': hops,
      };

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String,
        fromId: j['fromId'] as String,
        fromName: (j['fromName'] ?? '') as String,
        toId: j['toId'] as String,
        text: j['text'] as String,
        sentAt: DateTime.parse(j['sentAt'] as String),
        hops: (j['hops'] ?? 0) as int,
        delivered: true,
      );
}

/// Envelope used on the wire so one connection can carry several packet types.
class Packet {
  static const typeHello = 'hello'; // profile exchange on connect
  static const typeMessage = 'msg';
  static const typeAck = 'ack';

  final String type;
  final Map<String, dynamic> body;

  Packet(this.type, this.body);

  String encode() => jsonEncode({'t': type, 'b': body});

  static Packet? tryDecode(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return Packet(m['t'] as String, (m['b'] as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }
}

/// A device currently reachable over the mesh.
class Peer {
  final String endpointId; // transport-level id
  Profile? profile; // known after hello exchange
  final String advertisedName;
  bool connected;

  Peer({
    required this.endpointId,
    required this.advertisedName,
    this.profile,
    this.connected = false,
  });

  String get displayName => profile?.name.isNotEmpty == true
      ? profile!.name
      : advertisedName;
}

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/models.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.profile, this.firstRun = false});
  final Profile profile;
  final bool firstRun;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.profile.name);
  late final TextEditingController _headline =
      TextEditingController(text: widget.profile.headline);
  late final TextEditingController _company =
      TextEditingController(text: widget.profile.company);
  late final TextEditingController _phone =
      TextEditingController(text: widget.profile.phone);
  late final TextEditingController _email =
      TextEditingController(text: widget.profile.email);
  late final TextEditingController _website =
      TextEditingController(text: widget.profile.website);
  late final TextEditingController _bio =
      TextEditingController(text: widget.profile.bio);

  @override
  void dispose() {
    for (final c in [_name, _headline, _company, _phone, _email, _website, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final p = Profile(
      id: widget.profile.id,
      name: _name.text.trim(),
      headline: _headline.text.trim(),
      company: _company.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      website: _website.text.trim(),
      bio: _bio.text.trim(),
    );
    await AppScope.of(context).store.saveProfile(p);
    if (!mounted) return;
    if (widget.firstRun) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.firstRun ? 'Your profile' : 'Edit profile'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'This is the card other people receive when you connect.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            _field(_name, 'Full name', Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                autofocus: widget.firstRun),
            _field(_headline, 'Headline (e.g. Product designer)', Icons.work_outline),
            _field(_company, 'Company / school', Icons.business_outlined),
            _field(_phone, 'Phone', Icons.phone_outlined,
                keyboard: TextInputType.phone),
            _field(_email, 'Email', Icons.mail_outline,
                keyboard: TextInputType.emailAddress),
            _field(_website, 'Website / LinkedIn', Icons.link,
                keyboard: TextInputType.url),
            _field(_bio, 'Short bio', Icons.notes_outlined, lines: 3),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _save,
              child: Text(widget.firstRun ? 'Continue' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {String? Function(String?)? validator,
      TextInputType? keyboard,
      int lines = 1,
      bool autofocus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        validator: validator,
        keyboardType: keyboard,
        maxLines: lines,
        autofocus: autofocus,
        textCapitalization: lines > 1 || label.startsWith('Full')
            ? TextCapitalization.sentences
            : TextCapitalization.none,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}

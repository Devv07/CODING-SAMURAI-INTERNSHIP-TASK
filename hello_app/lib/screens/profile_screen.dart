import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authSvc = AuthService();
  final _chatSvc = ChatService();
  final _nameCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();

  UserModel? _user;
  bool _editing = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _statusCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = await _authSvc.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _nameCtrl.text = user?.name ?? '';
        _statusCtrl.text =
            user?.status ?? 'Hey there! I am using Hello Chat 👋';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;
    setState(() => _saving = true);
    try {
      await _chatSvc.updateProfile(
        uid: _uid,
        name: _nameCtrl.text.trim(),
        status: _statusCtrl.text.trim(),
      );
      await _load();
      setState(() => _editing = false);
      _snack('Profile saved!', AppColors.primary);
    } catch (_) {
      _snack('Failed to save profile.', AppColors.accent);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance.ref('profile_photos/$_uid.jpg');
      await ref.putFile(
        File(picked.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      await _chatSvc.updateProfile(uid: _uid, photoUrl: url);
      await _load();
      _snack('Photo updated!', AppColors.primary);
    } catch (_) {
      _snack('Failed to update photo.', AppColors.accent);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Poppins', color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authSvc.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (_) => false);
      }
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _topBar(),
              const SizedBox(height: 28),
              _avatarSection(),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _field(
                      icon: Icons.person_outline_rounded,
                      label: 'Display Name',
                      ctrl: _nameCtrl,
                      enabled: _editing,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      icon: Icons.info_outline_rounded,
                      label: 'About / Status',
                      ctrl: _statusCtrl,
                      enabled: _editing,
                    ),
                    const SizedBox(height: 16),
                    _readField(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _user?.email ?? '',
                    ),
                    const SizedBox(height: 40),
                    _signOutBtn(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('Profile',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const Spacer(),
          if (!_editing)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_rounded,
                  size: 16, color: AppColors.primary),
              label: const Text('Edit',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  )),
            )
          else
            TextButton(
              onPressed: _saving ? null : _saveProfile,
              child: _saving
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2))
                  : const Text('Save',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  )),
            ),
        ],
      ),
    );
  }

  Widget _avatarSection() {
    final colors = AppColors.avatarColor(_user?.name ?? '');
    return Column(
      children: [
        GestureDetector(
          onTap: _changePhoto,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Avatar
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: colors),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.5),
                    width: 2.5,
                  ),
                ),
                child: _user?.photoUrl.isNotEmpty == true
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(48),
                  child: Image.network(
                    _user!.photoUrl,
                    fit: BoxFit.cover,
                  ),
                )
                    : Center(
                  child: _uploadingPhoto
                      ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                      : Text(
                    _user?.initials ?? 'U',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              // Camera icon overlay
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _user?.name ?? '',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _user?.email ?? '',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        // Online badge
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.online.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.online,
                ),
              ),
              const SizedBox(width: 6),
              const Text('Online',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.online,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field({
    required IconData icon,
    required String label,
    required TextEditingController ctrl,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? AppColors.primary.withOpacity(0.4)
                  : Colors.transparent,
            ),
          ),
          child: TextField(
            controller: ctrl,
            enabled: enabled,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon,
                  color: enabled ? AppColors.primary : AppColors.textHint,
                  size: 20),
              border: InputBorder.none,
              isDense: false,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _readField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textHint, size: 20),
              const SizedBox(width: 12),
              Text(value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _signOutBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout_rounded,
            color: AppColors.accent, size: 20),
        label: const Text('Sign Out',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            )),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: AppColors.accent.withOpacity(0.4), width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
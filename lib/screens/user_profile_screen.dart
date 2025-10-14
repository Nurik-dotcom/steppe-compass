// lib/screens/user_profile_screen.dart
import 'dart:async';
import 'dart:convert'; // Для Cloudinary
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Для Cloudinary
import 'package:image_picker/image_picker.dart'; // Для выбора изображений

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin_panel_screen.dart';
import 'favorites_screen.dart';
import 'debug_data_screen.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

const Color _kButtonBg = Color(0xff8ddeff);
const Color _kButtonText = Color(0xff000E6B);

enum _DayTime { morning, day, evening, night }

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = AuthService();

  // Контроллеры форм
  final _emailFormKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>(); // <-- Для имени

  final _currentEmailC = TextEditingController();
  final _currentPassForEmailC = TextEditingController();
  final _newEmailC = TextEditingController();
  final _currentPassC = TextEditingController();
  final _newPassC = TextEditingController();
  final _displayNameC = TextEditingController(); // <-- Для имени

  // Состояния UI
  bool _isEditing = false;
  bool _isSaving = false;

  Timer? _tick;
  late _DayTime _currentDayTime;

  @override
  void initState() {
    super.initState();
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser?.email != null) _currentEmailC.text = fbUser!.email!;
    if (fbUser?.displayName != null) _displayNameC.text = fbUser!.displayName!;

    _currentDayTime = _getDayTime(DateTime.now());
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      final dt = _getDayTime(DateTime.now());
      if (dt != _currentDayTime) {
        setState(() => _currentDayTime = dt);
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _currentEmailC.dispose();
    _currentPassForEmailC.dispose();
    _newEmailC.dispose();
    _currentPassC.dispose();
    _newPassC.dispose();
    _displayNameC.dispose(); // <-- Не забываем
    super.dispose();
  }

  _DayTime _getDayTime(DateTime now) {
    final h = now.hour;
    if (h >= 6 && h < 12) return _DayTime.morning;
    if (h < 18) return _DayTime.day;
    if (h < 22) return _DayTime.evening;
    return _DayTime.night;
  }

  BoxDecoration _decorationForTime(_DayTime dt) {
    switch (dt) {
      case _DayTime.morning: return const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFBBC8C8), Color(0xFF5E9F9A), Color(0xFFDDBDAA)], begin: Alignment.topCenter, end: Alignment.bottomCenter));
      case _DayTime.day: return const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFA9C9EC), Color(0xFFC6D7EB), Color(0xFFD3BEA3), Color(0xFFD4AC77)], begin: Alignment.topCenter, end: Alignment.bottomCenter));
      case _DayTime.evening: return const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF61556A), Color(0xFF7E80A5), Color(0xFFE6BFB2)], begin: Alignment.topCenter, end: Alignment.bottomCenter));
      case _DayTime.night: return const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6B75AD), Color(0xFF324476), Color(0xFF11213B)], begin: Alignment.topCenter, end: Alignment.bottomCenter));
    }
  }

  // ==== Actions ==== //

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Выйти из аккаунта?'), content: const Text('Вы будете перенаправлены на экран входа.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти'))]));
    if (confirm != true) return;
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  void _showChangeEmailDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Text("Изменить Email"), content: Form(key: _emailFormKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: _currentEmailC, decoration: const InputDecoration(labelText: "Текущий Email"), validator: (v) => v == null || v.trim().isEmpty ? "Введите текущий email" : null), TextFormField(controller: _currentPassForEmailC, obscureText: true, decoration: const InputDecoration(labelText: "Пароль"), validator: (v) => v == null || v.isEmpty ? "Введите пароль" : null), TextFormField(controller: _newEmailC, decoration: const InputDecoration(labelText: "Новый Email"), validator: (v) => v == null || v.trim().isEmpty ? "Введите новый email" : null)]))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _kButtonBg, foregroundColor: _kButtonText), onPressed: () async { if (!_emailFormKey.currentState!.validate()) return; FocusScope.of(context).unfocus(); try { await _auth.updateEmail(currentEmail: _currentEmailC.text.trim(), currentPassword: _currentPassForEmailC.text, newEmail: _newEmailC.text.trim()); if (!mounted) return; Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ссылка для подтверждения отправлена на новый email'))); } catch (e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }}, child: const Text("Сохранить"))]));
  }

  void _showChangePasswordDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Text("Изменить пароль"), content: Form(key: _passFormKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: _currentEmailC, readOnly: true, decoration: const InputDecoration(labelText: "Email")), TextFormField(controller: _currentPassC, obscureText: true, decoration: const InputDecoration(labelText: "Текущий пароль"), validator: (v) => v == null || v.isEmpty ? "Введите текущий пароль" : null), TextFormField(controller: _newPassC, obscureText: true, decoration: const InputDecoration(labelText: "Новый пароль"), validator: (v) => v == null || v.length < 6 ? "Минимум 6 символов" : null)]))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _kButtonBg, foregroundColor: _kButtonText), onPressed: () async { if (!_passFormKey.currentState!.validate()) return; FocusScope.of(context).unfocus(); try { await _auth.updatePassword(currentPassword: _currentPassC.text, newPassword: _newPassC.text, email: _currentEmailC.text.trim()); if (!mounted) return; Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пароль обновлён'))); } catch (e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }}, child: const Text("Сохранить"))]));
  }

  // ==== Новые методы для профиля ==== //
  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      await _auth.updateUserProfile(displayName: _displayNameC.text.trim());
      if (mounted) setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    setState(() => _isSaving = true);
    try {
      // ▼▼▼ ВАЖНО: ЗАМЕНИТЕ ЭТИ ДАННЫЕ НА ВАШИ ▼▼▼
      const cloudName = 'dzlwxb5nl';
      const uploadPreset = 'steppe-compass';


      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = json.decode(responseString);
        final imageUrl = jsonMap['secure_url'];

        await _auth.updateUserProfile(displayName: _displayNameC.text.trim(), photoUrl: imageUrl);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Аватар обновлен!')));
      } else {
        final error = await response.stream.bytesToString();
        throw Exception('Ошибка загрузки в Cloudinary: ${response.reasonPhrase} ($error)');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==== UI helpers ==== //
  Widget _buildProfileCard({ required IconData icon, required String title, required VoidCallback onTap, }) {
    return Container(margin: const EdgeInsets.symmetric(vertical: 8), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]), child: Row(children: [Icon(icon, size: 26, color: Colors.teal), const SizedBox(width: 18), Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87))), const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.black38)]))));
  }

  @override
  Widget build(BuildContext context) {
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    return AnimatedContainer(duration: const Duration(milliseconds: 600), curve: Curves.easeInOut, decoration: _decorationForTime(_currentDayTime), child: Scaffold(backgroundColor: Colors.transparent, appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent, centerTitle: true, title: const Text("Профиль", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))), body: fbUser == null ? const Center(child: Text("Вы не авторизованы")) : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('users').doc(fbUser.uid).snapshots(), builder: (context, snap) { if (snap.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); } final data = snap.data?.data() ?? <String, dynamic>{}; final email = (data['email'] as String?) ?? fbUser.email ?? ''; final displayName = (data['displayName'] as String?) ?? fbUser.displayName ?? ''; final role = (data['role'] as String?) ?? 'user'; final isAdmin = role == 'admin'; if (_currentEmailC.text.isEmpty && email.isNotEmpty) _currentEmailC.text = email; return ListView(padding: const EdgeInsets.all(16), children: [const SizedBox(height: 20), Center(child: Form(key: _profileFormKey, child: Column(children: [Stack(alignment: Alignment.bottomRight, children: [CircleAvatar(radius: 45, backgroundImage: fbUser.photoURL != null && fbUser.photoURL!.isNotEmpty ? NetworkImage(fbUser.photoURL!) : const AssetImage('assets/images/avatar_placeholder.jpg') as ImageProvider), Material(color: Colors.teal, shape: const CircleBorder(), clipBehavior: Clip.antiAlias, child: InkWell(onTap: _isSaving ? null : _changeAvatar, child: const Padding(padding: EdgeInsets.all(6.0), child: Icon(Icons.edit, color: Colors.white, size: 18))))]), const SizedBox(height: 12), if (_isEditing) TextFormField(controller: _displayNameC, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), decoration: const InputDecoration(isDense: true, hintText: "Ваше имя", hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none), validator: (v) => (v == null || v.trim().isEmpty) ? 'Имя не может быть пустым' : null) else Text(displayName.isNotEmpty ? displayName : "Без имени", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), Text(email, style: const TextStyle(fontSize: 14, color: Colors.white70))]))), const SizedBox(height: 16), if (_isSaving) const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Colors.white))) else if (_isEditing) Row(mainAxisAlignment: MainAxisAlignment.center, children: [TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text("Отмена", style: TextStyle(color: Colors.white))), const SizedBox(width: 16), ElevatedButton.icon(onPressed: _saveProfile, icon: const Icon(Icons.save), label: const Text("Сохранить"))]) else IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () { _displayNameC.text = fb.FirebaseAuth.instance.currentUser?.displayName ?? ''; setState(() => _isEditing = true); }), const SizedBox(height: 16), _buildProfileCard(icon: Icons.favorite, title: "Избранное", onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())); }), _buildProfileCard(icon: Icons.email, title: "Изменить Email", onTap: _showChangeEmailDialog), _buildProfileCard(icon: Icons.lock, title: "Изменить Пароль", onTap: _showChangePasswordDialog), if (isAdmin) _buildProfileCard(icon: Icons.admin_panel_settings, title: "Админ-панель", onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())); }), if (isAdmin) _buildProfileCard(icon: Icons.bug_report, title: "Отладка", onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugDataScreen())); }), const SizedBox(height: 16), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24)), icon: const Icon(Icons.logout), label: const Text("Выйти", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), onPressed: _logout)]); })));
  }
}
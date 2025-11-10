import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../helpers/database_helper.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? currentUser;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DatabaseHelper.instance.getUserById(widget.userId);
    if (user != null) {
      setState(() {
        currentUser = user;
        _nameController.text = currentUser!['name'];
        _emailController.text = currentUser!['email'];
        _phoneController.text = currentUser!['phoneNumber'] ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        currentUser!['profileImage'] = image.path;
      });
      await _saveUserData();
    }
  }

  Future<void> _saveUserData() async {
    Map<String, dynamic> updatedUser = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneController.text.isNotEmpty ? _phoneController.text : null,
      'profileImage': currentUser!['profileImage'],
    };

    await DatabaseHelper.instance.updateUser(widget.userId, updatedUser);

    await _loadUserData();

    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profil mis à jour avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteAccount() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le compte'),
        content: Text('Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteUser(widget.userId);
      await DatabaseHelper.instance.deleteSession(widget.userId);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _changePassword() async {
    final _oldPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Ancien mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmer nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newPasswordController.text != _confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Les mots de passe ne correspondent pas'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (_newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Le mot de passe doit contenir au moins 6 caractères'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, true);
            },
            child: Text('Confirmer'),
          ),
        ],
      ),
    );

    if (result == true) {
      String oldPasswordHash = sha256.convert(utf8.encode(_oldPasswordController.text)).toString();

      if (oldPasswordHash != currentUser!['password']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ancien mot de passe incorrect'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String newPasswordHash = sha256.convert(utf8.encode(_newPasswordController.text)).toString();

      await DatabaseHelper.instance.updateUser(widget.userId, {
        'password': newPasswordHash,
      });

      // Envoi SMS de confirmation si numéro disponible
      if (currentUser!['phoneNumber'] != null && currentUser!['phoneNumber'].toString().isNotEmpty) {
        print('📱 Envoi SMS de confirmation changement mot de passe...');
        bool smsSent = await ApiService.sendSMS(
          phoneNumber: currentUser!['phoneNumber'],
          message: 'ZenLife: Votre mot de passe a été modifié avec succès. Si ce n\'était pas vous, contactez-nous immédiatement.',
        );
        
        if (smsSent) {
          print('✅ SMS de confirmation envoyé');
        }
      }

      await _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mot de passe modifié avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profil')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _saveUserData,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.teal.shade700],
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: currentUser!['profileImage'] != null
                            ? FileImage(File(currentUser!['profileImage']))
                            : null,
                        child: currentUser!['profileImage'] == null
                            ? Icon(Icons.person, size: 60, color: Colors.teal)
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: Icon(Icons.camera_alt, size: 20, color: Colors.teal),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    currentUser!['name'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    currentUser!['email'],
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations personnelles',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: !_isEditing,
                      fillColor: _isEditing ? null : Colors.grey[100],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: !_isEditing,
                      fillColor: _isEditing ? null : Colors.grey[100],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: !_isEditing,
                      fillColor: _isEditing ? null : Colors.grey[100],
                      helperText: 'Pour recevoir les SMS de sécurité',
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Sécurité',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.lock, color: Colors.teal),
                    title: Text('Changer le mot de passe'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _changePassword,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Compte créé le',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  Text(
                    _formatDate(currentUser!['createdAt']),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _deleteAccount,
                      icon: Icon(Icons.delete_forever),
                      label: Text('Supprimer mon compte'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _formatDate(String isoDate) {
    DateTime date = DateTime.parse(isoDate);
    List<String> months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
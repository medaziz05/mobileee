import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../helpers/database_helper.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final existingUser = await DatabaseHelper.instance.getUserByEmail(_emailController.text);

      if (existingUser != null) {
        _showError('Cet email est déjà utilisé');
        setState(() => _isLoading = false);
        return;
      }

      Map<String, dynamic> newUser = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        'password': _hashPassword(_passwordController.text),
        'profileImage': null,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await DatabaseHelper.instance.createUser(newUser);

      print('✅ Utilisateur créé dans la base de données');
      print('📧 Tentative d\'envoi d\'email à ${_emailController.text}');

      // Envoi de l'email de bienvenue
      bool emailSent = await ApiService.sendEmail(
        toEmail: _emailController.text,
        subject: 'Bienvenue sur ZenLife !',
        htmlContent: ApiService.getWelcomeEmailTemplate(_nameController.text),
      );

      // Envoi du SMS de bienvenue si numéro fourni
      if (_phoneController.text.isNotEmpty) {
        print('📱 Tentative d\'envoi de SMS à ${_phoneController.text}');
        bool smsSent = await ApiService.sendSMS(
          phoneNumber: _phoneController.text,
          message: 'Bienvenue sur ZenLife ${_nameController.text} ! 🧘 Votre compte a été créé avec succès.',
        );
        
        if (smsSent) {
          print('✅ SMS envoyé avec succès');
        }
      }

      if (emailSent) {
        _showSuccess('Compte créé avec succès ! Vérifiez votre email.');
      } else {
        _showSuccess('Compte créé avec succès !');
      }

      await Future.delayed(Duration(seconds: 2));
      Navigator.pop(context);

    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');
      _showError('Erreur lors de la création du compte');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal, Colors.teal.shade700],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, size: 70, color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Inscription',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom complet',
                      icon: Icons.person,
                      validator: (val) => val == null || val.isEmpty ? 'Nom requis' : null,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email requis';
                        if (!val.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Numéro de téléphone (optionnel)',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: null,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock,
                      isPassword: true,
                      isVisible: _isPasswordVisible,
                      onVisibilityToggle: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Mot de passe requis';
                        if (val.length < 6) return 'Minimum 6 caractères';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmer mot de passe',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isVisible: _isConfirmPasswordVisible,
                      onVisibilityToggle: () {
                        setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                      },
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.teal,
                              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              "S'inscrire",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Déjà un compte ? Se connecter',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword && onVisibilityToggle != null
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
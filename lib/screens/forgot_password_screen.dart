import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../helpers/database_helper.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;

  Future<void> _sendVerificationCode() async {
    if (_emailController.text.isEmpty) {
      _showError('Veuillez entrer votre email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await DatabaseHelper.instance.getUserByEmail(_emailController.text);

      if (user == null) {
        _showError('Aucun compte trouvé avec cet email');
        setState(() => _isLoading = false);
        return;
      }

      String verificationCode = _generateCode();
      print('🔐 Code généré: $verificationCode pour ${_emailController.text}');

      await DatabaseHelper.instance.createPasswordReset(_emailController.text, verificationCode);

      // Envoi de l'email via API
      print('📧 Tentative d\'envoi d\'email de réinitialisation...');
      bool emailSent = await ApiService.sendEmail(
        toEmail: _emailController.text,
        subject: 'Réinitialisation de votre mot de passe ZenLife',
        htmlContent: ApiService.getPasswordResetEmailTemplate(verificationCode),
      );

      if (emailSent) {
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
        _showSuccess('Code de vérification envoyé à votre email !');
      } else {
        _showError('Erreur lors de l\'envoi de l\'email. Veuillez réessayer.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Erreur: $e');
      _showError('Une erreur est survenue');
      setState(() => _isLoading = false);
    }
  }

  String _generateCode() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<void> _resetPassword() async {
    if (_codeController.text.isEmpty) {
      _showError('Veuillez entrer le code de vérification');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showError('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() => _isLoading = true);

    final resetRequest = await DatabaseHelper.instance.getPasswordReset(
      _emailController.text,
      _codeController.text,
    );

    if (resetRequest == null) {
      _showError('Code de vérification incorrect ou expiré');
      setState(() => _isLoading = false);
      return;
    }

    DateTime expiresAt = DateTime.parse(resetRequest['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      _showError('Le code a expiré. Veuillez en demander un nouveau.');
      await DatabaseHelper.instance.deletePasswordReset(_emailController.text);
      setState(() => _isLoading = false);
      return;
    }

    final user = await DatabaseHelper.instance.getUserByEmail(_emailController.text);
    if (user != null) {
      await DatabaseHelper.instance.updateUser(user['id'], {
        'password': _hashPassword(_newPasswordController.text),
      });

      // Envoi SMS de confirmation si numéro disponible
      if (user['phoneNumber'] != null && user['phoneNumber'].toString().isNotEmpty) {
        await ApiService.sendSMS(
          phoneNumber: user['phoneNumber'],
          message: 'ZenLife: Votre mot de passe a été réinitialisé avec succès. Si ce n\'était pas vous, contactez-nous immédiatement.',
        );
      }
    }

    await DatabaseHelper.instance.deletePasswordReset(_emailController.text);

    _showSuccess('Mot de passe réinitialisé avec succès !');
    await Future.delayed(Duration(seconds: 1));
    Navigator.pop(context);

    setState(() => _isLoading = false);
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
      appBar: AppBar(title: Text('Mot de passe oublié')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_reset, size: 80, color: Colors.teal),
            SizedBox(height: 30),
            Text(
              'Réinitialiser le mot de passe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Entrez votre email pour recevoir un code de vérification',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _emailController,
              enabled: !_codeSent,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (_codeSent) ...[
              SizedBox(height: 16),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Code de vérification',
                  prefixIcon: Icon(Icons.pin),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
            SizedBox(height: 30),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _codeSent ? _resetPassword : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _codeSent ? 'Réinitialiser' : 'Envoyer le code',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
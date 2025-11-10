// Créez ce fichier: lib/test_env.dart
// Pour tester que votre .env fonctionne

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/api_service.dart';

class TestEnvScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Configuration')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔍 Vérification des variables d\'environnement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            
            _buildConfigRow(
              'SENDGRID_API_KEY',
              dotenv.env['SENDGRID_API_KEY'] ?? 'MANQUANT',
              dotenv.env['SENDGRID_API_KEY']?.isNotEmpty ?? false,
            ),
            
            _buildConfigRow(
              'SENDER_EMAIL',
              dotenv.env['SENDER_EMAIL'] ?? 'MANQUANT',
              dotenv.env['SENDER_EMAIL']?.isNotEmpty ?? false,
            ),
            
            _buildConfigRow(
              'TWILIO_ACCOUNT_SID',
              dotenv.env['TWILIO_ACCOUNT_SID'] ?? 'MANQUANT',
              dotenv.env['TWILIO_ACCOUNT_SID']?.isNotEmpty ?? false,
            ),
            
            _buildConfigRow(
              'TWILIO_AUTH_TOKEN',
              dotenv.env['TWILIO_AUTH_TOKEN'] ?? 'MANQUANT',
              dotenv.env['TWILIO_AUTH_TOKEN']?.isNotEmpty ?? false,
            ),
            
            _buildConfigRow(
              'TWILIO_PHONE_NUMBER',
              dotenv.env['TWILIO_PHONE_NUMBER'] ?? 'MANQUANT',
              dotenv.env['TWILIO_PHONE_NUMBER']?.isNotEmpty ?? false,
            ),
            
            SizedBox(height: 30),
            
            Text('🧪 Tests rapides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: () => _testEmail(context),
              icon: Icon(Icons.email),
              label: Text('Tester l\'envoi d\'email'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            
            SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: () => _testSMS(context),
              icon: Icon(Icons.sms),
              label: Text('Tester l\'envoi de SMS'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String key, String value, bool isValid) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          isValid ? Icons.check_circle : Icons.error,
          color: isValid ? Colors.green : Colors.red,
        ),
        title: Text(key, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          value.length > 20 ? '${value.substring(0, 20)}...' : value,
          style: TextStyle(fontFamily: 'monospace'),
        ),
      ),
    );
  }

  void _testEmail(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Test Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Envoi d\'un email de test...'),
          ],
        ),
      ),
    );

    bool success = await ApiService.sendEmail(
      toEmail: dotenv.env['SENDER_EMAIL'] ?? 'test@test.com',
      subject: 'Test ZenLife - Email',
      htmlContent: '<h1>Test réussi !</h1><p>Votre configuration email fonctionne.</p>',
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ Email envoyé !' : '❌ Échec de l\'envoi'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _testSMS(BuildContext context) async {
    // Demander le numéro
    TextEditingController phoneController = TextEditingController();
    
    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test SMS'),
        content: TextField(
          controller: phoneController,
          decoration: InputDecoration(
            labelText: 'Numéro de téléphone',
            hintText: '+33612345678',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Envoyer'),
          ),
        ],
      ),
    );

    if (proceed != true || phoneController.text.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Test SMS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Envoi d\'un SMS de test...'),
          ],
        ),
      ),
    );

    bool success = await ApiService.sendSMS(
      phoneNumber: phoneController.text,
      message: 'Test ZenLife - Votre configuration SMS fonctionne !',
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ SMS envoyé !' : '❌ Échec de l\'envoi'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
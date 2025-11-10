import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // ===== EMAIL API (SendGrid) =====
  static Future<bool> sendEmail({
    required String toEmail,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      final apiKey = dotenv.env['SENDGRID_API_KEY'] ?? '';
      final senderEmail = dotenv.env['SENDER_EMAIL'] ?? '';
      final senderName = dotenv.env['SENDER_NAME'] ?? 'ZenLife';

      print('🔍 Debug - Envoi email à: $toEmail');
      print('🔍 Debug - API Key présente: ${apiKey.isNotEmpty}');
      print('🔍 Debug - API Key (premiers chars): ${apiKey.length > 10 ? apiKey.substring(0, 10) + "..." : "VIDE"}');
      print('🔍 Debug - Sender: $senderEmail');

      if (apiKey.isEmpty) {
        print('❌ ERREUR: SENDGRID_API_KEY manquante dans .env');
        return false;
      }

      // Vérification du format de la clé
      if (!apiKey.startsWith('SG.')) {
        print('❌ ERREUR: Format de clé SendGrid invalide (doit commencer par "SG.")');
        return false;
      }

      final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'personalizations': [
            {
              'to': [
                {'email': toEmail}
              ],
              'subject': subject,
            }
          ],
          'from': {
            'email': senderEmail,
            'name': senderName,
          },
          'content': [
            {
              'type': 'text/html',
              'value': htmlContent,
            }
          ],
        }),
      );

      print('📧 Status Code: ${response.statusCode}');
      print('📧 Response Body: ${response.body}');

      if (response.statusCode == 202) {
        print('✅ Email envoyé avec succès à $toEmail');
        return true;
      } else {
        print('❌ Erreur SendGrid: ${response.body}');
        if (response.statusCode == 401) {
          print('⚠️ ERREUR 401: Clé API invalide ou expirée. Générez une nouvelle clé sur SendGrid.');
        } else if (response.statusCode == 403) {
          print('⚠️ ERREUR 403: Email expéditeur non vérifié. Vérifiez votre Sender Authentication sur SendGrid.');
        }
        return false;
      }
    } catch (e) {
      print('❌ Exception lors de l\'envoi de l\'email: $e');
      return false;
    }
  }

  // ===== SMS API (Twilio) =====
  static Future<bool> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final accountSid = dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
      final authToken = dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
      final twilioNumber = dotenv.env['TWILIO_PHONE_NUMBER'] ?? '';

      // CORRECTION : Normalisation spécifique pour votre numéro 25985364
      String normalizedPhone = phoneNumber.trim();
      
      print('🔍 Numéro reçu: "$normalizedPhone"');
      
      // Supprimer tous les caractères non numériques
      normalizedPhone = normalizedPhone.replaceAll(RegExp(r'[^\d]'), '');
      
      print('🔍 Après nettoyage: "$normalizedPhone"');
      
      // CORRECTION SPÉCIFIQUE POUR VOTRE CAS
      // Si le numéro est exactement "25985364" (8 chiffres sans indicatif)
      if (normalizedPhone == '25985364') {
        normalizedPhone = '+21625985364';
      }
      // Si c'est un autre numéro tunisien de 8 chiffres sans indicatif
      else if (normalizedPhone.length == 8 && !normalizedPhone.startsWith('+')) {
        normalizedPhone = '+216$normalizedPhone';
      }
      // Si c'est un numéro avec 0 au début (ex: 025985364)
      else if (normalizedPhone.length == 9 && normalizedPhone.startsWith('0')) {
        normalizedPhone = '+216${normalizedPhone.substring(1)}';
      }
      // Si le numéro commence par 216 sans le +
      else if (normalizedPhone.startsWith('216') && normalizedPhone.length == 11) {
        normalizedPhone = '+$normalizedPhone';
      }
      
      print('🎯 Numéro final pour Twilio: "$normalizedPhone"');
      print('🔍 Debug - Account SID présent: ${accountSid.isNotEmpty}');
      print('🔍 Debug - From: $twilioNumber');

      if (accountSid.isEmpty || authToken.isEmpty) {
        print('❌ ERREUR: Credentials Twilio manquants dans .env');
        return false;
      }

      final url = Uri.parse(
          'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');

      final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': twilioNumber,
          'To': normalizedPhone,
          'Body': message,
        },
      );

      print('📱 Status Code: ${response.statusCode}');
      print('📱 Response Body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ SMS envoyé avec succès à $normalizedPhone');
        return true;
      } else {
        print('❌ Erreur Twilio: ${response.body}');
        if (response.statusCode == 401) {
          print('⚠️ ERREUR 401: Credentials Twilio invalides. Vérifiez Account SID et Auth Token.');
        } else if (response.statusCode == 400) {
          final errorData = json.decode(response.body);
          print('⚠️ ERREUR 400: ${errorData['message']}');
        }
        return false;
      }
    } catch (e) {
      print('❌ Exception lors de l\'envoi du SMS: $e');
      return false;
    }
  }

  // ===== ALTERNATIVE: SMS avec Vonage =====
  static Future<bool> sendSMSVonage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final apiKey = dotenv.env['VONAGE_API_KEY'] ?? '';
      final apiSecret = dotenv.env['VONAGE_API_SECRET'] ?? '';
      final vonageNumber = dotenv.env['VONAGE_PHONE_NUMBER'] ?? '';

      final url = Uri.parse('https://rest.nexmo.com/sms/json');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'api_key': apiKey,
          'api_secret': apiSecret,
          'from': vonageNumber,
          'to': phoneNumber,
          'text': message,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['messages'][0]['status'] == '0';
      }
      return false;
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du SMS (Vonage): $e');
      return false;
    }
  }

  // ===== TEMPLATES EMAIL =====
  static String getPasswordResetEmailTemplate(String code) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; background-color: #f5f5f5; padding: 20px; }
    .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; }
    .header { text-align: center; color: #009688; }
    .code { font-size: 32px; font-weight: bold; text-align: center; padding: 20px; background: #e0f2f1; border-radius: 8px; margin: 30px 0; letter-spacing: 8px; }
    .footer { text-align: center; color: #999; font-size: 12px; margin-top: 30px; }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="header">🔐 Réinitialisation de mot de passe</h1>
    <p>Bonjour,</p>
    <p>Vous avez demandé la réinitialisation de votre mot de passe ZenLife.</p>
    <p>Voici votre code de vérification :</p>
    <div class="code">$code</div>
    <p>Ce code expire dans 15 minutes.</p>
    <p>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
    <div class="footer">
      <p>© 2025 ZenLife - Votre bien-être au quotidien</p>
    </div>
  </div>
</body>
</html>
    ''';
  }

  static String getWelcomeEmailTemplate(String name) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; background-color: #f5f5f5; padding: 20px; }
    .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; }
    .header { text-align: center; color: #009688; }
    .welcome { text-align: center; font-size: 48px; margin: 20px 0; }
    .footer { text-align: center; color: #999; font-size: 12px; margin-top: 30px; }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="header">✨ Bienvenue sur ZenLife !</h1>
    <div class="welcome">🧘</div>
    <p>Bonjour <strong>$name</strong>,</p>
    <p>Nous sommes ravis de vous accueillir dans la communauté ZenLife !</p>
    <p>Votre compte a été créé avec succès. Vous pouvez maintenant :</p>
    <ul>
      <li>📊 Suivre vos activités quotidiennes</li>
      <li>🍎 Gérer votre nutrition</li>
      <li>🧘 Pratiquer la méditation</li>
      <li>👥 Rejoindre la communauté</li>
    </ul>
    <p>Prenez soin de vous et profitez de votre parcours vers le bien-être !</p>
    <div class="footer">
      <p>© 2025 ZenLife - Votre bien-être au quotidien</p>
    </div>
  </div>
</body>
</html>
    ''';
  }
}
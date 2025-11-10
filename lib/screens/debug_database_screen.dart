import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/database_helper.dart';

class DebugDatabaseScreen extends StatefulWidget {
  @override
  _DebugDatabaseScreenState createState() => _DebugDatabaseScreenState();
}

class _DebugDatabaseScreenState extends State<DebugDatabaseScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> sessions = [];
  List<Map<String, dynamic>> passwordResets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() => isLoading = true);
    
    try {
      final usersData = await DatabaseHelper.instance.getAllUsers();
      final sessionsData = await DatabaseHelper.instance.getAllSessions();
      final resetsData = await DatabaseHelper.instance.getAllPasswordResets();
      
      setState(() {
        users = usersData;
        sessions = sessionsData;
        passwordResets = resetsData;
        isLoading = false;
      });
      
      // Affiche aussi dans la console
      _printDatabaseSummary();
      
    } catch (e) {
      print('❌ Erreur : $e');
      setState(() => isLoading = false);
    }
  }

  void _printDatabaseSummary() {
    print('''
=== 📊 RÉSUMÉ BASE DE DONNÉES ===
👥 UTILISATEURS: ${users.length}
${users.map((u) => '   - ${u['id']}: ${u['name']} (${u['email']})').join('\n')}

🔐 SESSIONS: ${sessions.length}
${sessions.map((s) => '   - User${s['userId']}: ${s['isActive'] == 1 ? 'ACTIVE' : 'INACTIVE'}').join('\n')}

🔑 PASSWORD RESETS: ${passwordResets.length}
    ''');
  }

  Future<void> _copyAllDataToClipboard() async {
    final content = '''
=== ZENLIFE - DONNÉES COMPLÈTES ===
Exporté le: ${DateTime.now()}

👥 TABLE UTILISATEURS (${users.length})
${users.isEmpty ? 'Aucun utilisateur' : users.map((u) => '''
├─ ID: ${u['id']}
├─ Nom: ${u['name']}
├─ Email: ${u['email']}
├─ Téléphone: ${u['phoneNumber'] ?? 'Non renseigné'}
├─ Image: ${u['profileImage'] ?? 'Aucune'}
└─ Créé le: ${u['createdAt']}
''' ).join('\n')}

🔐 TABLE SESSIONS (${sessions.length})
${sessions.isEmpty ? 'Aucune session' : sessions.map((s) => '''
├─ ID: ${s['id']}
├─ UserID: ${s['userId']}
├─ Active: ${s['isActive'] == 1 ? 'OUI' : 'NON'}
└─ Dernière connexion: ${s['lastLogin']}
''' ).join('\n')}

🔑 TABLE PASSWORD_RESETS (${passwordResets.length})
${passwordResets.isEmpty ? 'Aucun reset en cours' : passwordResets.map((r) => '''
├─ ID: ${r['id']}
├─ Email: ${r['email']}
├─ Code: ${r['code']}
├─ Créé: ${r['createdAt']}
└─ Expire: ${r['expiresAt']}
''' ).join('\n')}
''';

    await Clipboard.setData(ClipboardData(text: content));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Toutes les données copiées ! Collez dans un éditeur.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(user['name'][0].toUpperCase(), style: TextStyle(color: Colors.white)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(user['email'], style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
                Text('ID: ${user['id']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            if (user['phoneNumber'] != null) ...[
              SizedBox(height: 8),
              Text('📱 ${user['phoneNumber']}'),
            ],
            SizedBox(height: 4),
            Text('📅 Inscrit le: ${_formatDate(user['createdAt'])}', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      DateTime date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔍 Base de Données ZenLife'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDatabaseInfo,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des données...'),
              ],
            ))
          : Column(
              children: [
                // En-tête avec statistiques
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  color: Colors.teal[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('👥 Utilisateurs', users.length, Colors.blue),
                      _buildStatItem('🔐 Sessions', sessions.length, Colors.green),
                      _buildStatItem('🔑 Resets', passwordResets.length, Colors.orange),
                    ],
                  ),
                ),

                // Bouton d'export
                Padding(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _copyAllDataToClipboard,
                    icon: Icon(Icons.content_copy),
                    label: Text('COPIER TOUTES LES DONNÉES'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ),

                // Liste des données
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Text('Utilisateurs enregistrés:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ...users.map((user) => _buildUserCard(user)).toList(),
                      
                      if (sessions.isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text('Sessions actives:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ...sessions.map((session) => Card(
                          margin: EdgeInsets.only(bottom: 8),
                          color: session['isActive'] == 1 ? Colors.green[50] : Colors.grey[100],
                          child: ListTile(
                            leading: Icon(session['isActive'] == 1 ? Icons.check_circle : Icons.cancel, 
                                     color: session['isActive'] == 1 ? Colors.green : Colors.grey),
                            title: Text('Utilisateur ID: ${session['userId']}'),
                            subtitle: Text('Dernière connexion: ${_formatDate(session['lastLogin'])}'),
                            trailing: Text(session['isActive'] == 1 ? 'ACTIVE' : 'INACTIVE', 
                                     style: TextStyle(color: session['isActive'] == 1 ? Colors.green : Colors.grey)),
                          ),
                        )).toList(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
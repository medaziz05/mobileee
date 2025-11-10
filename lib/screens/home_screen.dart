import 'package:flutter/material.dart';
import 'dart:io';
import '../helpers/database_helper.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  const HomeScreen({super.key, required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DatabaseHelper.instance.getUserById(widget.userId);
    setState(() {
      currentUser = user;
      });
  }

  Future<void> _logout() async {
    await DatabaseHelper.instance.deleteSession(widget.userId);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ZenLife'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId)),
              );
              _loadUserData();
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: currentUser == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.teal,
                            backgroundImage: currentUser!['profileImage'] != null
                                ? FileImage(File(currentUser!['profileImage']))
                                : null,
                            child: currentUser!['profileImage'] == null
                                ? Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour,',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                                Text(
                                  currentUser!['name'],
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currentUser!['email'],
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Modules disponibles',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildModuleCard(
                    'Activités',
                    'Suivez vos activités quotidiennes',
                    Icons.directions_run,
                    Colors.orange,
                  ),
                  _buildModuleCard(
                    'Nutrition',
                    'Gérez vos repas et calories',
                    Icons.restaurant,
                    Colors.green,
                  ),
                  _buildModuleCard(
                    'Méditation',
                    'Séances de relaxation guidées',
                    Icons.self_improvement,
                    Colors.purple,
                  ),
                  _buildModuleCard(
                    'Communauté',
                    'Partagez avec la communauté',
                    Icons.forum,
                    Colors.blue,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildModuleCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Module $title - Bientôt disponible !')),
          );
        },
      ),
    );
  }
}
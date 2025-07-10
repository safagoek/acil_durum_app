import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminScreen extends StatefulWidget {
  final String baseUrl;

  AdminScreen({required this.baseUrl});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool isLoggedIn = false;
  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return AdminLoginPage(
        baseUrl: widget.baseUrl,
        onLogin: () => setState(() => isLoggedIn = true),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => setState(() => isLoggedIn = false),
          ),
        ],
      ),
      body: currentTab == 0 
        ? EmergencyCallsTab(baseUrl: widget.baseUrl)
        : currentTab == 1
        ? CreateAnnouncementTab(baseUrl: widget.baseUrl)
        : currentTab == 2
        ? ManageAnnouncementsTab(baseUrl: widget.baseUrl)
        : ArchivedEmergencyCallsTab(baseUrl: widget.baseUrl),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: (index) => setState(() => currentTab = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'Acil Çağrılar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: 'Duyuru Ekle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Duyuru Yönetimi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.archive),
            label: 'Arşiv Çağrılar',
          ),
        ],
      ),
    );
  }
}

// ADMIN GİRİŞ SAYFASI
class AdminLoginPage extends StatefulWidget {
  final String baseUrl;
  final VoidCallback onLogin;

  AdminLoginPage({required this.baseUrl, required this.onLogin});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}?action=admin_login'),
        body: jsonEncode({
          'username': usernameController.text.trim(),
          'password': passwordController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      final result = jsonDecode(response.body);
      
      if (result['success'] == true) {
        widget.onLogin();
      } else {
        _showError('Hatalı kullanıcı adı veya şifre');
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }

    setState(() => isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Girişi')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 32),
              
              Text(
                'YÖNETİCİ PANELİ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Acil durum sistemine giriş yapın',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 40),
              
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kullanıcı adı gerekli';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre gerekli';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _login(),
              ),
              SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('GİRİŞ YAP'),
                ),
              ),
              SizedBox(height: 24),
              
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Test Bilgileri',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kullanıcı Adı: admin\nŞifre: 123',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.blue.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ACİL ÇAĞRILAR SEKMESİ
class EmergencyCallsTab extends StatefulWidget {
  final String baseUrl;

  EmergencyCallsTab({required this.baseUrl});

  @override
  _EmergencyCallsTabState createState() => _EmergencyCallsTabState();
}

class _EmergencyCallsTabState extends State<EmergencyCallsTab> {
  List emergencyCalls = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadEmergencyCalls();
  }

  Future<void> _loadEmergencyCalls() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}?action=get_emergency_calls'),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        emergencyCalls = jsonDecode(response.body);
      } else {
        error = 'Sunucu hatası: ${response.statusCode}';
      }
    } catch (e) {
      error = 'Bağlantı hatası: $e';
    }

    setState(() => isLoading = false);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return dateStr;
    }
  }

  void _showMapInfo(Map call) {
    final googleMapsUrl = 'https://www.google.com/maps?q=${call['latitude']},${call['longitude']}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konum Bilgisi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${call['ad']} ${call['soyad']} konumu:'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enlem: ${call['latitude']}', style: TextStyle(fontFamily: 'monospace')),
                  Text('Boylam: ${call['longitude']}', style: TextStyle(fontFamily: 'monospace')),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text('Google Maps URL:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            SelectableText(
              googleMapsUrl,
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveEmergencyCall(int id) async {
    bool? confirmed = await _showArchiveConfirmDialog();
    if (confirmed != true) return;

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}?action=archive_emergency_call'),
        body: jsonEncode({'id': id}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      final result = jsonDecode(response.body);
      
      if (result['success'] == true) {
        _showSuccess('Acil çağrı arşivlendi');
        _loadEmergencyCalls();
      } else {
        _showError('Arşivleme başarısız: ${result['error'] ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  Future<bool?> _showArchiveConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çağrıyı Arşivle'),
        content: Text('Bu acil çağrı arşivlenecek ve aktif listeden kaldırılacak. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('ARŞİVLE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Acil çağrılar yükleniyor...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              SizedBox(height: 16),
              Text('Hata Oluştu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(error!, textAlign: TextAlign.center),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadEmergencyCalls,
                icon: Icon(Icons.refresh),
                label: Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (emergencyCalls.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emergency_outlined, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'Henüz Acil Çağrı Yok',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
              SizedBox(height: 8),
              Text('Sistem aktif, acil çağrılar buraya gelecek.'),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadEmergencyCalls,
                icon: Icon(Icons.refresh),
                label: Text('Yenile'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // İstatistik
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Acil Çağrı',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${emergencyCalls.length}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadEmergencyCalls,
                icon: Icon(Icons.refresh, color: Colors.red),
                tooltip: 'Yenile',
              ),
            ],
          ),
        ),
        
        // Çağrı listesi
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadEmergencyCalls,
            color: Colors.red,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: emergencyCalls.length,
              itemBuilder: (context, index) {
                final call = emergencyCalls[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.emergency, color: Colors.red, size: 20),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${call['ad']} ${call['soyad']}',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'TC: ${call['tc_kimlik']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatDate(call['created_at']),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Mesaj
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Acil Durum Mesajı:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                call['mesaj'],
                                style: TextStyle(fontSize: 14, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        // Konum
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Konum Bilgisi:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${call['latitude']}, ${call['longitude']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Butonlar
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showMapInfo(call),
                                icon: Icon(Icons.map, size: 18),
                                label: Text('Haritada Gör'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final info = 'Ad: ${call['ad']} ${call['soyad']}\n'
                                             'TC: ${call['tc_kimlik']}\n'
                                             'Mesaj: ${call['mesaj']}\n'
                                             'Konum: ${call['latitude']}, ${call['longitude']}\n'
                                             'Tarih: ${call['created_at']}';
                                  
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Çağrı Detayları'),
                                      content: SelectableText(info),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Kapat'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: Icon(Icons.info, size: 18),
                                label: Text('Detaylar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _archiveEmergencyCall(int.parse(call['id'].toString())),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                minimumSize: Size(50, 36),
                              ),
                              child: Icon(Icons.archive, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// DUYURU OLUŞTURMA SEKMESİ
class CreateAnnouncementTab extends StatefulWidget {
  final String baseUrl;

  CreateAnnouncementTab({required this.baseUrl});

  @override
  _CreateAnnouncementTabState createState() => _CreateAnnouncementTabState();
}

class _CreateAnnouncementTabState extends State<CreateAnnouncementTab> {
  final _formKey = GlobalKey<FormState>();
  final baslikController = TextEditingController();
  final icerikController = TextEditingController();
  String selectedPriority = 'Orta';
  bool isLoading = false;

  final List<String> priorities = ['Düşük', 'Orta', 'Yüksek'];

  @override
  void dispose() {
    baslikController.dispose();
    icerikController.dispose();
    super.dispose();
  }

  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    bool? confirmed = await _showConfirmDialog();
    if (confirmed != true) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}?action=create_announcement'),
        body: jsonEncode({
          'baslik': baslikController.text.trim(),
          'icerik': icerikController.text.trim(),
          'oncelik': selectedPriority,
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      final result = jsonDecode(response.body);
      
      if (result['success'] == true) {
        _showSuccessDialog();
        _clearForm();
      } else {
        _showError('Oluşturma başarısız: ${result['error'] ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }

    setState(() => isLoading = false);
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Duyuru Onayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bu duyuru tüm vatandaşlara gönderilecek:'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Başlık: ${baslikController.text}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Öncelik: $selectedPriority'),
                  SizedBox(height: 8),
                  Text(icerikController.text),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('OLUŞTUR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Başarılı'),
          ],
        ),
        content: Text('Duyuru başarıyla oluşturuldu!\n\nTüm vatandaşlar bu duyuruyu görebilecek.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('TAMAM', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    baslikController.clear();
    icerikController.clear();
    setState(() => selectedPriority = 'Orta');
  }

  String _getPriorityIcon(String priority) {
    switch (priority) {
      case 'Yüksek': return '🔴';
      case 'Orta': return '🟡';
      case 'Düşük': return '🟢';
      default: return '🟡';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Yüksek': return Colors.red;
      case 'Orta': return Colors.orange;
      case 'Düşük': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Başlık
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.announcement, size: 50, color: Colors.green),
                  SizedBox(height: 10),
                  Text(
                    'YENİ DUYURU OLUŞTUR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Tüm vatandaşlara duyuru gönderin',
                    style: TextStyle(color: Colors.green.shade600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Başlık
            TextFormField(
              controller: baslikController,
              decoration: InputDecoration(
                labelText: 'Duyuru Başlığı *',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
                helperText: 'Duyurunuz için açıklayıcı bir başlık',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Başlık gerekli';
                }
                if (value.trim().length < 5) {
                  return 'Başlık en az 5 karakter olmalıdır';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 16),
            
            // Öncelik
            DropdownButtonFormField<String>(
              value: selectedPriority,
              decoration: InputDecoration(
                labelText: 'Öncelik Seviyesi *',
                prefixIcon: Icon(Icons.priority_high),
                border: OutlineInputBorder(),
                helperText: 'Duyurunuzun önem seviyesi',
              ),
              items: priorities.map((String priority) {
                final color = _getPriorityColor(priority);
                final icon = _getPriorityIcon(priority);
                
                return DropdownMenuItem<String>(
                  value: priority,
                  child: Row(
                    children: [
                      Text(icon),
                      SizedBox(width: 8),
                      Text(priority),
                      SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() => selectedPriority = newValue!);
              },
            ),
            SizedBox(height: 16),
            
            // İçerik
            TextFormField(
              controller: icerikController,
              decoration: InputDecoration(
                labelText: 'Duyuru İçeriği *',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                helperText: 'Duyuru detaylarını açık ve anlaşılır şekilde yazın',
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'İçerik gerekli';
                }
                if (value.trim().length < 20) {
                  return 'İçerik en az 20 karakter olmalıdır';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 24),
            
            // Önizleme
            if (baslikController.text.isNotEmpty || icerikController.text.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.preview, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Duyuru Önizlemesi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(selectedPriority).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getPriorityColor(selectedPriority).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_getPriorityIcon(selectedPriority)),
                                      SizedBox(width: 4),
                                      Text(
                                        selectedPriority,
                                        style: TextStyle(
                                          color: _getPriorityColor(selectedPriority),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  'Şimdi',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              baslikController.text.isEmpty ? 'Duyuru Başlığı' : baslikController.text,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: baslikController.text.isEmpty ? Colors.grey : null,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              icerikController.text.isEmpty ? 'Duyuru içeriği buraya gelecek...' : icerikController.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: icerikController.text.isEmpty ? Colors.grey : Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 32),
            
            // Oluştur butonu
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: isLoading ? null : _createAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('OLUŞTURULUYOR...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 24),
                          SizedBox(width: 8),
                          Text('DUYURU OLUŞTUR'),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 16),
            
            // Temizle butonu
            if (baslikController.text.isNotEmpty || icerikController.text.isNotEmpty)
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _clearForm,
                  icon: Icon(Icons.clear_all),
                  label: Text('FORMU TEMİZLE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            SizedBox(height: 16),
            
            // Bilgilendirme
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu duyuru tüm vatandaş kullanıcılarına gönderilecektir. '
                      'Açık ve anlaşılır bir dil kullanın.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        height: 1.4,
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
}

// DUYURU YÖNETİMİ SEKMESİ
class ManageAnnouncementsTab extends StatefulWidget {
  final String baseUrl;

  ManageAnnouncementsTab({required this.baseUrl});

  @override
  _ManageAnnouncementsTabState createState() => _ManageAnnouncementsTabState();
}

class _ManageAnnouncementsTabState extends State<ManageAnnouncementsTab> {
  List allAnnouncements = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}?action=get_all_announcements'),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        allAnnouncements = jsonDecode(response.body);
      } else {
        error = 'Sunucu hatası: ${response.statusCode}';
      }
    } catch (e) {
      error = 'Bağlantı hatası: $e';
    }

    setState(() => isLoading = false);
  }

  Future<void> _editAnnouncement(Map announcement) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditAnnouncementDialog(announcement: announcement),
    );

    if (result != null) {
      await _updateAnnouncement(result);
    }
  }

  Future<void> _updateAnnouncement(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}?action=update_announcement'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      final result = jsonDecode(response.body);
      
      if (result['success'] == true) {
        _showSuccess('Duyuru başarıyla güncellendi');
        _loadAnnouncements();
      } else {
        _showError('Güncelleme başarısız: ${result['error'] ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    bool? confirmed = await _showDeleteConfirmDialog();
    if (confirmed != true) return;

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}?action=delete_announcement'),
        body: jsonEncode({'id': id}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      final result = jsonDecode(response.body);
      
      if (result['success'] == true) {
        _showSuccess('Duyuru başarıyla silindi');
        _loadAnnouncements();
      } else {
        _showError('Silme başarısız: ${result['error'] ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  Future<void> _toggleAnnouncementStatus(int id, String currentStatus) async {
    final newStatus = currentStatus == 'aktif' ? 'arsivlendi' : 'aktif';
    final action = newStatus == 'arsivlendi' ? 'archive_announcement' : 'activate_announcement';

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}?action=$action'),
        body: jsonEncode({'id': id}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      final result = jsonDecode(response.body);
      
      if (result['success'] == true) {
        _showSuccess('Duyuru durumu güncellendi');
        _loadAnnouncements();
      } else {
        _showError('Durum güncelleme başarısız: ${result['error'] ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  Future<bool?> _showDeleteConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Duyuru Silme'),
        content: Text('Bu duyuru kalıcı olarak silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('SİL', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Yüksek': return Colors.red;
      case 'Orta': return Colors.orange;
      case 'Düşük': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getPriorityIcon(String priority) {
    switch (priority) {
      case 'Yüksek': return '🔴';
      case 'Orta': return '🟡';
      case 'Düşük': return '🟢';
      default: return '🟡';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text('Duyurular yükleniyor...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              SizedBox(height: 16),
              Text('Hata Oluştu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(error!, textAlign: TextAlign.center),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAnnouncements,
                icon: Icon(Icons.refresh),
                label: Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ),
      );
    }

    if (allAnnouncements.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.announcement_outlined, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'Henüz Duyuru Yok',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
              SizedBox(height: 8),
              Text('Yeni duyuru oluşturmak için "Duyuru Ekle" sekmesini kullanın.'),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAnnouncements,
                icon: Icon(Icons.refresh),
                label: Text('Yenile'),
              ),
            ],
          ),
        ),
      );
    }

    final activeAnnouncements = allAnnouncements.where((a) => a['status'] == 'aktif').toList();
    final archivedAnnouncements = allAnnouncements.where((a) => a['status'] == 'arsivlendi').toList();

    return Column(
      children: [
        // İstatistik
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.manage_accounts, color: Colors.blue, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toplam Duyuru',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${allAnnouncements.length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktif',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${activeAnnouncements.length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arşivlendi',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${archivedAnnouncements.length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadAnnouncements,
                icon: Icon(Icons.refresh, color: Colors.blue),
                tooltip: 'Yenile',
              ),
            ],
          ),
        ),
        
        // Duyuru listesi
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAnnouncements,
            color: Colors.blue,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: allAnnouncements.length,
              itemBuilder: (context, index) {
                final announcement = allAnnouncements[index];
                final isActive = announcement['status'] == 'aktif';
                
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık ve durum
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(announcement['oncelik']).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getPriorityColor(announcement['oncelik']).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_getPriorityIcon(announcement['oncelik'])),
                                  SizedBox(width: 4),
                                  Text(
                                    announcement['oncelik'],
                                    style: TextStyle(
                                      color: _getPriorityColor(announcement['oncelik']),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.shade100 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'AKTİF' : 'ARŞİVLENDİ',
                                style: TextStyle(
                                  color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        
                        // Başlık
                        Text(
                          announcement['baslik'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.black : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        // İçerik
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            announcement['icerik'],
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isActive ? Colors.black87 : Colors.grey.shade600,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        // Tarih
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                            SizedBox(width: 4),
                            Text(
                              'Oluşturulma: ${_formatDate(announcement['created_at'])}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            if (announcement['updated_at'] != announcement['created_at']) ...[
                              SizedBox(width: 16),
                              Icon(Icons.edit, size: 16, color: Colors.grey.shade500),
                              SizedBox(width: 4),
                              Text(
                                'Düzenleme: ${_formatDate(announcement['updated_at'])}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Butonlar
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _editAnnouncement(announcement),
                                icon: Icon(Icons.edit, size: 18),
                                label: Text('Düzenle'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _toggleAnnouncementStatus(
                                  int.parse(announcement['id'].toString()),
                                  announcement['status'],
                                ),
                                icon: Icon(isActive ? Icons.archive : Icons.unarchive, size: 18),
                                label: Text(isActive ? 'Arşivle' : 'Aktifleştir'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isActive ? Colors.orange : Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _deleteAnnouncement(int.parse(announcement['id'].toString())),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: Size(50, 36),
                              ),
                              child: Icon(Icons.delete, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// DUYURU DÜZENLEME DİYALOGU
class EditAnnouncementDialog extends StatefulWidget {
  final Map announcement;

  EditAnnouncementDialog({required this.announcement});

  @override
  _EditAnnouncementDialogState createState() => _EditAnnouncementDialogState();
}

class _EditAnnouncementDialogState extends State<EditAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController baslikController;
  late TextEditingController icerikController;
  late String selectedPriority;

  final List<String> priorities = ['Düşük', 'Orta', 'Yüksek'];

  @override
  void initState() {
    super.initState();
    baslikController = TextEditingController(text: widget.announcement['baslik']);
    icerikController = TextEditingController(text: widget.announcement['icerik']);
    selectedPriority = widget.announcement['oncelik'];
  }

  @override
  void dispose() {
    baslikController.dispose();
    icerikController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Yüksek': return Colors.red;
      case 'Orta': return Colors.orange;
      case 'Düşük': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getPriorityIcon(String priority) {
    switch (priority) {
      case 'Yüksek': return '🔴';
      case 'Orta': return '🟡';
      case 'Düşük': return '🟢';
      default: return '🟡';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 12),
                  Text(
                    'Duyuru Düzenle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Başlık
              TextFormField(
                controller: baslikController,
                decoration: InputDecoration(
                  labelText: 'Duyuru Başlığı *',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Başlık gerekli';
                  }
                  if (value.trim().length < 5) {
                    return 'Başlık en az 5 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Öncelik
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Öncelik Seviyesi *',
                  prefixIcon: Icon(Icons.priority_high),
                  border: OutlineInputBorder(),
                ),
                items: priorities.map((String priority) {
                  final color = _getPriorityColor(priority);
                  final icon = _getPriorityIcon(priority);
                  
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Row(
                      children: [
                        Text(icon),
                        SizedBox(width: 8),
                        Text(priority),
                        SizedBox(width: 8),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => selectedPriority = newValue!);
                },
              ),
              SizedBox(height: 16),
              
              // İçerik
              Expanded(
                child: TextFormField(
                  controller: icerikController,
                  decoration: InputDecoration(
                    labelText: 'Duyuru İçeriği *',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'İçerik gerekli';
                    }
                    if (value.trim().length < 20) {
                      return 'İçerik en az 20 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 24),
              
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('İPTAL'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            'id': widget.announcement['id'],
                            'baslik': baslikController.text.trim(),
                            'icerik': icerikController.text.trim(),
                            'oncelik': selectedPriority,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: Text('GÜNCELLE', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ARŞİVLENMİŞ ACİL ÇAĞRILAR SEKMESİ
class ArchivedEmergencyCallsTab extends StatefulWidget {
  final String baseUrl;

  ArchivedEmergencyCallsTab({required this.baseUrl});

  @override
  _ArchivedEmergencyCallsTabState createState() => _ArchivedEmergencyCallsTabState();
}

class _ArchivedEmergencyCallsTabState extends State<ArchivedEmergencyCallsTab> {
  List emergencyCalls = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadArchivedEmergencyCalls();
  }

  Future<void> _loadArchivedEmergencyCalls() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}?action=get_archived_emergency_calls'),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        emergencyCalls = jsonDecode(response.body);
      } else {
        error = 'Sunucu hatası: ${response.statusCode}';
      }
    } catch (e) {
      error = 'Bağlantı hatası: $e';
    }

    setState(() => isLoading = false);
  }

  Future<void> _activateEmergencyCall(int id) async {
    bool? confirmed = await _showActivateConfirmDialog();
    if (confirmed != true) return;

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}?action=activate_emergency_call'),
        body: jsonEncode({'id': id}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      final result = jsonDecode(response.body);
      
      if (result['success'] == true) {
        _showSuccess('Acil çağrı tekrar aktifleştirildi');
        _loadArchivedEmergencyCalls();
      } else {
        _showError('Aktifleştirme başarısız: ${result['error'] ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  Future<bool?> _showActivateConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çağrıyı Aktifleştir'),
        content: Text('Bu acil çağrı tekrar aktif çağrılar listesine taşınacak. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('AKTİFLEŞTİR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showMapInfo(Map call) {
    final googleMapsUrl = 'https://www.google.com/maps?q=${call['latitude']},${call['longitude']}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konum Bilgisi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${call['ad']} ${call['soyad']} konumu:'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enlem: ${call['latitude']}', style: TextStyle(fontFamily: 'monospace')),
                  Text('Boylam: ${call['longitude']}', style: TextStyle(fontFamily: 'monospace')),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text('Google Maps URL:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            SelectableText(
              googleMapsUrl,
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Arşivlenmiş çağrılar yükleniyor...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              SizedBox(height: 16),
              Text('Hata Oluştu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(error!, textAlign: TextAlign.center),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadArchivedEmergencyCalls,
                icon: Icon(Icons.refresh),
                label: Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      );
    }

    if (emergencyCalls.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.archive_outlined, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'Arşivlenmiş Çağrı Yok',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
              SizedBox(height: 8),
              Text('Henüz arşivlenmiş acil çağrı bulunmuyor.'),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadArchivedEmergencyCalls,
                icon: Icon(Icons.refresh),
                label: Text('Yenile'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // İstatistik
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.archive, color: Colors.orange, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arşivlenmiş Acil Çağrı',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${emergencyCalls.length}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadArchivedEmergencyCalls,
                icon: Icon(Icons.refresh, color: Colors.orange),
                tooltip: 'Yenile',
              ),
            ],
          ),
        ),
        
        // Çağrı listesi
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadArchivedEmergencyCalls,
            color: Colors.orange,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: emergencyCalls.length,
              itemBuilder: (context, index) {
                final call = emergencyCalls[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Başlık
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.archive, color: Colors.orange, size: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${call['ad']} ${call['soyad']}',
                                          style: TextStyle(
                                            fontSize: 18, 
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'ARŞİVLENDİ',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'TC: ${call['tc_kimlik']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatDate(call['created_at']),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          
                          // Mesaj
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Acil Durum Mesajı:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  call['mesaj'],
                                  style: TextStyle(
                                    fontSize: 14, 
                                    height: 1.4,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          
                          // Konum
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Konum Bilgisi:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${call['latitude']}, ${call['longitude']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Butonlar
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showMapInfo(call),
                                  icon: Icon(Icons.map, size: 18),
                                  label: Text('Haritada Gör'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final info = 'Ad: ${call['ad']} ${call['soyad']}\n'
                                               'TC: ${call['tc_kimlik']}\n'
                                               'Mesaj: ${call['mesaj']}\n'
                                               'Konum: ${call['latitude']}, ${call['longitude']}\n'
                                               'Tarih: ${call['created_at']}\n'
                                               'Durum: Arşivlenmiş';
                                    
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Çağrı Detayları'),
                                        content: SelectableText(info),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Kapat'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.info, size: 18),
                                  label: Text('Detaylar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _activateEmergencyCall(int.parse(call['id'].toString())),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(50, 36),
                                ),
                                child: Icon(Icons.unarchive, size: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

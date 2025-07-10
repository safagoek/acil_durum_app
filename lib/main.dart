import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'admin.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Acil Durum Sistemi',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  final String baseUrl = 'http://localhost/acil_durum_api/api.php';

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      EmergencyPage(baseUrl: baseUrl),
      AnnouncementsPage(baseUrl: baseUrl),
      MapPage(baseUrl: baseUrl),
    ];
  }

  final List<String> titles = [
    'Acil Yardım',
    'Duyurular', 
    'Toplanma Alanları'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Paneli',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen(baseUrl: baseUrl)),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'Acil Yardım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: 'Duyurular',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Harita',
          ),
        ],
      ),
    );
  }
}

// ACİL DURUM SAYFASI
class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  _EmergencyPageState createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final _formKey = GlobalKey<FormState>();
  final tcController = TextEditingController();
  final adController = TextEditingController();
  final soyadController = TextEditingController();
  final mesajController = TextEditingController();
  
  Position? currentPosition;
  bool isLoading = false;
  bool isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    tcController.dispose();
    adController.dispose();
    soyadController.dispose();
    mesajController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLocationLoading = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          );
        }
      }
    } catch (e) {
      debugPrint('Konum hatası: $e');
    }
    
    setState(() => isLocationLoading = false);
  }

  Future<void> _sendEmergency() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (currentPosition == null) {
      _showSnackBar('Konum bilgisi gerekli. Lütfen konum iznini verin.', Colors.orange);
      return;
    }

    bool? confirmed = await _showConfirmDialog();
    if (confirmed != true) return;

    setState(() => isLoading = true);

    try {
      final dio = Dio();
      dio.options.connectTimeout = Duration(seconds: 30);
      dio.options.receiveTimeout = Duration(seconds: 30);
      dio.options.headers = {
        'Content-Type': 'application/json',
      };

      final response = await dio.post(
        widget.baseUrl + '?action=send_emergency',
        data: jsonEncode({
          'tc': tcController.text.trim(),
          'ad': adController.text.trim(),
          'soyad': soyadController.text.trim(),
          'mesaj': mesajController.text.trim(),
          'lat': currentPosition!.latitude,
          'lng': currentPosition!.longitude,
        }),
      ).timeout(Duration(seconds: 30));

      final result = response.data;
      
      if (result['success'] == true) {
        _showSuccessDialog();
        _clearForm();
      } else {
        _showSnackBar('Gönderim başarısız: ${result['error'] ?? 'Bilinmeyen hata'}', Colors.red);
      }
    } on DioException catch (e) {
      _showSnackBar('Bağlantı hatası: ${e.message}', Colors.red);
    } catch (e) {
      _showSnackBar('Bağlantı hatası: $e', Colors.red);
    }

    setState(() => isLoading = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Acil Çağrı Onayı'),
        content: Text('Acil çağrı gönderilsin mi?\n\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('GÖNDER', style: TextStyle(color: Colors.white)),
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
        content: Text('Acil çağrı başarıyla gönderildi!\n\nYardım ekipleri en kısa sürede sizinle iletişime geçecektir.'),
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

  void _clearForm() {
    _formKey.currentState?.reset();
    tcController.clear();
    adController.clear();
    soyadController.clear();
    mesajController.clear();
  }

  String? _validateTC(String? value) {
    if (value == null || value.isEmpty) return 'TC Kimlik gerekli';
    if (value.length != 11) return 'TC Kimlik 11 haneli olmalıdır';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Sadece rakam girebilirsiniz';
    return null;
  }

  String? _validateName(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field gerekli';
    if (value.trim().length < 2) return '$field en az 2 karakter olmalıdır';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Başlık
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.emergency, size: 50, color: Colors.red),
                  SizedBox(height: 10),
                  Text(
                    'ACİL DURUM ÇAĞRI SİSTEMİ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Acil durumda bu formu doldurun',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // TC Kimlik
            TextFormField(
              controller: tcController,
              decoration: InputDecoration(
                labelText: 'T.C. Kimlik Numarası *',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
                helperText: '11 haneli TC Kimlik numaranız',
              ),
              keyboardType: TextInputType.number,
              maxLength: 11,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateTC,
            ),
            SizedBox(height: 16),
            
            // Ad
            TextFormField(
              controller: adController,
              decoration: InputDecoration(
                labelText: 'Adınız *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _validateName(value, 'Ad'),
            ),
            SizedBox(height: 16),
            
            // Soyad
            TextFormField(
              controller: soyadController,
              decoration: InputDecoration(
                labelText: 'Soyadınız *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _validateName(value, 'Soyad'),
            ),
            SizedBox(height: 16),
            
            // Mesaj
            TextFormField(
              controller: mesajController,
              decoration: InputDecoration(
                labelText: 'Acil Durum Mesajı *',
                prefixIcon: Icon(Icons.message),
                border: OutlineInputBorder(),
                helperText: 'Durumunuzu detaylı olarak açıklayın',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Mesaj gerekli';
                if (value.trim().length < 10) return 'Mesaj en az 10 karakter olmalıdır';
                return null;
              },
            ),
            SizedBox(height: 20),
            
            // Konum bilgisi
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentPosition != null ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: currentPosition != null ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: currentPosition != null ? Colors.green : Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Konum Bilgisi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: currentPosition != null ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                      Spacer(),
                      if (isLocationLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: _getCurrentLocation,
                          iconSize: 20,
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (isLocationLoading)
                    Text('Konum alınıyor...')
                  else if (currentPosition != null)
                    Text(
                      'Lat: ${currentPosition!.latitude.toStringAsFixed(6)}\n'
                      'Lng: ${currentPosition!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    )
                  else
                    Text(
                      'Konum alınamadı. Yenile butonuna basın.',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                ],
              ),
            ),
            SizedBox(height: 32),
            
            // Gönder butonu
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: isLoading ? null : _sendEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
                          Text('GÖNDERİLİYOR...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emergency, size: 28),
                          SizedBox(width: 8),
                          Text('ACİL YARDIM ÇAĞRISI GÖNDER'),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 16),
            
            // Bilgilendirme
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu form sadece gerçek acil durumlar için kullanılmalıdır.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
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

// DUYURULAR SAYFASI
class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  _AnnouncementsPageState createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List announcements = [];
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
      final dio = Dio();
      dio.options.connectTimeout = Duration(seconds: 30);
      dio.options.receiveTimeout = Duration(seconds: 30);
      
      final response = await dio.get(
        '${widget.baseUrl}?action=get_announcements'
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        setState(() {
          announcements = response.data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Sunucu hatası: ${response.statusCode}';
          isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        error = 'Bağlantı hatası: ${e.message}';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Bağlantı hatası: $e';
        isLoading = false;
      });
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Yüksek': return Colors.red;
      case 'Orta': return Colors.orange;
      case 'Düşük': return Colors.green;
      default: return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
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
              Text(
                'Hata Oluştu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(error!, textAlign: TextAlign.center),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAnnouncements,
                icon: Icon(Icons.refresh),
                label: Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (announcements.isEmpty) {
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
              Text('Şu anda görüntülenecek duyuru bulunmuyor.'),
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

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      color: Colors.red,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          final priorityColor = _getPriorityColor(announcement['oncelik']);
          
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve öncelik
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: priorityColor.withAlpha(75)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_getPriorityIcon(announcement['oncelik'])),
                            SizedBox(width: 4),
                            Text(
                              announcement['oncelik'],
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          announcement['baslik'],
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // İçerik
                  Text(
                    announcement['icerik'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                  ),
                  SizedBox(height: 12),
                  
                  // Tarih
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                      SizedBox(width: 4),
                      Text(
                        _formatDate(announcement['created_at']),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// HARİTA SAYFASI - YENİDEN DÜZENLENDİ
class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  List<dynamic> toplanmaAlanlari = [];
  Position? currentPosition;
  List<Map<String, dynamic>> nearestAreas = [];
  bool isLoading = true;
  bool isLocationLoading = false;
  String? error;
  
  final LatLng izmirCenter = LatLng(38.4237, 27.1428);

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('MapPage başlatılıyor...');
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    await _getCurrentLocation();
    await _loadToplanmaAlanlari();
    
    setState(() => isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLocationLoading = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          );
          if (kDebugMode) {
            print('Konum alındı: ${currentPosition!.latitude}, ${currentPosition!.longitude}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Konum alma hatası: $e');
      }
    } finally {
      setState(() => isLocationLoading = false);
    }
  }

  Future<void> _loadToplanmaAlanlari() async {
    try {
      if (kDebugMode) {
        print('API isteği başlatılıyor...');
      }
      
      // İzmir Büyükşehir Belediyesi API'si
      final uri = 'https://openapi.izmir.bel.tr/api/ibb/cbs/afetaciltoplanmaalani';
      
      if (kDebugMode) {
        print('API URL: $uri');
      }
      
      final dio = Dio();
      dio.options.connectTimeout = Duration(seconds: 100);
      dio.options.receiveTimeout = Duration(seconds: 100);
      dio.options.headers = {
        'Accept': 'application/json',
        'User-Agent': 'AcilDurumApp/1.0 (Flutter)',
        'Content-Type': 'application/json',
      };
      
      // Handle TLS/certificate issues with platform-specific settings
      if (!kIsWeb && Platform.isAndroid) {
        // Only for Android: configure to accept all certificates in debug mode
        if (kDebugMode) {
          dio.httpClientAdapter = IOHttpClientAdapter(
            createHttpClient: () {
              final client = HttpClient();
              client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
              return client;
            },
          );
        }
      }
      
      final response = await dio.get(uri).timeout(Duration(seconds: 60));

      if (kDebugMode) {
        print('API Yanıt Kodu: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('API Yanıt Gövdesi (ilk 100 karakter): ${response.data.toString().substring(0, math.min(100, response.data.toString().length))}');
        }
        
        final data = response.data;
        
        if (data is List) {
          // Veriyi filtrele ve doğrula
          setState(() {
            toplanmaAlanlari = data.where((item) {
              if (item == null) return false;
              
              var enlem = item['ENLEM'];
              var boylam = item['BOYLAM'];
              
              // String veya number olabilir, her ikisini de kontrol edelim
              double? lat, lng;
              
              if (enlem != null) {
                if (enlem is String) {
                  lat = double.tryParse(enlem);
                } else if (enlem is num) {
                  lat = enlem.toDouble();
                }
              }
              
              if (boylam != null) {
                if (boylam is String) {
                  lng = double.tryParse(boylam);
                } else if (boylam is num) {
                  lng = boylam.toDouble();
                }
              }
              
              // Geçerli koordinat kontrolü (İzmir sınırları içinde)
              bool isValidCoordinate = lat != null && lng != null && 
                                    lat > 37.5 && lat < 39.5 && // İzmir enlem aralığı
                                    lng > 26.0 && lng < 28.0;   // İzmir boylam aralığı
              
              if (!isValidCoordinate && kDebugMode) {
                print('Geçersiz koordinat filtrendi: lat=$lat, lng=$lng, alan=${item['ADI']}');
              }
              
              return isValidCoordinate;
            }).toList();
          });
          
          if (kDebugMode) {
            print('${toplanmaAlanlari.length} geçerli toplanma alanı yüklendi');
          }
          
          if (toplanmaAlanlari.isEmpty) {
            error = 'API\'den veri alındı ancak geçerli koordinat bulunamadı';
            _loadFallbackData();
          }
        } else {
          throw Exception('API geçersiz veri formatı döndürdü (Liste bekleniyor)');
        }
      } else {
        throw Exception('API Hatası: ${response.statusCode}');
      }
      
      // Verileri aldıktan sonra en yakın alanları hesapla
      _calculateNearestAreas();
      
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Dio Hatası: ${e.message}');
        if (e.response != null) {
          print('Yanıt Kodu: ${e.response!.statusCode}');
        }
      }
      
      setState(() {
        error = 'API bağlantı hatası: ${e.message}';
      });
      _loadFallbackData();
      _calculateNearestAreas();
    } catch (e) {
      setState(() {
        error = 'Bilinmeyen hata: $e';
      });
      if (kDebugMode) {
        print('Genel Hata: $e');
      }
      _loadFallbackData();
      _calculateNearestAreas();
    }
  }

  // Fallback veri fonksiyonu
  void _loadFallbackData() {
    if (kDebugMode) {
      print('Fallback verisi yükleniyor...');
    }
    setState(() {
      toplanmaAlanlari = [
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.321239734907,
    'BOYLAM': 26.765143431249,
    'ILCE': "URLA",
    'MAHALLE': "YENİ",
    'ACIKLAMA': "3529-032-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.490260836861,
    'BOYLAM': 27.132488849816,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "KÖRFEZ",
    'ACIKLAMA': "3530-012-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.085166364875,
    'BOYLAM': 28.216002394612,
    'ILCE': "BEYDAĞ",
    'MAHALLE': "ATATÜRK",
    'ACIKLAMA': "3506-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.662609542686,
    'BOYLAM': 26.752700430406,
    'ILCE': "FOÇA",
    'MAHALLE': "ATATÜRK",
    'ACIKLAMA': "3512-001-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.113356744109,
    'BOYLAM': 27.184530525229,
    'ILCE': "BERGAMA",
    'MAHALLE': "GAZİOSMANPAŞA",
    'ACIKLAMA': "3505-051-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.789450919219,
    'BOYLAM': 26.962659784174,
    'ILCE': "ALİAĞA",
    'MAHALLE': "SİTELER",
    'ACIKLAMA': "3502-023-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.430132364501,
    'BOYLAM': 27.416142238495,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "SEKİZ EYLÜL",
    'ACIKLAMA': "3517-038-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.160549158151,
    'BOYLAM': 27.743549330724,
    'ILCE': "BAYINDIR",
    'MAHALLE': "PINARLI",
    'ACIKLAMA': "3504-047-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 37.946613924009,
    'BOYLAM': 27.369198553689,
    'ILCE': "SELÇUK",
    'MAHALLE': "ATATÜRK",
    'ACIKLAMA': "3526-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.439394688705,
    'BOYLAM': 27.148187456328,
    'ILCE': "KONAK",
    'MAHALLE': "UMURBEY",
    'ACIKLAMA': "3520-100-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.636835278845,
    'BOYLAM': 27.100409657725,
    'ILCE': "MENEMEN",
    'MAHALLE': "BELEN",
    'ACIKLAMA': "3522-012-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.619454194596,
    'BOYLAM': 27.152498531579,
    'ILCE': "MENEMEN",
    'MAHALLE': "EMİRALEM MERKEZ",
    'ACIKLAMA': "3522-022-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.622346163764,
    'BOYLAM': 27.136695604617,
    'ILCE': "MENEMEN",
    'MAHALLE': "YAYLA",
    'ACIKLAMA': "3522-063-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.316274949238,
    'BOYLAM': 26.923365699402,
    'ILCE': "GÜZELBAHÇE",
    'MAHALLE': "PAYAMLI",
    'ACIKLAMA': "3514-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.355706063432,
    'BOYLAM': 26.881151262135,
    'ILCE': "GÜZELBAHÇE",
    'MAHALLE': "KAHRAMANDERE",
    'ACIKLAMA': "3514-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 37.997687659304,
    'BOYLAM': 27.659253062936,
    'ILCE': "TİRE",
    'MAHALLE': "BAŞKÖY",
    'ACIKLAMA': "3527-013-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.517730044127,
    'BOYLAM': 27.270967188219,
    'ILCE': "BORNOVA",
    'MAHALLE': "KARAÇAM",
    'ACIKLAMA': "3507-022-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.362320115727,
    'BOYLAM': 27.099431584475,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "YURDOĞLU",
    'ACIKLAMA': "3531-057-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 37.95674621532,
    'BOYLAM': 27.371113674878,
    'ILCE': "SELÇUK",
    'MAHALLE': "İSA BEY",
    'ACIKLAMA': "3526-010-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.613663430165,
    'BOYLAM': 27.185943686929,
    'ILCE': "MENEMEN",
    'MAHALLE': "AYVACIK",
    'ACIKLAMA': "3522-010-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.4592364522,
    'BOYLAM': 27.44973829248,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "SÜTÇÜLER",
    'ACIKLAMA': "3517-041-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.397325704509,
    'BOYLAM': 27.513563109559,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "AŞAĞIKIZILCA",
    'ACIKLAMA': "3517-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.384691679944,
    'BOYLAM': 27.061053424591,
    'ILCE': "BALÇOVA",
    'MAHALLE': "ÇETİN EMEÇ",
    'ACIKLAMA': "3503-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.453877996621,
    'BOYLAM': 27.106625041141,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "AKSOY",
    'ACIKLAMA': "3516-001-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.542423506232,
    'BOYLAM': 27.132661416751,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "YAMANLAR",
    'ACIKLAMA': "3516-026-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.620378227589,
    'BOYLAM': 27.227778563944,
    'ILCE': "MENEMEN",
    'MAHALLE': "ÇALTI",
    'ACIKLAMA': "3522-017-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.612569607923,
    'BOYLAM': 27.163123741716,
    'ILCE': "MENEMEN",
    'MAHALLE': "GÖKTEPE",
    'ACIKLAMA': "3522-028-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.637052679088,
    'BOYLAM': 27.17895478634,
    'ILCE': "MENEMEN",
    'MAHALLE': "SÜLEYMANLI",
    'ACIKLAMA': "3522-052-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.25334367585,
    'BOYLAM': 27.122865586317,
    'ILCE': "MENDERES",
    'MAHALLE': "BARBAROS",
    'ACIKLAMA': "3521-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.256625016491,
    'BOYLAM': 27.101984397655,
    'ILCE': "MENDERES",
    'MAHALLE': "AKÇAKÖY",
    'ACIKLAMA': "3521-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.259477967698,
    'BOYLAM': 27.069785555192,
    'ILCE': "MENDERES",
    'MAHALLE': "ÇATALCA",
    'ACIKLAMA': "3521-011-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.184292897461,
    'BOYLAM': 27.186095337155,
    'ILCE': "MENDERES",
    'MAHALLE': "TEKELİ ATATÜRK",
    'ACIKLAMA': "3521-045-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.136658742509,
    'BOYLAM': 27.194858129453,
    'ILCE': "MENDERES",
    'MAHALLE': "ÇİLEME",
    'ACIKLAMA': "3521-013-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.494944927705,
    'BOYLAM': 27.117282800815,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "LATİFE HANIM",
    'ACIKLAMA': "3516-016-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.021165250105,
    'BOYLAM': 27.096440820842,
    'ILCE': "MENDERES",
    'MAHALLE': "ÇUKURALTI",
    'ACIKLAMA': "3521-014-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.077752807219,
    'BOYLAM': 26.960030418272,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "MERSİN ALANI",
    'ACIKLAMA': "3525-014-03",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.031318346247,
    'BOYLAM': 27.242263062402,
    'ILCE': "MENDERES",
    'MAHALLE': "GÖLOVA",
    'ACIKLAMA': "3521-023-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.396985112792,
    'BOYLAM': 27.118736711586,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "BAHAR",
    'ACIKLAMA': "3531-018-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.470036914803,
    'BOYLAM': 27.107581008578,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "DEDEBAŞI",
    'ACIKLAMA': "3516-009-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.461466691739,
    'BOYLAM': 27.117060587987,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "BAHARİYE",
    'ACIKLAMA': "3516-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.098567408855,
    'BOYLAM': 27.915520059578,
    'ILCE': "TİRE",
    'MAHALLE': "KOCAALİLER",
    'ACIKLAMA': "3527-058-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.463743579151,
    'BOYLAM': 27.128181784816,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "TERSANE",
    'ACIKLAMA': "3516-023-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.052717036738,
    'BOYLAM': 27.052297991986,
    'ILCE': "MENDERES",
    'MAHALLE': "ORTA",
    'ACIKLAMA': "3521-041-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.05849598995,
    'BOYLAM': 27.036980059965,
    'ILCE': "MENDERES",
    'MAHALLE': "GÜMÜLDÜR İNÖNÜ",
    'ACIKLAMA': "3521-028-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.169113319463,
    'BOYLAM': 26.95343063305,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "ORHANLI",
    'ACIKLAMA': "3525-015-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.242501784095,
    'BOYLAM': 26.815700863872,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "DÜZCE",
    'ACIKLAMA': "3525-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.258217186839,
    'BOYLAM': 26.805444448615,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "TURGUT",
    'ACIKLAMA': "3525-020-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.275906002343,
    'BOYLAM': 26.80866979375,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "İHSANİYE",
    'ACIKLAMA': "3525-012-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.179342314958,
    'BOYLAM': 26.836151054157,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "TEPECİK",
    'ACIKLAMA': "3525-018-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.189527942748,
    'BOYLAM': 26.835742650213,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "HIDIRLIK",
    'ACIKLAMA': "3525-011-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.25187707894,
    'BOYLAM': 27.138159223619,
    'ILCE': "MENDERES",
    'MAHALLE': "MİTHATPAŞA",
    'ACIKLAMA': "3521-038-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.245966083765,
    'BOYLAM': 27.113026360222,
    'ILCE': "MENDERES",
    'MAHALLE': "DEREKÖY",
    'ACIKLAMA': "3521-018-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.118511782049,
    'BOYLAM': 27.141061431514,
    'ILCE': "MENDERES",
    'MAHALLE': "DEĞİRMENDERE",
    'ACIKLAMA': "3521-048-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.903759712915,
    'BOYLAM': 27.112024239938,
    'ILCE': "ALİAĞA",
    'MAHALLE': "BAHÇEDERE",
    'ACIKLAMA': "3502-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.074945766276,
    'BOYLAM': 26.908504685076,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "CUMHURİYET",
    'ACIKLAMA': "3525-005-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.086058663149,
    'BOYLAM': 26.867209875616,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "ATATÜRK",
    'ACIKLAMA': "3525-001-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.222377163034,
    'BOYLAM': 27.648843604876,
    'ILCE': "BAYINDIR",
    'MAHALLE': "MİTHATPAŞA",
    'ACIKLAMA': "3504-040-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.223146733794,
    'BOYLAM': 27.641666744411,
    'ILCE': "BAYINDIR",
    'MAHALLE': "YENİ",
    'ACIKLAMA': "3504-055-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.460061090881,
    'BOYLAM': 27.101087423025,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "BOSTANLI",
    'ACIKLAMA': "3516-007-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.080050222662,
    'BOYLAM': 27.374537313336,
    'ILCE': "TORBALI",
    'MAHALLE': "AHMETLİ",
    'ACIKLAMA': "3528-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.321960359469,
    'BOYLAM': 27.312001516507,
    'ILCE': "BERGAMA",
    'MAHALLE': "KATRANCI",
    'ACIKLAMA': "3505-081-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.332434327108,
    'BOYLAM': 26.791144754906,
    'ILCE': "URLA",
    'MAHALLE': "YENİCE",
    'ACIKLAMA': "3529-033-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.285194992372,
    'BOYLAM': 26.313143319172,
    'ILCE': "ÇEŞME",
    'MAHALLE': "OVACIK",
    'ACIKLAMA': "3509-019-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.158614347413,
    'BOYLAM': 27.349699253117,
    'ILCE': "TORBALI",
    'MAHALLE': "CUMHURİYET",
    'ACIKLAMA': "3528-011-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.205818678254,
    'BOYLAM': 27.512856134248,
    'ILCE': "BAYINDIR",
    'MAHALLE': "KIZILCAOVA",
    'ACIKLAMA': "3504-037-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.200212718607,
    'BOYLAM': 27.502919474601,
    'ILCE': "BAYINDIR",
    'MAHALLE': "ÇİFTÇİGEDİĞİ",
    'ACIKLAMA': "3504-015-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.395508826083,
    'BOYLAM': 27.153127993337,
    'ILCE': "BUCA",
    'MAHALLE': "YİĞİTLER",
    'ACIKLAMA': "3508-047-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.638018055162,
    'BOYLAM': 27.110090708803,
    'ILCE': "MENEMEN",
    'MAHALLE': "HAYKIRAN",
    'ACIKLAMA': "3522-034-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.700601162174,
    'BOYLAM': 27.043789467556,
    'ILCE': "MENEMEN",
    'MAHALLE': "HATUNDERE",
    'ACIKLAMA': "3522-033-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.628269399219,
    'BOYLAM': 26.926994795514,
    'ILCE': "MENEMEN",
    'MAHALLE': "MUSTAFA KEMAL ATATÜRK",
    'ACIKLAMA': "3522-050-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.224034137996,
    'BOYLAM': 27.291141053141,
    'ILCE': "TORBALI",
    'MAHALLE': "BAHÇELİEVLER",
    'ACIKLAMA': "3528-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.342462776142,
    'BOYLAM': 27.334550410909,
    'ILCE': "BERGAMA",
    'MAHALLE': "TOPALLAR",
    'ACIKLAMA': "3505-121-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.989149100637,
    'BOYLAM': 26.927464783855,
    'ILCE': "DİKİLİ",
    'MAHALLE': "DELİKTAŞ",
    'ACIKLAMA': "3511-007-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.239735081584,
    'BOYLAM': 26.504089228287,
    'ILCE': "URLA",
    'MAHALLE': "ZEYTİNELİ",
    'ACIKLAMA': "3529-036-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.157993310989,
    'BOYLAM': 26.892471623358,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "KAVAKDERE",
    'ACIKLAMA': "3525-013-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.083518446577,
    'BOYLAM': 27.732032866576,
    'ILCE': "TİRE",
    'MAHALLE': "CUMHURİYET",
    'ACIKLAMA': "3527-036-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.3415034306,
    'BOYLAM': 27.398297752546,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "VİŞNELİ",
    'ACIKLAMA': "3517-042-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.583068390656,
    'BOYLAM': 26.970824368606,
    'ILCE': "MENEMEN",
    'MAHALLE': "GAZİ MUSTAFA KEMAL",
    'ACIKLAMA': "3522-027-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.377898850322,
    'BOYLAM': 26.899865404847,
    'ILCE': "GÜZELBAHÇE",
    'MAHALLE': "YALI",
    'ACIKLAMA': "3514-011-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.39275767307,
    'BOYLAM': 27.082716165451,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "POLİGON",
    'ACIKLAMA': "3531-040-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.438151116981,
    'BOYLAM': 27.176765032686,
    'ILCE': "KONAK",
    'MAHALLE': "MERSİNLİ",
    'ACIKLAMA': "3520-073-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.604522176645,
    'BOYLAM': 27.062639001073,
    'ILCE': "MENEMEN",
    'MAHALLE': "AHIHIDIR",
    'ACIKLAMA': "3522-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.086265008044,
    'BOYLAM': 27.307917977482,
    'ILCE': "KINIK",
    'MAHALLE': "YAYAKENT",
    'ACIKLAMA': "3518-035-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.242297997452,
    'BOYLAM': 28.031893783517,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "KÜÇÜKAVULCUK",
    'ACIKLAMA': "3524-063-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.922753601097,
    'BOYLAM': 27.096573282332,
    'ILCE': "ALİAĞA",
    'MAHALLE': "AŞAĞIŞAKRAN",
    'ACIKLAMA': "3502-001-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.461428022864,
    'BOYLAM': 27.168658719752,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "BAYRAKLI",
    'ACIKLAMA': "3530-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.249012470222,
    'BOYLAM': 27.509297365903,
    'ILCE': "TORBALI",
    'MAHALLE': "DAĞTEKE",
    'ACIKLAMA': "3528-017-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.606324309115,
    'BOYLAM': 27.231527685518,
    'ILCE': "MENEMEN",
    'MAHALLE': "KARAORMAN",
    'ACIKLAMA': "3522-041-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.534996519975,
    'BOYLAM': 27.050502180999,
    'ILCE': "ÇİĞLİ",
    'MAHALLE': "HARMANDALI GAZİ MUSTAFA KEMAL ATATÜRK",
    'ACIKLAMA': "3510-016-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.309365589758,
    'BOYLAM': 26.959181025284,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "KAVACIK",
    'ACIKLAMA': "3531-030-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.957560651819,
    'BOYLAM': 26.920587554585,
    'ILCE': "DİKİLİ",
    'MAHALLE': "YAYLAYURT",
    'ACIKLAMA': "3511-029-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.49455872612,
    'BOYLAM': 27.090009138357,
    'ILCE': "ÇİĞLİ",
    'MAHALLE': "AHMET TANER KIŞLALI",
    'ACIKLAMA': "3510-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.476371698224,
    'BOYLAM': 27.104619675448,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "İMBATLI",
    'ACIKLAMA': "3516-014-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.472149103011,
    'BOYLAM': 27.103172148531,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "FİKRİ ALTAY",
    'ACIKLAMA': "3516-012-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.470024977724,
    'BOYLAM': 27.167507710678,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "ALPASLAN",
    'ACIKLAMA': "3530-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.474765900163,
    'BOYLAM': 27.091474112178,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "ŞEMİKLER",
    'ACIKLAMA': "3516-022-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.471176147813,
    'BOYLAM': 27.099352062593,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "DEMİRKÖPRÜ",
    'ACIKLAMA': "3516-010-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.284547701299,
    'BOYLAM': 26.941879155413,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "ÇAMTEPE",
    'ACIKLAMA': "3525-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.494912842337,
    'BOYLAM': 27.160481703819,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "DOĞANÇAY",
    'ACIKLAMA': "3530-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.292024862287,
    'BOYLAM': 27.131441190492,
    'ILCE': "MENDERES",
    'MAHALLE': "ATA",
    'ACIKLAMA': "3521-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.468333935382,
    'BOYLAM': 27.118731956024,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "EMEK",
    'ACIKLAMA': "3530-009-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.833683027961,
    'BOYLAM': 27.077011533382,
    'ILCE': "ALİAĞA",
    'MAHALLE': "ÇORAKLAR",
    'ACIKLAMA': "3502-009-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.852894885899,
    'BOYLAM': 27.034587707136,
    'ILCE': "ALİAĞA",
    'MAHALLE': "ÇALTILIDERE",
    'ACIKLAMA': "3502-007-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.3893322707,
    'BOYLAM': 27.049785434803,
    'ILCE': "BALÇOVA",
    'MAHALLE': "ONUR",
    'ACIKLAMA': "3503-007-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.071050104333,
    'BOYLAM': 27.211067155488,
    'ILCE': "MENDERES",
    'MAHALLE': "ÇAKALTEPE",
    'ACIKLAMA': "3521-009-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.199983869635,
    'BOYLAM': 26.834986011159,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "ÇOLAK İBRAHİM BEY",
    'ACIKLAMA': "3525-007-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.25566747202,
    'BOYLAM': 27.135969880483,
    'ILCE': "MENDERES",
    'MAHALLE': "KEMALPAŞA",
    'ACIKLAMA': "3521-034-03",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.078447716141,
    'BOYLAM': 26.973484068967,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "MERSİN ALANI",
    'ACIKLAMA': "3525-014-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.274760316314,
    'BOYLAM': 26.484551467611,
    'ILCE': "ÇEŞME",
    'MAHALLE': "KARAKÖY",
    'ACIKLAMA': "3509-017-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.283667804474,
    'BOYLAM': 26.56150483341,
    'ILCE': "URLA",
    'MAHALLE': "ZEYTİNLER",
    'ACIKLAMA': "3529-037-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.222813676573,
    'BOYLAM': 27.652449341475,
    'ILCE': "BAYINDIR",
    'MAHALLE': "HACI BEŞİR",
    'ACIKLAMA': "3504-024-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.940801802649,
    'BOYLAM': 27.133301294141,
    'ILCE': "BERGAMA",
    'MAHALLE': "KIZILTEPE",
    'ACIKLAMA': "3505-084-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.394398776094,
    'BOYLAM': 27.096458121065,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "ADNAN SÜVARİ",
    'ACIKLAMA': "3531-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.393265745625,
    'BOYLAM': 27.08928086862,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "ESENYALI",
    'ACIKLAMA': "3531-021-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.398052261052,
    'BOYLAM': 27.083259251961,
    'ILCE': "KONAK",
    'MAHALLE': "GÜZELYALI",
    'ACIKLAMA': "3520-043-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.388211768533,
    'BOYLAM': 27.075019117804,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "ESENTEPE",
    'ACIKLAMA': "3531-020-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.394532065177,
    'BOYLAM': 27.072909395373,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "ÜÇKUYULAR",
    'ACIKLAMA': "3531-053-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.396122247586,
    'BOYLAM': 27.06133236473,
    'ILCE': "BALÇOVA",
    'MAHALLE': "EĞİTİM",
    'ACIKLAMA': "3503-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.389475257759,
    'BOYLAM': 27.038132492472,
    'ILCE': "BALÇOVA",
    'MAHALLE': "KORUTÜRK",
    'ACIKLAMA': "3503-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.395213230855,
    'BOYLAM': 27.040385471391,
    'ILCE': "BALÇOVA",
    'MAHALLE': "İNCİRALTI",
    'ACIKLAMA': "3503-005-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.475946110774,
    'BOYLAM': 27.185357110295,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "OSMANGAZİ",
    'ACIKLAMA': "3530-018-08",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.458158248483,
    'BOYLAM': 27.116662423147,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "TUNA",
    'ACIKLAMA': "3516-024-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.65456598783,
    'BOYLAM': 27.081695820079,
    'ILCE': "MENEMEN",
    'MAHALLE': "YANIKKÖY",
    'ACIKLAMA': "3522-062-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.619695398181,
    'BOYLAM': 27.200964816537,
    'ILCE': "MENEMEN",
    'MAHALLE': "BAĞCILAR",
    'ACIKLAMA': "3522-011-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.333336787752,
    'BOYLAM': 26.896410153946,
    'ILCE': "GÜZELBAHÇE",
    'MAHALLE': "KÜÇÜKKAYA",
    'ACIKLAMA': "3514-005-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.962725153762,
    'BOYLAM': 27.346964360582,
    'ILCE': "KINIK",
    'MAHALLE': "ÖRTÜLÜ",
    'ACIKLAMA': "3518-030-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.113120735305,
    'BOYLAM': 27.174501573846,
    'ILCE': "BERGAMA",
    'MAHALLE': "MALTEPE",
    'ACIKLAMA': "3505-092-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.358528463095,
    'BOYLAM': 27.080572333421,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "YAŞAR KEMAL",
    'ACIKLAMA': "3531-055-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.078626682351,
    'BOYLAM': 28.056745025468,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "BADEMLİ",
    'ACIKLAMA': "3524-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.371423493728,
    'BOYLAM': 27.173473846422,
    'ILCE': "BUCA",
    'MAHALLE': "YILDIZ",
    'ACIKLAMA': "3508-045-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.392376327286,
    'BOYLAM': 27.118598085348,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "KAZIM KARABEKİR",
    'ACIKLAMA': "3531-031-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.396724248243,
    'BOYLAM': 27.064549347547,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "FAHRETTİN ALTAY",
    'ACIKLAMA': "3531-022-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.384402304494,
    'BOYLAM': 27.057011406338,
    'ILCE': "BALÇOVA",
    'MAHALLE': "TELEFERİK",
    'ACIKLAMA': "3503-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.126707670858,
    'BOYLAM': 27.177197537217,
    'ILCE': "BERGAMA",
    'MAHALLE': "SELÇUK",
    'ACIKLAMA': "3505-111-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.217940428603,
    'BOYLAM': 28.380157153377,
    'ILCE': "KİRAZ",
    'MAHALLE': "İĞDELİ",
    'ACIKLAMA': "3519-022-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.392241749422,
    'BOYLAM': 27.011945454919,
    'ILCE': "NARLIDERE",
    'MAHALLE': "ÇAMTEPE",
    'ACIKLAMA': "3523-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.146808532925,
    'BOYLAM': 27.371330768065,
    'ILCE': "TORBALI",
    'MAHALLE': "KARŞIYAKA",
    'ACIKLAMA': "3528-033-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.086071554948,
    'BOYLAM': 27.749724412082,
    'ILCE': "TİRE",
    'MAHALLE': "DUATEPE",
    'ACIKLAMA': "3527-032-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.461596990088,
    'BOYLAM': 27.10819863645,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "BAHRİYE ÜÇOK",
    'ACIKLAMA': "3516-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.253727046864,
    'BOYLAM': 28.119289234065,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "CEVİZALAN",
    'ACIKLAMA': "3524-019-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.076639332204,
    'BOYLAM': 26.890406024454,
    'ILCE': "DİKİLİ",
    'MAHALLE': "CUMHURİYET",
    'ACIKLAMA': "3511-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.319220791162,
    'BOYLAM': 27.130592232732,
    'ILCE': "GAZİEMİR",
    'MAHALLE': "ATIFBEY",
    'ACIKLAMA': "3513-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.146242234691,
    'BOYLAM': 27.372463377789,
    'ILCE': "TORBALI",
    'MAHALLE': "KARŞIYAKA",
    'ACIKLAMA': "3528-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.241289192693,
    'BOYLAM': 27.950044223057,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "YENİCEKÖY",
    'ACIKLAMA': "3524-093-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.184228575652,
    'BOYLAM': 28.34652535574,
    'ILCE': "KİRAZ",
    'MAHALLE': "SOLAKLAR",
    'ACIKLAMA': "3519-042-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.584099312424,
    'BOYLAM': 27.0926128879,
    'ILCE': "MENEMEN",
    'MAHALLE': "YEŞİL PINAR",
    'ACIKLAMA': "3522-064-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.588097863238,
    'BOYLAM': 27.075583833303,
    'ILCE': "MENEMEN",
    'MAHALLE': "ZEYTİNLİK",
    'ACIKLAMA': "3522-067-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.076551845234,
    'BOYLAM': 26.990413266015,
    'ILCE': "MENDERES",
    'MAHALLE': "GÜMÜLDÜR CUMHURİYET",
    'ACIKLAMA': "3521-026-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.047987579498,
    'BOYLAM': 27.78962744921,
    'ILCE': "TİRE",
    'MAHALLE': "BÜYÜKKEMERDERE",
    'ACIKLAMA': "3527-016-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.391072045093,
    'BOYLAM': 27.148660718739,
    'ILCE': "BUCA",
    'MAHALLE': "İNKILAP",
    'ACIKLAMA': "3508-025-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.416959286566,
    'BOYLAM': 27.201307631586,
    'ILCE': "BORNOVA",
    'MAHALLE': "MERKEZ",
    'ACIKLAMA': "3507-032-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.224650102109,
    'BOYLAM': 27.884853224602,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "IŞIK",
    'ACIKLAMA': "3524-043-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.339383629497,
    'BOYLAM': 27.144176046503,
    'ILCE': "GAZİEMİR",
    'MAHALLE': "BEYAZEVLER",
    'ACIKLAMA': "3513-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.49445474501,
    'BOYLAM': 27.065655175175,
    'ILCE': "ÇİĞLİ",
    'MAHALLE': "KÖYİÇİ",
    'ACIKLAMA': "3510-020-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.499091949083,
    'BOYLAM': 27.28446008095,
    'ILCE': "BORNOVA",
    'MAHALLE': "ÇİÇEKLİ",
    'ACIKLAMA': "3507-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.297378539526,
    'BOYLAM': 27.844328623472,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "KIZILCA",
    'ACIKLAMA': "3524-055-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.376322411319,
    'BOYLAM': 27.344329617853,
    'ILCE': "BERGAMA",
    'MAHALLE': "YUKARIADA",
    'ACIKLAMA': "3505-132-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.79176113202,
    'BOYLAM': 26.976948096415,
    'ILCE': "ALİAĞA",
    'MAHALLE': "YENİ",
    'ACIKLAMA': "3502-027-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.356529633311,
    'BOYLAM': 27.234133568416,
    'ILCE': "BUCA",
    'MAHALLE': "29 EKİM",
    'ACIKLAMA': "3508-001-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.1920128113,
    'BOYLAM': 27.553697232662,
    'ILCE': "BAYINDIR",
    'MAHALLE': "CUMHURİYET",
    'ACIKLAMA': "3504-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.293914896852,
    'BOYLAM': 27.174134973621,
    'ILCE': "GAZİEMİR",
    'MAHALLE': "ATATÜRK",
    'ACIKLAMA': "3513-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.544871454142,
    'BOYLAM': 27.036130235545,
    'ILCE': "MENEMEN",
    'MAHALLE': "29 EKİM",
    'ACIKLAMA': "3522-001-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.537681066133,
    'BOYLAM': 27.052818325588,
    'ILCE': "ÇİĞLİ",
    'MAHALLE': "CUMHURİYET",
    'ACIKLAMA': "3510-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.429765223832,
    'BOYLAM': 27.204819592929,
    'ILCE': "BORNOVA",
    'MAHALLE': "YEŞİLOVA",
    'ACIKLAMA': "3507-042-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.401970646531,
    'BOYLAM': 27.196288107018,
    'ILCE': "BUCA",
    'MAHALLE': "MURATHAN",
    'ACIKLAMA': "3508-036-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.39176928001,
    'BOYLAM': 27.181407362151,
    'ILCE': "BUCA",
    'MAHALLE': "GAZİLER",
    'ACIKLAMA': "3508-021-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.65632370188,
    'BOYLAM': 27.159446467222,
    'ILCE': "MENEMEN",
    'MAHALLE': "İĞNEDERE",
    'ACIKLAMA': "3522-036-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.69570948591,
    'BOYLAM': 26.854199869761,
    'ILCE': "FOÇA",
    'MAHALLE': "KOCA MEHMETLER",
    'ACIKLAMA': "3512-011-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.511381495591,
    'BOYLAM': 27.039316167411,
    'ILCE': "ÇİĞLİ",
    'MAHALLE': "BALATÇIK",
    'ACIKLAMA': "3510-007-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.397781276609,
    'BOYLAM': 27.096796185679,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "BASIN SİTESİ",
    'ACIKLAMA': "3531-012-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.329368668458,
    'BOYLAM': 27.131995124934,
    'ILCE': "GAZİEMİR",
    'MAHALLE': "GAZİ",
    'ACIKLAMA': "3513-009-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.20124486962,
    'BOYLAM': 27.701159739374,
    'ILCE': "BAYINDIR",
    'MAHALLE': "YAKACIK",
    'ACIKLAMA': "3504-053-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.182171413124,
    'BOYLAM': 27.108396490997,
    'ILCE': "MENDERES",
    'MAHALLE': "ŞAŞAL",
    'ACIKLAMA': "3521-044-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.429298297137,
    'BOYLAM': 27.273339252155,
    'ILCE': "BORNOVA",
    'MAHALLE': "GÜRPINAR",
    'ACIKLAMA': "3507-018-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.341014884104,
    'BOYLAM': 26.870903011778,
    'ILCE': "GÜZELBAHÇE",
    'MAHALLE': "MUSTAFA KEMAL PAŞA",
    'ACIKLAMA': "3514-007-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.218346339183,
    'BOYLAM': 27.966037390407,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "EMMİOĞLU",
    'ACIKLAMA': "3524-032-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.091398388559,
    'BOYLAM': 27.167087355185,
    'ILCE': "MENDERES",
    'MAHALLE': "ATAKÖY",
    'ACIKLAMA': "3521-005-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.212212523114,
    'BOYLAM': 27.368898129279,
    'ILCE': "TORBALI",
    'MAHALLE': "ORTAKÖY",
    'ACIKLAMA': "3528-042-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.649339756034,
    'BOYLAM': 27.164953768927,
    'ILCE': "MENEMEN",
    'MAHALLE': "GÖRECE",
    'ACIKLAMA': "3522-030-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.240637200114,
    'BOYLAM': 28.251580725772,
    'ILCE': "KİRAZ",
    'MAHALLE': "AYDOĞDU",
    'ACIKLAMA': "3519-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.649640980497,
    'BOYLAM': 27.091703984091,
    'ILCE': "MENEMEN",
    'MAHALLE': "DOĞA",
    'ACIKLAMA': "3522-021-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.614324178937,
    'BOYLAM': 27.112037739481,
    'ILCE': "MENEMEN",
    'MAHALLE': "YAHŞELLİ",
    'ACIKLAMA': "3522-061-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.46768586264,
    'BOYLAM': 27.095307392884,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "YALI",
    'ACIKLAMA': "3516-025-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.239480915594,
    'BOYLAM': 27.246806426463,
    'ILCE': "BERGAMA",
    'MAHALLE': "ÜÇTEPE",
    'ACIKLAMA': "3505-124-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.166312687677,
    'BOYLAM': 27.294098580035,
    'ILCE': "TORBALI",
    'MAHALLE': "KAPLANCIK",
    'ACIKLAMA': "3528-029-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.510790137543,
    'BOYLAM': 27.050671100147,
    'ILCE': "ÇİĞLİ",
    'MAHALLE': "ESENTEPE",
    'ACIKLAMA': "3510-011-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.508528671453,
    'BOYLAM': 27.064710155336,
    'ILCE': "ÇİĞLİ",
    'MAHALLE': "İZKENT",
    'ACIKLAMA': "3510-018-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.27021213755,
    'BOYLAM': 27.011401998523,
    'ILCE': "BERGAMA",
    'MAHALLE': "AŞAĞICUMA",
    'ACIKLAMA': "3505-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.487873619543,
    'BOYLAM': 27.053210269256,
    'ILCE': "ÇİĞLİ",
    'MAHALLE': "ATAŞEHİR",
    'ACIKLAMA': "3510-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.458749139546,
    'BOYLAM': 27.267646232085,
    'ILCE': "BORNOVA",
    'MAHALLE': "NALDÖKEN",
    'ACIKLAMA': "3507-034-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.124830111468,
    'BOYLAM': 27.925431133249,
    'ILCE': "TİRE",
    'MAHALLE': "YEĞENLİ",
    'ACIKLAMA': "3527-083-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.242988044045,
    'BOYLAM': 27.214870548883,
    'ILCE': "MENDERES",
    'MAHALLE': "OĞLANANASI ATATÜRK",
    'ACIKLAMA': "3521-039-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.932953032905,
    'BOYLAM': 27.213667848271,
    'ILCE': "BERGAMA",
    'MAHALLE': "İSMAİLLİ",
    'ACIKLAMA': "3505-070-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.4032994018,
    'BOYLAM': 27.117364915276,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "BAHÇELİEVLER",
    'ACIKLAMA': "3531-009-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.095034063083,
    'BOYLAM': 27.744387569914,
    'ILCE': "TİRE",
    'MAHALLE': "ADNAN MENDERES",
    'ACIKLAMA': "3527-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.415036802514,
    'BOYLAM': 27.154745088906,
    'ILCE': "KONAK",
    'MAHALLE': "AKARCALI",
    'ACIKLAMA': "3520-108-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.285312152009,
    'BOYLAM': 27.379497958055,
    'ILCE': "TORBALI",
    'MAHALLE': "ÇAKIRBEYLİ",
    'ACIKLAMA': "3528-012-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.466338706046,
    'BOYLAM': 27.107868942942,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "GONCALAR",
    'ACIKLAMA': "3516-013-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.069190159298,
    'BOYLAM': 27.01616624574,
    'ILCE': "MENDERES",
    'MAHALLE': "GÜMÜLDÜR FEVZİ ÇAKMAK",
    'ACIKLAMA': "3521-027-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.012523259483,
    'BOYLAM': 27.326711853474,
    'ILCE': "SELÇUK",
    'MAHALLE': "BARUTÇU",
    'ACIKLAMA': "3526-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.076763520327,
    'BOYLAM': 26.927391509671,
    'ILCE': "SEFERİHİSAR",
    'MAHALLE': "PAYAMLI",
    'ACIKLAMA': "3525-016-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.422973526155,
    'BOYLAM': 27.134893365943,
    'ILCE': "KONAK",
    'MAHALLE': "AKDENİZ",
    'ACIKLAMA': "3520-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.016939176335,
    'BOYLAM': 27.435980657419,
    'ILCE': "KINIK",
    'MAHALLE': "ÇANKÖY",
    'ACIKLAMA': "3518-011-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.267086381461,
    'BOYLAM': 26.981822118709,
    'ILCE': "BERGAMA",
    'MAHALLE': "AYVATLAR",
    'ACIKLAMA': "3505-017-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.324255301947,
    'BOYLAM': 27.270022603218,
    'ILCE': "BERGAMA",
    'MAHALLE': "HACILAR (DEREKÖY BUCAĞI)",
    'ACIKLAMA': "3505-059-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.242767998144,
    'BOYLAM': 27.428449924113,
    'ILCE': "BERGAMA",
    'MAHALLE': "KOZLUCA",
    'ACIKLAMA': "3505-088-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.890417818011,
    'BOYLAM': 27.148297086821,
    'ILCE': "ALİAĞA",
    'MAHALLE': "YÜKSEKKÖY",
    'ACIKLAMA': "3502-030-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.055216034083,
    'BOYLAM': 27.185633619989,
    'ILCE': "BERGAMA",
    'MAHALLE': "ARMAĞANLAR",
    'ACIKLAMA': "3505-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.264759870522,
    'BOYLAM': 27.141280929323,
    'ILCE': "MENDERES",
    'MAHALLE': "GAZİPAŞA",
    'ACIKLAMA': "3521-021-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.200488792283,
    'BOYLAM': 27.579773088718,
    'ILCE': "BAYINDIR",
    'MAHALLE': "ELİFLİ",
    'ACIKLAMA': "3504-019-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.427752225931,
    'BOYLAM': 27.1969606349,
    'ILCE': "BORNOVA",
    'MAHALLE': "BİRLİK",
    'ACIKLAMA': "3507-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 37.993921537853,
    'BOYLAM': 27.235444157797,
    'ILCE': "MENDERES",
    'MAHALLE': "AHMETBEYLİ",
    'ACIKLAMA': "3521-001-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.06395615331,
    'BOYLAM': 28.228157783713,
    'ILCE': "BEYDAĞ",
    'MAHALLE': "TABAKLAR",
    'ACIKLAMA': "3506-020-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.690109566673,
    'BOYLAM': 26.901999644488,
    'ILCE': "FOÇA",
    'MAHALLE': "YENİKÖY",
    'ACIKLAMA': "3512-016-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.178908137101,
    'BOYLAM': 27.822891907262,
    'ILCE': "TİRE",
    'MAHALLE': "DOYRANLI",
    'ACIKLAMA': "3527-031-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.261114022548,
    'BOYLAM': 27.130079248738,
    'ILCE': "MENDERES",
    'MAHALLE': "KASIMPAŞA",
    'ACIKLAMA': "3521-032-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.385444299867,
    'BOYLAM': 27.058426397672,
    'ILCE': "BALÇOVA",
    'MAHALLE': "FEVZİ ÇAKMAK",
    'ACIKLAMA': "3503-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.301469245923,
    'BOYLAM': 27.55899803455,
    'ILCE': "BAYINDIR",
    'MAHALLE': "OSMANLAR",
    'ACIKLAMA': "3504-046-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.328934624378,
    'BOYLAM': 26.761979752693,
    'ILCE': "URLA",
    'MAHALLE': "RÜSTEM",
    'ACIKLAMA': "3529-024-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.249382135855,
    'BOYLAM': 27.140870629559,
    'ILCE': "MENDERES",
    'MAHALLE': "ALTINTEPE",
    'ACIKLAMA': "3521-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.408075575969,
    'BOYLAM': 27.169566509841,
    'ILCE': "KONAK",
    'MAHALLE': "ULUBATLI",
    'ACIKLAMA': "3520-099-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.076141615177,
    'BOYLAM': 26.893753992812,
    'ILCE': "DİKİLİ",
    'MAHALLE': "İSMETPAŞA",
    'ACIKLAMA': "3511-014-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.087527613211,
    'BOYLAM': 27.379732862134,
    'ILCE': "KINIK",
    'MAHALLE': "YENİ",
    'ACIKLAMA': "3518-037-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.266612238848,
    'BOYLAM': 27.368998040631,
    'ILCE': "TORBALI",
    'MAHALLE': "SAİPLER",
    'ACIKLAMA': "3528-047-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.625846168941,
    'BOYLAM': 27.159115487984,
    'ILCE': "MENEMEN",
    'MAHALLE': "KIR",
    'ACIKLAMA': "3522-046-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.664281150902,
    'BOYLAM': 26.415429093542,
    'ILCE': "KARABURUN",
    'MAHALLE': "HASSEKİ",
    'ACIKLAMA': "3515-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.561506305399,
    'BOYLAM': 27.04691346632,
    'ILCE': "MENEMEN",
    'MAHALLE': "30 AĞUSTOS",
    'ACIKLAMA': "3522-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.290778372928,
    'BOYLAM': 27.045710023178,
    'ILCE': "BERGAMA",
    'MAHALLE': "HACIHAMZALAR",
    'ACIKLAMA': "3505-058-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.217528932739,
    'BOYLAM': 28.065936610721,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "GERÇEKLİ",
    'ACIKLAMA': "3524-034-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.577000974574,
    'BOYLAM': 27.070666147728,
    'ILCE': "MENEMEN",
    'MAHALLE': "KEMAL ATATÜRK",
    'ACIKLAMA': "3522-044-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.517038809362,
    'BOYLAM': 27.238386279887,
    'ILCE': "BORNOVA",
    'MAHALLE': "KAYADİBİ",
    'ACIKLAMA': "3507-024-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.411486392433,
    'BOYLAM': 27.622290087235,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "BAĞYURDU KEMAL ATATÜRK",
    'ACIKLAMA': "3517-027-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.288070175979,
    'BOYLAM': 27.384681399026,
    'ILCE': "BERGAMA",
    'MAHALLE': "ALHATLI",
    'ACIKLAMA': "3505-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.045261373528,
    'BOYLAM': 27.466225284581,
    'ILCE': "KINIK",
    'MAHALLE': "BÜYÜKOBA",
    'ACIKLAMA': "3518-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.433829682488,
    'BOYLAM': 27.684835203601,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "GÖKÇEYURT",
    'ACIKLAMA': "3517-018-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.416560010061,
    'BOYLAM': 27.127102541969,
    'ILCE': "KONAK",
    'MAHALLE': "KONAK",
    'ACIKLAMA': "3520-061-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.168351543537,
    'BOYLAM': 28.213436008827,
    'ILCE': "KİRAZ",
    'MAHALLE': "KARAMAN",
    'ACIKLAMA': "3519-028-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.060866252304,
    'BOYLAM': 27.422864213502,
    'ILCE': "KINIK",
    'MAHALLE': "BAĞALAN",
    'ACIKLAMA': "3518-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.313598503266,
    'BOYLAM': 28.052783368274,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "OVACIK",
    'ACIKLAMA': "3524-074-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.611121145653,
    'BOYLAM': 27.065276976757,
    'ILCE': "MENEMEN",
    'MAHALLE': "CAMİİKEBİR",
    'ACIKLAMA': "3522-015-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.35794851743,
    'BOYLAM': 27.129505089067,
    'ILCE': "GAZİEMİR",
    'MAHALLE': "EMREZ",
    'ACIKLAMA': "3513-007-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.392073342619,
    'BOYLAM': 27.131752019784,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "GENERAL ASIM GÜNDÜZ",
    'ACIKLAMA': "3531-024-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.995250848277,
    'BOYLAM': 27.209048410227,
    'ILCE': "BERGAMA",
    'MAHALLE': "AVUNDUK",
    'ACIKLAMA': "3505-014-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.221829506608,
    'BOYLAM': 27.267890749884,
    'ILCE': "BERGAMA",
    'MAHALLE': "ÖRENLİ",
    'ACIKLAMA': "3505-100-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.494238757946,
    'BOYLAM': 27.077391116964,
    'ILCE': "ÇİĞLİ",
    'MAHALLE': "MALTEPE",
    'ACIKLAMA': "3510-022-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.388036384392,
    'BOYLAM': 27.151328929942,
    'ILCE': "BUCA",
    'MAHALLE': "AKINCILAR",
    'ACIKLAMA': "3508-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.473245050509,
    'BOYLAM': 27.254406272851,
    'ILCE': "BORNOVA",
    'MAHALLE': "EVKA 3",
    'ACIKLAMA': "3507-014-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.34309096564,
    'BOYLAM': 26.552300008808,
    'ILCE': "URLA",
    'MAHALLE': "KADIOVACIK",
    'ACIKLAMA': "3529-016-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.382942237133,
    'BOYLAM': 27.016310505276,
    'ILCE': "NARLIDERE",
    'MAHALLE': "ATATÜRK",
    'ACIKLAMA': "3523-001-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.367537198566,
    'BOYLAM': 26.876940336771,
    'ILCE': "GÜZELBAHÇE",
    'MAHALLE': "ÇELEBİ",
    'ACIKLAMA': "3514-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.381367428924,
    'BOYLAM': 27.160737893154,
    'ILCE': "BUCA",
    'MAHALLE': "YENİGÜN",
    'ACIKLAMA': "3508-043-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.700923654906,
    'BOYLAM': 27.034773971087,
    'ILCE': "ALİAĞA",
    'MAHALLE': "MİMAR SİNAN",
    'ACIKLAMA': "3502-021-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.479194946827,
    'BOYLAM': 27.18312261793,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "R.ŞEVKET İNCE",
    'ACIKLAMA': "3530-020-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.381005119885,
    'BOYLAM': 26.924837159057,
    'ILCE': "NARLIDERE",
    'MAHALLE': "LİMANREİS",
    'ACIKLAMA': "3523-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.496214816537,
    'BOYLAM': 27.142998788341,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "DOĞANÇAY",
    'ACIKLAMA': "3530-024-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.230364003478,
    'BOYLAM': 27.970202102967,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "BENGİSU",
    'ACIKLAMA': "3524-010-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.738809249453,
    'BOYLAM': 26.837999871833,
    'ILCE': "FOÇA",
    'MAHALLE': "MUSTAFA KEMAL ATATÜRK",
    'ACIKLAMA': "3512-014-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.335583705101,
    'BOYLAM': 26.43245608524,
    'ILCE': "ÇEŞME",
    'MAHALLE': "YALI",
    'ACIKLAMA': "3509-025-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.145199679837,
    'BOYLAM': 27.404150361312,
    'ILCE': "TORBALI",
    'MAHALLE': "ŞEHİTLER",
    'ACIKLAMA': "3528-049-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.45029823097,
    'BOYLAM': 27.314924010314,
    'ILCE': "BORNOVA",
    'MAHALLE': "KAVAKLIDERE",
    'ACIKLAMA': "3507-023-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.438498184825,
    'BOYLAM': 27.210174551557,
    'ILCE': "BORNOVA",
    'MAHALLE': "KARACAOĞLAN",
    'ACIKLAMA': "3507-021-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.607463173168,
    'BOYLAM': 27.073767940846,
    'ILCE': "MENEMEN",
    'MAHALLE': "KASIMPAŞA",
    'ACIKLAMA': "3522-042-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.464095054085,
    'BOYLAM': 27.211443501967,
    'ILCE': "BORNOVA",
    'MAHALLE': "ERGENE",
    'ACIKLAMA': "3507-012-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.425156276982,
    'BOYLAM': 27.232878460627,
    'ILCE': "BORNOVA",
    'MAHALLE': "EGEMENLİK",
    'ACIKLAMA': "3507-010-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.733380582281,
    'BOYLAM': 26.897147690261,
    'ILCE': "FOÇA",
    'MAHALLE': "CUMHURİYET",
    'ACIKLAMA': "3512-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.45084516596,
    'BOYLAM': 27.254083311877,
    'ILCE': "BORNOVA",
    'MAHALLE': "DOĞANLAR",
    'ACIKLAMA': "3507-009-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.413551291262,
    'BOYLAM': 27.188437701091,
    'ILCE': "BORNOVA",
    'MAHALLE': "ÇAMKULE",
    'ACIKLAMA': "3507-006-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.616399040755,
    'BOYLAM': 26.992777325137,
    'ILCE': "MENEMEN",
    'MAHALLE': "KESİK",
    'ACIKLAMA': "3522-045-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.68570656483,
    'BOYLAM': 26.918800269678,
    'ILCE': "FOÇA",
    'MAHALLE': "ILIPINAR",
    'ACIKLAMA': "3512-007-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.606978337979,
    'BOYLAM': 27.066134489987,
    'ILCE': "MENEMEN",
    'MAHALLE': "GAYBİ",
    'ACIKLAMA': "3522-025-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.222174148723,
    'BOYLAM': 27.056363685893,
    'ILCE': "MENDERES",
    'MAHALLE': "YENİKÖY",
    'ACIKLAMA': "3521-047-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.36170017593,
    'BOYLAM': 26.894548106941,
    'ILCE': "GÜZELBAHÇE",
    'MAHALLE': "YAKA",
    'ACIKLAMA': "3514-010-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.339286417033,
    'BOYLAM': 28.074635617596,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "BOZDAĞ",
    'ACIKLAMA': "3524-015-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.229692398767,
    'BOYLAM': 28.417720964469,
    'ILCE': "KİRAZ",
    'MAHALLE': "ÖREN",
    'ACIKLAMA': "3519-035-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.229055218667,
    'BOYLAM': 28.203207972572,
    'ILCE': "KİRAZ",
    'MAHALLE': "YENİ",
    'ACIKLAMA': "3519-053-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.232819833548,
    'BOYLAM': 27.965697260333,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "MİMAR SİNAN",
    'ACIKLAMA': "3524-068-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.118901844254,
    'BOYLAM': 27.975409663059,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "BOZCAYAKA",
    'ACIKLAMA': "3524-014-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.148753507875,
    'BOYLAM': 28.151412996076,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "ALAŞARLI",
    'ACIKLAMA': "3524-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.140183141414,
    'BOYLAM': 28.151186643083,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "KIZILCAAVLU",
    'ACIKLAMA': "3524-056-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.17792507485,
    'BOYLAM': 28.087698532345,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "KURUCUOVA",
    'ACIKLAMA': "3524-060-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.272100843755,
    'BOYLAM': 28.005079538966,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "GÖLCÜK",
    'ACIKLAMA': "3524-036-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.087965091124,
    'BOYLAM': 27.890794495044,
    'ILCE': "TİRE",
    'MAHALLE': "ÇOBANKÖY",
    'ACIKLAMA': "3527-023-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.135308785567,
    'BOYLAM': 28.07418334537,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "MESCİTLİ",
    'ACIKLAMA': "3524-066-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.147520844152,
    'BOYLAM': 28.438438979248,
    'ILCE': "KİRAZ",
    'MAHALLE': "TUMBULLAR",
    'ACIKLAMA': "3519-047-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.473636690989,
    'BOYLAM': 27.073713938361,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "MAVİŞEHİR",
    'ACIKLAMA': "3516-017-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.338268528973,
    'BOYLAM': 26.867313983672,
    'ILCE': "GÜZELBAHÇE",
    'MAHALLE': "YELKİ",
    'ACIKLAMA': "3514-012-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.395459054818,
    'BOYLAM': 27.006413472141,
    'ILCE': "NARLIDERE",
    'MAHALLE': "YENİKALE",
    'ACIKLAMA': "3523-011-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.428147554391,
    'BOYLAM': 27.675193385057,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "YEŞİLYURT",
    'ACIKLAMA': "3517-047-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.381863026485,
    'BOYLAM': 27.110892800627,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "ALİ FUAT CEBESOY",
    'ACIKLAMA': "3531-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.232902453885,
    'BOYLAM': 27.962824841409,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "KUVVETLİ",
    'ACIKLAMA': "3524-062-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.37718628886,
    'BOYLAM': 27.899242417081,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "HORZUM",
    'ACIKLAMA': "3524-041-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.066647352039,
    'BOYLAM': 27.298632646005,
    'ILCE': "KINIK",
    'MAHALLE': "KARATEKELİ",
    'ACIKLAMA': "3518-022-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.215977069427,
    'BOYLAM': 27.905273532088,
    'ILCE': "ÖDEMİŞ",
    'MAHALLE': "DEMİRCİLİ",
    'ACIKLAMA': "3524-027-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.190602469667,
    'BOYLAM': 28.261552748105,
    'ILCE': "KİRAZ",
    'MAHALLE': "YENİKÖY",
    'ACIKLAMA': "3519-054-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.03521696956,
    'BOYLAM': 27.274513353725,
    'ILCE': "KINIK",
    'MAHALLE': "ÇİFTLİKKÖY",
    'ACIKLAMA': "3518-012-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.254151066032,
    'BOYLAM': 28.177619059877,
    'ILCE': "KİRAZ",
    'MAHALLE': "KARABAĞ",
    'ACIKLAMA': "3519-038-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.262317037034,
    'BOYLAM': 28.193746971666,
    'ILCE': "KİRAZ",
    'MAHALLE': "VELİLER",
    'ACIKLAMA': "3519-051-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.614147986085,
    'BOYLAM': 27.067332082869,
    'ILCE': "MENEMEN",
    'MAHALLE': "MERMERLİ",
    'ACIKLAMA': "3522-048-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.493270859324,
    'BOYLAM': 27.11259622112,
    'ILCE': "KARŞIYAKA",
    'MAHALLE': "ZÜBEYDE HANIM",
    'ACIKLAMA': "3516-027-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.425303245758,
    'BOYLAM': 27.203746605907,
    'ILCE': "BORNOVA",
    'MAHALLE': "ZAFER",
    'ACIKLAMA': "3507-045-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.437963164209,
    'BOYLAM': 27.18823066158,
    'ILCE': "BORNOVA",
    'MAHALLE': "YILDIRIM BEYAZIT",
    'ACIKLAMA': "3507-043-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.546938694077,
    'BOYLAM': 27.275449046646,
    'ILCE': "BORNOVA",
    'MAHALLE': "SARNIÇ",
    'ACIKLAMA': "3507-036-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.441971148348,
    'BOYLAM': 27.192862631532,
    'ILCE': "BORNOVA",
    'MAHALLE': "RAFETPAŞA",
    'ACIKLAMA': "3507-035-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.394062506977,
    'BOYLAM': 27.018739502778,
    'ILCE': "NARLIDERE",
    'MAHALLE': "ILICA",
    'ACIKLAMA': "3523-007-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.440632280718,
    'BOYLAM': 27.695048978509,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "SARIÇALI",
    'ACIKLAMA': "3517-036-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.518348021758,
    'BOYLAM': 27.454012209617,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "BEŞPINAR",
    'ACIKLAMA': "3517-009-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.476979372216,
    'BOYLAM': 27.167423453694,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "CENGİZHAN",
    'ACIKLAMA': "3530-005-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.187837532392,
    'BOYLAM': 27.235299218824,
    'ILCE': "BERGAMA",
    'MAHALLE': "YUKARIKIRIKLAR",
    'ACIKLAMA': "3505-135-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.405510740496,
    'BOYLAM': 27.53662932222,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "ARMUTLU HÜRRİYET",
    'ACIKLAMA': "3517-023-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.439859451301,
    'BOYLAM': 27.666862195677,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "HALİLBEYLİ",
    'ACIKLAMA': "3517-020-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.409269072598,
    'BOYLAM': 27.597507647001,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "ÖREN EGEMEN",
    'ACIKLAMA': "3517-017-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.497897922931,
    'BOYLAM': 27.376627997399,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "DAMLACIK",
    'ACIKLAMA': "3517-015-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.465227005306,
    'BOYLAM': 27.194758968553,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "MANAVKUYU",
    'ACIKLAMA': "3530-013-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.474276942613,
    'BOYLAM': 27.155134765041,
    'ILCE': "BAYRAKLI",
    'MAHALLE': "75. YIL",
    'ACIKLAMA': "3530-001-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.685187001238,
    'BOYLAM': 27.034979372467,
    'ILCE': "MENEMEN",
    'MAHALLE': "YILDIRIM",
    'ACIKLAMA': "3522-065-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.318192642507,
    'BOYLAM': 27.096580585537,
    'ILCE': "BERGAMA",
    'MAHALLE': "YUKARICUMA",
    'ACIKLAMA': "3505-134-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.250154155179,
    'BOYLAM': 27.265476898762,
    'ILCE': "BERGAMA",
    'MAHALLE': "YORTANLI",
    'ACIKLAMA': "3505-131-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.151887945016,
    'BOYLAM': 27.136502349039,
    'ILCE': "BERGAMA",
    'MAHALLE': "YERLİTAHTACI",
    'ACIKLAMA': "3505-130-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.009101747208,
    'BOYLAM': 27.058608292552,
    'ILCE': "BERGAMA",
    'MAHALLE': "YENİKENT",
    'ACIKLAMA': "3505-128-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.091105919174,
    'BOYLAM': 27.124792084915,
    'ILCE': "BERGAMA",
    'MAHALLE': "YALNIZEV",
    'ACIKLAMA': "3505-127-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.355870752323,
    'BOYLAM': 27.375128195129,
    'ILCE': "BERGAMA",
    'MAHALLE': "ÜRKÜTLER",
    'ACIKLAMA': "3505-125-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.199323324546,
    'BOYLAM': 27.188943353913,
    'ILCE': "BERGAMA",
    'MAHALLE': "GÖKÇEYURT",
    'ACIKLAMA': "3505-055-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.119531701515,
    'BOYLAM': 27.172925569767,
    'ILCE': "BERGAMA",
    'MAHALLE': "ZAFER",
    'ACIKLAMA': "3505-021-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.046153484522,
    'BOYLAM': 27.194542607339,
    'ILCE': "BERGAMA",
    'MAHALLE': "GAYLAN",
    'ACIKLAMA': "3505-050-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.472032160789,
    'BOYLAM': 27.355377773433,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "ULUCAK CUMHURİYET",
    'ACIKLAMA': "3517-011-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.32184011867,
    'BOYLAM': 27.53733011048,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "BAYRAMLI",
    'ACIKLAMA': "3517-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.481158162536,
    'BOYLAM': 27.403811518539,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "ANSIZCA",
    'ACIKLAMA': "3517-005-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.577543861244,
    'BOYLAM': 27.067759191855,
    'ILCE': "MENEMEN",
    'MAHALLE': "ULUS",
    'ACIKLAMA': "3522-059-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.54980451251,
    'BOYLAM': 26.938842477145,
    'ILCE': "MENEMEN",
    'MAHALLE': "TUZÇULLU",
    'ACIKLAMA': "3522-056-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.662993227901,
    'BOYLAM': 27.216026967965,
    'ILCE': "MENEMEN",
    'MAHALLE': "TELEKLER",
    'ACIKLAMA': "3522-054-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.53712176546,
    'BOYLAM': 26.911804479668,
    'ILCE': "MENEMEN",
    'MAHALLE': "SÜZBEYLİ",
    'ACIKLAMA': "3522-053-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.597503994948,
    'BOYLAM': 27.077665913035,
    'ILCE': "MENEMEN",
    'MAHALLE': "İSMET İNÖNÜ",
    'ACIKLAMA': "3522-039-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.568295122529,
    'BOYLAM': 26.997792523602,
    'ILCE': "MENEMEN",
    'MAHALLE': "GÜNERLİ",
    'ACIKLAMA': "3522-031-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.131432773353,
    'BOYLAM': 27.297235951594,
    'ILCE': "BERGAMA",
    'MAHALLE': "DAĞISTAN",
    'ACIKLAMA': "3505-039-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.262550025339,
    'BOYLAM': 27.229220058846,
    'ILCE': "BERGAMA",
    'MAHALLE': "ÇÜRÜKBAĞLAR",
    'ACIKLAMA': "3505-038-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.220757251033,
    'BOYLAM': 27.219583169848,
    'ILCE': "BERGAMA",
    'MAHALLE': "MAHMUDİYE",
    'ACIKLAMA': "3505-091-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.252633825906,
    'BOYLAM': 27.393995075675,
    'ILCE': "BERGAMA",
    'MAHALLE': "ÇAMOBA",
    'ACIKLAMA': "3505-034-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.087840760373,
    'BOYLAM': 27.080576070254,
    'ILCE': "BERGAMA",
    'MAHALLE': "ÇAMKÖY",
    'ACIKLAMA': "3505-033-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.14291883381,
    'BOYLAM': 27.117454360679,
    'ILCE': "BERGAMA",
    'MAHALLE': "ÇAKIRLAR",
    'ACIKLAMA': "3505-029-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.942755692066,
    'BOYLAM': 27.27858336455,
    'ILCE': "BERGAMA",
    'MAHALLE': "BEKİRLER",
    'ACIKLAMA': "3505-023-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.953184820116,
    'BOYLAM': 27.202003736948,
    'ILCE': "BERGAMA",
    'MAHALLE': "BALABAN",
    'ACIKLAMA': "3505-020-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.101417432023,
    'BOYLAM': 27.151937200111,
    'ILCE': "BERGAMA",
    'MAHALLE': "BAHÇELİEVLER",
    'ACIKLAMA': "3505-019-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.46245033448,
    'BOYLAM': 27.479886171984,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "AKALAN",
    'ACIKLAMA': "3517-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.404824683983,
    'BOYLAM': 27.532411003329,
    'ILCE': "KEMALPAŞA",
    'MAHALLE': "ARMUTLU HÜRRİYET",
    'ACIKLAMA': "3517-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.656688251693,
    'BOYLAM': 26.468822844085,
    'ILCE': "KARABURUN",
    'MAHALLE': "BOZKÖY",
    'ACIKLAMA': "3515-002-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.447826371892,
    'BOYLAM': 27.304224533284,
    'ILCE': "BORNOVA",
    'MAHALLE': "YEŞİLÇAM",
    'ACIKLAMA': "3507-041-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.546965822505,
    'BOYLAM': 27.252597436972,
    'ILCE': "BORNOVA",
    'MAHALLE': "KURUDERE",
    'ACIKLAMA': "3507-029-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.08678160268,
    'BOYLAM': 27.804063139673,
    'ILCE': "TİRE",
    'MAHALLE': "ÇİNİYERİ",
    'ACIKLAMA': "3527-022-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.020236911646,
    'BOYLAM': 27.759346462624,
    'ILCE': "TİRE",
    'MAHALLE': "BÜYÜKKÖMÜRCÜ",
    'ACIKLAMA': "3527-017-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.03350869741,
    'BOYLAM': 27.558256371423,
    'ILCE': "TİRE",
    'MAHALLE': "BÜYÜKKALE",
    'ACIKLAMA': "3527-015-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.100727334509,
    'BOYLAM': 27.727860059975,
    'ILCE': "TİRE",
    'MAHALLE': "ATATÜRK",
    'ACIKLAMA': "3527-010-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.085398957517,
    'BOYLAM': 27.382894532397,
    'ILCE': "KINIK",
    'MAHALLE': "TÜRKCEDİT",
    'ACIKLAMA': "3518-034-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.040863161346,
    'BOYLAM': 27.346062971814,
    'ILCE': "KINIK",
    'MAHALLE': "KODUKBURUN",
    'ACIKLAMA': "3518-025-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.044441412626,
    'BOYLAM': 27.5012041177,
    'ILCE': "KINIK",
    'MAHALLE': "KALEMKÖY",
    'ACIKLAMA': "3518-020-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.098277089852,
    'BOYLAM': 27.445418296673,
    'ILCE': "KINIK",
    'MAHALLE': "ÇALTI",
    'ACIKLAMA': "3518-010-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 39.086352338455,
    'BOYLAM': 27.382277702296,
    'ILCE': "KINIK",
    'MAHALLE': "AŞAĞI",
    'ACIKLAMA': "3518-003-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.697336273052,
    'BOYLAM': 27.121085449731,
    'ILCE': "MENEMEN",
    'MAHALLE': "ÇUKURKÖY",
    'ACIKLAMA': "3522-019-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.598135283149,
    'BOYLAM': 27.061006587865,
    'ILCE': "MENEMEN",
    'MAHALLE': "ATATÜRK",
    'ACIKLAMA': "3522-008-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.383374359352,
    'BOYLAM': 27.100322024599,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "SALİH OMURTAK",
    'ACIKLAMA': "3531-043-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.371354171404,
    'BOYLAM': 27.110770315762,
    'ILCE': "KARABAĞLAR",
    'MAHALLE': "DEVRİM",
    'ACIKLAMA': "3531-017-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.431081494719,
    'BOYLAM': 27.274486203834,
    'ILCE': "BORNOVA",
    'MAHALLE': "KEMALPAŞA",
    'ACIKLAMA': "3507-026-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.377797715237,
    'BOYLAM': 27.24064531526,
    'ILCE': "BORNOVA",
    'MAHALLE': "GÖKDERE",
    'ACIKLAMA': "3507-017-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.08621454891,
    'BOYLAM': 27.743423444135,
    'ILCE': "TİRE",
    'MAHALLE': "PAŞA",
    'ACIKLAMA': "3527-071-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.208472327929,
    'BOYLAM': 28.2061389875,
    'ILCE': "KİRAZ",
    'MAHALLE': "ARKACILAR",
    'ACIKLAMA': "3519-004-01",
  },
  {
    'ADI': "1 NO'LU AFET VE ACİL DURUM TOPLANMA ALANI",
    'ENLEM': 38.236595098746,
    'BOYLAM': 28.38809426566,
    'ILCE': "KİRAZ",
    'MAHALLE': "AKPINAR",
    'ACIKLAMA': "3519-002-01",
  },

      ];
    });
  }

  void _calculateNearestAreas() {
    if (currentPosition == null || toplanmaAlanlari.isEmpty) return;

    List<Map<String, dynamic>> distances = [];
    
    for (var alan in toplanmaAlanlari) {
      try {
        double lat = double.parse(alan['ENLEM'].toString());
        double lng = double.parse(alan['BOYLAM'].toString());
        
        if (lat == 0 || lng == 0) continue;
        
        double distance = Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          lat,
          lng,
        );
        
        distances.add({
          'alan': alan,
          'distance': distance,
          'lat': lat,
          'lng': lng,
        });
      } catch (e) {
        continue;
      }
    }
    
    distances.sort((a, b) => a['distance'].compareTo(b['distance']));
    
    setState(() {
      nearestAreas = distances.take(3).toList();
    });
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Mevcut konum
    if (currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.my_location, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    // Toplanma alanları
    for (var alan in toplanmaAlanlari) {
      try {
        double lat = double.parse(alan['ENLEM'].toString());
        double lng = double.parse(alan['BOYLAM'].toString());
        
        if (lat == 0 || lng == 0) continue;
        
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            child: GestureDetector(
              onTap: () => _showAreaDetails(alan, lat, lng),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.emergency, color: Colors.white, size: 18),
              ),
            ),
          ),
        );
      } catch (e) {
        continue;
      }
    }

    return markers;
  }

  void _showAreaDetails(Map<String, dynamic> alan, double lat, double lng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Toplanma Alanı')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alan['ADI'] ?? 'Bilinmeyen Alan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
                    if (alan['ILCE'] != null) ...[
                      _buildInfoRow('İlçe:', alan['ILCE']),
                      SizedBox(height: 4),
                    ],
                    if (alan['MAHALLE'] != null) ...[
                      _buildInfoRow('Mahalle:', alan['MAHALLE']),
                      SizedBox(height: 4),
                    ],
                    if (alan['YOL'] != null) ...[
                      _buildInfoRow('Yol:', alan['YOL']),
                      SizedBox(height: 4),
                    ],
                    if (alan['ACIKLAMA'] != null) ...[
                      _buildInfoRow('Açıklama:', alan['ACIKLAMA']),
                      SizedBox(height: 8),
                    ],
                    _buildInfoRow('Enlem:', lat.toStringAsFixed(6)),
                    SizedBox(height: 4),
                    _buildInfoRow('Boylam:', lng.toStringAsFixed(6)),
                  ],
                ),
              ),
              
              if (currentPosition != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.near_me, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Uzaklık: ${(Geolocator.distanceBetween(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                          lat,
                          lng,
                        ) / 1000).toStringAsFixed(1)} km',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openGoogleMaps(lat, lng, alan['ADI'] ?? 'Toplanma Alanı');
            },
            icon: Icon(Icons.directions, size: 18),
            label: Text('Yol Tarifi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _focusOnArea(lat, lng);
            },
            icon: Icon(Icons.zoom_in, size: 18),
            label: Text('Yakınlaştır'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _openGoogleMaps(double lat, double lng, String title) async {
    final encodedTitle = Uri.encodeComponent(title);
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_name=$encodedTitle';
    
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnackBar('Yol tarifi alınamadı: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _focusOnLocation() {
    if (currentPosition != null) {
      mapController.move(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        16.0,
      );
    }
  }

  void _focusOnArea(double lat, double lng) {
    mapController.move(LatLng(lat, lng), 17.0);
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
            Text('Toplanma alanları yükleniyor...'),
            if (error != null) ...[
              SizedBox(height: 8),
              Text(error!, style: TextStyle(color: Colors.orange, fontSize: 12)),
              SizedBox(height: 8),
              Text('Test verisi kullanılıyor...', style: TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // En yakın alanlar listesi
          if (nearestAreas.isNotEmpty)
            Container(
              height: 180,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.near_me, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Size En Yakın Toplanma Alanları',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (error != null) ...[
                        SizedBox(width: 8),
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                      ],
                    ],
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: nearestAreas.length,
                      itemBuilder: (context, index) {
                        final area = nearestAreas[index];
                        final alan = area['alan'];
                        return Container(
                          width: 220,
                          height: 120, // Sabit yükseklik
                          margin: EdgeInsets.only(right: 12),
                          child: Card(
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _focusOnArea(area['lat'], area['lng']),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 8,
                                            backgroundColor: Colors.red,
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              alan['ADI'] ?? 'Toplanma Alanı',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    if (alan['ILCE'] != null)
                                      Flexible(
                                        child: Text(
                                          '${alan['ILCE']} - ${alan['MAHALLE'] ?? ''}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 10, color: Colors.blue),
                                        SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            '${(area['distance'] / 1000).toStringAsFixed(1)} km',
                                            style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _openGoogleMaps(area['lat'], area['lng'], alan['ADI'] ?? 'Toplanma Alanı'),
                                          icon: Icon(Icons.directions, size: 12, color: Colors.green),
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                                          tooltip: 'Yol Tarifi',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Hata mesajı gösterme alanı
          if (error != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API Hatası: $error (Test verisi kullanılıyor)',
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          // Harita
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentPosition != null
                    ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                    : izmirCenter,
                initialZoom: currentPosition != null ? 13.0 : 11.0,
                minZoom: 8.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.acil_durum_app',
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Yenile butonu
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: _loadData,
            backgroundColor: Colors.orange,
            tooltip: 'Verileri Yenile',
            mini: true,
            child: Icon(Icons.refresh, color: Colors.white),
          ),
          SizedBox(height: 8),
          // Konumuma git butonu
          if (currentPosition != null)
            FloatingActionButton(
              heroTag: "location",
              onPressed: _focusOnLocation,
              backgroundColor: Colors.blue,
              tooltip: 'Konumuma Git',
              child: Icon(Icons.my_location, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const SalonBookingApp());
const green = Color(0xFF850000);
const cream = Color(0xFFF6F5F0);
const pink = Color(0xFFF7C8D8);

Future<String?> pickSalonImage() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 72,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  if (bytes.length > 900 * 1024) {
    throw Exception('Sawirku wali wuu weyn yahay. Dooro sawir ka yar.');
  }
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}


Future<String?> pickStaffImage() async {
  final file=await ImagePicker().pickImage(source:ImageSource.gallery,maxWidth:900,maxHeight:900,imageQuality:58);
  if(file==null)return null;
  final bytes=await file.readAsBytes();
  if(bytes.length>450*1024)throw Exception('Sawirku waa inuu ka yaraadaa 450KB. Dooro sawir kale.');
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

Widget salonImage(String? source, {BoxFit fit = BoxFit.cover, Widget? fallback}) {
  final value = (source ?? '').trim();
  if (value.startsWith('data:image/') && value.contains(',')) {
    try {
      return Image.memory(base64Decode(value.substring(value.indexOf(',') + 1)), fit: fit,
        errorBuilder: (_, __, ___) => fallback ?? const Icon(Icons.image_not_supported));
    } catch (_) {
      return fallback ?? const Icon(Icons.image_not_supported);
    }
  }
  if (value.startsWith('https://') || value.startsWith('http://')) {
    return Image.network(value, fit: fit,
      errorBuilder: (_, __, ___) => fallback ?? const Icon(Icons.image_not_supported));
  }
  return fallback ?? const Icon(Icons.image_not_supported);
}

class SalonApi {
  static const String baseUrl = 'https://salon-booking-api.cabdihakiimjaamac112.workers.dev';


  static Future<List<Map<String,dynamic>>> featuredProducts() async {
    final r=await http.get(Uri.parse('$baseUrl/api/featured-products'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200 || b['ok']!=true) throw Exception('Alaabta lama soo qaadi karin');
    return (b['products'] as List).cast<Map<String,dynamic>>();
  }
  static Future<String> adminLogin(String password) async {
    final r=await http.post(Uri.parse('$baseUrl/api/admin/login'),headers:{'Content-Type':'application/json'},body:jsonEncode({'password':password}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200 || b['ok']!=true) throw Exception(b['error']??'Admin login wuu fashilmay');
    return b['token'] as String;
  }
  static Future<void> addFeaturedProduct(String token,Map<String,dynamic> p) async {
    final r=await http.post(Uri.parse('$baseUrl/api/admin/featured-products'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode(p));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=201 || b['ok']!=true) throw Exception(b['error']??'Kaydintu way fashilantay');
  }
  static Future<void> updateFeaturedProduct(String token,String id,Map<String,dynamic> p) async {
    final r=await http.put(Uri.parse('$baseUrl/api/admin/featured-products/$id'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode(p));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200 || b['ok']!=true) throw Exception(b['error']??'Wax ka beddelku wuu fashilmay');
  }

  static Future<void> deleteFeaturedProduct(String token,String id) async {
    final r=await http.delete(Uri.parse('$baseUrl/api/admin/featured-products/$id'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200 || b['ok']!=true) throw Exception(b['error']??'Tirtiriddu way fashilantay');
  }

  static Future<Map<String, dynamic>> createBooking({
    required String category,
    required String customerName,
    required String customerPhone,
    required String customerWhatsApp,
    required Map<String, dynamic> details,
    String? merchantId,
    String? packageId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'category': category,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerWhatsApp': customerWhatsApp,
        if (merchantId != null) 'merchantId': merchantId,
        if (packageId != null) 'packageId': packageId,
        'details': details,
      }),
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['ok'] != true) {
      throw Exception(decoded['error'] ?? 'Codsiga server-ka lama gudbin.');
    }
    return decoded;
  }

  static Future<List<Map<String,dynamic>>> customerOrders(String phone) async {
    final r=await http.get(Uri.parse('$baseUrl/api/customer/orders?phone=${Uri.encodeQueryComponent(phone)}'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Dalabyada lama soo qaadi karin');
    return (b['orders'] as List).cast<Map<String,dynamic>>();
  }
  static Future<void> submitPayment(String id,String customerPhone,String provider,String senderPhone,double amount,String currency) async {
    final r=await http.post(Uri.parse('$baseUrl/api/bookings/$id/payment'),headers:{'Content-Type':'application/json'},body:jsonEncode({'customerPhone':customerPhone,'provider':provider,'senderPhone':senderPhone,'amount':amount,'currency':currency}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Xogta lacag-bixinta lama dirin');
  }
  static Future<List<Map<String,dynamic>>> adminPayments(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/admin/payments'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Lacag-bixinnada lama soo qaadi karin');
    return (b['payments'] as List).cast<Map<String,dynamic>>();
  }
  static Future<void> reviewPayment(String token,String id,String status) async {
    final r=await http.patch(Uri.parse('$baseUrl/api/admin/payments/$id'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'status':status}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Xaqiijinta lacagtu way fashilantay');
  }

  static Future<Map<String,dynamic>> paymentConfig(String merchantId) async {
    final r=await http.get(Uri.parse('$baseUrl/api/payments/config?merchantId=${Uri.encodeQueryComponent(merchantId)}'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Hababka lacagta lama soo qaadi karin');
    return b;
  }
  static Future<void> savePaymentConfig(String token,String merchantId,String provider,String currency,String recipientNumber) async {
    final r=await http.put(Uri.parse('$baseUrl/api/admin/payment-configs'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'merchantId':merchantId,'provider':provider,'currency':currency,'recipientNumber':recipientNumber}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Lambarka lacagta lama kaydin');
  }
  static Future<Map<String,dynamic>> promotionConfig() async {
    final r=await http.get(Uri.parse('$baseUrl/api/settings/promotions'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Lambarrada xayeysiiska lama soo qaadi karin');
    return b;
  }
  static Future<void> savePromotionConfig(String token,String telesom,String somtel) async {
    final r=await http.put(Uri.parse('$baseUrl/api/admin/settings/promotions'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'telesomNumber':telesom,'somtelNumber':somtel}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Lambarrada xayeysiiska lama kaydin');
  }
  static Future<Map<String,dynamic>> ownerPromotionInfo(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/owner/promotions'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Xogta boosaska lama soo qaadi karin');
    return b;
  }
  static Future<void> createOwnerPromotion(String token,int slot,int days,String provider,String senderPhone) async {
    final r=await http.post(Uri.parse('$baseUrl/api/owner/promotions'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'slot':slot,'planDays':days,'provider':provider,'senderPhone':senderPhone}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=201||b['ok']!=true) throw Exception(b['error']??'Codsiga xayeysiiska lama dirin');
  }
  static Future<List<Map<String,dynamic>>> adminPromotionRequests(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/admin/promotions'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Codsiyada xayeysiiska lama soo qaadi karin');
    return (b['requests'] as List).cast<Map<String,dynamic>>();
  }
  static Future<void> reviewPromotion(String token,String id,String status) async {
    final r=await http.patch(Uri.parse('$baseUrl/api/admin/promotions/$id'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'status':status}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Xaqiijinta xayeysiiska way fashilantay');
  }

  static Future<double?> exchangeRate() async {
    final r=await http.get(Uri.parse('$baseUrl/api/settings/fx'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception('Sarifka lama soo qaadi karin');
    return (b['slshPerUsd'] as num?)?.toDouble();
  }
  static Future<void> saveExchangeRate(String token,double rate) async {
    final r=await http.put(Uri.parse('$baseUrl/api/admin/settings/fx'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'slshPerUsd':rate}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Sarifka lama kaydin');
  }

  static Future<List<Map<String,dynamic>>> packages({String? category}) async {
    final q=category==null?'':'?category=${Uri.encodeQueryComponent(category)}';
    final r=await http.get(Uri.parse('$baseUrl/api/packages$q'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Full Package lama soo qaadi karin');
    return (b['packages'] as List).cast<Map<String,dynamic>>();
  }
  static Future<List<Map<String,dynamic>>> adminMerchants(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/admin/merchants'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Meheradaha lama soo qaadi karin');
    return (b['merchants'] as List).cast<Map<String,dynamic>>();
  }
  static Future<void> savePackage(String token,Map<String,dynamic> p,{bool update=false}) async {
    final uri=Uri.parse('$baseUrl/api/packages');
    final headers={'Content-Type':'application/json','Authorization':'Bearer $token'};
    final response=update?await http.put(uri,headers:headers,body:jsonEncode(p)):await http.post(uri,headers:headers,body:jsonEncode(p));
    final b=jsonDecode(response.body) as Map<String,dynamic>;
    if(response.statusCode<200||response.statusCode>=300||b['ok']!=true) throw Exception(b['error']??'Package lama kaydin');
  }

  static Future<List<Map<String,dynamic>>> publicMerchants(String category) async {
    final r=await http.get(Uri.parse('$baseUrl/api/merchants?category=${Uri.encodeQueryComponent(category)}'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Meheradaha lama soo qaadi karin');
    return (b['merchants'] as List).cast<Map<String,dynamic>>();
  }
  static Future<String> createMerchant(String token,Map<String,dynamic> merchant) async {
    final r=await http.post(Uri.parse('$baseUrl/api/admin/merchants'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode(merchant));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=201||b['ok']!=true) throw Exception(b['error']??'Meheradda lama diiwaangelin');
    return b['id'].toString();
  }
  static Future<void> createOwner(String token,String merchantId,String username,String password) async {
    final r=await http.post(Uri.parse('$baseUrl/api/admin/owners'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'merchantId':merchantId,'username':username,'password':password}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=201||b['ok']!=true) throw Exception(b['error']??'Akoonka meheradda lama samayn');
  }
  static Future<void> updateMerchant(String token,String id,Map<String,dynamic> values) async {
    final r=await http.patch(Uri.parse('$baseUrl/api/admin/merchants/$id'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode(values));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Xogta meheradda lama beddelin');
  }
  static Future<void> updateStaffLimit(String token,String merchantId,int limit) async {
    final r=await http.patch(Uri.parse('$baseUrl/api/admin/merchants/$merchantId/staff-limit'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'staffLimit':limit}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Xadka shaqaalaha lama beddelin');
  }
  static Future<String> ownerLogin(String username,String password) async {
    final r=await http.post(Uri.parse('$baseUrl/api/owner/login'),headers:{'Content-Type':'application/json'},body:jsonEncode({'username':username,'password':password}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Gelitaanka meheraddu wuu fashilmay');
    return b['token'].toString();
  }

  static Future<List<Map<String,dynamic>>> rentalItems(String category,String city) async {
    final q='?category=${Uri.encodeQueryComponent(category)}&city=${Uri.encodeQueryComponent(city)}';
    final r=await http.get(Uri.parse('$baseUrl/api/rentals$q'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Sawirada alaabta lama soo qaadi karin');
    return (b['items'] as List).cast<Map<String,dynamic>>();
  }
  static Future<List<Map<String,dynamic>>> ownerRentals(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/owner/rentals'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Alaabta lama soo qaadi karin');
    return (b['items'] as List).cast<Map<String,dynamic>>();
  }
  static Future<void> saveOwnerRental(String token,Map<String,dynamic> item,{String? id}) async {
    final headers={'Content-Type':'application/json','Authorization':'Bearer $token'};
    final uri=Uri.parse(id==null?'$baseUrl/api/owner/rentals':'$baseUrl/api/owner/rentals/$id');
    final r=id==null?await http.post(uri,headers:headers,body:jsonEncode(item)):await http.patch(uri,headers:headers,body:jsonEncode(item));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if((r.statusCode!=200&&r.statusCode!=201)||b['ok']!=true) throw Exception(b['error']??'Alaabta lama kaydin');
  }
  static Future<void> deleteOwnerRental(String token,String id) async {
    final r=await http.delete(Uri.parse('$baseUrl/api/owner/rentals/$id'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Alaabta lama tirtirin');
  }

  static Future<Map<String,dynamic>> ownerStaff(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/owner/staff'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Shaqaalaha lama soo qaadi karin');
    return b;
  }
  static Future<List<Map<String,dynamic>>> publicStaff(String merchantId) async {
    final r=await http.get(Uri.parse('$baseUrl/api/merchants/$merchantId/staff'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Shaqaalaha lama soo qaadi karin');
    return (b['staff'] as List).cast<Map<String,dynamic>>();
  }
  static Future<void> addOwnerStaff(String token,Map<String,dynamic> staff) async {
    final r=await http.post(Uri.parse('$baseUrl/api/owner/staff'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode(staff));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=201||b['ok']!=true) throw Exception(b['error']??'Shaqaalaha lama diiwaangelin');
  }
  static Future<void> updateOwnerStaff(String token,String id,Map<String,dynamic> staff) async {
    final r=await http.patch(Uri.parse('$baseUrl/api/owner/staff/$id'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode(staff));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Shaqaalaha lama beddelin');
  }
  static Future<void> deleteOwnerStaff(String token,String id) async {
    final r=await http.delete(Uri.parse('$baseUrl/api/owner/staff/$id'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Shaqaalaha lama tirtirin');
  }

  static Future<List<Map<String,dynamic>>> ownerBookings(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/owner/bookings'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Ballamaha lama soo qaadi karin');
    return (b['bookings'] as List).cast<Map<String,dynamic>>();
  }

  static Future<void> updateBookingStatus(String token,String id,String status) async {
    final r=await http.patch(Uri.parse('$baseUrl/api/bookings/$id'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'status':status}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Xaaladda ballanta lama beddelin');
  }

}

class SalonBookingApp extends StatelessWidget {
  const SalonBookingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'SALON BOOKING',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: green), scaffoldBackgroundColor: cream),
    home: const RegistrationGate());
}
class Salon {
  Salon(this.id, this.name, this.location, this.services, {this.whatsappNumber = '', this.staffLimit = 5});
  String id, name, location, whatsappNumber;
  int staffLimit;
  List<String> services;
}

String phoneDigits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

Future<void> openWhatsApp(BuildContext context, String number, String message) async {
  final digits = phoneDigits(number);
  if (digits.length < 7) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lambarka WhatsApp ee goobtan wali lama gelin.')));
    return;
  }
  final uri = Uri.parse('https://wa.me/' + digits + '?text=' + Uri.encodeComponent(message));
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp lama furi karin.')));
  }
}

Future<void> callProvider(BuildContext context, String number) async {
  final digits = phoneDigits(number);
  if (digits.length < 7) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lambarka telefoonka ee goobtan wali lama gelin.')));
    return;
  }
  await launchUrl(Uri.parse('tel:' + digits), mode: LaunchMode.externalApplication);
}

Future<void> showBookingContactOptions(BuildContext context, String number, String message) async {
  await showModalBottomSheet<void>(context: context, builder: (sheetContext) => SafeArea(child: Padding(
    padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Dooro sida aad ula xiriirayso goobta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: () { Navigator.pop(sheetContext); openWhatsApp(context, number, message); },
        icon: const Icon(Icons.chat), label: const Text('U DIR WHATSAPP'),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: () { Navigator.pop(sheetContext); callProvider(context, number); },
        icon: const Icon(Icons.call), label: const Text('CALL NOW'))),
    ]))));
}
const images = <String, List<String>>{
  'Timaha': ['https://images.unsplash.com/photo-1560066984-138dadb4c035?w=500','https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=500','https://images.unsplash.com/photo-1562322140-8baeececf3df?w=500'],
  'Qurxinta wajiga': ['https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=500','https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=500'],
  'Daryeelka jirka': ['https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=500','https://images.unsplash.com/photo-1540555700478-4be289fbe5b1?w=500'],
  'Ciddiyaha': ['https://images.unsplash.com/photo-1604654894610-df63bc536371?w=500','https://images.unsplash.com/photo-1610992015732-2449b76344bc?w=500'],
  'Makeup': ['https://images.unsplash.com/photo-1526045478516-99145907023c?w=500','https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=500'],
  'Adeegyo kale': ['https://images.unsplash.com/photo-1600948836101-f9ffda59d250?w=500','https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=500'],
};

class RegistrationGate extends StatefulWidget {
  const RegistrationGate({super.key});
  @override
  State<RegistrationGate> createState() => _RegistrationGateState();
}

class _RegistrationGateState extends State<RegistrationGate> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRegistration();
  }

  Future<void> _loadRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('customer_name');
    final phone = prefs.getString('customer_phone');
    if (!mounted) return;
    if (name != null && name.trim().isNotEmpty && phone != null && phone.trim().isNotEmpty) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      return;
    }
    setState(() => loading = false);
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (name.isEmpty || digits.length < 7 || digits.length > 15) {
      setState(() => error = 'Geli magacaaga iyo number telefoon oo sax ah.');
      return;
    }
    setState(() { saving = true; error = null; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_name', name);
    final whatsapp = whatsappController.text.trim().isEmpty ? phone : whatsappController.text.trim();
    await prefs.setString('customer_phone', phone);
    await prefs.setString('customer_whatsapp', whatsapp);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, color: green), filled: true,
    fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: green.withOpacity(.18))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: green, width: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: pink, body: Center(child: CircularProgressIndicator(color: green)));
    return Scaffold(
      backgroundColor: pink,
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 88, height: 88, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.spa, color: green, size: 48)),
          const SizedBox(height: 20),
          Image.asset('assets/salon_logo.png', width: 300, height: 112, fit: BoxFit.contain),
          const SizedBox(height: 8),
          const Text('Ku soo dhowow. Isdiiwaangeli si aad u gasho.', textAlign: TextAlign.center, style: TextStyle(color: green)),
          const SizedBox(height: 28),
          TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: _decoration('Geli Number kaaga', Icons.phone)),
          const SizedBox(height: 14),
          TextField(controller: whatsappController, keyboardType: TextInputType.phone, decoration: _decoration('Number-ka WhatsApp (haddii uu ka duwan yahay)', Icons.chat)),
          const SizedBox(height: 14),
          TextField(controller: nameController, textCapitalization: TextCapitalization.words, decoration: _decoration('Geli magacaaga', Icons.person)),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, height: 52, child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
            onPressed: saving ? null : _register,
            child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          )),
        ]),
      ))),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  bool admin = false;
  String selectedCity = 'Hargeysa';
  static const List<String> activeCities = ['Hargeysa', 'Burco'];
  static const List<String> upcomingCities = ['Boorama', 'Berbera', 'Ceerigaabo', 'Gebiley'];

  String? adminToken;
  List<Map<String,dynamic>> featured=[];
  bool featuredLoading=true;
  int featuredPage=0;
  final PageController featuredController=PageController(viewportFraction:.84);
  Timer? featuredTimer;
  @override
  void initState(){
    super.initState(); loadFeatured(); loadSelectedCity(); loadSalons();
    featuredTimer=Timer.periodic(const Duration(seconds:3),(_){
      if(!mounted||featured.length<2||!featuredController.hasClients)return;
      featuredPage=(featuredPage+1)%featured.length;
      featuredController.animateToPage(featuredPage,duration:const Duration(milliseconds:550),curve:Curves.easeInOut);
    });
  }
  @override
  void dispose(){featuredTimer?.cancel();featuredController.dispose();super.dispose();}
  Future<void> loadSelectedCity() async {final p=await SharedPreferences.getInstance();final saved=p.getString('selected_city');if(mounted&&activeCities.contains(saved))setState(()=>selectedCity=saved!);}

  Future<void> loadSalons() async {
    try {
      final rows=await SalonApi.publicMerchants('SALON');
      final list=rows.map((m)=>Salon(
        m['id'].toString(),
        (m['name']??'Salon').toString(),
        (m['location']??'Hargeysa').toString(),
        ['Timaha','Qurxinta wajiga','Daryeelka jirka','Ciddiyaha','Makeup','Adeegyo kale'],
        whatsappNumber:(m['owner_whatsapp']??'').toString(),
        staffLimit:int.tryParse((m['staff_limit']??5).toString())??5,
      )).toList();
      if(mounted)setState(()=>{salons..clear()..addAll(list),salonsLoading=false});
    } catch(e) {
      if(mounted)setState(()=>salonsLoading=false);
    }
  }
  Future<void> loadSalonStaff(String merchantId) async {
    if(staffByMerchant.containsKey(merchantId)||staffLoadingIds.contains(merchantId))return;
    setState(()=>staffLoadingIds.add(merchantId));
    try {
      final rows=await SalonApi.publicStaff(merchantId);
      if(mounted)setState(()=>staffByMerchant[merchantId]=rows);
    } catch(_) {
      if(mounted)setState(()=>staffByMerchant[merchantId]=[]);
    }
    if(mounted)setState(()=>staffLoadingIds.remove(merchantId));
  }
  Future<void> chooseCity() async {
    final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Dooro magaaladaada'),content:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Magaalooyinka shaqaynaya'),...activeCities.map((city)=>ListTile(leading:const Icon(Icons.location_city,color:green),title:Text(city),onTap:()=>Navigator.pop(ctx,city))),const Divider(),const Text('Weli lama diiwaangelin'),...upcomingCities.map((city)=>ListTile(enabled:false,leading:const Icon(Icons.lock_outline),title:Text(city),subtitle:const Text('Dib ayaa loogu dari doonaa')))])));
    if(value==null)return;final p=await SharedPreferences.getInstance();await p.setString('selected_city',value);if(mounted)setState(()=>selectedCity=value);
  }
  final Map<String,String> categoryImageUrls={};
  final Map<String,String> categoryImageIds={};
  static const String categoryImageMarker='__CATEGORY_IMAGE__';
  Future<void> loadFeatured() async {
    try{
      final x=await SalonApi.featuredProducts();
      final products=<Map<String,dynamic>>[];
      final urls=<String,String>{}, ids=<String,String>{};
      for(final p in x){
        if(p['title']==categoryImageMarker){
          final c=(p['category']??'').toString();
          urls[c]=(p['image_url']??'').toString();
          ids[c]=(p['id']??'').toString();
        } else { products.add(p); }
      }
      if(mounted)setState((){
        featured=products; categoryImageUrls..clear()..addAll(urls);
        categoryImageIds..clear()..addAll(ids); featuredLoading=false;
      });
    } catch(_){if(mounted)setState(()=>featuredLoading=false);}
  }
  Future<void> setCategoryImage(String category) async {
    final urlController=TextEditingController(
      text:(categoryImageUrls[category]??'').startsWith('http')?categoryImageUrls[category]!:'' );
    String? selectedImage=categoryImageUrls[category];
    final url=await showDialog<String>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:Text('Sawirka $category'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        SizedBox(height:130,width:double.infinity,child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Container(color:cream,child:salonImage(selectedImage,fit:BoxFit.cover,fallback:const Icon(Icons.image,size:42,color:green))))),
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:() async {try{final picked=await pickSalonImage();if(picked!=null)refresh(()=>selectedImage=picked);}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},icon:const Icon(Icons.photo_library),label:const Text('KA DOORO GALLERY-GA')),
        TextField(controller:urlController,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'Ama geli HTTPS URL (ikhtiyaari)',hintText:'https://...'),onChanged:(v){if(v.trim().startsWith('https://'))refresh(()=>selectedImage=v.trim());}),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,selectedImage??urlController.text.trim()),child:const Text('Kaydi'))],
    )));
    if(url==null||url.isEmpty||!mounted)return;
    if(!url.startsWith('data:image/')&&!url.startsWith('https://')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Dooro sawir ama geli HTTPS URL sax ah.')));return;}
    try{
      await SalonApi.addFeaturedProduct(adminToken!,{
        'title':categoryImageMarker,'description':'Home category image',
        'price':'','currency':'USD','category':category,'imageUrl':url
      });
      final oldId=categoryImageIds[category];
      if(oldId!=null&&oldId.isNotEmpty) await SalonApi.deleteFeaturedProduct(adminToken!,oldId);
      await loadFeatured();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Sawirka $category waa la beddelay.')));
    }catch(e){
      await loadFeatured();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Sawirka lama kaydin: $e')));
    }
  }
  Future<void> openAdminTools() async {
    if(adminToken==null){
      final c=TextEditingController();
      final pass=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Admin Login'),
        content:TextField(controller:c,obscureText:true,decoration:const InputDecoration(labelText:'Admin password')),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text),child:const Text('Gal'))]));
      if(pass==null||pass.isEmpty||!mounted)return;
      try{adminToken=await SalonApi.adminLogin(pass);if(mounted)setState(()=>admin=true);}
      catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));return;}
    }
    await addFeaturedProduct();
  }
  Future<void> addFeaturedProduct() async {
    final title=TextEditingController(),desc=TextEditingController(),price=TextEditingController(),img=TextEditingController();
    String category='SALON',currency='USD';
    String? selectedImage;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('Ku dar ALAAB CUSUB'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Magaca alaabta')),
        TextField(controller:desc,maxLines:2,decoration:const InputDecoration(labelText:'Faahfaahin')),
        TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Qiimaha (ikhtiyaari)')),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Qaybta'),items:['SALON','CAKES','DECORATION','KIRAYSO'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>category=v??'SALON')),
        DropdownButtonFormField<String>(value:currency,decoration:const InputDecoration(labelText:'Lacagta'),items:['USD','SLSH'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>currency=v??'USD')),
        SizedBox(height:120,width:double.infinity,child:ClipRRect(borderRadius:BorderRadius.circular(10),child:Container(color:cream,child:salonImage(selectedImage,fit:BoxFit.cover,fallback:const Icon(Icons.image,size:40,color:green))))),
        OutlinedButton.icon(onPressed:() async {try{final picked=await pickSalonImage();if(picked!=null)refresh(()=>selectedImage=picked);}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},icon:const Icon(Icons.photo_library),label:const Text('KA DOORO GALLERY-GA')),
        TextField(controller:img,decoration:const InputDecoration(labelText:'Ama geli HTTPS URL (ikhtiyaari)'),onChanged:(v){if(v.trim().startsWith('https://'))refresh(()=>selectedImage=v.trim());}),
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydi'))])));
    if(ok!=true||title.text.trim().isEmpty||!mounted)return;
    final imageValue=selectedImage??img.text.trim();
    if(imageValue.isNotEmpty&&!imageValue.startsWith('data:image/')&&!imageValue.startsWith('https://')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Dooro sawir ama geli HTTPS URL sax ah.')));return;}
    try{await SalonApi.addFeaturedProduct(adminToken!,{'title':title.text.trim(),'description':desc.text.trim(),'price':price.text.trim(),'currency':currency,'category':category,'imageUrl':imageValue});await loadFeatured();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Alaabta waa la daabacay.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> editFeatured(Map<String,dynamic> p) async {
    final title=TextEditingController(text:(p['title']??'').toString());
    final desc=TextEditingController(text:(p['description']??'').toString());
    final price=TextEditingController(text:(p['price']??'').toString());
    final existingImage=(p['image_url']??'').toString();
    final img=TextEditingController(text:existingImage.startsWith('https://')?existingImage:'');
    String? selectedImage=existingImage.isNotEmpty?existingImage:null;
    String category=(p['category']??'SALON').toString(),currency=(p['currency']??'USD').toString();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('Wax ka beddel alaabta'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Magaca alaabta')),
        TextField(controller:desc,maxLines:2,decoration:const InputDecoration(labelText:'Faahfaahin')),
        TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Qiimaha')),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Qaybta'),items:['SALON','CAKES','DECORATION','KIRAYSO'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>category=v??'SALON')),
        DropdownButtonFormField<String>(value:currency,decoration:const InputDecoration(labelText:'Lacagta'),items:['USD','SLSH'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>currency=v??'USD')),
        SizedBox(height:120,width:double.infinity,child:ClipRRect(borderRadius:BorderRadius.circular(10),child:Container(color:cream,child:salonImage(selectedImage,fit:BoxFit.cover,fallback:const Icon(Icons.image,size:40,color:green))))),
        OutlinedButton.icon(onPressed:() async {try{final picked=await pickSalonImage();if(picked!=null)refresh(()=>selectedImage=picked);}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},icon:const Icon(Icons.photo_library),label:const Text('KA DOORO GALLERY-GA')),
        TextField(controller:img,decoration:const InputDecoration(labelText:'Ama geli HTTPS URL (ikhtiyaari)'),onChanged:(v){if(v.trim().startsWith('https://'))refresh(()=>selectedImage=v.trim());}),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydi'))])));
    if(ok!=true||title.text.trim().isEmpty||!mounted)return;
    final imageValue=selectedImage??img.text.trim();
    if(imageValue.isNotEmpty&&!imageValue.startsWith('data:image/')&&!imageValue.startsWith('https://')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Dooro sawir ama geli HTTPS URL sax ah.')));return;}
    try{
      await SalonApi.updateFeaturedProduct(adminToken!,p['id'].toString(),{'title':title.text.trim(),'description':desc.text.trim(),'price':price.text.trim(),'currency':currency,'category':category,'imageUrl':imageValue});
      await loadFeatured();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Alaabta waa la cusboonaysiiyey.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> removeFeatured(Map<String,dynamic> p) async {
    try{await SalonApi.deleteFeaturedProduct(adminToken!,p['id'].toString());await loadFeatured();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Widget featuredSection(){
    if(featuredLoading)return const Padding(padding:EdgeInsets.all(14),child:Center(child:CircularProgressIndicator(color:green)));
    if(featured.isEmpty&&!admin)return const SizedBox.shrink();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('ALAAB CUSUB',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold,color:green)),if(admin)TextButton.icon(onPressed:addFeaturedProduct,icon:const Icon(Icons.add),label:const Text('Ku dar'))]),
      if(featured.isEmpty)const Text('Weli alaab cusub lama soo bandhigin.'),
      if(featured.isNotEmpty)SizedBox(height:180,child:PageView.builder(controller:featuredController,itemCount:featured.length,onPageChanged:(i)=>featuredPage=i,itemBuilder:(ctx,i){
        final p=featured[i];return Padding(padding:const EdgeInsets.only(right:10),child:Card(clipBehavior:Clip.antiAlias,child:Row(children:[
          SizedBox(width:112,height:180,child:(p['image_url']??'').toString().isNotEmpty?salonImage(p['image_url'].toString(),fit:BoxFit.cover,fallback:Container(color:cream,child:const Icon(Icons.shopping_bag,color:green,size:36))):Container(color:cream,child:const Icon(Icons.shopping_bag,color:green,size:36))),
          Expanded(child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
            Text(p['title']??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:15)),
            Text(p['category']??'',style:const TextStyle(color:green,fontSize:11)),
            if(p['price']!=null)Text('${p['price']} ${p['currency']??'USD'}',style:const TextStyle(color:green,fontWeight:FontWeight.bold)),
            Text(p['description']??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11)),
            if(admin)Align(alignment:Alignment.centerRight,child:Wrap(children:[IconButton(tooltip:'Wax ka beddel',onPressed:()=>editFeatured(p),icon:const Icon(Icons.edit,color:green)),IconButton(tooltip:'Tirtir',onPressed:()=>removeFeatured(p),icon:const Icon(Icons.delete_outline,color:Colors.red))])),
          ])))
        ])));
      })),
      if(featured.length>1)Center(child:Text('${featuredPage+1} / ${featured.length}',style:const TextStyle(fontSize:11,color:Colors.black54))),
    ]);
  }
  int opened = -1;
  int selectedSection = -1;
  final List<Salon> salons = [];
  bool salonsLoading = true;
  final Map<String,List<Map<String,dynamic>>> staffByMerchant = {};
  final Set<String> staffLoadingIds = {};
  Future<String?> ask(String title, String hint) async {
    final c = TextEditingController();
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: TextField(controller: c, decoration: InputDecoration(hintText: hint)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ka noqo')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Kaydi'))]));
  }
  Future<void> addSalon() async {
    if(adminToken==null)return;
    final n=await ask('Ku dar Salon','Magaca salon-ka');
    if(n==null||n.isEmpty||!mounted)return;
    final l=await ask('Goobta Salon-ka','Magaalada / xaafadda');
    if(!mounted)return;
    final w=await ask('WhatsApp-ka Salon-ka','Tusaale: 25263xxxxxxx');
    if(!mounted)return;
    final username=await ask('Akoonka meheradda','Username-ka uu ku geli doono');
    if(username==null||username.trim().isEmpty||!mounted)return;
    final password=await ask('Password-ka meheradda','Ugu yaraan 10 xaraf');
    if(password==null||password.length<10||!mounted)return;
    try {
      final id=await SalonApi.createMerchant(adminToken!,{'category':'SALON','name':n.trim(),'location':l??'Hargeysa','ownerWhatsApp':w??''});
      await SalonApi.createOwner(adminToken!,id,username.trim(),password);
      await loadSalons();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Meheradda iyo akoonkeeda waa la diiwaangeliyey.')));
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Diiwaangelintu way fashilantay: $e')));
    }
  }
  Future<void> editStaffLimit(Salon salon) async {
    if(adminToken==null)return;
    final c=TextEditingController(text:salon.staffLimit.toString());
    final value=await showDialog<int>(context:context,builder:(ctx)=>AlertDialog(
      title:Text('Xadka hablaha — '+salon.name),
      content:TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Tirada ugu badan',border:OutlineInputBorder())),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,int.tryParse(c.text.trim())),child:const Text('Kaydi'))]));
    if(value==null)return;
    if(value<1||value>100){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Xadka waa inuu u dhexeeyaa 1 ilaa 100.')));return;}
    try{await SalonApi.updateStaffLimit(adminToken!,salon.id,value);await loadSalons();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Xadka hablaha waa la beddelay.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  void openMerchantLogin() {
    Navigator.push(context,MaterialPageRoute(builder:(_)=>const MerchantLoginPage()));
  }
  Future<void> rename(int i) async {
    final n = await ask('Beddel magaca', salons[i].name);
    if (n != null && n.isNotEmpty) setState(() => salons[i].name = n);
  }
  Future<void> editSalonPhone(int i) async {
    if(adminToken==null)return;
    final n=await ask('WhatsApp / telefoonka '+salons[i].name,salons[i].whatsappNumber.isEmpty?'252...':salons[i].whatsappNumber);
    if(n==null)return;
    try{await SalonApi.updateMerchant(adminToken!,salons[i].id,{'ownerWhatsApp':n.trim()});await loadSalons();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Lambarka meheradda waa la kaydiyey.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: green, foregroundColor: Colors.white,
      title: const Text('SALON BOOKING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      actions: [if (admin) IconButton(onPressed: addSalon, icon: const Icon(Icons.add_business)),
        if (admin) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>FullPackagesPage(adminToken:adminToken))),icon:const Icon(Icons.inventory_2),tooltip:'Full Package'),
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminPaymentsPage(token:adminToken!))),icon:const Icon(Icons.payments),tooltip:'Xaqiiji lacagaha'),
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminPromotionPage(token:adminToken!))),icon:const Icon(Icons.campaign),tooltip:'Xaqiiji boosaska xayeysiiska'),
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminPaymentSettingsPage(token:adminToken!))),icon:const Icon(Icons.settings_applications),tooltip:'Hababka lacagta iyo sarifka'),
        IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CustomerOrdersPage())),icon:const Icon(Icons.receipt_long),tooltip:'Dalabyadayda'),
        IconButton(onPressed: openMerchantLogin, icon: const Icon(Icons.storefront), tooltip: 'Gelitaanka meheradda'),
        IconButton(onPressed: openAdminTools, icon: const Icon(Icons.admin_panel_settings), tooltip: 'Admin')]),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [green, Color(0xFF164B39)])),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ku soo dhowow', style: TextStyle(color: Colors.white70)), SizedBox(height: 5),
          Text('Quruxdaada, hal meel.', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
          SizedBox(height: 8), Text('Dooro qaybta aad u baahan tahay.', style: TextStyle(color: Colors.white))])),
      const SizedBox(height: 16),
      Card(child:ListTile(leading:const Icon(Icons.location_on,color:green),title:const Text('Magaaladaada'),subtitle:Text(selectedCity,style:const TextStyle(fontWeight:FontWeight.bold,color:green)),trailing:const Icon(Icons.keyboard_arrow_down),onTap:chooseCity)),
      featuredSection(),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1,
        children: [
          sectionTile('SALON', 'Adeegyada quruxda', Icons.spa_outlined, 0),
          sectionTile('CAKES', 'Dalbo cake', Icons.cake_outlined, 1),
          sectionTile('DECORATION', 'Qurxinta munaasabadaha', Icons.celebration_outlined, 2),
          sectionTile('KIRAYSO', 'SAD KIRAYSO, TAASH iyo maryo', Icons.checkroom, 3),
        ],
      ),
      if (selectedSection == 0) ...[
        const SizedBox(height: 20),
        const Text('BALLAN QABSO — SALON', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green)),
        const SizedBox(height: 6), const Text('SALON-LADA', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const FullPackagesPage(category:'SALON'))),icon:const Icon(Icons.inventory_2),label:const Text('FULL PACKAGE')),
        const SizedBox(height: 10),
        if(salonsLoading) const Center(child:Padding(padding:EdgeInsets.all(18),child:CircularProgressIndicator(color:green)))
        else if(salons.where((s)=>s.location.trim().toLowerCase()==selectedCity.toLowerCase()).isEmpty) Padding(padding:const EdgeInsets.all(18),child:Text('Magaalada $selectedCity weli lagama diiwaangelin meherado salon ah.',textAlign:TextAlign.center))
        else Wrap(spacing:10,runSpacing:10,children:salons.asMap().entries.where((e)=>e.value.location.trim().toLowerCase()==selectedCity.toLowerCase()).map((e)=>SizedBox(width:(MediaQuery.of(context).size.width-48)/2,child:salonCard(e.key))).toList()),
      ],
      if (selectedSection == 1) ...[
        const SizedBox(height: 20),
        const Text('BALLAN QABSO — CAKES', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: green)),
        const SizedBox(height: 8),
        categoryDirectoryCard('CAKES', '20 meheradood oo sameeya cakes', Icons.cake_outlined, true),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const FullPackagesPage(category:'CAKES'))),icon:const Icon(Icons.inventory_2),label:const Text('FULL PACKAGE')),
      ],
      if (selectedSection == 2) ...[
        const SizedBox(height: 20),
        const Text('BALLAN QABSO — DECORATION', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: green)),
        const SizedBox(height: 8),
        categoryDirectoryCard('DECORATION', '20 meheradood oo decoration ah', Icons.celebration_outlined, false),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const FullPackagesPage(category:'DECORATION'))),icon:const Icon(Icons.inventory_2),label:const Text('FULL PACKAGE')),
      ],
      if (admin) const Padding(padding: EdgeInsets.only(top: 15), child: Text('ADMIN: Meheradaha, shaqaalaha iyo xadkooda waxaa lagu kaydiyaa server-ka.', style: TextStyle(color: green, fontSize: 12))),
    ]));
  Widget sectionTile(String title, String subtitle, IconData icon, int index) {
    final imageUrl=categoryImageUrls[title];
    return InkWell(
      onTap: () {
        if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderDirectoryPage(title: 'DECORATION', isCake: false, city:selectedCity)));
          return;
        }
        if(index==3){
          Navigator.push(context,MaterialPageRoute(builder:(_)=>RentalPage(city:selectedCity)));
          return;
        }
        setState(() => selectedSection = selectedSection == index ? -1 : index);
      },
      borderRadius: BorderRadius.circular(18),
      child: ClipRRect(borderRadius:BorderRadius.circular(18),child:Container(
        decoration:BoxDecoration(color:Colors.white,border:Border.all(color:green.withOpacity(.18)),boxShadow:[
          BoxShadow(color:green.withOpacity(.08),blurRadius:7,offset:const Offset(0,3))]),
        child:Stack(fit:StackFit.expand,children:[
          if(imageUrl!=null&&imageUrl.isNotEmpty) salonImage(imageUrl,fit:BoxFit.cover,
            fallback:Container(color:cream,child:Icon(icon,color:green,size:42))),
          if(imageUrl==null||imageUrl.isEmpty) Container(color:Colors.white),
          Container(decoration:BoxDecoration(gradient:LinearGradient(
            begin:Alignment.topCenter,end:Alignment.bottomCenter,
            colors:imageUrl!=null&&imageUrl.isNotEmpty
              ? [Colors.black.withOpacity(.12),Colors.black.withOpacity(.68)]
              : [Colors.white,Colors.white]))),
          Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            if(imageUrl==null||imageUrl.isEmpty) Container(width:58,height:58,
              decoration:BoxDecoration(color:cream,borderRadius:BorderRadius.circular(16)),
              child:Icon(icon,color:green,size:32)),
            if(imageUrl!=null&&imageUrl.isNotEmpty) const SizedBox(height:8),
            const SizedBox(height:10),
            Text(title,textAlign:TextAlign.center,style:TextStyle(
              color:imageUrl!=null&&imageUrl.isNotEmpty?Colors.white:green,
              fontSize:16,fontWeight:FontWeight.bold,shadows:imageUrl!=null&&imageUrl.isNotEmpty
                ? [const Shadow(color:Colors.black54,blurRadius:4)] : null)),
            const SizedBox(height:4),
            Padding(padding:const EdgeInsets.symmetric(horizontal:8),child:Text(subtitle,
              textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis,
              style:TextStyle(color:imageUrl!=null&&imageUrl.isNotEmpty?Colors.white:Colors.black54,fontSize:11))),
            const SizedBox(height:6),
            Icon(selectedSection==index?Icons.keyboard_arrow_up:Icons.arrow_downward,
              color:imageUrl!=null&&imageUrl.isNotEmpty?Colors.white:green,size:18),
          ]),
          if(admin) Positioned(right:4,top:4,child:Material(color:Colors.black54,shape:const CircleBorder(),
            child:IconButton(icon:const Icon(Icons.edit,color:Colors.white,size:18),tooltip:'Beddel sawirka',
              onPressed:()=>setCategoryImage(title)))),
        ]),
      )),
    );
  }
  Widget salonCard(int i) {
    final s = salons[i]; final isOpen = opened == i;
    return Card(margin: const EdgeInsets.only(bottom: 11), clipBehavior: Clip.antiAlias, child: Column(children: [
      InkWell(onTap: () {setState(() => opened = isOpen ? -1 : i);if(!isOpen)loadSalonStaff(s.id);}, child: Row(children: [
        Container(width: 98, height: 88, color: cream, child: const Icon(Icons.storefront, color: green, size: 42)),
        Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4),
          Row(children: [const Icon(Icons.location_on, size: 15, color: green), Text(s.location)]),
          const SizedBox(height: 5), Text(isOpen ? 'Qari adeegyada' : 'Taabo si aad adeegyada u aragto', style: const TextStyle(color: green, fontSize: 12))]))),
        Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: green), const SizedBox(width: 8)])),
      if (admin) Wrap(children: [
        TextButton.icon(onPressed: () => editSalonPhone(i), icon: const Icon(Icons.phone, size: 16), label: const Text('Lambarka')),
        TextButton.icon(onPressed: () => editStaffLimit(s), icon: const Icon(Icons.groups, size: 16), label: Text('Xadka hablaha: '+s.staffLimit.toString()))]),
      if (isOpen) ...[const Divider(height: 1),
        if(staffLoadingIds.contains(s.id)) const Padding(padding:EdgeInsets.all(14),child:Center(child:CircularProgressIndicator(color:green)))
        else if((staffByMerchant[s.id]??[]).isEmpty) const Padding(padding:EdgeInsets.all(12),child:Text('Meheraddan wali ma diiwaangelin hablaha shaqeeya.'))
        else ...(staffByMerchant[s.id]??[]).map((person)=>staffCard(s,person)),
        ...s.services.map((service) => serviceTile(i, service)),
        if (admin) TextButton.icon(onPressed: () async { final v = await ask('Ku dar adeeg', 'Magaca adeegga'); if (v != null && v.isNotEmpty) setState(() => s.services.add(v)); },
          icon: const Icon(Icons.add), label: const Text('Ku dar adeeggan salon-kan'))],
    ]));
  }

  Widget staffCard(Salon salon,Map<String,dynamic> person) {
    List<dynamic> services=[];
    try{services=jsonDecode((person['services_json']??'[]').toString()) as List;}catch(_){}
    return Card(margin:const EdgeInsets.symmetric(horizontal:10,vertical:6),child:Padding(padding:const EdgeInsets.all(10),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      ClipRRect(borderRadius:BorderRadius.circular(10),child:salonImage((person['photoUrl']??'').toString(),fit:BoxFit.cover,fallback:Container(width:76,height:86,color:cream,child:const Icon(Icons.person,color:green,size:34)))),
      const SizedBox(width:10),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text((person['name']??'').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:15)),
        if((person['title']??'').toString().isNotEmpty)Text(person['title'].toString(),style:const TextStyle(color:Colors.black54,fontSize:12)),
        const SizedBox(height:6),
        Wrap(spacing:5,runSpacing:4,children:services.map((v)=>OutlinedButton(
          style:OutlinedButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),minimumSize:const Size(0,30)),
          onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SalonBookingPage(salonName:salon.name,serviceName:v.toString(),whatsappNumber:salon.whatsappNumber,merchantId:salon.id,staffId:person['id'].toString(),staffName:person['name'].toString()))),
          child:Text('BALLAN: '+v.toString(),style:const TextStyle(fontSize:10)))).toList())
      ]))
    ])));
  }
  Widget serviceTile(int salonIndex, String service) => ExpansionTile(
    leading: const Icon(Icons.spa_outlined, color: green), title: Text(service, style: const TextStyle(fontWeight: FontWeight.w600)),
    children: [SizedBox(height: 128, child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), scrollDirection: Axis.horizontal,
      itemCount: (images[service] ?? images['Adeegyo kale']!).length, separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, j) { final pics = images[service] ?? images['Adeegyo kale']!;
        return ClipRRect(borderRadius: BorderRadius.circular(12), child: Stack(children: [
          Image.network(pics[j], width: 145, height: 112, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 145, height: 112, color: Colors.black12, child: const Icon(Icons.image))),
          Positioned(left: 5, right: 5, bottom: 5, child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: green, padding: const EdgeInsets.symmetric(horizontal: 5)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SalonBookingPage(salonName: salons[salonIndex].name, serviceName: service, whatsappNumber: salons[salonIndex].whatsappNumber, merchantId: salons[salonIndex].id))),
            child: const Text('BALLAN QABSO', style: TextStyle(fontSize: 10))))])); })),
      if (admin) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => setState(() => salons[salonIndex].services.remove(service)),
        child: const Text('Ka saar adeeggan salon-kan', style: TextStyle(color: Colors.red))))]);
  Widget categoryDirectoryCard(String title, String subtitle, IconData icon, bool isCake) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProviderDirectoryPage(title: title, isCake: isCake, city:selectedCity))),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 58, height: 58, decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: green, size: 32)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 5), const Text('Eeg 20-ka meheradood  →', style: TextStyle(color: green, fontWeight: FontWeight.w600, fontSize: 12)),
        ])),
        const Icon(Icons.arrow_forward_ios, size: 17, color: green),
      ])),
    ),
  );

  Widget actionCard(String title, String button, IconData icon, VoidCallback onTap) => Card(child: Padding(padding: const EdgeInsets.all(13), child: Column(children: [
    Icon(icon, color: green, size: 34), const SizedBox(height: 7), Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 9), SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: button == 'KIRAYSO' ? cream : green, foregroundColor: button == 'KIRAYSO' ? green : Colors.white), onPressed: onTap, child: Text(button)))])));
}

class ProviderDirectoryPage extends StatefulWidget {
  const ProviderDirectoryPage({super.key, required this.title, required this.isCake, required this.city});
  final String title;
  final bool isCake;
  final String city;
  @override
  State<ProviderDirectoryPage> createState() => _ProviderDirectoryPageState();
}
class _ProviderDirectoryPageState extends State<ProviderDirectoryPage> {
  bool adminMode = false;
  Map<String, String> numbers = {};
  Map<String, String> providerCities = {};
  List<String> get providers => List<String>.generate(20, (i) =>
    widget.isCake ? 'Cake Meherad ' + (i + 1).toString() : 'Decoration Meherad ' + (i + 1).toString());
  String get storageKey => widget.isCake ? 'cake_provider_whatsapp' : 'decoration_provider_whatsapp';
  @override
  void initState() { super.initState(); _loadNumbers(); }
  Future<void> _loadNumbers() async {
    final p = await SharedPreferences.getInstance();
    final cityRaw=p.getString(storageKey+'_cities');
    if(cityRaw!=null){final d=jsonDecode(cityRaw) as Map<String,dynamic>;providerCities=d.map((k,v)=>MapEntry(k,v.toString()));}
    for(final provider in providers){providerCities.putIfAbsent(provider,()=> 'Hargeysa');}
    final raw = p.getString(storageKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (mounted) setState(() => numbers = decoded.map((k,v) => MapEntry(k, v.toString())));
    }
    if(mounted)setState((){});
  }
  Future<void> _editCity(String provider) async {
    final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:Text('Magaalada $provider'),content:DropdownButtonFormField<String>(value:providerCities[provider]??'Hargeysa',items:const [DropdownMenuItem(value:'Hargeysa',child:Text('Hargeysa')),DropdownMenuItem(value:'Burco',child:Text('Burco'))],onChanged:(v)=>Navigator.pop(ctx,v))));
    if(value==null)return;providerCities[provider]=value;final p=await SharedPreferences.getInstance();await p.setString(storageKey+'_cities',jsonEncode(providerCities));if(mounted)setState((){});
  }
  Future<void> _editNumber(String provider) async {
    final c = TextEditingController(text: numbers[provider] ?? '');
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Lambarka ' + provider), content: TextField(controller: c, keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'WhatsApp / telefoon', hintText: '25263xxxxxxx')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ka noqo')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Kaydi'))]));
    if (value == null) return;
    numbers[provider] = value;
    final p = await SharedPreferences.getInstance();
    await p.setString(storageKey, jsonEncode(numbers));
    if (mounted) setState(() {});
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title), backgroundColor: green, foregroundColor: Colors.white,
      actions: [IconButton(tooltip: 'Admin demo: lambarrada goobaha', onPressed: () => setState(() => adminMode = !adminMode),
        icon: Icon(adminMode ? Icons.admin_panel_settings : Icons.lock_outline))]),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        color: const Color(0xFFE5EFE9), borderRadius: BorderRadius.circular(14)),
        child: Text('Dooro meheradda aad rabto. Waxaa halkan ku jira 20 meheradood oo ' +
          (widget.isCake ? 'cakes' : 'decoration') + ' ah.', style: const TextStyle(fontWeight: FontWeight.w600))),
      if (adminMode) const Padding(padding: EdgeInsets.only(top: 8), child: Text('ADMIN DEMO: lambarrada halkan lagu kaydiyo waxay ku jiraan telefoonkan oo keliya.', style: TextStyle(color: Colors.deepOrange, fontSize: 12))),
      const SizedBox(height: 12),
      if(providers.where((p)=>providerCities[p]==widget.city).isEmpty) Padding(padding:const EdgeInsets.all(18),child:Text('Magaalada ${widget.city} weli lagama diiwaangelin meherado ${widget.title.toLowerCase()} ah.',textAlign:TextAlign.center)),
      Wrap(spacing: 10, runSpacing: 10, children: providers.where((p)=>providerCities[p]==widget.city).map((provider) {
        return SizedBox(width: (MediaQuery.of(context).size.width - 48) / 2, child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: adminMode ? () => _editNumber(provider) : () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
              widget.isCake ? CakePage(providerName: provider, whatsappNumber: numbers[provider] ?? '') :
                DecorationBookingPage(providerName: provider, whatsappNumber: numbers[provider] ?? ''))),
            child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(backgroundColor: const Color(0xFFE5EFE9),
                child: Icon(widget.isCake ? Icons.cake_outlined : Icons.celebration_outlined, color: green)),
              const SizedBox(height: 9),
              Text(provider, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(widget.isCake ? 'Cake design iyo dalabyo' : 'Qurxinta munaasabadaha', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
              Text('Magaalada: ${providerCities[provider]??'Hargeysa'}',style:const TextStyle(fontSize:11,color:green)),
              if(adminMode)Wrap(children:[TextButton(onPressed:()=>_editCity(provider),child:const Text('Magaalo')),TextButton(onPressed:()=>_editNumber(provider),child:const Text('Telefoon'))]) else const Align(alignment:Alignment.centerRight,child:Icon(Icons.arrow_forward_ios,size:14,color:green)),
            ])),
          ),
        ));
      }).toList()),
    ]),
  );
}

class DecorationBookingPage extends StatefulWidget {
  const DecorationBookingPage({super.key, required this.providerName, this.whatsappNumber = ''});
  final String providerName;
  final String whatsappNumber;
  @override
  State<DecorationBookingPage> createState() => _DecorationBookingPageState();
}
class _DecorationBookingPageState extends State<DecorationBookingPage> {
  final customer = TextEditingController();
  final phone = TextEditingController();
  final event = TextEditingController();
  final date = TextEditingController();
  final place = TextEditingController();
  final details = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    customer.text = prefs.getString('customer_name') ?? '';
    phone.text = prefs.getString('customer_phone') ?? '';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    customer.dispose(); phone.dispose(); event.dispose(); date.dispose();
    place.dispose(); details.dispose(); super.dispose();
  }

  Widget field(TextEditingController c, String label, {int lines = 1, TextInputType? type}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: c, maxLines: lines, keyboardType: type,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));

  Future<void> _submit() async {
    if ([customer.text, phone.text, event.text, date.text, place.text].any((v) => v.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Buuxi magaca, telefoonka, munaasabadda, taariikhda iyo goobta.')));
      return;
    }
    setState(() => saving = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      await SalonApi.createBooking(
        category: 'DECORATION',
        customerName: customer.text.trim(),
        customerPhone: phone.text.trim(),
        customerWhatsApp: prefs.getString('customer_whatsapp') ?? phone.text.trim(),
        details: {'provider': widget.providerName, 'event': event.text.trim(), 'date': date.text.trim(),
          'place': place.text.trim(), 'details': details.text.trim()},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diristu way fashilantay: $e')));
      return;
    }
    final records = prefs.getStringList('decoration_booking_requests') ?? <String>[];
    final request = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'type': 'DECORATION', 'provider': widget.providerName,
      'customerName': customer.text.trim(), 'customerPhone': phone.text.trim(),
      'event': event.text.trim(), 'date': date.text.trim(), 'place': place.text.trim(),
      'details': details.text.trim(), 'status': 'Sugaya xaqiijinta',
      'createdAt': DateTime.now().toIso8601String(),
    };
    records.add(jsonEncode(request));
    await prefs.setStringList('decoration_booking_requests', records);
    if (!mounted) return;
    setState(() => saving = false);
    showDialog(context: context, barrierDismissible: false, builder: (dialogContext) => AlertDialog(
      title: const Text('Codsiga decoration-ka waa la kaydiyey'),
      content: const Text('Xogta codsiga waa la kaydiyey telefoonka. Hadda dooro WhatsApp ama wicitaan.'),
      actions: [FilledButton(onPressed: () {
        Navigator.pop(dialogContext);
        showBookingContactOptions(context, widget.whatsappNumber,
          'BALLAN DECORATION\\nMeherad: ' + widget.providerName +
          '\\nMagac: ' + customer.text.trim() + '\\nTelefoon: ' + phone.text.trim() +
          '\\nMunaasabadda: ' + event.text.trim() + '\\nTaariikh: ' + date.text.trim() +
          '\\nGoobta: ' + place.text.trim() + '\\nFaahfaahin: ' + details.text.trim());
      }, child: const Text('WHATSAPP / CALL NOW'))],
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('BALLAN QABSO — DECORATION'), backgroundColor: green, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Text(widget.providerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      field(customer, 'Magacaaga'),
      field(phone, 'Number telefoonka', type: TextInputType.phone),
      field(event, 'Nooca munaasabadda'),
      field(date, 'Taariikhda iyo waqtiga'),
      field(place, 'Goobta munaasabadda'),
      field(details, 'Faahfaahinta decoration-ka iyo midabada', lines: 3),
      SizedBox(height: 50, child: FilledButton(
        onPressed: saving ? null : _submit,
        child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('BALLAN QABSO'))),
    ]),
  );
}

class CakePage extends StatefulWidget {
  const CakePage({super.key, this.providerName, this.whatsappNumber = ''});
  final String? providerName;
  final String whatsappNumber;
  @override
  State<CakePage> createState() => _CakePageState();
}

class _CakePageState extends State<CakePage> {
  final customer = TextEditingController();
  final phone = TextEditingController();
  final decoration = TextEditingController();
  final place = TextEditingController();
  String size = 'Dhexdhexaad', tiers = '1', design = 'Casri';
  DateTime? deliveryDate;
  TimeOfDay? deliveryTime;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    customer.text = prefs.getString('customer_name') ?? '';
    phone.text = prefs.getString('customer_phone') ?? '';
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    customer.dispose();
    phone.dispose();
    decoration.dispose();
    place.dispose();
    super.dispose();
  }

  Future<void> _chooseDeliveryDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: deliveryDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (value != null) setState(() => deliveryDate = value);
  }

  Future<void> _chooseDeliveryTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: deliveryTime ?? TimeOfDay.now(),
    );
    if (value != null) setState(() => deliveryTime = value);
  }

  Widget pick(String label, String value, List<String> choices, ValueChanged<String?> change) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: choices.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: change,
      ),
    );

  Future<void> _submit() async {
    if (customer.text.trim().isEmpty || phone.text.trim().isEmpty ||
        deliveryDate == null || deliveryTime == null || place.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buuxi magaca, telefoonka, taariikhda, waqtiga iyo goobta keenista.')),
      );
      return;
    }
    setState(() => saving = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      await SalonApi.createBooking(
        category: 'CAKES',
        customerName: customer.text.trim(),
        customerPhone: phone.text.trim(),
        customerWhatsApp: prefs.getString('customer_whatsapp') ?? phone.text.trim(),
        details: {'provider': widget.providerName ?? 'Meherad aan wali la dooran', 'size': size,
          'tiers': tiers, 'design': design, 'decorationAndText': decoration.text.trim(),
          'deliveryDate': deliveryDate!.toIso8601String().split('T').first,
          'deliveryTime': deliveryTime!.format(context), 'deliveryLocation': place.text.trim()},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diristu way fashilantay: $e')));
      return;
    }
    final records = prefs.getStringList('cake_booking_requests') ?? <String>[];
    final dateText = deliveryDate!.year.toString() + '-' +
      deliveryDate!.month.toString().padLeft(2, '0') + '-' +
      deliveryDate!.day.toString().padLeft(2, '0');
    final request = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'type': 'CAKE',
      'provider': widget.providerName ?? 'Meherad aan wali la dooran',
      'customerName': customer.text.trim(),
      'customerPhone': phone.text.trim(),
      'size': size,
      'tiers': tiers,
      'design': design,
      'decorationAndText': decoration.text.trim(),
      'deliveryDate': dateText,
      'deliveryTime': deliveryTime!.format(context),
      'deliveryLocation': place.text.trim(),
      'status': 'Sugaya xaqiijinta',
      'createdAt': DateTime.now().toIso8601String(),
    };
    records.add(jsonEncode(request));
    await prefs.setStringList('cake_booking_requests', records);
    if (!mounted) return;
    setState(() => saving = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Codsiga cake-ka waa la kaydiyey'),
        content: const Text('Dalabkaaga waxaa lagu kaydiyey telefoonkan. Hadda dooro WhatsApp ama wicitaan si aad ula xiriirto meheradda.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              showBookingContactOptions(context, widget.whatsappNumber,
                'DALAB CAKE\nMeherad: ' + (widget.providerName ?? '') + '\nMagac: ' + customer.text.trim() + '\nTelefoon: ' + phone.text.trim() + '\nCabir: ' + size + '\nDabaqyo: ' + tiers + '\nNaqshad: ' + design + '\nQurxin/qoraal: ' + decoration.text.trim() + '\nTaariikh: ' + dateText + '\nWaqti: ' + deliveryTime!.format(context) + '\nGoobta: ' + place.text.trim());
            },
            child: const Text('WHATSAPP / CALL NOW'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.providerName == null ? 'BALLAN QABSO — CAKE' : 'CAKE — ' + widget.providerName!),
      backgroundColor: green,
      foregroundColor: Colors.white,
    ),
    body: loading
      ? const Center(child: CircularProgressIndicator(color: green))
      : ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('DALABKA CAKE-KA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green)),
                if (widget.providerName != null) ...[
                  const SizedBox(height: 5),
                  Text('Meheradda: ' + widget.providerName!, style: const TextStyle(color: green)),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            TextField(controller: customer, textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Magacaaga', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phone, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Number telefoonka', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            pick('Cabirka cake-ka', size, ['Yar','Dhexdhexaad','Weyn','Aad u weyn'], (v) => setState(() => size = v!)),
            pick('Tirada dabaqyada', tiers, ['1','2','3','4','5+'], (v) => setState(() => tiers = v!)),
            pick('Naqshadda', design, ['Casri','Classic','Wedding','Birthday','Custom'], (v) => setState(() => design = v!)),
            const SizedBox(height: 4),
            TextField(controller: decoration, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Midabka, qurxinta iyo qoraalka/magaca cake-ka', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _chooseDeliveryDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(deliveryDate == null ? 'Dooro taariikhda keenista' :
                deliveryDate!.day.toString() + '/' + deliveryDate!.month.toString() + '/' + deliveryDate!.year.toString()),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _chooseDeliveryTime,
              icon: const Icon(Icons.access_time),
              label: Text(deliveryTime == null ? 'Dooro waqtiga keenista' : deliveryTime!.format(context)),
            ),
            const SizedBox(height: 12),
            TextField(controller: place, maxLines: 2,
              decoration: const InputDecoration(labelText: 'Goobta la geynayo', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(height: 50, child: FilledButton(
              onPressed: saving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
              child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('BALLAN QABSO'),
            )),
          ],
        ),
  );
}


class SalonBookingPage extends StatefulWidget {
  const SalonBookingPage({super.key, required this.salonName, required this.serviceName, this.whatsappNumber = '', this.staffId, this.staffName, this.merchantId});
  final String salonName;
  final String serviceName;
  final String whatsappNumber;
  final String? merchantId;
  final String? staffId;
  final String? staffName;
  @override
  State<SalonBookingPage> createState() => _SalonBookingPageState();
}

class _SalonBookingPageState extends State<SalonBookingPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final notes = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    name.text = prefs.getString('customer_name') ?? '';
    phone.text = prefs.getString('customer_phone') ?? '';
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (value != null) setState(() => selectedDate = value);
  }

  Future<void> _chooseTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (value != null) setState(() => selectedTime = value);
  }

  Future<void> _submit() async {
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty ||
        selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buuxi magaca, telefoonka, taariikhda iyo waqtiga ballanta.')),
      );
      return;
    }
    setState(() => saving = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      await SalonApi.createBooking(
        category: 'SALON',
        merchantId: widget.merchantId,
        customerName: name.text.trim(),
        customerPhone: phone.text.trim(),
        customerWhatsApp: prefs.getString('customer_whatsapp') ?? phone.text.trim(),
        details: {'salon': widget.salonName, 'service': widget.serviceName,
          if(widget.staffId!=null)'staffId':widget.staffId,
          if(widget.staffName!=null)'staffName':widget.staffName,
          'date': selectedDate!.toIso8601String().split('T').first,
          'time': selectedTime!.format(context), 'notes': notes.text.trim()},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diristu way fashilantay: $e')));
      return;
    }
    final records = prefs.getStringList('salon_booking_requests') ?? <String>[];
    final dateText = selectedDate!.year.toString() + '-' +
      selectedDate!.month.toString().padLeft(2, '0') + '-' +
      selectedDate!.day.toString().padLeft(2, '0');
    final booking = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'salon': widget.salonName,
      'service': widget.serviceName,
      if(widget.staffId!=null)'staffId':widget.staffId,
      if(widget.staffName!=null)'staffName':widget.staffName,
      'customerName': name.text.trim(),
      'customerPhone': phone.text.trim(),
      'date': dateText,
      'time': selectedTime!.format(context),
      'notes': notes.text.trim(),
      'status': 'Sugaya xaqiijinta',
      'createdAt': DateTime.now().toIso8601String(),
    };
    records.add(jsonEncode(booking));
    await prefs.setStringList('salon_booking_requests', records);
    if (!mounted) return;
    setState(() => saving = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Codsiga waa la kaydiyey'),
        content: Text('Ballantaada ' + widget.serviceName + ' ee ' + widget.salonName + (widget.staffName==null?'':' — '+widget.staffName!) + ' waa la diray. Sug xaqiijinta meheradda.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              showBookingContactOptions(context, widget.whatsappNumber,
                'BALLAN SALON\nSalon: ' + widget.salonName + '\nAdeeg: ' + widget.serviceName + (widget.staffName==null?'':'\nShaqaalaha: '+widget.staffName!) + '\nMagac: ' + name.text.trim() + '\nTelefoon: ' + phone.text.trim() + '\nTaariikh: ' + dateText + '\nWaqti: ' + selectedTime!.format(context) + '\nFaahfaahin: ' + notes.text.trim());
            },
            child: const Text('WHATSAPP / CALL NOW'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('BALLAN QABSO'),
      backgroundColor: green,
      foregroundColor: Colors.white,
    ),
    body: loading
      ? const Center(child: CircularProgressIndicator(color: green))
      : ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.salonName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: green)),
                const SizedBox(height: 5),
                Text('Adeegga: ' + widget.serviceName, style: const TextStyle(color: green)),
                if(widget.staffName!=null)Padding(padding:const EdgeInsets.only(top:5),child:Text('Shaqaalaha: '+widget.staffName!,style:const TextStyle(color:green,fontWeight:FontWeight.bold))),
              ]),
            ),
            const SizedBox(height: 18),
            TextField(controller: name, textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Magacaaga', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phone, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Number telefoonka', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _chooseDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(selectedDate == null ? 'Dooro taariikhda ballanta' :
                selectedDate!.day.toString() + '/' + selectedDate!.month.toString() + '/' + selectedDate!.year.toString()),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _chooseTime,
              icon: const Icon(Icons.access_time),
              label: Text(selectedTime == null ? 'Dooro waqtiga ballanta' : selectedTime!.format(context)),
            ),
            const SizedBox(height: 12),
            TextField(controller: notes, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Faahfaahin dheeraad ah (ikhtiyaari)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(height: 50, child: FilledButton(
              onPressed: saving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
              child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('BALLAN QABSO'),
            )),
          ],
        ),
  );
}



class MerchantLoginPage extends StatefulWidget {
  const MerchantLoginPage({super.key});
  @override
  State<MerchantLoginPage> createState()=>_MerchantLoginPageState();
}
class _MerchantLoginPageState extends State<MerchantLoginPage> {
  final username=TextEditingController(),password=TextEditingController();
  bool loading=false;
  @override
  void dispose(){username.dispose();password.dispose();super.dispose();}
  Future<void> login() async {
    if(username.text.trim().isEmpty||password.text.isEmpty)return;
    setState(()=>loading=true);
    try{
      final token=await SalonApi.ownerLogin(username.text.trim(),password.text);
      if(!mounted)return;
      Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>OwnerStaffPage(token:token)));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    if(mounted)setState(()=>loading=false);
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('GELITAANKA MEHERADDA'),backgroundColor:green,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(20),children:[
    const Icon(Icons.storefront,color:green,size:58),const SizedBox(height:18),
    TextField(controller:username,decoration:const InputDecoration(labelText:'Username-ka meheradda',border:OutlineInputBorder())),
    const SizedBox(height:12),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Password',border:OutlineInputBorder())),
    const SizedBox(height:18),FilledButton(onPressed:loading?null:login,style:FilledButton.styleFrom(backgroundColor:green),child:loading?const CircularProgressIndicator(color:Colors.white):const Text('GAL'))
  ]));
}

class OwnerStaffPage extends StatefulWidget {
  const OwnerStaffPage({super.key,required this.token});
  final String token;
  @override
  State<OwnerStaffPage> createState()=>_OwnerStaffPageState();
}
class _OwnerStaffPageState extends State<OwnerStaffPage> {
  Map<String,dynamic> data={};
  bool loading=true;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    setState(()=>loading=true);
    try{final d=await SalonApi.ownerStaff(widget.token);if(mounted)setState(()=>{data=d,error=null,loading=false});}
    catch(e){if(mounted)setState(()=>{error=e.toString(),loading=false});}
  }
  Future<void> editStaff([Map<String,dynamic>? person]) async {
    final name=TextEditingController(text:(person?['name']??'').toString());
    final title=TextEditingController(text:(person?['title']??'').toString());
    List<dynamic> existing=[];try{existing=jsonDecode((person?['services_json']??'[]').toString()) as List;}catch(_){}
    final services=TextEditingController(text:existing.join(', '));
    String? photoData;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:Text(person==null?'Diiwaangeli gabar shaqaale':'Wax ka beddel shaqaalaha'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Magaca gabadha')),
        TextField(controller:title,decoration:const InputDecoration(labelText:'Shaqada / xirfadda')),
        TextField(controller:services,maxLines:2,decoration:const InputDecoration(labelText:'Adeegyada ay qabato (comma ku kala saar)')),
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:()async{try{final p=await pickStaffImage();if(p!=null)refresh(()=>photoData=p);}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},icon:const Icon(Icons.photo_library),label:Text(photoData==null?(person==null?'Dooro sawirka gabadha':'Beddel sawirka'): 'Sawirka waa la doortay')),
        if(photoData!=null)Padding(padding:const EdgeInsets.only(top:8),child:Image.memory(base64Decode(photoData!.split(',').last),height:90,fit:BoxFit.cover)),
        if(person!=null&&photoData==null)Padding(padding:const EdgeInsets.only(top:8),child:Image.network((person['photoUrl']??'').toString(),height:90,errorBuilder:(_,__,___)=>const Icon(Icons.person)))
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydi'))]
    )));
    if(ok!=true||!mounted)return;
    final serviceList=services.text.split(',').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList();
    if(name.text.trim().isEmpty||serviceList.isEmpty||(person==null&&photoData==null)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Magac, adeegyo iyo sawir geli.')));return;}
    final payload=<String,dynamic>{'name':name.text.trim(),'title':title.text.trim(),'services':serviceList,if(photoData!=null)'photoData':photoData};
    try{
      if(person==null)await SalonApi.addOwnerStaff(widget.token,payload);
      else await SalonApi.updateOwnerStaff(widget.token,person['id'].toString(),payload);
      await load();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Xogta shaqaalaha waa la kaydiyey.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> removeStaff(Map<String,dynamic> p) async {
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Ka saar shaqaalaha?'),content:Text('Ma hubtaa inaad ka saarayso '+p['name'].toString()+'?'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Maya')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Haa'))]));
    if(ok!=true)return;
    try{await SalonApi.deleteOwnerStaff(widget.token,p['id'].toString());await load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override
  Widget build(BuildContext context){
    final staff=(data['staff'] as List?)?.cast<Map<String,dynamic>>()??<Map<String,dynamic>>[];
    final limit=int.tryParse((data['staffLimit']??5).toString())??5;
    final activeStaff=staff.where((x)=>x['active']!=0&&x['active']!='0').toList();
    final name=(data['merchantName']??'Meheraddaada').toString();
    return Scaffold(appBar:AppBar(title:Text(name),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerBookingsPage(token:widget.token))),icon:const Icon(Icons.calendar_month),tooltip:'Ballamaha'),IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerPromotionPage(token:widget.token))),icon:const Icon(Icons.campaign),tooltip:'Boosaska xayeysiiska'),
      IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerRentalPage(token:widget.token))),icon:const Icon(Icons.checkroom),tooltip:'Alaabta kirada'),IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
      floatingActionButton:FloatingActionButton.extended(onPressed:activeStaff.length>=limit?null:()=>editStaff(),backgroundColor:green,foregroundColor:Colors.white,icon:const Icon(Icons.person_add),label:const Text('KU DAR GABAR')),
      body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):ListView(padding:const EdgeInsets.all(14),children:[
        Text('SHAQAALAHA: '+activeStaff.length.toString()+' / '+limit.toString(),style:const TextStyle(color:green,fontWeight:FontWeight.bold,fontSize:17)),
        const SizedBox(height:8),
        if(activeStaff.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('Weli gabdho shaqaale ah lama diiwaangelin.')),
        ...activeStaff.map((p)=>Card(child:ListTile(
          leading:ClipRRect(borderRadius:BorderRadius.circular(8),child:salonImage((p['photoUrl']??'').toString(),fit:BoxFit.cover,fallback:const Icon(Icons.person,color:green))),
          title:Text((p['name']??'').toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
          subtitle:Text((p['title']??'').toString()+'\n'+((jsonDecode((p['services_json']??'[]').toString()) as List).join(', '))),
          isThreeLine:true,trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')editStaff(p);if(v=='delete')removeStaff(p);},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Wax ka beddel')),PopupMenuItem(value:'delete',child:Text('Ka saar'))])
        )))
      ]));
  }
}



class OwnerPromotionPage extends StatefulWidget {
  const OwnerPromotionPage({super.key,required this.token});
  final String token;
  @override
  State<OwnerPromotionPage> createState()=>_OwnerPromotionPageState();
}
class _OwnerPromotionPageState extends State<OwnerPromotionPage>{
  Map<String,dynamic> data={};
  bool loading=true,sending=false;
  int slot=1,days=7;
  String provider='Telesom';
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    setState(()=>loading=true);
    try{final d=await SalonApi.ownerPromotionInfo(widget.token);if(mounted)setState(()=>{data=d,loading=false});}
    catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  }
  int get amount=>days==7?10000:days==10?15000:50000;
  String fmt(dynamic value){if(value==null)return '—';try{return DateTime.parse(value.toString()).toLocal().toString().substring(0,16);}catch(_){return value.toString();}}
  Future<void> sendNow() async {
    final payment=(data['payment'] as Map?)?.cast<String,dynamic>()??{};
    final number=(provider=='Telesom'?payment['telesomNumber']:payment['somtelNumber'])?.toString()??'';
    final ussd=provider=='Telesom'?'*220*$number*$amount#':'*770*$number*$amount#';
    try{await launchUrl(Uri(scheme:'tel',path:ussd),mode:LaunchMode.externalApplication);}catch(_){}
    final sender=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('LAMBARKA AAD LACAGTA KA DIRAY'),
      content:TextField(controller:sender,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Geli lambarka Telesom / Somtel ee aad ka dirtay')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('DIR CODSIGA'))]));
    if(ok!=true||!mounted)return;
    if(sender.text.trim().replaceAll(RegExp(r'[^0-9]'),'').length<7){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Geli lambarka lacagta aad ka dirtay.')));return;}
    setState(()=>sending=true);
    try{await SalonApi.createOwnerPromotion(widget.token,slot,days,provider,sender.text.trim());await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Codsiga waa la diray. Sug inta Admin-ku xaqiijinayo lacagta.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    if(mounted)setState(()=>sending=false);
  }
  @override
  Widget build(BuildContext context){
    final slots=(data['slots'] as List?)?.cast<Map<String,dynamic>>()??<Map<String,dynamic>>[];
    final requests=(data['requests'] as List?)?.cast<Map<String,dynamic>>()??<Map<String,dynamic>>[];
    return Scaffold(appBar:AppBar(title:const Text('BOOSASKA XAYEYSIISKA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
      body:loading?const Center(child:CircularProgressIndicator(color:green)):ListView(padding:const EdgeInsets.all(14),children:[
        const Text('DOORO MID KA MID AH 4-TA BOOS',style:TextStyle(fontWeight:FontWeight.bold,color:green,fontSize:17)),
        const SizedBox(height:6),
        const Text('Boosaska la kiraystay waxay muujinayaan muddada ay ku egyihiin. Waxaad codsan kartaa booska marka uu xoroobo; bilowga muddadaada wuxuu noqonayaa marka Admin-ku xaqiijiyo lacagta.'),
        const SizedBox(height:10),
        ...slots.map((x){final n=Number.tryParse((x['slot']??0).toString())?.toInt()??1;final busy=x['occupied']==true;return Card(child:RadioListTile<int>(value:n,groupValue:slot,onChanged:(v)=>setState(()=>slot=v??1),title:Text('BOOSKA $n',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(busy?'Hadda waa la kiraystay • Muddada: ${x['planDays']??'—'} maalmood • Wuxuu dhacayaa: ${fmt(x['expiresAt'])}\nWaxaad qabsan kartaa laga bilaabo: ${fmt(x['nextAvailableAt'])}':'Waa bannaan yahay • Hadda ayaad codsan kartaa'),isThreeLine:busy));}),
        const Divider(height:28),
        const Text('MUDDADA XAYEYSIISKA',style:TextStyle(fontWeight:FontWeight.bold,color:green)),
        RadioListTile<int>(value:7,groupValue:days,onChanged:(v)=>setState(()=>days=v??7),title:const Text('7 maalmood — 10,000 SLSH')),
        RadioListTile<int>(value:10,groupValue:days,onChanged:(v)=>setState(()=>days=v??10),title:const Text('10 maalmood — 15,000 SLSH')),
        RadioListTile<int>(value:30,groupValue:days,onChanged:(v)=>setState(()=>days=v??30),title:const Text('30 maalmood — 50,000 SLSH')),
        const Divider(height:24),
        DropdownButtonFormField<String>(value:provider,decoration:const InputDecoration(labelText:'Habka lacag-bixinta'),items:const ['Telesom','Somtel'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>provider=v??'Telesom')),
        const SizedBox(height:10),
        Text('WADARTA: $amount SLSH',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:green)),
        const SizedBox(height:10),
        FilledButton.icon(onPressed:sending?null:sendNow,style:FilledButton.styleFrom(backgroundColor:green),icon:const Icon(Icons.send),label:sending?const Text('WAA LA DIRAY'):const Text('SEND NOW')),
        const Divider(height:28),
        const Text('CODSIYADAYDA',style:TextStyle(fontWeight:FontWeight.bold,color:green,fontSize:17)),
        if(requests.isEmpty)const Text('Weli codsi xayeysiis ma aadan dirin.'),
        ...requests.map((r)=>Card(child:ListTile(title:Text('Booska ${r['slot_number']} • ${r['plan_days']} maalmood'),subtitle:Text('${r['amount_slsh']} SLSH • ${r['provider']} • ${r['sender_phone']}\nXaaladda: ${r['status']}'+(r['starts_at']==null?'':'\nBilow: ${fmt(r['starts_at'])} • Dhacaya: ${fmt(r['expires_at'])}'))))),
      ]));
  }
}

class AdminPromotionPage extends StatefulWidget {
  const AdminPromotionPage({super.key,required this.token});
  final String token;
  @override
  State<AdminPromotionPage> createState()=>_AdminPromotionPageState();
}
class _AdminPromotionPageState extends State<AdminPromotionPage>{
  List<Map<String,dynamic>> rows=[];
  bool loading=true;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {setState(()=>loading=true);try{final x=await SalonApi.adminPromotionRequests(widget.token);if(mounted)setState(()=>{rows=x,loading=false});}catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}}
  Future<void> review(Map<String,dynamic> row,String status) async {try{await SalonApi.reviewPromotion(widget.token,row['id'].toString(),status);await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('XAQIIJINTA XAYEYSIISKA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):rows.isEmpty?const Center(child:Text('Weli codsi lacag-bixin xayeysiis ah ma jiro.')):ListView(padding:const EdgeInsets.all(14),children:[
      ...rows.map((r)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text((r['merchant_name']??'Meherad').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
        Text('Qaybta: ${r['category']} • Booska: ${r['slot_number']}'),
        Text('Muddada: ${r['plan_days']} maalmood • Lacagta: ${r['amount_slsh']} SLSH'),
        Text('Habka: ${r['provider']} • Lambarka laga diray: ${r['sender_phone']}'),
        Text('Codsiga: ${r['created_at']} • Xaalad: PENDING'),
        Wrap(spacing:8,children:[
          FilledButton(onPressed:()=>review(r,'APPROVED'),style:FilledButton.styleFrom(backgroundColor:green),child:const Text('Xaqiiji lacagta')),
          OutlinedButton(onPressed:()=>review(r,'REJECTED'),child:const Text('Diid codsiga')),
        ])
      ])))),
    ]));
}

class OwnerRentalPage extends StatefulWidget {
  const OwnerRentalPage({super.key,required this.token});
  final String token;
  @override
  State<OwnerRentalPage> createState()=>_OwnerRentalPageState();
}
class _OwnerRentalPageState extends State<OwnerRentalPage> {
  List<Map<String,dynamic>> items=[];
  bool loading=true;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    setState(()=>loading=true);
    try{final rows=await SalonApi.ownerRentals(widget.token);if(mounted)setState(()=>{items=rows.where((x)=>x['active']!=0&&x['active']!='0').toList(),loading=false});}
    catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  }
  Future<void> edit([Map<String,dynamic>? p]) async {
    final name=TextEditingController(text:(p?['name']??'').toString());
    final desc=TextEditingController(text:(p?['description']??'').toString());
    String category=(p?['category']??'SAD RENTAL').toString();
    String? photo;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:Text(p==null?'Ku dar alaab kiraysi':'Wax ka beddel alaabta'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Qaybta'),items:['SAD RENTAL','TAASH','TOOBKA MEHERKA','SUBEECIYAD'].map((v)=>DropdownMenuItem(value:v,child:Text(v=='SAD RENTAL'?'SAD KIRAYSO':v))).toList(),onChanged:(v)=>refresh(()=>category=v??category)),
        TextField(controller:name,decoration:const InputDecoration(labelText:'Magaca alaabta')),
        TextField(controller:desc,maxLines:3,decoration:const InputDecoration(labelText:'Faahfaahin (ikhtiyaari)')),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:()async{try{final v=await pickSalonImage();if(v!=null)refresh(()=>photo=v);}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},icon:const Icon(Icons.photo_library),label:Text(photo==null?'Dooro sawirka alaabta':'Sawirka waa la doortay')),
        if(photo!=null)Image.memory(base64Decode(photo!.split(',').last),height:120,fit:BoxFit.cover)
        else if(p!=null)Image.network((p['photoUrl']??'').toString(),height:120,errorBuilder:(_,__,___)=>const Icon(Icons.image_not_supported)),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydi'))]
    )));
    if(ok!=true||!mounted)return;
    if(name.text.trim().isEmpty||(p==null&&photo==null)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Magaca iyo sawirka alaabta geli.')));return;}
    try{
      await SalonApi.saveOwnerRental(widget.token,{'category':category,'name':name.text.trim(),'description':desc.text.trim(),if(photo!=null)'photoData':photo},id:p?['id']?.toString());
      await load();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> remove(Map<String,dynamic> p) async {
    try{await SalonApi.deleteOwnerRental(widget.token,p['id'].toString());await load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('ALAABTA KIRADA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(),backgroundColor:green,foregroundColor:Colors.white,icon:const Icon(Icons.add),label:const Text('KU DAR ALAAB')),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):items.isEmpty?const Center(child:Text('Weli alaab kiraysi lama gelin.')):ListView(padding:const EdgeInsets.all(14),children:items.map((p)=>Card(child:ListTile(
      leading:ClipRRect(borderRadius:BorderRadius.circular(8),child:salonImage((p['photoUrl']??'').toString(),fit:BoxFit.cover,fallback:const Icon(Icons.image,color:green))),
      title:Text((p['name']??'').toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
      subtitle:Text((p['category']??'').toString()),
      trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')edit(p);if(v=='delete')remove(p);},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Wax ka beddel')),PopupMenuItem(value:'delete',child:Text('Ka saar'))])
    ))).toList())
  );
}


class OwnerBookingsPage extends StatefulWidget {
  const OwnerBookingsPage({super.key,required this.token});
  final String token;
  @override
  State<OwnerBookingsPage> createState()=>_OwnerBookingsPageState();
}
class _OwnerBookingsPageState extends State<OwnerBookingsPage> {
  List<Map<String,dynamic>> bookings=[];
  bool loading=true;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    setState(()=>loading=true);
    try{final rows=await SalonApi.ownerBookings(widget.token);if(mounted)setState(()=>{bookings=rows,error=null,loading=false});}
    catch(e){if(mounted)setState(()=>{error=e.toString(),loading=false});}
  }
  Future<void> review(Map<String,dynamic> booking,String status) async {
    try{await SalonApi.updateBookingStatus(widget.token,booking['id'].toString(),status);await load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('BALLAMAHA SALON-KA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):bookings.isEmpty?const Center(child:Text('Weli ballamo ma jiraan.')):ListView(padding:const EdgeInsets.all(14),children:bookings.map((b){
      Map<String,dynamic> d={};try{d=jsonDecode((b['details_json']??'{}').toString()) as Map<String,dynamic>;}catch(_){}
      final status=(b['status']??'Sugaya jawaab').toString();
      return Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text((b['customer_name']??'Macmiil').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
        Text('Adeeg: '+(d['service']??'').toString()),
        if((d['staffName']??'').toString().isNotEmpty)Text('Gabadha: '+d['staffName'].toString(),style:const TextStyle(color:green,fontWeight:FontWeight.bold)),
        Text('Taariikh: '+(d['date']??'').toString()+' • Waqti: '+(d['time']??'').toString()),
        Text('Telefoon: '+(b['customer_phone']??'').toString()),
        Text('Xaalad: '+status,style:const TextStyle(fontWeight:FontWeight.w600,color:green)),
        if(status=='Sugaya jawaab')Row(children:[
          Expanded(child:OutlinedButton(onPressed:()=>review(b,'Lama heli karo'),child:const Text('DIID'))),
          const SizedBox(width:8),
          Expanded(child:FilledButton(onPressed:()=>review(b,'La aqbalay'),style:FilledButton.styleFrom(backgroundColor:green),child:const Text('AQBAL')))
        ])
      ])));
    }).toList())
  );
}

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});
  @override
  State<CustomerOrdersPage> createState()=>_CustomerOrdersPageState();
}
class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  List<Map<String,dynamic>> orders=[];
  bool loading=true;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    final p=await SharedPreferences.getInstance(),phone=p.getString('customer_phone')??'';
    try{final x=await SalonApi.customerOrders(phone);if(mounted)setState(()=>{orders=x,loading=false,error=null});}
    catch(e){if(mounted)setState(()=>{loading=false,error=e.toString()});}
  }
  Future<void> pay(Map<String,dynamic> order) async {
    final sender=TextEditingController(text:(order['customer_phone']??'').toString());
    final amount=TextEditingController();
    String provider='Telesom',currency='USD';
    final id=(order['id']??'').toString();
    final p=await SharedPreferences.getInstance();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('Xaqiiji inaad iibsatay'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('Marka hore lacagta u dir meheradda. Kadib geli lambarka aad lacagta ka dirtay iyo qadarka aad dirtay.'),
        DropdownButtonFormField<String>(value:provider,decoration:const InputDecoration(labelText:'Habka lacagta'),items:['Somtel','Telesom','Soltelco'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>provider=v??provider)),
        TextField(controller:sender,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Number-ka aad lacagta ka dirtay')),
        TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Lacagta aad dirtay')),
        DropdownButtonFormField<String>(value:currency,decoration:const InputDecoration(labelText:'Lacagta lagu diray'),items:['USD','SLSH'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>currency=v??currency)),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Gudbi xaqiijin'))]
    )));
    if(ok!=true||!mounted)return;
    final v=double.tryParse(amount.text.trim());
    if(sender.text.trim().length<7||v==null||v<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Hubi lambarka iyo qadarka lacagta.')));return;}
    try{await SalonApi.submitPayment(id,p.getString('customer_phone')??'',provider,sender.text.trim(),v,currency);await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Xogta lacagta waa la diray. Admin-ka ayaa hubinaya.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  String status(Map<String,dynamic> o)=>(o['status']??'Sugaya jawaab').toString();
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('DALABYADAYDA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):orders.isEmpty?const Center(child:Text('Weli dalab ma lihid.')):ListView(padding:const EdgeInsets.all(14),children:[
      ...orders.map((o){
        Map<String,dynamic> details={};try{details=jsonDecode((o['details_json']??'{}').toString()) as Map<String,dynamic>;}catch(_){}
        final st=status(o),payment=(o['payment_status']??'').toString();
        return Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text((o['category']??'DALAB').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17,color:green)),
          if((o['merchant_name']??'').toString().isNotEmpty)Text('Meherad: ${o['merchant_name']}'),
          if(details.isNotEmpty)Text(details.entries.map((e)=>'${e.key}: ${e.value}').join(' • ')),
          const SizedBox(height:5),Text('Xaaladda dalabka: $st',style:const TextStyle(fontWeight:FontWeight.w600)),
          if(payment.isNotEmpty)Text('Xaaladda lacagta: $payment'),
          if(st=='La aqbalay'&&payment.isEmpty)Padding(padding:const EdgeInsets.only(top:8),child:SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>pay(o),style:FilledButton.styleFrom(backgroundColor:green),child:const Text('WAAN IIBSADAY')))),
          if(payment=='Sugaya xaqiijin')const Text('Lacagtaada admin-ka ayaa hubinaya.',style:TextStyle(color:Colors.orange)),
          if(st=='PURCHASED')const Text('Dalabka waa la iibsaday, lacagtiisana waa la xaqiijiyey.',style:TextStyle(color:green,fontWeight:FontWeight.bold)),
        ])));
      })
    ])
  );
}

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key,required this.token});
  final String token;
  @override
  State<AdminPaymentsPage> createState()=>_AdminPaymentsPageState();
}
class _AdminPaymentsPageState extends State<AdminPaymentsPage>{
  List<Map<String,dynamic>> payments=[];
  bool loading=true;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    try{final x=await SalonApi.adminPayments(widget.token);if(mounted)setState(()=>{payments=x,loading=false,error=null});}
    catch(e){if(mounted)setState(()=>{loading=false,error=e.toString()});}
  }
  Future<void> review(Map<String,dynamic> p,String status) async {
    try{await SalonApi.reviewPayment(widget.token,p['id'].toString(),status);await load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('XAQIIJINTA LACAGAHA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):payments.isEmpty?const Center(child:Text('Weli lacag la xaqiijinayo ma jirto.')):ListView(padding:const EdgeInsets.all(14),children:[
      ...payments.map((p)=>Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text((p['customer_name']??'Macmiil').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
        Text('Dalab: ${p['category']??''} • Meherad: ${p['merchant_name']??'—'}'),
        Text('Habka: ${p['provider']} • Lacag: ${p['amount']} ${p['currency']}'),
        Text('Lambarka lacagta laga diray: ${p['sender_phone']}'),
        Text('Lambarka macmiilka: ${p['customer_phone']}'),
        Text('Xaaladda: ${p['status']}'),
        if(p['status']=='Sugaya xaqiijin')Wrap(spacing:8,children:[
          FilledButton(onPressed:()=>review(p,'La xaqiijiyey'),style:FilledButton.styleFrom(backgroundColor:green),child:const Text('Xaqiiji lacagta')),
          OutlinedButton(onPressed:()=>review(p,'Lama xaqiijin'),child:const Text('Diid')),
        ]),
      ])))),
    ])
  );
}

class AdminPaymentSettingsPage extends StatefulWidget {
  const AdminPaymentSettingsPage({super.key,required this.token});
  final String token;
  @override
  State<AdminPaymentSettingsPage> createState()=>_AdminPaymentSettingsPageState();
}
class _AdminPaymentSettingsPageState extends State<AdminPaymentSettingsPage>{
  final promoTelesom=TextEditingController(text:'63123456');
  final promoSomtel=TextEditingController(text:'651233567');

  List<Map<String,dynamic>> merchants=[];
  bool loading=true;
  String? error;
  final fx=TextEditingController();
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    try{
      final p=await SalonApi.adminMerchants(widget.token);
      final rate=await SalonApi.exchangeRate();
      final promo=await SalonApi.promotionConfig();
      promoTelesom.text=(promo['telesomNumber']??'63123456').toString();
      promoSomtel.text=(promo['somtelNumber']??'651233567').toString();
      if(mounted)setState(()=>{merchants=p,fx.text=rate?.toString()??'',loading=false,error=null});
    }catch(e){if(mounted)setState(()=>{loading=false,error=e.toString()});}
  }
  Future<void> editMerchant(Map<String,dynamic> merchant) async {
    final number=TextEditingController();
    String provider='Telesom',currency='USD';
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:Text('Lambarka lacagta — ${merchant['name']}'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:provider,decoration:const InputDecoration(labelText:'Shirkadda lacagta'),items:['Somtel','Telesom','Soltelco'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>provider=v??provider)),
        DropdownButtonFormField<String>(value:currency,decoration:const InputDecoration(labelText:'Lacagta'),items:['USD','SLSH'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>currency=v??currency)),
        TextField(controller:number,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Number-ka meheraddu lacagta ku hesho')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydi'))]
    )));
    if(ok!=true||number.text.trim().isEmpty||!mounted)return;
    try{
      await SalonApi.savePaymentConfig(widget.token,merchant['id'].toString(),provider,currency,number.text.trim());
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Lambarka lacagta waa la kaydiyey.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> saveFx() async {
    final v=double.tryParse(fx.text.trim());
    if(v==null||v<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Geli sarif sax ah.')));return;}
    try{await SalonApi.saveExchangeRate(widget.token,v);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Sarifka maanta waa la kaydiyey.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override
  void dispose(){fx.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('HABABKA LACAGTA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):ListView(padding:const EdgeInsets.all(14),children:[
      const Text('SARIFKA MAANTA',style:TextStyle(fontWeight:FontWeight.bold,color:green,fontSize:17)),
      const SizedBox(height:8),
      TextField(controller:fx,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'1 USD = imisa SLSH?',border:OutlineInputBorder())),
      const SizedBox(height:8),
      FilledButton(onPressed:saveFx,style:FilledButton.styleFrom(backgroundColor:green),child:const Text('KAYDI SARIFKA')),
      const Divider(height:28),
      const Text('LAMBARRADA MEHERADAHA',style:TextStyle(fontWeight:FontWeight.bold,color:green,fontSize:17)),
      const SizedBox(height:6),
      const Text('Meherad kasta u deji lambarkeeda Somtel, Telesom ama Soltelco; USD iyo SLSH si kala gaar ah.'),
      ...merchants.map((m)=>Card(child:ListTile(title:Text((m['name']??'Meherad').toString()),subtitle:Text((m['category']??'').toString()),trailing:const Icon(Icons.edit,color:green),onTap:()=>editMerchant(m)))),
    ])
  );
}

class FullPackagesPage extends StatefulWidget {
  const FullPackagesPage({super.key,this.category,this.adminToken});
  final String? category;
  final String? adminToken;
  @override
  State<FullPackagesPage> createState()=>_FullPackagesPageState();
}
class _FullPackagesPageState extends State<FullPackagesPage> {
  List<Map<String,dynamic>> rows=[];
  List<Map<String,dynamic>> merchants=[];
  bool loading=true,saving=false;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    setState(()=>loading=true);
    try{
      final result=await SalonApi.packages(category:widget.category);
      final ms=widget.adminToken==null? <Map<String,dynamic>>[]:await SalonApi.adminMerchants(widget.adminToken!);
      if(mounted)setState(()=>{rows=result,merchants=ms,error=null,loading=false});
    }catch(e){if(mounted)setState(()=>{error=e.toString(),loading=false});}
  }
  String money(dynamic v,String currency)=>'${v??0} $currency';
  Future<void> editPackage([Map<String,dynamic>? p]) async {
    if(widget.adminToken==null)return;
    if(merchants.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Marka hore Admin-ku ha diiwaangeliyo meheradaha.')));return;}
    final name=TextEditingController(text:(p?['name']??'').toString());
    final desc=TextEditingController(text:(p?['description']??'').toString());
    final items=TextEditingController(text:p==null?'':((jsonDecode((p['items_json']??'[]').toString()) as List).join(', ')));
    final retail=TextEditingController(text:(p?['retail_total']??'').toString());
    final price=TextEditingController(text:(p?['package_price']??'').toString());
    String category=(p?['category']??widget.category??'SALON').toString();
    String currency=(p?['currency']??'USD').toString();
    String merchantId=(p?['merchant_id']??merchants.first['id']).toString();
    bool active=p==null?true:(p['active']!=0&&p['active']!='0'&&p['active']!=false);
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:Text(p==null?'Ku dar Full Package':'Wax ka beddel Full Package'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:merchantId,decoration:const InputDecoration(labelText:'Meheradda'),items:merchants.map((m)=>DropdownMenuItem(value:m['id'].toString(),child:Text(m['name'].toString(),overflow:TextOverflow.ellipsis))).toList(),onChanged:(v)=>refresh(()=>merchantId=v??merchantId)),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Qaybta'),items:['SALON','CAKES','DECORATION','KIRAYSO'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>category=v??'SALON')),
        TextField(controller:name,decoration:const InputDecoration(labelText:'Magaca package-ka')),
        TextField(controller:desc,maxLines:2,decoration:const InputDecoration(labelText:'Faahfaahin')),
        TextField(controller:items,maxLines:3,decoration:const InputDecoration(labelText:'Waxyaabaha ku jira (comma ku kala saar)')),
        TextField(controller:retail,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Wadarta qiimaha tafaariiqda')),
        TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Qiimaha Full Package')),
        DropdownButtonFormField<String>(value:currency,decoration:const InputDecoration(labelText:'Lacagta'),items:['USD','SLSH'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>currency=v??'USD')),
        if(p!=null)SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Package muuqda'),value:active,onChanged:(v)=>refresh(()=>active=v)),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydi'))]
    )));
    if(ok!=true||!mounted)return;
    final itemList=items.text.split(',').map((v)=>v.trim()).where((v)=>v.isNotEmpty).toList();
    final rt=double.tryParse(retail.text.trim()),pr=double.tryParse(price.text.trim());
    if(name.text.trim().isEmpty||itemList.isEmpty||rt==null||pr==null||pr<=0||pr>=rt){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Hubi magaca, waxyaabaha, qiimaha tafaariiqda iyo in package-ku ka jaban yahay.')));return;
    }
    setState(()=>saving=true);
    try{
      final payload=<String,dynamic>{'merchantId':merchantId,'category':category,'name':name.text.trim(),'description':desc.text.trim(),'items':itemList,'retailTotal':rt,'packagePrice':pr,'currency':currency,'active':active};
      if(p!=null)payload['id']=p['id'];
      await SalonApi.savePackage(widget.adminToken!,payload,update:p!=null);
      await load();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Full Package waa la kaydiyey.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    if(mounted)setState(()=>saving=false);
  }
  Future<void> orderPackage(Map<String,dynamic> p) async {
    final prefs=await SharedPreferences.getInstance();
    final name=prefs.getString('customer_name')??'',phone=prefs.getString('customer_phone')??'';
    if(name.isEmpty||phone.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Marka hore isdiiwaangeli.')));return;}
    try{
      await SalonApi.createBooking(category:(p['category']??'SALON').toString(),customerName:name,customerPhone:phone,customerWhatsApp:prefs.getString('customer_whatsapp')??phone,merchantId:p['merchant_id']?.toString(),packageId:p['id']?.toString(),details:{'type':'FULL_PACKAGE','packageName':p['name'],'packagePrice':p['package_price'],'currency':p['currency']});
      if(mounted)showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Codsiga waa la diray'),content:const Text('Codsiga Full Package waxaa loo diray meheradda. Sug jawaabta meheradda.'),actions:[FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Hagaag'))]));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Diristu way fashilantay: $e')));}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.category==null?'FULL PACKAGE':'FULL PACKAGE — ${widget.category}'),backgroundColor:green,foregroundColor:Colors.white,actions:[if(widget.adminToken!=null)IconButton(onPressed:()=>editPackage(),icon:const Icon(Icons.add),tooltip:'Ku dar package')]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):rows.isEmpty?const Center(child:Text('Weli Full Package lama soo gelin.')):ListView(padding:const EdgeInsets.all(14),children:[
      if(widget.adminToken!=null)Padding(padding:const EdgeInsets.only(bottom:10),child:Text('Admin: waxaad package u samayn kartaa meherad kasta oo ku jirta liiska.',style:TextStyle(color:green))),
      ...rows.map((p){
        final currency=(p['currency']??'USD').toString();
        final rt=double.tryParse((p['retail_total']??0).toString())??0;
        final price=double.tryParse((p['package_price']??0).toString())??0;
        List<dynamic> itemList=[];try{itemList=jsonDecode((p['items_json']??'[]').toString()) as List;}catch(_){}
        return Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Expanded(child:Text((p['name']??'Full Package').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18))),if(widget.adminToken!=null)IconButton(onPressed:()=>editPackage(p),icon:const Icon(Icons.edit,color:green))]),
          Text((p['merchant_name']??'Meherad').toString(),style:const TextStyle(color:green,fontWeight:FontWeight.w600)),
          if((p['description']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:5),child:Text(p['description'].toString())),
          if(itemList.isNotEmpty)Padding(padding:const EdgeInsets.only(top:7),child:Text('Waxyaabaha ku jira: ${itemList.join(' • ')}')),
          const SizedBox(height:8),
          Row(children:[Expanded(child:Text('Tafaariiq: ${money(rt,currency)}',style:const TextStyle(decoration:TextDecoration.lineThrough,color:Colors.black54))),Expanded(child:Text('Package: ${money(price,currency)}',style:const TextStyle(color:green,fontWeight:FontWeight.bold)))]),
          Text('Waxaad kaydsanaysaa: ${money(rt-price,currency)}',style:const TextStyle(color:green,fontWeight:FontWeight.bold)),
          if(widget.adminToken==null)Padding(padding:const EdgeInsets.only(top:10),child:SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>orderPackage(p),style:FilledButton.styleFrom(backgroundColor:green),child:Text(p['category']=='KIRAYSO'?'KIRAYSO':'BALLAN QABSO')))),
        ])));
      })
    ])
  );
}



class RentalPage extends StatelessWidget {
  const RentalPage({super.key, required this.city});
  final String city;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:const Text('KIRAYSO'),backgroundColor:green,foregroundColor:Colors.white),
    body:ListView(padding:const EdgeInsets.all(18),children:[
      Text('Magaalada: $city',style:const TextStyle(color:green,fontWeight:FontWeight.bold)),
      const Text('Qaybta kiraynta',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold,color:green)),
      const SizedBox(height:6),
      const Text('Dooro qaybta aad rabto, kadib halkan ka eeg sawirada alaabta.'),
      const SizedBox(height:12),
      ...['SAD RENTAL','TAASH','TOOBKA MEHERKA','SUBEECIYAD'].map((v)=>Card(
        margin:const EdgeInsets.only(bottom:10),
        child:ListTile(contentPadding:const EdgeInsets.all(14),
          leading:const CircleAvatar(backgroundColor:cream,child:Icon(Icons.checkroom,color:green)),
          title:Text(v=='SAD RENTAL'?'SAD KIRAYSO':v,style:const TextStyle(fontWeight:FontWeight.bold)),
          subtitle:const Text('Halkan ka eeg sawirada alaabta'),
          trailing:const Icon(Icons.arrow_forward_ios,size:16),
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RentalGalleryPage(category:v,city:city))),
        )))
    ])
  );
}

class RentalGalleryPage extends StatefulWidget {
  const RentalGalleryPage({super.key,required this.category,required this.city});
  final String category,city;
  @override
  State<RentalGalleryPage> createState()=>_RentalGalleryPageState();
}
class _RentalGalleryPageState extends State<RentalGalleryPage> {
  List<Map<String,dynamic>> items=[];
  bool loading=true;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    try{final rows=await SalonApi.rentalItems(widget.category,widget.city);if(mounted)setState(()=>{items=rows,loading=false,error=null});}
    catch(e){if(mounted)setState(()=>{loading=false,error=e.toString()});}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.category=='SAD RENTAL'?'SAD KIRAYSO':widget.category),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):items.isEmpty?const Center(child:Text('Weli sawirro alaab ah laguma darin qaybtan magaalada.')):GridView.builder(
      padding:const EdgeInsets.all(12),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.68,crossAxisSpacing:10,mainAxisSpacing:10),itemCount:items.length,
      itemBuilder:(ctx,i){final p=items[i];return Card(clipBehavior:Clip.antiAlias,child:InkWell(
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RentalRequestPage(category:widget.category,selectedItem:(p['name']??'').toString(),merchantId:(p['merchant_id']??'').toString(),merchantName:(p['merchant_name']??'').toString(),merchantLocation:(p['location']??'').toString()))),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:salonImage((p['photoUrl']??'').toString(),fit:BoxFit.cover,fallback:Container(color:cream,child:const Icon(Icons.checkroom,color:green,size:42)))),
          Padding(padding:const EdgeInsets.all(9),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text((p['name']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold)),
            Text((p['merchant_name']??'Meherad').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:green,fontSize:12)),
            Row(children:[const Icon(Icons.location_on,size:13,color:green),Expanded(child:Text((p['location']??widget.city).toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11)))]),
            const SizedBox(height:4),const Text('Taabo sawirka si aad u codsato',style:TextStyle(color:green,fontSize:10,fontWeight:FontWeight.w600))
          ]))
        ])
      ));}
    )
  );
}

class RentalRequestPage extends StatefulWidget {
  const RentalRequestPage({super.key, required this.category, required this.selectedItem, required this.merchantId, required this.merchantName, required this.merchantLocation});
  final String category, selectedItem, merchantId, merchantName, merchantLocation;
  @override
  State<RentalRequestPage> createState() => _RentalRequestPageState();
}

class _RentalRequestPageState extends State<RentalRequestPage> {
  final customer = TextEditingController();
  final phone = TextEditingController();
  final item = TextEditingController();
  final size = TextEditingController();
  final location = TextEditingController();
  final notes = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final p = await SharedPreferences.getInstance();
    customer.text = p.getString('customer_name') ?? '';
    phone.text = p.getString('customer_phone') ?? '';
    item.text = widget.selectedItem;
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    customer.dispose(); phone.dispose(); item.dispose(); size.dispose();
    location.dispose(); notes.dispose(); super.dispose();
  }

  String dateLabel(DateTime? d) => d == null ? 'Dooro taariikhda' :
    d.day.toString().padLeft(2, '0') + '/' + d.month.toString().padLeft(2, '0') + '/' + d.year.toString();

  Future<DateTime?> chooseDate(DateTime? current, {DateTime? minimum}) async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? minimum ?? now,
      firstDate: minimum ?? DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
  }

  Widget field(TextEditingController c, String label, {int lines = 1, TextInputType? type}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
      controller: c, maxLines: lines, keyboardType: type,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));

  Future<void> submit() async {
    if ([customer.text, phone.text, item.text, location.text].any((v) => v.trim().isEmpty) ||
        startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Buuxi magaca, telefoonka, agabka, goobta iyo muddada kirada.')));
      return;
    }
    if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Taariikhda dhammaadka kiradu kama horrayn karto bilowga.')));
      return;
    }
    setState(() => saving = true);
    final p = await SharedPreferences.getInstance();
    late final Map<String,dynamic> bookingResult;
    try {
      bookingResult = await SalonApi.createBooking(
        category: 'KIRAYSO',
        merchantId: widget.merchantId,
        customerName: customer.text.trim(),
        customerPhone: phone.text.trim(),
        customerWhatsApp: p.getString('customer_whatsapp') ?? phone.text.trim(),
        details: {'rentalCategory': widget.category, 'item': item.text.trim(), 'merchantName':widget.merchantName, 'merchantLocation':widget.merchantLocation, 'size': size.text.trim(),
          'startDate': startDate!.toIso8601String().split('T').first,
          'endDate': endDate!.toIso8601String().split('T').first,
          'location': location.text.trim(), 'notes': notes.text.trim()},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diristu way fashilantay: $e')));
      return;
    }
    final records = p.getStringList('rental_booking_requests') ?? <String>[];
    final request = <String, dynamic>{
      'id': (bookingResult['id'] ?? DateTime.now().microsecondsSinceEpoch).toString(),
      'type': 'RENTAL', 'category': widget.category,
      'item': item.text.trim(), 'size': size.text.trim(),
      'customerName': customer.text.trim(), 'customerPhone': phone.text.trim(),
      'startDate': startDate!.toIso8601String().split('T').first,
      'endDate': endDate!.toIso8601String().split('T').first,
      'location': location.text.trim(), 'notes': notes.text.trim(),
      'status': (bookingResult['status'] ?? 'Sugaya jawaab').toString(), 'createdAt': DateTime.now().toIso8601String(),
    };
    records.add(jsonEncode(request));
    await p.setStringList('rental_booking_requests', records);
    if (!mounted) return;
    setState(() => saving = false);
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: const Text('Codsiga kiraysiga waa la diray'),
      content: const Text('Codsigaaga si guul leh ayaa loogu diray nidaamka SALON BOOKING. Meheraddu waxay ka jawaabi doontaa marka ay hubiso helitaanka agabka.'),
      actions: [FilledButton(onPressed: () {
        Navigator.pop(ctx);
        Navigator.pop(context);
      }, child: const Text('Hagaag'))],
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Gudbi codsiga'), backgroundColor: green, foregroundColor: Colors.white),
    body: loading ? const Center(child: CircularProgressIndicator(color: green)) :
      ListView(padding: const EdgeInsets.all(18), children: [
        Text(widget.category, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: green)),
        const SizedBox(height: 14),
        field(customer, 'Magacaaga'),
        field(phone, 'Number telefoonka', type: TextInputType.phone),
        field(item, 'Magaca / nooca agabka aad kiraysanayso'),
        field(size, 'Cabirka ama midabka (ikhtiyaari)'),
        OutlinedButton.icon(onPressed: () async {
          final d = await chooseDate(startDate);
          if (d != null) setState(() { startDate = d; if (endDate != null && endDate!.isBefore(d)) endDate = null; });
        }, icon: const Icon(Icons.calendar_today), label: Text('Bilowga kirada: ' + dateLabel(startDate))),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: startDate == null ? null : () async {
          final d = await chooseDate(endDate, minimum: startDate);
          if (d != null) setState(() => endDate = d);
        }, icon: const Icon(Icons.event_available), label: Text('Dhammaadka kirada: ' + dateLabel(endDate))),
        const SizedBox(height: 12),
        field(location, 'Goobta / xaafadda'),
        field(notes, 'Faahfaahin dheeraad ah (ikhtiyaari)', lines: 3),
        const SizedBox(height: 10),
        SizedBox(height: 52, child: FilledButton(
          onPressed: saving ? null : submit,
          style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
          child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('CODSIGA KIRADA DIR'),
        )),
      ]),
  );
}

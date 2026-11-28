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

Widget _orderAlertLine(String label,String value)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:92,child:Text('$label:',style:const TextStyle(fontWeight:FontWeight.bold))),Expanded(child:Text(value,style:const TextStyle(fontWeight:FontWeight.w600)))]));

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
  static Future<List<Map<String,dynamic>>> ownerPayments(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/owner/payments'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Codsiyada lacag-bixinta lama soo qaadi karin');
    return (b['payments'] as List).cast<Map<String,dynamic>>();
  }
  static Future<void> reviewOwnerPayment(String token,String id,String status) async {
    final r=await http.patch(Uri.parse('$baseUrl/api/owner/payments/$id'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'status':status}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Xaqiijinta lacagtu way fashilantay');
  }
  static Future<Map<String,dynamic>> adminStorage(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/admin/storage'),headers:{'Authorization':'Bearer $token'});
    final decoded=jsonDecode(r.body);
    if(decoded is! Map<String,dynamic>) throw Exception('Jawaabta server-ka ma aha JSON sax ah');
    final b=decoded;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Kaydka lama soo qaadi karin');
    return b;
  }
  static Future<Map<String,dynamic>> paymentConfig(String merchantId) async {
    final r=await http.get(Uri.parse('$baseUrl/api/payments/config?merchantId=${Uri.encodeQueryComponent(merchantId)}'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Hababka lacagta lama soo qaadi karin');
    return b;
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

  static Future<List<Map<String,dynamic>>> publicAllMerchants(String city) async {
    final r=await http.get(Uri.parse('$baseUrl/api/merchants?city=${Uri.encodeQueryComponent(city)}'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Meheradaha lama soo qaadi karin');
    return (b['merchants'] as List).cast<Map<String,dynamic>>();
  }
  static Future<List<Map<String,dynamic>>> publicMerchants(String category) async {
    final r=await http.get(Uri.parse('$baseUrl/api/merchants?category=${Uri.encodeQueryComponent(category)}'));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Meheradaha lama soo qaadi karin');
    return (b['merchants'] as List).cast<Map<String,dynamic>>();
  }
  static Future<void> createMerchantWithOwner(String token,Map<String,dynamic> data) async {
    final r=await http.post(Uri.parse('$baseUrl/api/admin/merchant-registration'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode(data));
    Map<String,dynamic> b;
    try {
      final decoded=jsonDecode(r.body);
      if(decoded is! Map<String,dynamic>) throw const FormatException('Jawaabta server-ku ma aha JSON object.');
      b=decoded;
    } catch (_) {
      final raw=r.body.trim();
      throw Exception('Server-ka diiwaangelintu wuxuu soo celiyey jawaab aan JSON ahayn (HTTP ${r.statusCode}). Hubi Worker-ka Cloudflare. Faahfaahin: ${raw.isEmpty?'jawaab madhan':raw.substring(0,raw.length>180?180:raw.length)}');
    }
    if(r.statusCode!=201||b['ok']!=true) throw Exception(b['error']??'Meheradda iyo akoonkeeda lama diiwaangelin (HTTP ${r.statusCode})');
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
  static Future<void> updatePhotoLimit(String token,String merchantId,int limit) async {
    final r=await http.patch(Uri.parse('$baseUrl/api/admin/merchants/$merchantId/photo-limit'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'photoLimit':limit}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Xadka sawirrada lama beddelin');
  }
  static Future<Map<String,dynamic>> ownerRentalInfo(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/owner/rentals'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Alaabta lama soo qaadi karin');
    return b;
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

  static Future<Map<String,dynamic>> salonAvailability(String merchantId,String date,{String? staffId}) async {
    final query=<String,String>{'merchantId':merchantId,'date':date,if(staffId!=null&&staffId.isNotEmpty)'staffId':staffId};
    final r=await http.get(Uri.parse('$baseUrl/api/availability').replace(queryParameters:query));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Jadwalka lama soo qaadi karin');
    return b;
  }
  static Future<Map<String,dynamic>> saveOwnerSchedule(String token,Map<String,dynamic> schedule) async {
    final r=await http.put(Uri.parse('$baseUrl/api/owner/schedule'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode(schedule));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Jadwalka lama kaydin');
    return b;
  }
  static Future<Set<String>> availableSalonTimes(String merchantId,String date,{String? staffId}) async {
    final query=<String,String>{'merchantId':merchantId,'date':date,if(staffId!=null&&staffId.isNotEmpty)'staffId':staffId};
    final r=await http.get(Uri.parse('$baseUrl/api/availability').replace(queryParameters:query));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Waqtiyada bannaan lama soo qaadi karin');
    return (b['busyTimes'] as List? ?? const []).map((x)=>x.toString()).toSet();
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

  static Future<void> recordRevenue(String token,Map<String,dynamic> data) async {
    final r=await http.post(Uri.parse('$baseUrl/api/owner/revenue'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode(data));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=201||b['ok']!=true) throw Exception(b['error']??'Dakhliga lama diiwaangelin');
  }
  static Future<List<Map<String,dynamic>>> adminCoupons(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/admin/coupons'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Coupons lama soo qaadi karin');
    return (b['coupons'] as List).cast<Map<String,dynamic>>();
  }
  static Future<void> createAdminCoupon(String token,Map<String,dynamic> data) async {
    final r=await http.post(Uri.parse('$baseUrl/api/admin/coupons'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode(data));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=201||b['ok']!=true) throw Exception(b['error']??'Coupon lama samayn');
  }
  static Future<void> setAdminCouponActive(String token,String id,bool active) async {
    final r=await http.patch(Uri.parse('$baseUrl/api/admin/coupons/$id'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token'},body:jsonEncode({'active':active}));
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Xaaladda coupon-ka lama beddelin');
  }
  static Future<void> deleteAdminCoupon(String token,String id) async {
    final r=await http.delete(Uri.parse('$baseUrl/api/admin/coupons/$id'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Coupon lama tirtirin');
  }

  static Future<Map<String,dynamic>> ownerRevenue(String token,String from,String to) async {
    final r=await http.get(Uri.parse('$baseUrl/api/owner/revenue?from=$from&to=$to'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Warbixinta dakhliga lama helin');
    return b;
  }

  static Future<Map<String,dynamic>> adminRevenue(String token,String from,String to) async {
    final r=await http.get(Uri.parse('$baseUrl/api/admin/revenue?from=$from&to=$to'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Warbixinta dakhliga lama helin');
    return b;
  }
  static Future<List<Map<String,dynamic>>> ownerBookings(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/owner/bookings'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Ballamaha lama soo qaadi karin');
    return (b['bookings'] as List).cast<Map<String,dynamic>>();
  }
  static Future<List<Map<String,dynamic>>> adminBookings(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/api/admin/bookings'),headers:{'Authorization':'Bearer $token'});
    final b=jsonDecode(r.body) as Map<String,dynamic>;
    if(r.statusCode!=200||b['ok']!=true) throw Exception(b['error']??'Dalabyada lama soo qaadi karin');
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
  bool customerRegistrationStarted = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRegistration();
  }

  Future<void> _loadRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerToken = prefs.getString('owner_token');
    final name = prefs.getString('customer_name');
    final phone = prefs.getString('customer_phone');
    if (!mounted) return;
    if (ownerToken != null && ownerToken.trim().isNotEmpty) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OwnerStaffPage(token: ownerToken)));
      return;
    }
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
    if (!customerRegistrationStarted) return Scaffold(
      backgroundColor: cream,
      body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset('assets/salon_logo.png', width: 300, height: 112, fit: BoxFit.contain),
        const SizedBox(height: 18),
        const Text('DOORO NOOCA GELITAANKA', style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 58, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white), onPressed: () => setState(() => customerRegistrationStarted = true), icon: const Icon(Icons.person), label: const Text('MACMIIL', style: TextStyle(fontWeight: FontWeight.bold)))),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, height: 58, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: green, side: const BorderSide(color: green, width: 1.5)), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MerchantLoginPage())), icon: const Icon(Icons.storefront), label: const Text('MULKIILAHA MEHERADDA', style: TextStyle(fontWeight: FontWeight.bold)))),
      ]))));
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
  String customerFirstName = '';
  String selectedCity = 'Hargeysa';
  static const List<String> activeCities = ['Hargeysa', 'Burco', 'Boorama', 'Berbera', 'Ceerigaabo', 'Gebiley'];
  static const List<String> upcomingCities = [];

  String? adminToken;
  List<Map<String,dynamic>> featured=[];
  bool featuredLoading=true;
  int featuredPage=0;
  final PageController featuredController=PageController(viewportFraction:.84);
  Timer? featuredTimer;
  Timer? adminOrderPollTimer;
  final Set<String> seenAdminBookingIds=<String>{};
  bool adminBookingSnapshotReady=false;
  bool adminOrderAlertShowing=false;
  @override
  void initState(){
    super.initState(); loadFeatured(); loadSelectedCity(); loadSalons(); loadCustomerFirstName();
    featuredTimer=Timer.periodic(const Duration(seconds:3),(_){
      if(!mounted||featured.length<2||!featuredController.hasClients)return;
      featuredPage=(featuredPage+1)%featured.length;
      featuredController.animateToPage(featuredPage,duration:const Duration(milliseconds:550),curve:Curves.easeInOut);
    });
  }
  @override
  void dispose(){featuredTimer?.cancel();adminOrderPollTimer?.cancel();featuredController.dispose();super.dispose();}
  Future<void> _startAdminOrderAlerts() async {
    adminOrderPollTimer?.cancel();
    seenAdminBookingIds.clear();
    adminBookingSnapshotReady=false;
    await _checkAdminNewOrders();
    adminOrderPollTimer=Timer.periodic(const Duration(seconds:15),(_)=>_checkAdminNewOrders());
  }
  Future<void> _checkAdminNewOrders() async {
    final token=adminToken;
    if(!mounted||!admin||token==null)return;
    try{
      final rows=await SalonApi.adminBookings(token);
      if(!mounted)return;
      if(!adminBookingSnapshotReady){
        seenAdminBookingIds.addAll(rows.map((x)=>(x['id']??'').toString()).where((x)=>x.isNotEmpty));
        adminBookingSnapshotReady=true;
        return;
      }
      if(ModalRoute.of(context)?.isCurrent!=true)return;
      final fresh=rows.where((x){
        final id=(x['id']??'').toString();
        final status=(x['status']??'').toString();
        return id.isNotEmpty&&!seenAdminBookingIds.contains(id)&&status!='Lama heli karo';
      }).toList();
      seenAdminBookingIds.addAll(rows.map((x)=>(x['id']??'').toString()).where((x)=>x.isNotEmpty));
      if(fresh.isEmpty||adminOrderAlertShowing)return;
      adminOrderAlertShowing=true;
      final first=fresh.first;
      Map<String,dynamic> details={};
      try{details=jsonDecode((first['details_json']??'{}').toString()) as Map<String,dynamic>;}catch(_){}
      final customer=(first['customer_name']??'Macmiil').toString();
      final category=(first['category']??'DALAB').toString();
      final merchant=(first['merchant_name']??'Meherad').toString();
      final service=(details['service']??details['itemName']??details['productName']??details['hallName']??'Dalab cusub').toString();
      final when=(details['appointmentDate']??details['eventDate']??details['deliveryDate']??'').toString();
      await showDialog<void>(context:context,barrierDismissible:false,builder:(dialogContext)=>Dialog(
        insetPadding:const EdgeInsets.symmetric(horizontal:22,vertical:24),
        child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Icon(Icons.notifications_active,color:green,size:54),
          const SizedBox(height:12),
          const Text('DALAB CUSUB!',textAlign:TextAlign.center,style:TextStyle(fontSize:23,fontWeight:FontWeight.w900,color:green)),
          const SizedBox(height:12),
          Text(fresh.length==1?'Waxaa soo galay dalab cusub.':'Waxaa soo galay ${fresh.length} dalab cusub.',textAlign:TextAlign.center,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700)),
          const Divider(height:24),
          _orderAlertLine('Macmiil',customer),
          _orderAlertLine('Qaybta',category),
          _orderAlertLine('Meheradda',merchant),
          _orderAlertLine('Adeegga',service),
          if(when.isNotEmpty)_orderAlertLine('Taariikhda',when),
          const SizedBox(height:18),
          SizedBox(width:double.infinity,child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:green,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(vertical:14)),onPressed:()=>Navigator.pop(dialogContext),icon:const Icon(Icons.receipt_long),label:const Text('WAA LA ARKAY — EEG DALABYADA'))),
        ])),
      ));
      adminOrderAlertShowing=false;
    }catch(_){}
  }
  Future<void> loadCustomerFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = (prefs.getString('customer_name') ?? '').trim();
    final firstName = fullName.isEmpty ? '' : fullName.split(RegExp(r'\\s+')).first;
    if (mounted) setState(() => customerFirstName = firstName);
  }
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
    final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Dooro magaaladaada'),content:Column(mainAxisSize:MainAxisSize.min,children:activeCities.map((city)=>ListTile(leading:const Icon(Icons.location_city,color:green),title:Text(city),onTap:()=>Navigator.pop(ctx,city))).toList())));
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
        } else if((p['category']??'').toString()!='HALL AROOS') { products.add(p); }
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
      try{adminToken=await SalonApi.adminLogin(pass);if(mounted){setState(()=>admin=true);_startAdminOrderAlerts();}}
      catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));return;}
    }
    await addFeaturedProduct();
  }
  Future<void> addFeaturedProduct() async {
    final title=TextEditingController(),desc=TextEditingController(),price=TextEditingController(),img=TextEditingController(),img2=TextEditingController();
    String category='SALON',currency='USD';
    String? selectedImage,selectedImage2;
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
        const SizedBox(height:12),
        SizedBox(height:100,width:double.infinity,child:ClipRRect(borderRadius:BorderRadius.circular(10),child:Container(color:cream,child:salonImage(selectedImage2,fit:BoxFit.cover,fallback:const Icon(Icons.image_outlined,size:34,color:green))))),
        OutlinedButton.icon(onPressed:() async {try{final picked=await pickSalonImage();if(picked!=null)refresh(()=>selectedImage2=picked);}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},icon:const Icon(Icons.add_photo_alternate),label:const Text('BEDDEL / KU DAR SAWIRKA LABAAD')),
        TextField(controller:img2,decoration:const InputDecoration(labelText:'URL sawirka labaad (ikhtiyaari)'),onChanged:(v){if(v.trim().startsWith('https://'))refresh(()=>selectedImage2=v.trim());}),
        const SizedBox(height:12),
        SizedBox(height:100,width:double.infinity,child:ClipRRect(borderRadius:BorderRadius.circular(10),child:Container(color:cream,child:salonImage(selectedImage2,fit:BoxFit.cover,fallback:const Icon(Icons.image_outlined,size:34,color:green))))),
        OutlinedButton.icon(onPressed:() async {try{final picked=await pickSalonImage();if(picked!=null)refresh(()=>selectedImage2=picked);}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},icon:const Icon(Icons.add_photo_alternate),label:const Text('KU DAR SAWIRKA LABAAD')),
        TextField(controller:img2,decoration:const InputDecoration(labelText:'URL sawirka labaad (ikhtiyaari)'),onChanged:(v){if(v.trim().startsWith('https://'))refresh(()=>selectedImage2=v.trim());}),
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydi'))])));
    if(ok!=true||title.text.trim().isEmpty||!mounted)return;
    final imageValue=selectedImage??img.text.trim(),imageValue2=selectedImage2??img2.text.trim();
    if(imageValue2.isNotEmpty&&!imageValue2.startsWith('data:image/')&&!imageValue2.startsWith('https://')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Sawirka labaad dooro ama geli HTTPS URL sax ah.')));return;}
    if(imageValue.isNotEmpty&&!imageValue.startsWith('data:image/')&&!imageValue.startsWith('https://')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Dooro sawir ama geli HTTPS URL sax ah.')));return;}
    try{await SalonApi.addFeaturedProduct(adminToken!,{'title':title.text.trim(),'description':desc.text.trim(),'price':price.text.trim(),'currency':currency,'category':category,'imageUrl':imageValue,'imageUrl2':imageValue2});await loadFeatured();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Alaabta waa la daabacay.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> editFeatured(Map<String,dynamic> p) async {
    final title=TextEditingController(text:(p['title']??'').toString());
    final desc=TextEditingController(text:(p['description']??'').toString());
    final price=TextEditingController(text:(p['price']??'').toString());
    final existingImage=(p['image_url']??'').toString();
    final existingImage2=(p['image_url2']??'').toString();
    final img2=TextEditingController(text:existingImage2.startsWith('https://')?existingImage2:'');
    String? selectedImage2=existingImage2.isNotEmpty?existingImage2:null;
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
    final imageValue2=selectedImage2??img2.text.trim();
    if(imageValue2.isNotEmpty&&!imageValue2.startsWith('data:image/')&&!imageValue2.startsWith('https://')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Sawirka labaad dooro ama geli HTTPS URL sax ah.')));return;}
    if(imageValue.isNotEmpty&&!imageValue.startsWith('data:image/')&&!imageValue.startsWith('https://')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Dooro sawir ama geli HTTPS URL sax ah.')));return;}
    try{
      await SalonApi.updateFeaturedProduct(adminToken!,p['id'].toString(),{'title':title.text.trim(),'description':desc.text.trim(),'price':price.text.trim(),'currency':currency,'category':category,'imageUrl':imageValue,'imageUrl2':imageValue2});
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
          SizedBox(width:224,height:180,child:Row(children:[
            Expanded(child:(p['image_url']??'').toString().isNotEmpty?salonImage(p['image_url'].toString(),fit:BoxFit.cover,fallback:Container(color:cream,child:const Icon(Icons.shopping_bag,color:green,size:36))):Container(color:cream,child:const Icon(Icons.shopping_bag,color:green,size:36))),
            if((p['image_url2']??'').toString().isNotEmpty)Expanded(child:salonImage(p['image_url2'].toString(),fit:BoxFit.cover,fallback:Container(color:cream,child:const Icon(Icons.image,color:green,size:30)))),
          ])),
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
    if(adminToken==null){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Admin kuma jiro. Fadlan dib uga gal Admin-ka.')));
      return;
    }
    String chosenCategory='SALON';
    final category=await showDialog<String>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('QAYBTA MEHERADDA'),
      content:DropdownButtonFormField<String>(value:chosenCategory,items:const [
        DropdownMenuItem(value:'SALON',child:Text('SALON')),
        DropdownMenuItem(value:'CAKES',child:Text('CAKES')),
        DropdownMenuItem(value:'DECORATION',child:Text('DECORATION')),
        DropdownMenuItem(value:'KIRAYSO',child:Text('KIRAYSO')),
      ],onChanged:(v)=>refresh(()=>chosenCategory=v??chosenCategory)),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,chosenCategory),child:const Text('SII WAD'))]
    )));
    if(category==null||!mounted)return;
    final n=await ask('Diiwaangeli Meherad','Magaca meheradda');
    if(n==null||!mounted)return;
    if(n.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Magaca salon-ka waa waajib.')));return;}
    String chosenMerchantCity='Hargeysa';
    final l=await showDialog<String>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('Dooro magaalada meheradda'),
      content:DropdownButtonFormField<String>(value:chosenMerchantCity,isExpanded:true,decoration:const InputDecoration(labelText:'Magaalada'),items:activeCities.map((city)=>DropdownMenuItem(value:city,child:Text(city))).toList(),onChanged:(v)=>refresh(()=>chosenMerchantCity=v??chosenMerchantCity)),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,chosenMerchantCity),child:const Text('Dooro'))]
    )));
    if(l==null||!mounted)return;
    final locationDescription=await ask('Tilmaanta meheradda','Tusaale: Xaafadda Jigjiga Yar, agagaarka suuqa');
    if(locationDescription==null||!mounted)return;
    if(locationDescription.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Tilmaanta meheraddu waa waajib.')));return;}
    final w=await ask('WhatsApp-ka Salon-ka','Tusaale: 25263xxxxxxx');
    if(!mounted)return;
    final username=await ask('Akoonka meheradda','Username-ka uu ku geli doono');
    if(username==null||!mounted)return;
    if(username.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Username-ka waa waajib.')));return;}
    final password=await ask('Password-ka meheradda','Ugu yaraan 10 xaraf');
    if(password==null||!mounted)return;
    if(password.trim().length<10){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Password-ku waa inuu ugu yaraan 10 xaraf ahaadaa.')));return;}
    final telesomUsd=await ask('Telesom USD — lambarka meheradda','Lambarka lacagta laguugu soo dirayo (ikhtiyaari)');
    if(!mounted)return;
    final telesomSlsh=await ask('Telesom SLSH — lambarka meheradda','Lambarka lacagta laguugu soo dirayo (ikhtiyaari)');
    if(!mounted)return;
    final somtelUsd=await ask('Somtel USD — lambarka meheradda','Lambarka lacagta laguugu soo dirayo (ikhtiyaari)');
    if(!mounted)return;
    final somtelSlsh=await ask('Somtel SLSH — lambarka meheradda','Lambarka lacagta laguugu soo dirayo (ikhtiyaari)');
    if(!mounted)return;
    final paymentConfigs=<Map<String,dynamic>>[
      if((telesomUsd??'').trim().isNotEmpty) {'provider':'Telesom','currency':'USD','recipientNumber':telesomUsd!.trim()},
      if((telesomSlsh??'').trim().isNotEmpty) {'provider':'Telesom','currency':'SLSH','recipientNumber':telesomSlsh!.trim()},
      if((somtelUsd??'').trim().isNotEmpty) {'provider':'Somtel','currency':'USD','recipientNumber':somtelUsd!.trim()},
      if((somtelSlsh??'').trim().isNotEmpty) {'provider':'Somtel','currency':'SLSH','recipientNumber':somtelSlsh!.trim()},
    ];
    try {
      await SalonApi.createMerchantWithOwner(adminToken!,{'category':category,'name':n.trim(),'location':l,'locationDescription':locationDescription.trim(),'ownerWhatsApp':(w??'').trim(),'username':username.trim(),'password':password,'paymentConfigs':paymentConfigs});
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
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminRevenuePage(token:adminToken!))),icon:const Icon(Icons.bar_chart),tooltip:'Dakhliga meheradaha'),
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminCouponsPage(token:adminToken!))),icon:const Icon(Icons.discount),tooltip:'Coupons iyo qiimo-dhimis'),
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminPaymentsPage(token:adminToken!))),icon:const Icon(Icons.payments),tooltip:'La soco lacagaha'),
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminStoragePage(token:adminToken!))),icon:const Icon(Icons.storage),tooltip:'Maamulka Storage-ka'),
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminPromotionPage(token:adminToken!))),icon:const Icon(Icons.campaign),tooltip:'Xaqiiji boosaska xayeysiiska'),
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminPaymentSettingsPage(token:adminToken!))),icon:const Icon(Icons.settings_applications),tooltip:'Hababka lacagta iyo sarifka'),
        IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MerchantSearchPage(city:selectedCity))),icon:const Icon(Icons.search),tooltip:'Raadi meherad'),
        IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CustomerOrdersPage())),icon:const Icon(Icons.receipt_long),tooltip:'Ballamahayga iyo dalabyadayda'),
        IconButton(onPressed: openMerchantLogin, icon: const Icon(Icons.storefront), tooltip: 'Gelitaanka meheradda'),
        IconButton(onPressed: openAdminTools, icon: const Icon(Icons.admin_panel_settings), tooltip: 'Admin')]),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [green, Color(0xFF164B39)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            customerFirstName.isEmpty ? 'SOO DHAWOOW MARWO' : 'SOO DHAWOOW MARWO $customerFirstName'.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 9),
          const Text('Quruxdaada, hal meel.', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Dooro qaybta aad u baahan tahay.', style: TextStyle(color: Colors.white))
        ])),
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
          sectionTile('HALL AROOS', 'Halls-ka aroosyada', Icons.church_outlined, 4),
        ],
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 30),
          title: const Text('RATE US', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Qiimee app-ka adigoo dooranaya 1 ilaa 5 xiddigood'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: rateUs,
        ),
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
  Future<void> rateUs() async {
    int selectedRating = 0;
    final rating = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('RATE US'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Qiimee SALON BOOKING'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  tooltip: '${index + 1} xiddig',
                  onPressed: () => setDialogState(() => selectedRating = index + 1),
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 34,
                  ),
                )),
              ),
              Text(selectedRating == 0 ? 'Dooro xiddigaha' : '$selectedRating / 5'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('XIR')),
            FilledButton(
              onPressed: selectedRating == 0 ? null : () => Navigator.pop(dialogContext, selectedRating),
              style: FilledButton.styleFrom(backgroundColor: green),
              child: const Text('DIR QIIMAYNTA'),
            ),
          ],
        ),
      ),
    );
    if (rating == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('salon_app_rating', rating);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mahadsanid qiimayntaada!')),
    );
  }

  Widget sectionTile(String title, String subtitle, IconData icon, int index) {
    final imageUrl=categoryImageUrls[title];
    return InkWell(
      onTap: () {
        if (index == 0) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SalonDirectoryPage(city:selectedCity)));
          return;
        }
        if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderDirectoryPage(title: 'DECORATION', isCake: false, city:selectedCity)));
          return;
        }
        if(index==3){
          Navigator.push(context,MaterialPageRoute(builder:(_)=>RentalPage(city:selectedCity)));
          return;
        }
        if(index==4){
          Navigator.push(context,MaterialPageRoute(builder:(_)=>HallAroosPage(adminToken:adminToken)));
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
        builder: (_) => isCake
          ? MerchantSearchPage(city:selectedCity, initialCategory:'CAKES')
          : ProviderDirectoryPage(title: title, isCake: isCake, city:selectedCity))),
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

class MerchantSearchPage extends StatefulWidget {
  const MerchantSearchPage({super.key,required this.city,this.initialCategory='DHAMMAAN'});
  final String city;
  final String initialCategory;
  @override
  State<MerchantSearchPage> createState()=>_MerchantSearchPageState();
}
class _MerchantSearchPageState extends State<MerchantSearchPage>{
  final search=TextEditingController();
  late String category=widget.initialCategory;
  bool loading=true;
  bool favoritesOnly=false;
  String? error;
  List<Map<String,dynamic>> merchants=[];
  Set<String> favoriteIds={};
  String get favoriteKey {
    final phone=phoneDigits(SharedPreferences.getInstance().toString());
    return 'salon_favorites_${widget.city.toLowerCase()}';
  }
  @override
  void initState(){super.initState();load();}
  @override
  void dispose(){search.dispose();super.dispose();}
  Future<void> load() async {
    setState(()=>loading=true);
    try{
      final prefs=await SharedPreferences.getInstance();
      final saved=prefs.getStringList('salon_favorites_${widget.city.toLowerCase()}')??<String>[];
      final rows=await SalonApi.publicAllMerchants(widget.city);
      if(mounted)setState(()=>{merchants=rows,favoriteIds=saved.toSet(),loading=false,error=null});
    }catch(e){if(mounted)setState(()=>{loading=false,error=e.toString()});}
  }
  Future<void> toggleFavorite(String id) async {
    final next={...favoriteIds};
    if(!next.add(id))next.remove(id);
    final prefs=await SharedPreferences.getInstance();
    await prefs.setStringList('salon_favorites_${widget.city.toLowerCase()}',next.toList());
    if(mounted)setState(()=>favoriteIds=next);
  }
  List<Map<String,dynamic>> get filtered {
    final q=search.text.trim().toLowerCase();
    return merchants.where((m){
      final c=(m['category']??'').toString();
      final name=(m['name']??'').toString().toLowerCase();
      final loc=(m['location']??'').toString().toLowerCase();
      final id=(m['id']??'').toString();
      return (category=='DHAMMAAN'||c==category)&&(!favoritesOnly||favoriteIds.contains(id))&&(q.isEmpty||name.contains(q)||loc.contains(q));
    }).toList();
  }
  void openMerchant(Map<String,dynamic> m){
    final id=(m['id']??'').toString(),name=(m['name']??'Meherad').toString();
    final loc=(m['location']??widget.city).toString(),phone=(m['owner_whatsapp']??'').toString();
    final c=(m['category']??'').toString();
    if(c=='SALON'){
      final salon=Salon(id,name,loc,['Timaha','Qurxinta wajiga','Daryeelka jirka','Ciddiyaha','Makeup','Adeegyo kale'],whatsappNumber:phone);
      showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.white,builder:(_)=>_SalonServicesSheet(salon:salon));
    }else if(c=='CAKES'){
      Navigator.push(context,MaterialPageRoute(builder:(_)=>CakePage(providerName:name,whatsappNumber:phone,merchantId:id)));
    }else if(c=='DECORATION'){
      Navigator.push(context,MaterialPageRoute(builder:(_)=>DecorationBookingPage(providerName:name,whatsappNumber:phone,merchantId:id)));
    }else if(c=='KIRAYSO'){
      Navigator.push(context,MaterialPageRoute(builder:(_)=>MerchantRentalGalleryPage(merchantId:id,merchantName:name,city:loc)));
    }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('RAADI MEHERAD'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(14,14,14,8),child:TextField(
        controller:search,onChanged:(_)=>setState((){}),
        decoration:InputDecoration(prefixIcon:const Icon(Icons.search,color:green),hintText:'Geli magaca meheradda ama xaafadda',suffixIcon:search.text.isEmpty?null:IconButton(onPressed:(){search.clear();setState((){});},icon:const Icon(Icons.close)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14))))),
      SizedBox(height:52,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:10),children:[
        Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:const Text('KAYDSAN'),selected:favoritesOnly,onSelected:(_)=>setState(()=>favoritesOnly=!favoritesOnly))),
        for(final c in ['DHAMMAAN','SALON','CAKES','DECORATION','KIRAYSO'])
          Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:Text(c),selected:category==c,onSelected:(_)=>setState(()=>category=c)))
      ])),
      Expanded(child:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):filtered.isEmpty?const Center(child:Text('Meherad ku habboon raadintaada lama helin.')):ListView.builder(
        padding:const EdgeInsets.all(12),itemCount:filtered.length,itemBuilder:(ctx,i){
          final m=filtered[i];
          return Card(child:ListTile(
            leading:CircleAvatar(backgroundColor:cream,child:Icon(m['category']=='SALON'?Icons.spa:m['category']=='CAKES'?Icons.cake:m['category']=='DECORATION'?Icons.celebration:m['category']=='KIRAYSO'?Icons.checkroom:Icons.storefront,color:green)),
            title:Text((m['name']??'Meherad').toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
            subtitle:Text('${m['category']??''} • ${m['location']??widget.city}'),
            trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(tooltip:favoriteIds.contains((m['id']??'').toString())?'Ka saar kaydka':'Ku dar kaydka',onPressed:()=>toggleFavorite((m['id']??'').toString()),icon:Icon(favoriteIds.contains((m['id']??'').toString())?Icons.favorite:Icons.favorite_border,color:favoriteIds.contains((m['id']??'').toString())?Colors.red:green)),const Icon(Icons.arrow_forward_ios,size:16,color:green)]),
            onTap:()=>openMerchant(m),
          ));
        }))
    ])
  );
}

class MerchantRentalGalleryPage extends StatefulWidget {
  const MerchantRentalGalleryPage({super.key,required this.merchantId,required this.merchantName,required this.city});
  final String merchantId,merchantName,city;
  @override
  State<MerchantRentalGalleryPage> createState()=>_MerchantRentalGalleryPageState();
}
class _MerchantRentalGalleryPageState extends State<MerchantRentalGalleryPage>{
  bool loading=true;
  String? error;
  List<Map<String,dynamic>> items=[];
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    try{
      final all=<Map<String,dynamic>>[];
      for(final c in ['SAD RENTAL','TAASH','TOOBKA MEHERKA','SUBEECIYAD']){
        all.addAll(await SalonApi.rentalItems(c,widget.city));
      }
      if(mounted)setState(()=>{items=all.where((x)=>(x['merchant_id']??'').toString()==widget.merchantId).toList(),loading=false,error=null});
    }catch(e){if(mounted)setState(()=>{loading=false,error=e.toString()});}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.merchantName),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):items.isEmpty?const Center(child:Text('Meheraddan wali alaab kiraysi ah laguma darin.')):GridView.builder(
      padding:const EdgeInsets.all(12),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.68,crossAxisSpacing:10,mainAxisSpacing:10),itemCount:items.length,
      itemBuilder:(ctx,i){final p=items[i];return Card(clipBehavior:Clip.antiAlias,child:InkWell(
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RentalRequestPage(category:(p['category']??'').toString(),selectedItem:(p['name']??'').toString(),merchantId:widget.merchantId,merchantName:widget.merchantName,merchantLocation:widget.city))),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:salonImage((p['photoUrl']??'').toString(),fit:BoxFit.cover,fallback:Container(color:cream,child:const Icon(Icons.checkroom,color:green,size:40)))),
          Padding(padding:const EdgeInsets.all(8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text((p['name']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold)),
            Text('${p['price']??''} ${p['currency']??'USD'}',style:const TextStyle(color:green,fontWeight:FontWeight.bold)),
            Text((p['category']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11))
          ]))
        ])
      ));}
    )
  );
}

class SalonDirectoryPage extends StatefulWidget {
  const SalonDirectoryPage({super.key, required this.city});
  final String city;
  @override
  State<SalonDirectoryPage> createState() => _SalonDirectoryPageState();
}

class _SalonDirectoryPageState extends State<SalonDirectoryPage> {
  bool loading=true;
  String? error;
  List<Salon> salons=[];
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    try {
      final rows=await SalonApi.publicMerchants('SALON');
      final list=rows.map((m)=>Salon(m['id'].toString(),(m['name']??'Salon').toString(),(m['location']??'Hargeysa').toString(),['Timaha','Qurxinta wajiga','Daryeelka jirka','Ciddiyaha','Makeup','Adeegyo kale'],whatsappNumber:(m['owner_whatsapp']??'').toString(),staffLimit:int.tryParse((m['staff_limit']??5).toString())??5)).where((s)=>s.location.trim().toLowerCase()==widget.city.trim().toLowerCase()).toList();
      if(mounted)setState(()=>{salons=list,loading=false,error=null});
    } catch(e){if(mounted)setState(()=>{loading=false,error=e.toString()});}
  }
  Future<void> openSalon(Salon salon) async {
    showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.white,builder:(ctx)=>_SalonServicesSheet(salon:salon));
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text('SALON-LADA — ${widget.city}'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):salons.isEmpty?Center(child:Text('Magaalada ${widget.city} weli lagama diiwaangelin meherado salon ah.',textAlign:TextAlign.center)):GridView.builder(
      padding:const EdgeInsets.all(14),itemCount:salons.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:.9),
      itemBuilder:(context,i){final s=salons[i];return Card(clipBehavior:Clip.antiAlias,margin:EdgeInsets.zero,child:InkWell(onTap:()=>openSalon(s),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Expanded(child:Container(color:cream,child:const Center(child:Icon(Icons.storefront,color:green,size:48)))),
        Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:15,color:green)),
          const SizedBox(height:4),Row(children:[const Icon(Icons.location_on,size:14,color:green),Expanded(child:Text(s.location,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,color:Colors.black54)))]),
          const SizedBox(height:6),const Text('Eeg adeegyada  →',style:TextStyle(color:green,fontSize:12,fontWeight:FontWeight.w600))
        ]))
      ])));}));
}

class _SalonServicesSheet extends StatefulWidget {
  const _SalonServicesSheet({required this.salon});
  final Salon salon;
  @override
  State<_SalonServicesSheet> createState()=>_SalonServicesSheetState();
}
class _SalonServicesSheetState extends State<_SalonServicesSheet>{
  bool loading=true;
  List<Map<String,dynamic>> staff=[];
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {try{final rows=await SalonApi.publicStaff(widget.salon.id);if(mounted)setState(()=>{staff=rows,loading=false});}catch(_){if(mounted)setState(()=>loading=false);}}
  @override
  Widget build(BuildContext context)=>SafeArea(child:Padding(padding:EdgeInsets.only(left:16,right:16,top:16,bottom:MediaQuery.of(context).viewInsets.bottom+16),child:SizedBox(height:MediaQuery.of(context).size.height*.72,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(widget.salon.name,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:green)),
    Text(widget.salon.location,style:const TextStyle(color:Colors.black54)),
    const SizedBox(height:12),const Text('ADEEGYADA SALON-KA',style:TextStyle(fontWeight:FontWeight.bold)),
    const SizedBox(height:8),Expanded(child:loading?const Center(child:CircularProgressIndicator(color:green)):ListView(children:[
      if(staff.isEmpty)const Padding(padding:EdgeInsets.all(10),child:Text('Meheraddan wali ma diiwaangelin hablaha shaqeeya.')),
      ...staff.map((person) {
        List<dynamic> services = [];
        try {
          services = jsonDecode((person['services_json'] ?? '[]').toString()) as List;
        } catch (_) {}
        return Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: cream, child: Icon(Icons.person, color: green)),
            title: Text((person['name'] ?? '').toString()),
            subtitle: Text(services.join(', ')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 15),
            onTap: services.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalonBookingPage(
                          salonName: widget.salon.name,
                          serviceName: services.first.toString(),
                          whatsappNumber: widget.salon.whatsappNumber,
                          merchantId: widget.salon.id,
                          staffId: person['id'].toString(),
                          staffName: person['name'].toString(),
                        ),
                      ),
                    );
                  },
          ),
        );
      }),
      ...widget.salon.services.map((service)=>ListTile(leading:const Icon(Icons.spa_outlined,color:green),title:Text(service),trailing:const Icon(Icons.arrow_forward_ios,size:15),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SalonBookingPage(salonName:widget.salon.name,serviceName:service,whatsappNumber:widget.salon.whatsappNumber,merchantId:widget.salon.id)))))
    ]))
  ]))));
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
  const DecorationBookingPage({super.key, required this.providerName, this.whatsappNumber = '', this.merchantId});
  final String providerName;
  final String whatsappNumber;
  final String? merchantId;
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
        merchantId: widget.merchantId,
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
  const CakePage({super.key, this.providerName, this.whatsappNumber = '', this.merchantId});
  final String? providerName;
  final String whatsappNumber;
  final String? merchantId;
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
        merchantId: widget.merchantId,
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
  final couponCode = TextEditingController();
  DateTime? selectedDate;
  String? selectedTime;
  Set<String> busyTimes = <String>{};
  bool loading = true;
  bool saving = false;
  bool availabilityLoading = false;
  String? availabilityError;
  Set<int> workingDays = <int>{1,2,3,4,5,6};
  String openTime = '08:00';
  String closeTime = '19:30';

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
    couponCode.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) => d.year.toString().padLeft(4, '0') + '-' +
      d.month.toString().padLeft(2, '0') + '-' + d.day.toString().padLeft(2, '0');

  Future<void> _loadAvailability() async {
    if (widget.merchantId == null || widget.merchantId!.isEmpty || selectedDate == null) return;
    setState(() {
      availabilityLoading = true;
      availabilityError = null;
      selectedTime = null;
    });
    try {
      final result = await SalonApi.salonAvailability(
        widget.merchantId!, _dateKey(selectedDate!), staffId: widget.staffId,
      );
      if (mounted) setState(() {
        busyTimes = (result['busyTimes'] as List? ?? const []).map((x)=>x.toString()).toSet();
        workingDays = (result['workingDays'] as List? ?? const [1,2,3,4,5,6]).map((x)=>int.tryParse(x.toString())??1).toSet();
        openTime = (result['openTime']??'08:00').toString();
        closeTime = (result['closeTime']??'19:30').toString();
        if(result['isWorkingDay']!=true) availabilityError='Maalintan salon-ku ama shaqaaluhu ma shaqeeyo.';
      });
    } catch (e) {
      if (mounted) setState(() => availabilityError = e.toString());
    }
    if (mounted) setState(() => availabilityLoading = false);
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (value != null && mounted) {
      setState(() {
        selectedDate = value;
        selectedTime = null;
        busyTimes = <String>{};
      });
      await _loadAvailability();
    }
  }

  List<String> get _timeSlots {
    int minutes(String value) { final p=value.split(':'); return (int.tryParse(p[0])??8)*60+(int.tryParse(p[1])??0); }
    final start=minutes(openTime), end=minutes(closeTime);
    if(end<=start)return <String>[];
    return List<String>.generate(((end-start)/30).ceil(),(i){
      final total=start+i*30;
      return (total~/60).toString().padLeft(2,'0')+':'+(total%60).toString().padLeft(2,'0');
    }).where((slot)=>minutes(slot)+30<=end).toList();
  }

  Future<void> _submit() async {
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty ||
        selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buuxi magaca, telefoonka, taariikhda iyo waqtiga ballanta.')),
      );
      return;
    }
    if (widget.merchantId == null || widget.merchantId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salon-kan lama aqoonsan karo. Fadlan dib uga dooro liiska meheradaha.')),
      );
      return;
    }
    setState(() => saving = true);
    final prefs = await SharedPreferences.getInstance();
    late final Map<String,dynamic> bookingResult;
    final dateText = _dateKey(selectedDate!);
    try {
      bookingResult = await SalonApi.createBooking(
        category: 'SALON',
        merchantId: widget.merchantId,
        customerName: name.text.trim(),
        customerPhone: phone.text.trim(),
        customerWhatsApp: prefs.getString('customer_whatsapp') ?? phone.text.trim(),
        details: {
          'salon': widget.salonName,
          'service': widget.serviceName,
          if(widget.staffId!=null)'staffId':widget.staffId,
          if(widget.staffName!=null)'staffName':widget.staffName,
          'date': dateText,
          'time': selectedTime,
          'appointmentDate': dateText,
          'appointmentTime': selectedTime,
          'notes': notes.text.trim(),
          if(couponCode.text.trim().isNotEmpty)'couponCode':couponCode.text.trim().toUpperCase(),
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diristu way fashilantay: $e')));
      await _loadAvailability();
      return;
    }
    final records = prefs.getStringList('salon_booking_requests') ?? <String>[];
    records.add(jsonEncode(<String, dynamic>{
      'id': (bookingResult['id'] ?? '').toString(),
      'salon': widget.salonName,
      'service': widget.serviceName,
      if(widget.staffId!=null)'staffId':widget.staffId,
      if(widget.staffName!=null)'staffName':widget.staffName,
      'customerName': name.text.trim(),
      'customerPhone': phone.text.trim(),
      'date': dateText,
      'time': selectedTime,
      'notes': notes.text.trim(),
      'status': (bookingResult['status'] ?? 'Sugaya jawaab').toString(),
      'createdAt': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList('salon_booking_requests', records);
    if (!mounted) return;
    setState(() => saving = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Codsiga waa la diray'),
        content: Text('Ballantaada ' + widget.serviceName + ' ee ' + widget.salonName +
            (widget.staffName == null ? '' : ' — ' + widget.staffName!) +
            ' waa la diray. Sug jawaabta meheradda.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('HAGAAG'),
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
            TextField(controller: couponCode, textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Coupon code (ikhtiyaari)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _chooseDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(selectedDate == null ? 'Dooro taariikhda ballanta' :
                selectedDate!.day.toString() + '/' + selectedDate!.month.toString() + '/' + selectedDate!.year.toString()),
            ),
            const SizedBox(height: 12),
            if (selectedDate != null) ...[
              Text('DOORO WAQTIGA BANNaan ($openTime – $closeTime)', style: const TextStyle(fontWeight: FontWeight.bold, color: green)),
              const SizedBox(height: 8),
              if (availabilityLoading)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: green)))
              else if (availabilityError != null)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Waqtiyada lama soo qaadi karin: ' + availabilityError!, style: const TextStyle(color: Colors.red)),
                  TextButton.icon(onPressed: _loadAvailability, icon: const Icon(Icons.refresh), label: const Text('DIB U HUBI')),
                ])
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timeSlots.map((slot) {
                    final busy = busyTimes.contains(slot);
                    final selected = selectedTime == slot;
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 68) / 4,
                      child: OutlinedButton(
                        onPressed: busy ? null : () => setState(() => selectedTime = slot),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected ? green : (busy ? Colors.black12 : Colors.white),
                          foregroundColor: selected ? Colors.white : (busy ? Colors.black38 : green),
                          side: BorderSide(color: selected ? green : Colors.black26),
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
                        ),
                        child: Text(slot, style: const TextStyle(fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              if (!availabilityLoading && availabilityError == null)
                const Padding(padding: EdgeInsets.only(top: 7), child: Text('Waqtiyada cawlka ah waa la qabsaday. Waqtiyada kale waa bannaan yihiin.', style: TextStyle(fontSize: 11, color: Colors.black54))),
            ],
            const SizedBox(height: 12),
            TextField(controller: notes, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Faahfaahin dheeraad ah (ikhtiyaari)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(height: 50, child: FilledButton(
              onPressed: saving || availabilityLoading || availabilityError != null ? null : _submit,
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
      final prefs=await SharedPreferences.getInstance();
      await prefs.setString('owner_token',token);
      if(!mounted)return;
      Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>OwnerStaffPage(token:token)),(route)=>false);
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
  Future<void> editSchedule({Map<String,dynamic>? person}) async {
    final isStaff=person!=null;
    final source=isStaff?person:data;
    final rawDays=source['working_days_json']??source['workingDays'];
    List<int> days;
    try{days=(rawDays is String?jsonDecode(rawDays):rawDays as List).map((x)=>int.parse(x.toString())).toList();}
    catch(_){days=(data['workingDays'] as List? ?? [1,2,3,4,5,6]).map((x)=>int.parse(x.toString())).toList();}
    final selected=<int>{...days};
    TimeOfDay parseTime(String v){final p=v.split(':');return TimeOfDay(hour:int.tryParse(p[0])??8,minute:int.tryParse(p[1])??0);}
    String open=(source['open_time']??source['openTime']??data['openTime']??'08:00').toString();
    String close=(source['close_time']??source['closeTime']??data['closeTime']??'19:30').toString();
    TimeOfDay opening=parseTime(open),closing=parseTime(close);
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:Text(isStaff?'JADWALKA SHAQAALAHA':'JADWALKA MEHERADDA'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('MAALMAHA SHAQADA',style:TextStyle(fontWeight:FontWeight.bold,color:green)),
        ...['Axad','Isniin','Talaado','Arbaco','Khamiis','Jimce','Sabti'].asMap().entries.map((e)=>CheckboxListTile(contentPadding:EdgeInsets.zero,dense:true,value:selected.contains(e.key),title:Text(e.value),onChanged:(v)=>refresh(()=>v==true?selected.add(e.key):selected.remove(e.key)))),
        const Divider(),
        ListTile(contentPadding:EdgeInsets.zero,title:const Text('Waqtiga furitaanka'),subtitle:Text(opening.format(ctx)),trailing:const Icon(Icons.access_time),onTap:()async{final v=await showTimePicker(context:ctx,initialTime:opening);if(v!=null)refresh(()=>opening=v);}),
        ListTile(contentPadding:EdgeInsets.zero,title:const Text('Waqtiga xiritaanka'),subtitle:Text(closing.format(ctx)),trailing:const Icon(Icons.access_time),onTap:()async{final v=await showTimePicker(context:ctx,initialTime:closing);if(v!=null)refresh(()=>closing=v);}),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('KA NOQO')),FilledButton(onPressed:selected.isEmpty||opening.hour*60+opening.minute>=closing.hour*60+closing.minute?null:()=>Navigator.pop(ctx,true),child:const Text('KAYDI JADWALKA'))]
    )));
    if(ok!=true||!mounted)return;
    String fmt(TimeOfDay t)=>t.hour.toString().padLeft(2,'0')+':'+t.minute.toString().padLeft(2,'0');
    final payload=<String,dynamic>{'workingDays':selected.toList()..sort(),'openTime':fmt(opening),'closeTime':fmt(closing)};
    try{
      if(isStaff) await SalonApi.updateOwnerStaff(widget.token,person['id'].toString(),payload);
      else await SalonApi.saveOwnerSchedule(widget.token,payload);
      await load();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Jadwalka waa la kaydiyey.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }

  Map<String,dynamic> data={};
  bool loading=true;
  String? error;
  Timer? orderPollTimer;
  final Set<String> seenBookingIds=<String>{};
  bool bookingSnapshotReady=false;
  bool orderAlertShowing=false;
  @override
  void initState(){
    super.initState();
    load();
    _checkNewBookings();
    orderPollTimer=Timer.periodic(const Duration(seconds:20),(_)=>_checkNewBookings());
  }
  @override
  void dispose(){orderPollTimer?.cancel();super.dispose();}
  Future<void> _checkNewBookings() async {
    if(!mounted)return;
    try{
      final rows=await SalonApi.ownerBookings(widget.token);
      if(!mounted)return;
      if(!bookingSnapshotReady){
        seenBookingIds.addAll(rows.map((x)=>(x['id']??'').toString()).where((x)=>x.isNotEmpty));
        bookingSnapshotReady=true;
        return;
      }
      if(ModalRoute.of(context)?.isCurrent!=true)return;
      final fresh=rows.where((x){
        final id=(x['id']??'').toString();
        final status=(x['status']??'Sugaya jawaab').toString();
        return id.isNotEmpty&&!seenBookingIds.contains(id)&&status=='Sugaya jawaab';
      }).toList();
      seenBookingIds.addAll(rows.map((x)=>(x['id']??'').toString()).where((x)=>x.isNotEmpty));
      if(fresh.isEmpty||orderAlertShowing)return;
      orderAlertShowing=true;
      final first=fresh.first;
      Map<String,dynamic> details={};
      try{details=jsonDecode((first['details_json']??'{}').toString()) as Map<String,dynamic>;}catch(_){}
      final customer=(first['customer_name']??'Macmiil').toString();
      final category=(first['category']??'DALAB').toString();
      final service=(details['service']??details['itemName']??details['productName']??'Dalab cusub').toString();
      final when=(details['appointmentDate']??details['eventDate']??details['deliveryDate']??'').toString();
      await showDialog<void>(context:context,barrierDismissible:false,builder:(dialogContext)=>Dialog(
        insetPadding:const EdgeInsets.symmetric(horizontal:22,vertical:24),
        child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Icon(Icons.notifications_active,color:green,size:54),
          const SizedBox(height:12),
          const Text('DALAB CUSUB!',textAlign:TextAlign.center,style:TextStyle(fontSize:23,fontWeight:FontWeight.w900,color:green)),
          const SizedBox(height:12),
          Text(fresh.length==1?'Macmiil ayaa dalab cusub kuu soo diray.':'Waxaa kuu yimid ${fresh.length} dalab cusub.',textAlign:TextAlign.center,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700)),
          const Divider(height:24),
          _orderAlertLine('Macmiil',customer),
          _orderAlertLine('Qaybta',category),
          _orderAlertLine('Adeegga',service),
          if(when.isNotEmpty)_orderAlertLine('Taariikhda',when),
          const SizedBox(height:18),
          SizedBox(width:double.infinity,child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:green,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(vertical:14)),onPressed:(){Navigator.pop(dialogContext);Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerBookingsPage(token:widget.token)));},icon:const Icon(Icons.receipt_long),label:const Text('EEG DALABKA'))),
        ])),
      ));
      orderAlertShowing=false;
    }catch(_){}
  }
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
    final photoLimit=int.tryParse((data['photoLimit']??10).toString())??10;
    final photoCount=int.tryParse((data['photoCount']??0).toString())??0;
    final activeStaff=staff.where((x)=>x['active']!=0&&x['active']!='0').toList();
    final name=(data['merchantName']??'Meheraddaada').toString();
    return Scaffold(appBar:AppBar(title:Text(name),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerPaymentsPage(token:widget.token))),icon:const Icon(Icons.payments),tooltip:'Xaqiiji lacagaha'),IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerBookingsPage(token:widget.token))),icon:const Icon(Icons.calendar_month),tooltip:'Ballamaha'),IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerPromotionPage(token:widget.token))),icon:const Icon(Icons.campaign),tooltip:'Boosaska xayeysiiska'),
      IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerRevenuePage(token:widget.token))),icon:const Icon(Icons.bar_chart),tooltip:'Warbixinta ganacsiga'),
      IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerRentalPage(token:widget.token))),icon:const Icon(Icons.checkroom),tooltip:'Alaabta kirada'),IconButton(onPressed:load,icon:const Icon(Icons.refresh)),IconButton(tooltip:'LOGOUT',icon:const Icon(Icons.logout),onPressed:()async{final prefs=await SharedPreferences.getInstance();await prefs.remove('owner_token');if(!mounted)return;Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const RegistrationGate()),(route)=>false);})]),
      floatingActionButton:FloatingActionButton.extended(onPressed:activeStaff.length>=limit?null:()=>editStaff(),backgroundColor:green,foregroundColor:Colors.white,icon:const Icon(Icons.person_add),label:const Text('KU DAR GABAR')),
      body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):ListView(padding:const EdgeInsets.all(14),children:[
        Card(child:ListTile(
          leading:const CircleAvatar(backgroundColor:cream,child:Icon(Icons.bar_chart,color:green)),
          title:const Text('WARBIXINTA GANACSIGA',style:TextStyle(fontWeight:FontWeight.bold)),
          subtitle:const Text('Dakhliga iyo tirada adeegyada aad dhammeystirtay'),
          trailing:const Icon(Icons.arrow_forward_ios,color:green),
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OwnerRevenuePage(token:widget.token))),
        )),
        Card(child:ListTile(
          leading:const CircleAvatar(backgroundColor:cream,child:Icon(Icons.schedule,color:green)),
          title:const Text('JADWALKA MEHERADDA',style:TextStyle(fontWeight:FontWeight.bold)),
          subtitle:Text('Maalmaha: '+((data['workingDays'] as List? ?? [1,2,3,4,5,6]).map((x)=>['Axad','Isniin','Talaado','Arbaco','Khamiis','Jimce','Sabti'][int.parse(x.toString())]).join(', '))+'\\n'+(data['openTime']??'08:00').toString()+' – '+(data['closeTime']??'19:30').toString()),
          trailing:const Icon(Icons.edit,color:green),onTap:()=>editSchedule(),
        )),
        Text('SHAQAALAHA: '+activeStaff.length.toString()+' / '+limit.toString(),style:const TextStyle(color:green,fontWeight:FontWeight.bold,fontSize:17)),
        const SizedBox(height:5),
        Text('SAWIRRADA MEHERADDA: $photoCount / $photoLimit',style:const TextStyle(color:green,fontWeight:FontWeight.w600)),
        const SizedBox(height:8),
        if(activeStaff.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('Weli gabdho shaqaale ah lama diiwaangelin.')),
        ...activeStaff.map((p)=>Card(child:ListTile(
          leading:ClipRRect(borderRadius:BorderRadius.circular(8),child:salonImage((p['photoUrl']??'').toString(),fit:BoxFit.cover,fallback:const Icon(Icons.person,color:green))),
          title:Text((p['name']??'').toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
          subtitle:Text((p['title']??'').toString()+'\n'+((jsonDecode((p['services_json']??'[]').toString()) as List).join(', '))),
          isThreeLine:true,trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')editStaff(p);if(v=='schedule')editSchedule(person:p);if(v=='delete')removeStaff(p);},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Wax ka beddel')),PopupMenuItem(value:'schedule',child:Text('Jadwalka shaqada')),PopupMenuItem(value:'delete',child:Text('Ka saar'))])
        )))
      ]));
  }
}



class AdminCouponsPage extends StatefulWidget {
  const AdminCouponsPage({super.key,required this.token});
  final String token;
  @override State<AdminCouponsPage> createState()=>_AdminCouponsPageState();
}
class _AdminCouponsPageState extends State<AdminCouponsPage>{
  List<Map<String,dynamic>> rows=[];
  bool loading=true;
  @override void initState(){super.initState();load();}
  Future<void> load() async {if(mounted)setState(()=>loading=true);try{final x=await SalonApi.adminCoupons(widget.token);if(mounted)setState(()=>{rows=x,loading=false});}catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}}
  Future<void> create() async {
    final code=TextEditingController(),discount=TextEditingController(text:'10'),uses=TextEditingController();
    String category='ALL';DateTime? expiry;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('SAMEE COUPON CUSUB'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:code,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'Koodhka coupon-ka')),
        TextField(controller:discount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Dhimista boqolkiiba (%)')),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Qaybta'),items:const ['ALL','SALON','CAKES','DECORATION','KIRAYSO'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>category=v??'ALL')),
        TextField(controller:uses,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Tirada ugu badan (madhan = aan xad lahayn)')),
        ListTile(contentPadding:EdgeInsets.zero,title:Text(expiry==null?'Waqtiga uu dhacayo: ma xadidna':'Wuxuu dhacayaa: ${expiry!.year}-${expiry!.month.toString().padLeft(2,'0')}-${expiry!.day.toString().padLeft(2,'0')}'),trailing:const Icon(Icons.date_range),onTap:()async{final d=await showDatePicker(context:ctx,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:730)),initialDate:expiry??DateTime.now().add(const Duration(days:30)));if(d!=null)refresh(()=>expiry=d);}),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('KA NOQO')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('KAYDI'))]
    )));
    if(ok!=true)return;
    final pct=int.tryParse(discount.text.trim()),max=uses.text.trim().isEmpty?null:int.tryParse(uses.text.trim());
    if(code.text.trim().isEmpty||pct==null||pct<1||pct>100||(uses.text.trim().isNotEmpty&&(max==null||max<1))){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Hubi koodhka, boqolkiiba iyo tirada isticmaalka.')));return;}
    try{await SalonApi.createAdminCoupon(widget.token,{'code':code.text.trim(),'discountPercent':pct,'category':category,'maxUses':max,'expiresAt':expiry==null?null:DateTime(expiry!.year,expiry!.month,expiry!.day,23,59,59).toUtc().toIso8601String()});await load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('COUPONS IYO DHIMIS'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),floatingActionButton:FloatingActionButton.extended(onPressed:create,backgroundColor:green,foregroundColor:Colors.white,icon:const Icon(Icons.add),label:const Text('SAMEE COUPON')),body:loading?const Center(child:CircularProgressIndicator(color:green)):rows.isEmpty?const Center(child:Text('Weli coupon lama samayn.')):ListView(padding:const EdgeInsets.all(14),children:[
    const Text('Koodhadhka qiimo-dhimista. Macmiilku wuxuu geli karaa koodhka marka uu ballan salon qabsanayo.',style:TextStyle(color:Colors.black54)),
    ...rows.map((x){final active=x['active']==1||x['active']==true;return Card(child:ListTile(title:Text((x['code']??'').toString(),style:const TextStyle(fontWeight:FontWeight.bold,color:green)),subtitle:Text('${x['discount_percent']}% dhimista • ${x['category']} • La isticmaalay ${x['used_count']??0}/${x['max_uses']??'∞'}'),trailing:PopupMenuButton<String>(onSelected:(v)async{try{if(v=='toggle')await SalonApi.setAdminCouponActive(widget.token,x['id'].toString(),!active);if(v=='delete')await SalonApi.deleteAdminCoupon(widget.token,x['id'].toString());await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},itemBuilder:(_)=>[PopupMenuItem(value:'toggle',child:Text(active?'Dami':'Dib u daar')),const PopupMenuItem(value:'delete',child:Text('Tirtir'))])));}),
  ]));
}

class OwnerRevenuePage extends StatefulWidget {
  const OwnerRevenuePage({super.key,required this.token});
  final String token;
  @override
  State<OwnerRevenuePage> createState()=>_OwnerRevenuePageState();
}
class _OwnerRevenuePageState extends State<OwnerRevenuePage>{
  DateTime from=DateTime(DateTime.now().year,DateTime.now().month,1),to=DateTime.now();
  Map<String,dynamic>? report;
  bool loading=true;
  String? error;
  String date(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    if(mounted)setState(()=>{loading=true,error=null});
    try{final x=await SalonApi.ownerRevenue(widget.token,date(from),date(to));if(mounted)setState(()=>{report=x,loading=false});}
    catch(e){if(mounted)setState(()=>{error=e.toString(),loading=false});}
  }
  @override Widget build(BuildContext context){
    final totals=(report?['totals'] as List?)?.cast<Map<String,dynamic>>()??<Map<String,dynamic>>[];
    return Scaffold(appBar:AppBar(title:const Text('WARBIXINTA GANACSIGA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
      body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):ListView(padding:const EdgeInsets.all(14),children:[
        Card(child:ListTile(title:const Text('Muddada warbixinta'),subtitle:Text('${date(from)} ilaa ${date(to)}'),trailing:IconButton(icon:const Icon(Icons.date_range),onPressed:()async{final d=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime.now(),initialDateRange:DateTimeRange(start:from,end:to));if(d!=null){setState(()=>{from=d.start,to=d.end});load();}}))),
        const Text('DAKHLIGA LA DIIWAANGELIYEY',style:TextStyle(fontWeight:FontWeight.bold,color:green,fontSize:17)),
        if(totals.isEmpty)const Padding(padding:EdgeInsets.all(16),child:Text('Muddadan dakhli la diiwaangeliyey ma jiro.')),
        ...totals.map((x)=>Card(child:ListTile(leading:const Icon(Icons.payments,color:green),title:Text('${x['jobs']??0} adeeg oo dhammaaday'),trailing:Text('${x['total']??0} ${x['currency']??''}',style:const TextStyle(fontWeight:FontWeight.bold,color:green,fontSize:17))))),
        const Padding(padding:EdgeInsets.only(top:12),child:Text('Warbixintani waxay muujinaysaa dakhliga milkiiluhu gacantiisa ku diiwaangeliyey marka ballantu dhammaato. Ma aha lacag si toos ah app-ku u xaqiijiyey.',style:TextStyle(fontSize:12,color:Colors.black54))),
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
  Future<void> showOccupiedSlotMessage() async {
    if(!mounted)return;
    await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('BOOSKAN WAA LA KIRAYSTAY'),
      content:const Text('MACMIIL BOOSKAN WUU KIRAYSAN YAHAY FADLAN BOOS KALE DOORO AMA SUG INTAY MUDDADU KA DHAMAANAYSO KIRAYSTAHA BOOSKAN'),
      actions:[FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('HAGAAG'))],
    ));
  }
  Future<void> sendNow() async {
    final currentSlots=(data['slots'] as List?)?.cast<Map<String,dynamic>>()??<Map<String,dynamic>>[];
    final selected=currentSlots.where((x)=>(int.tryParse((x['slot']??0).toString())??-1)==slot).toList();
    if(selected.isEmpty||selected.first['occupied']==true){
      await showOccupiedSlotMessage();
      await load();
      return;
    }
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
        const Text('DOORO MID KA MID AH 6-DA BOOS',style:TextStyle(fontWeight:FontWeight.bold,color:green,fontSize:17)),
        const SizedBox(height:6),
        const Text('Boosaska la kiraystay waxay muujinayaan muddada ay ku egyihiin. Waxaad codsan kartaa booska marka uu xoroobo; bilowga muddadaada wuxuu noqonayaa marka Admin-ku xaqiijiyo lacagta.'),
        const SizedBox(height:10),
        ...slots.map((x){final n=int.tryParse((x['slot']??0).toString())??1;final busy=x['occupied']==true;return Card(child:RadioListTile<int>(value:n,groupValue:slot,onChanged:(v){if(busy){showOccupiedSlotMessage();return;}setState(()=>slot=v??1);},title:Text('BOOSKA $n',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(busy?'WAA LA KIRAYSTAY • Wuxuu dhacayaa: ${fmt(x['expiresAt'])}':'Waa bannaan yahay • Hadda ayaad codsan kartaa'),isThreeLine:busy));}),
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

class AdminRevenuePage extends StatefulWidget {
  const AdminRevenuePage({super.key,required this.token});
  final String token;
  @override
  State<AdminRevenuePage> createState()=>_AdminRevenuePageState();
}
class _AdminRevenuePageState extends State<AdminRevenuePage>{
  DateTime from=DateTime(DateTime.now().year,DateTime.now().month,1),to=DateTime.now();
  Map<String,dynamic>? report;bool loading=true;String? error;
  String date(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  @override void initState(){super.initState();load();}
  Future<void> load() async {setState(()=>{loading=true,error=null});try{final x=await SalonApi.adminRevenue(widget.token,date(from),date(to));if(mounted)setState(()=>{report=x,loading=false});}catch(e){if(mounted)setState(()=>{error=e.toString(),loading=false});}}
  @override Widget build(BuildContext context){final merchants=(report?['merchants'] as List?)?.cast<Map<String,dynamic>>()??[];final daily=(report?['daily'] as List?)?.cast<Map<String,dynamic>>()??[];return Scaffold(appBar:AppBar(title:const Text('DAKHLIGA MEHERADAHA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):ListView(padding:const EdgeInsets.all(14),children:[
    Card(child:ListTile(title:const Text('Muddada warbixinta'),subtitle:Text('${date(from)} ilaa ${date(to)}'),trailing:IconButton(icon:const Icon(Icons.date_range),onPressed:()async{final d=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime.now(),initialDateRange:DateTimeRange(start:from,end:to));if(d!=null){setState(()=>{from=d.start,to=d.end});load();}}))),
    const Text('WARBIXINTA MEHERAD KASTA',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
    if(merchants.isEmpty)const Padding(padding:EdgeInsets.all(16),child:Text('Weli dakhli la diiwaangeliyey ma jiro.')),
    ...merchants.map((m)=>Card(child:ListTile(title:Text((m['merchant_name']??'Meherad').toString(),style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${m['category']} • Adeegyo dhammaaday: ${m['completed_jobs']}'),trailing:Text('${m['total']} ${m['currency']}',style:const TextStyle(fontWeight:FontWeight.bold,color:green))))),
    const Divider(),const Text('DAKHLIGA MAALINLAHA AH',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
    ...daily.map((d)=>ListTile(dense:true,title:Text('${d['service_date']} • ${d['currency']}'),subtitle:Text('Adeegyo: ${d['jobs']}'),trailing:Text('${d['total']}'))),
    const Padding(padding:EdgeInsets.only(top:12),child:Text('Xogtan waxay ku salaysan tahay dakhliga uu milkiiluhu diiwaangeliyey marka adeeggu dhammaado. Ma aha lacag app-ku si toos ah u xaqiijiyey.',style:TextStyle(fontSize:12,color:Colors.black54))),
  ]));}
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
  int photoCount=0,photoLimit=10;
  bool loading=true;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    setState(()=>loading=true);
    try{final d=await SalonApi.ownerRentalInfo(widget.token);final rows=(d['items'] as List).cast<Map<String,dynamic>>();if(mounted)setState(()=>{items=rows.where((x)=>x['active']!=0&&x['active']!='0').toList(),photoCount=int.tryParse((d['photoCount']??0).toString())??0,photoLimit=int.tryParse((d['photoLimit']??10).toString())??10,loading=false});}
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
    floatingActionButton:FloatingActionButton.extended(onPressed:photoCount>=photoLimit?null:()=>edit(),backgroundColor:green,foregroundColor:Colors.white,icon:const Icon(Icons.add),label:const Text('KU DAR ALAAB')),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):ListView(padding:const EdgeInsets.all(14),children:[
      Text('SAWIRRADA MEHERADDA: $photoCount / $photoLimit',style:const TextStyle(color:green,fontWeight:FontWeight.bold,fontSize:16)),
      if(photoCount>=photoLimit)const Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text('Xadka sawirrada waa buuxsamay. La xiriir Admin-ka si uu kuu kordhiyo.',style:TextStyle(color:Colors.red,fontWeight:FontWeight.w600))),
      if(items.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('Weli alaab kiraysi lama gelin.')),
      ...items.map((p)=>Card(child:ListTile(
      leading:ClipRRect(borderRadius:BorderRadius.circular(8),child:salonImage((p['photoUrl']??'').toString(),fit:BoxFit.cover,fallback:const Icon(Icons.image,color:green))),
      title:Text((p['name']??'').toString(),style:const TextStyle(fontWeight:FontWeight.bold)),
      subtitle:Text((p['category']??'').toString()),
      trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')edit(p);if(v=='delete')remove(p);},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Wax ka beddel')),PopupMenuItem(value:'delete',child:Text('Ka saar'))])
    ))),
    ])
  );
}


class OwnerPaymentsPage extends StatefulWidget {
  const OwnerPaymentsPage({super.key,required this.token});
  final String token;
  @override
  State<OwnerPaymentsPage> createState()=>_OwnerPaymentsPageState();
}
class _OwnerPaymentsPageState extends State<OwnerPaymentsPage>{
  List<Map<String,dynamic>> payments=[];
  bool loading=true;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    setState(()=>loading=true);
    try{final rows=await SalonApi.ownerPayments(widget.token);if(mounted)setState(()=>{payments=rows,error=null,loading=false});}
    catch(e){if(mounted)setState(()=>{error=e.toString(),loading=false});}
  }
  Future<void> review(Map<String,dynamic> p,String status) async {
    try{await SalonApi.reviewOwnerPayment(widget.token,p['id'].toString(),status);await load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('CODSIYADA LACAG-BIXINTA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):payments.isEmpty?const Center(child:Text('Weli codsi lacag-bixin ma jiro.')):ListView(padding:const EdgeInsets.all(14),children:payments.map((p){
      Map<String,dynamic> d={};try{d=jsonDecode((p['details_json']??'{}').toString()) as Map<String,dynamic>;}catch(_){}
      return Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text((p['customer_name']??'Macmiil').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
        Text('Alaab: ${d['itemName']??d['rentalItemName']??d['rentalItemId']??p['category']??''}'),
        Text('Qiimaha: ${p['amount']} ${p['currency']}'),
        Text('Habka lacagta: ${p['provider']}'),
        Text('Lambarka lacagta laga diray: ${p['sender_phone']}'),
        Text('Telefoonka macmiilka: ${p['customer_phone']}'),
        Text('Xaaladda: ${p['status']}',style:const TextStyle(fontWeight:FontWeight.w600)),
        if(p['status']=='Sugaya xaqiijin')Wrap(spacing:8,children:[
          FilledButton(onPressed:()=>review(p,'La xaqiijiyey'),style:FilledButton.styleFrom(backgroundColor:green),child:const Text('XAQIIJI LACAGTA')),
          OutlinedButton(onPressed:()=>review(p,'Lama xaqiijin'),child:const Text('DIID')),
        ]),
        if(p['status']=='La xaqiijiyey')const Text('LA XAQIIJIYEY',style:TextStyle(color:green,fontWeight:FontWeight.bold)),
      ])));
    }).toList())
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
  String filter='DHAMMAAN';
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    if(mounted)setState(()=>loading=true);
    try{final rows=await SalonApi.ownerBookings(widget.token);if(mounted)setState(()=>{bookings=rows,error=null,loading=false});}
    catch(e){if(mounted)setState(()=>{error=e.toString(),loading=false});}
  }
  List<Map<String,dynamic>> get visibleBookings {
    final statuses=switch(filter){
      'SUGAYA'=>['Sugaya jawaab'],
      'LA AQBALAY'=>['La aqbalay'],
      'LA DHAMMEEYEY'=>['La dhammeeyey','COMPLETED'],
      'LA DIIDAY'=>['Lama heli karo'],
      _=>null,
    };
    if(statuses==null)return bookings;
    return bookings.where((b)=>statuses.contains((b['status']??'').toString())).toList();
  }
  Future<void> recordIncome(Map<String,dynamic> booking) async {
    final amount=TextEditingController();
    String currency='USD';
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(
      title:const Text('DIIWAANGELI DAKHLIGA'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Lacagta aad dhab ahaan heshay')),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:currency,items:const [DropdownMenuItem(value:'USD',child:Text('USD')),DropdownMenuItem(value:'SLSH',child:Text('SLSH'))],onChanged:(v)=>setDialog(()=>currency=v??'USD'),decoration:const InputDecoration(labelText:'Lacagta')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('JOOJI')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('KAYDI'))],
    )));
    if(ok!=true){amount.dispose();return;}
    final n=double.tryParse(amount.text.trim());amount.dispose();
    if(n==null||n<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Geli lacag sax ah.')));return;}
    try{await SalonApi.recordRevenue(widget.token,{'bookingId':booking['id'],'amount':n,'currency':currency,'serviceDate':DateTime.now().toIso8601String().substring(0,10)});await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Adeegga waa la dhammeeyey, dakhliga iyo taariikhdana waa la kaydiyey.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> review(Map<String,dynamic> booking,String status) async {
    try{await SalonApi.updateBookingStatus(widget.token,booking['id'].toString(),status);await load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('BALLAMAHA SALON-KA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):Column(children:[
      SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),child:Row(children:[
        for(final label in ['DHAMMAAN','SUGAYA','LA AQBALAY','LA DHAMMEEYEY','LA DIIDAY'])
          Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(label:Text(label),selected:filter==label,onSelected:(_)=>setState(()=>filter=label)))
      ])),
      Expanded(child:visibleBookings.isEmpty?Center(child:Text(filter=='DHAMMAAN'?'Weli ballamo ma jiraan.':'Qaybtan wax ballamo ah kuma jiraan.')):ListView(padding:const EdgeInsets.fromLTRB(14,2,14,14),children:visibleBookings.map((b){
        Map<String,dynamic> d={};try{d=jsonDecode((b['details_json']??'{}').toString()) as Map<String,dynamic>;}catch(_){}
        final status=(b['status']??'Sugaya jawaab').toString();
        return Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Expanded(child:Text((b['customer_name']??'Macmiil').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16))),Text(status,style:const TextStyle(fontWeight:FontWeight.w700,color:green))]),
          Text('Adeeg: '+(d['service']??d['itemName']??'').toString()),
          if((d['staffName']??'').toString().isNotEmpty)Text('Gabadha: '+d['staffName'].toString(),style:const TextStyle(color:green,fontWeight:FontWeight.bold)),
          Text('Taariikh: '+(d['date']??d['deliveryDate']??'').toString()+' • Waqti: '+(d['time']??d['deliveryTime']??'').toString()),
          Text('Telefoon: '+(b['customer_phone']??'').toString()),
          if((b['owner_reply']??'').toString().isNotEmpty)Text('Jawaab: '+b['owner_reply'].toString()),
          if(status=='La aqbalay')Padding(padding:const EdgeInsets.only(top:8),child:SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>recordIncome(b),icon:const Icon(Icons.point_of_sale),label:const Text('ADEEGGA DHAMMEE • DIIWAANGELI DAKHLIGA'),style:FilledButton.styleFrom(backgroundColor:green,foregroundColor:Colors.white)))),
          if(status=='Sugaya jawaab')Row(children:[
            Expanded(child:OutlinedButton(onPressed:()=>review(b,'Lama heli karo'),child:const Text('DIID'))),
            const SizedBox(width:8),
            Expanded(child:FilledButton(onPressed:()=>review(b,'La aqbalay'),style:FilledButton.styleFrom(backgroundColor:green),child:const Text('AQBAL')))
          ])
        ])));
      }).toList()))
    ])
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
    Map<String,dynamic> details={};
    try{details=jsonDecode((order['details_json']??'{}').toString()) as Map<String,dynamic>;}catch(_){}
    final amount=TextEditingController(text:(details['itemPrice']??details['price']??'').toString());
    final merchantId=(order['merchant_id']??'').toString();
    if(merchantId.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Meheradda dalabkan lama aqoonsan.')));return;}
    Map<String,dynamic> config;
    try{config=await SalonApi.paymentConfig(merchantId);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));return;}
    final methods=(config['methods'] as List?)?.cast<Map<String,dynamic>>()??<Map<String,dynamic>>[];
    if(methods.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Meheraddu weli ma dejin lambarrada lacagta. La xiriir meheradda.')));return;}
    String provider=(methods.first['provider']??'Telesom').toString();
    String currency=(details['currency']??methods.first['currency']??'USD').toString();
    String recipient=methods.first['recipient_number']?.toString()??'';
    final id=(order['id']??'').toString();
    final p=await SharedPreferences.getInstance();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh){
      final available=methods.where((m)=>m['provider']==provider).toList();
      if(available.isNotEmpty&&!available.any((m)=>m['currency']==currency)){currency=available.first['currency'].toString();}
      final selected=methods.where((m)=>m['provider']==provider&&m['currency']==currency).toList();
      recipient=selected.isEmpty?'':(selected.first['recipient_number']??'').toString();
      return AlertDialog(
        title:const Text('DIR LACAGTA MEHERADDA'),
        content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Text('U dir lacagta lambarka meheradda ee hoose. Kadib geli lambarka aad lacagta ka dirtay.'),
          DropdownButtonFormField<String>(value:provider,decoration:const InputDecoration(labelText:'Habka lacagta'),items:methods.map((m)=>m['provider'].toString()).toSet().map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>provider=v??provider)),
          DropdownButtonFormField<String>(value:currency,decoration:const InputDecoration(labelText:'Lacagta'),items:available.map((m)=>m['currency'].toString()).toSet().map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>currency=v??currency)),
          Container(width:double.infinity,margin:const EdgeInsets.symmetric(vertical:10),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:green.withOpacity(.08),borderRadius:BorderRadius.circular(10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('LAMBARKA LACAGTA MEHERADDA',style:TextStyle(fontSize:11,fontWeight:FontWeight.bold)),SelectableText(recipient.isEmpty?'Lambar lama hayo':recipient,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:green))])),
          TextField(controller:sender,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Number-ka aad lacagta ka dirtay')),
          TextField(controller:amount,readOnly:true,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Qiimaha alaabta (lama beddeli karo)')),
        ])),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('DIR CODSIGA'))]
      );
    }));
    if(ok!=true||!mounted)return;
    final v=double.tryParse(amount.text.trim());
    if(sender.text.trim().length<7||v==null||v<=0||recipient.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Hubi lambarka meheradda, lambarka aad ka dirtay iyo qadarka.')));return;}
    try{await SalonApi.submitPayment(id,p.getString('customer_phone')??'',provider,sender.text.trim(),v,currency);await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Codsiga lacagta waa la diray. Milkiilaha meheradda ayaa hubinaya.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  String status(Map<String,dynamic> o)=>(o['status']??'Sugaya jawaab').toString();
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('BALLAMAHAYGA IYO DALABYADAYDA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):orders.isEmpty?const Center(child:Text('Weli dalab ma lihid.')):ListView(padding:const EdgeInsets.all(14),children:[
      ...orders.where((o){
        if((o['category']??'').toString()!='SALON'||!['Sugaya jawaab','La aqbalay'].contains(status(o)))return false;
        try{final d=jsonDecode((o['details_json']??'{}').toString()) as Map<String,dynamic>;final date=(d['appointmentDate']??d['date']??'').toString();final time=(d['appointmentTime']??d['time']??'').toString();if(date.isEmpty||time.isEmpty)return false;final at=DateTime.parse('${date}T${time}:00');final left=at.difference(DateTime.now());return !left.isNegative&&left<=const Duration(hours:24);}catch(_){return false;}
      }).map((o){
        Map<String,dynamic> d={};try{d=jsonDecode((o['details_json']??'{}').toString()) as Map<String,dynamic>;}catch(_){}
        return Card(color:cream,child:ListTile(leading:const Icon(Icons.notifications_active,color:green,size:30),title:const Text('XUSUUSIN BALLAN',style:TextStyle(fontWeight:FontWeight.bold,color:green)),subtitle:Text('${d['service']??'Adeeg salon'} • ${d['appointmentDate']??d['date']??''} • ${d['appointmentTime']??d['time']??''}'),));
      }),
      ...orders.map((o){
        Map<String,dynamic> details={};try{details=jsonDecode((o['details_json']??'{}').toString()) as Map<String,dynamic>;}catch(_){}
        final st=status(o),payment=(o['payment_status']??'').toString();
        return Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text((o['category']??'DALAB').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17,color:green)),
          if((o['merchant_name']??'').toString().isNotEmpty)Text('Meherad: ${o['merchant_name']}'),
          if((o['category']??'').toString()=='SALON')...[
            if((details['service']??'').toString().isNotEmpty)Text('Adeegga: ${details['service']}'),
            if((details['appointmentDate']??details['date']??'').toString().isNotEmpty)Text('Taariikhda ballanta: ${details['appointmentDate']??details['date']}'),
            if((details['appointmentTime']??details['time']??'').toString().isNotEmpty)Text('Saacadda: ${details['appointmentTime']??details['time']}'),
            if((details['staffName']??'').toString().isNotEmpty)Text('Shaqaalaha aad dooratay: ${details['staffName']}'),
            if((details['notes']??'').toString().isNotEmpty)Text('Faahfaahin: ${details['notes']}'),
          ] else if(details.isNotEmpty)Text(details.entries.map((e)=>'${e.key}: ${e.value}').join(' • ')),
          const SizedBox(height:5),Text('Xaaladda dalabka: $st',style:const TextStyle(fontWeight:FontWeight.w600)),
          if(payment.isNotEmpty)Text('Xaaladda lacagta: $payment'),
          if((st=='La aqbalay'||(o['category']=='KIRAYSO'&&st=='Sugaya lacag-bixin')||payment=='Lama xaqiijin')&&payment!='Sugaya xaqiijin'&&st!='PURCHASED')Padding(padding:const EdgeInsets.only(top:8),child:SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>pay(o),style:FilledButton.styleFrom(backgroundColor:green),child:const Text('DIR LACAGTA')))),
          if(payment=='Sugaya xaqiijin')const Text('Milkiilaha meheradda ayaa hubinaya lacagtaada.',style:TextStyle(color:Colors.orange)),
          if(st=='PURCHASED')const Text('Dalabka waa la iibsaday, lacagtiisana waa la xaqiijiyey.',style:TextStyle(color:green,fontWeight:FontWeight.bold)),
        ])));
      })
    ])
  );
}

class HallAroosPage extends StatefulWidget {
  const HallAroosPage({super.key,this.adminToken});
  final String? adminToken;
  @override
  State<HallAroosPage> createState()=>_HallAroosPageState();
}
class _HallAroosPageState extends State<HallAroosPage>{
  bool loading=true;
  String? error;
  List<Map<String,dynamic>> halls=[];
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    if(mounted)setState(()=>{loading=true,error=null});
    try{
      final all=await SalonApi.featuredProducts();
      final rows=all.where((p)=>(p['category']??'').toString()=='HALL AROOS'&&p['title']!='__CATEGORY_IMAGE__').toList();
      if(mounted)setState(()=>{halls=rows,loading=false});
    }catch(e){if(mounted)setState(()=>{error=e.toString(),loading=false});}
  }
  Future<void> manage({Map<String,dynamic>? hall}) async {
    final token=widget.adminToken;
    if(token==null||token.isEmpty)return;
    final name=TextEditingController(text:(hall?['title']??'').toString());
    final desc=TextEditingController(text:(hall?['description']??'').toString());
    final existing=(hall?['image_url']??'').toString();
    final url=TextEditingController(text:existing.startsWith('https://')?existing:'');
    String? image=existing.isNotEmpty?existing:null;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:Text(hall==null?'KU DAR HALL AROOS':'WAX KA BEDDEL HALL'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Magaca Hall-ka')),
        TextField(controller:desc,maxLines:3,decoration:const InputDecoration(labelText:'Faahfaahin / goobta (ikhtiyaari)')),
        const SizedBox(height:10),
        SizedBox(height:150,width:double.infinity,child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Container(color:cream,child:salonImage(image,fit:BoxFit.cover,fallback:const Icon(Icons.church_outlined,size:45,color:green))))),
        OutlinedButton.icon(onPressed:()async{try{final v=await pickSalonImage();if(v!=null)refresh(()=>image=v);}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(e.toString())));}},icon:const Icon(Icons.photo_library),label:const Text('DOORO SAWIRKA HALL-KA')),
        TextField(controller:url,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'Ama geli HTTPS image URL'),onChanged:(v){if(v.trim().startsWith('https://'))refresh(()=>image=v.trim());}),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('KA NOQO')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('KAYDI'))],
    )));
    if(ok!=true||!mounted)return;
    if(name.text.trim().isEmpty||image==null||image!.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Magaca Hall-ka iyo sawirkiisa waa waajib.')));return;}
    if(!image!.startsWith('data:image/')&&!image!.startsWith('https://')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Sawir sax ah dooro.')));return;}
    final payload={'title':name.text.trim(),'description':desc.text.trim(),'price':'','currency':'USD','category':'HALL AROOS','imageUrl':image};
    try{
      if(hall==null){await SalonApi.addFeaturedProduct(token,payload);}
      else{await SalonApi.updateFeaturedProduct(token,(hall['id']??'').toString(),payload);}
      await load();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(hall==null?'Hall-ka waa lagu daray.':'Hall-ka waa la cusboonaysiiyey.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Kaydintu way fashilantay: $e')));}
  }
  Future<void> remove(Map<String,dynamic> hall) async {
    final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Tirtir Hall-kan?'),content:Text((hall['title']??'Hall').toString()),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('MAYA')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('TIRTIR'))]));
    if(yes!=true||!mounted)return;
    try{await SalonApi.deleteFeaturedProduct(widget.adminToken!,(hall['id']??'').toString());await load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Tirtiriddu way fashilantay: $e')));}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('HALL AROOS'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    floatingActionButton:widget.adminToken!=null?FloatingActionButton.extended(backgroundColor:green,foregroundColor:Colors.white,onPressed:()=>manage(),icon:const Icon(Icons.add),label:const Text('KU DAR HALL')):null,
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!,textAlign:TextAlign.center),TextButton(onPressed:load,child:const Text('DIB U CUSBOONAYSII'))])):halls.isEmpty?const Center(child:Text('Weli HALL AROOS lama soo gelin.')):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(14),children:[
      Text('HALLS-KA AROOSKA — ${halls.length}',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold,color:green)),
      const SizedBox(height:10),
      ...halls.map((h)=>InkWell(
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>HallWelcomePage(hallName:(h['title']??'HALL AROOS').toString(),imageUrl:(h['image_url']??'').toString(),description:(h['description']??'').toString()))),
        borderRadius:BorderRadius.circular(14),
        child:Card(clipBehavior:Clip.antiAlias,margin:const EdgeInsets.only(bottom:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        SizedBox(width:double.infinity,height:205,child:salonImage((h['image_url']??'').toString(),fit:BoxFit.cover,fallback:Container(color:cream,child:const Icon(Icons.church_outlined,size:50,color:green)))),
        Padding(padding:const EdgeInsets.fromLTRB(14,12,14,14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text((h['title']??'HALL AROOS').toString(),style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:green)),
          if((h['description']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:5),child:Text(h['description'].toString())),
          if(widget.adminToken!=null)Row(mainAxisAlignment:MainAxisAlignment.end,children:[
            TextButton.icon(onPressed:()=>manage(hall:h),icon:const Icon(Icons.edit),label:const Text('BEDDEL')),
            TextButton.icon(onPressed:()=>remove(h),icon:const Icon(Icons.delete_outline,color:Colors.red),label:const Text('TIRTIR',style:TextStyle(color:Colors.red))),
          ])
        ]))
      ]))))
    ])),
  );
}

class HallWelcomePage extends StatefulWidget {
  const HallWelcomePage({super.key,required this.hallName,required this.imageUrl,this.description='' });
  final String hallName,imageUrl,description;
  @override
  State<HallWelcomePage> createState()=>_HallWelcomePageState();
}
class _HallWelcomePageState extends State<HallWelcomePage>{
  final name=TextEditingController(),phone=TextEditingController(),whatsapp=TextEditingController(),event=TextEditingController(),notes=TextEditingController();
  DateTime? eventDate;
  bool sending=false;
  @override
  void dispose(){name.dispose();phone.dispose();whatsapp.dispose();event.dispose();notes.dispose();super.dispose();}
  Future<void> submit() async {
    if(name.text.trim().isEmpty||phoneDigits(phone.text).length<7||eventDate==null){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Geli magaca, telefoon sax ah iyo taariikhda xafladda.')));return;
    }
    setState(()=>sending=true);
    try{
      await SalonApi.createBooking(category:'HALL AROOS',customerName:name.text.trim(),customerPhone:phoneDigits(phone.text),customerWhatsApp:whatsapp.text.trim().isEmpty?phoneDigits(phone.text):phoneDigits(whatsapp.text),details:{'hallName':widget.hallName,'eventType':event.text.trim(),'eventDate':eventDate!.toIso8601String().split('T').first,'notes':notes.text.trim()});
      if(!mounted)return;
      await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:const Text('CODSIGA WAA LA DIRAY'),content:const Text('Mahadsanid. Codsigaaga HALL AROOS waa la diray. Fadlan sug inta lagaa soo jawaabayo.'),actions:[FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('HAGAAG'))]));
      if(mounted)Navigator.pop(context);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Codsiga lama dirin: $e')));}
    finally{if(mounted)setState(()=>sending=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.hallName),backgroundColor:green,foregroundColor:Colors.white),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      ClipRRect(borderRadius:BorderRadius.circular(16),child:SizedBox(height:190,child:salonImage(widget.imageUrl,fit:BoxFit.cover,fallback:Container(color:cream,child:const Icon(Icons.church_outlined,size:55,color:green))))),
      const SizedBox(height:18),
      Text('MACMIIL KUSOO DHAWOOW ${widget.hallName.toUpperCase()}',textAlign:TextAlign.center,style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold,color:green)),
      const SizedBox(height:12),
      const Text('WAAN KAAGA MAHAD-CELINAYNAA DOORASHADAADA',textAlign:TextAlign.center,style:TextStyle(fontSize:16,fontWeight:FontWeight.w600)),
      const SizedBox(height:10),
      const Text('FADLAN QABSO BALLAN SI AANU KUUGU QURXINO XAFLADAADA',textAlign:TextAlign.center,style:TextStyle(fontSize:15,color:Colors.black87)),
      if(widget.description.trim().isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(widget.description,textAlign:TextAlign.center)),
      const Divider(height:30),
      const Text('DIWAANGELI CODSIGAAGA',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:green)),
      const SizedBox(height:10),
      TextField(controller:name,decoration:const InputDecoration(labelText:'Magaca macmiilka',border:OutlineInputBorder())),
      const SizedBox(height:10),
      TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Lambarka telefoonka',border:OutlineInputBorder())),
      const SizedBox(height:10),
      TextField(controller:whatsapp,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'WhatsApp (ikhtiyaari)',border:OutlineInputBorder())),
      const SizedBox(height:10),
      TextField(controller:event,decoration:const InputDecoration(labelText:'Nooca xafladda (ikhtiyaari)',border:OutlineInputBorder())),
      const SizedBox(height:10),
      OutlinedButton.icon(onPressed:()=>showDatePicker(context:context,initialDate:DateTime.now().add(const Duration(days:7)),firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:730))).then((d){if(d!=null&&mounted)setState(()=>eventDate=d);}),icon:const Icon(Icons.calendar_month),label:Text(eventDate==null?'DOORO TAARIIKHDA XAFLADDA':'Taariikhda: ${eventDate!.day}/${eventDate!.month}/${eventDate!.year}')),
      const SizedBox(height:10),
      TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'Faahfaahin dheeraad ah (ikhtiyaari)',border:OutlineInputBorder())),
      const SizedBox(height:18),
      SizedBox(width:double.infinity,child:FilledButton(onPressed:sending?null:submit,style:FilledButton.styleFrom(backgroundColor:green,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(vertical:15)),child:sending?const CircularProgressIndicator(color:Colors.white):const Text('DIR CODSIGA'))),
    ]),
  );
}

class AdminStoragePage extends StatefulWidget {
  const AdminStoragePage({super.key,required this.token});
  final String token;
  @override
  State<AdminStoragePage> createState()=>_AdminStoragePageState();
}
class _AdminStoragePageState extends State<AdminStoragePage>{
  Map<String,dynamic>? data;
  bool loading=true;
  String? error;
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    setState(()=>{loading=true,error=null});
    try{final x=await SalonApi.adminStorage(widget.token);if(mounted)setState(()=>{data=x,loading=false});}
    catch(e){if(mounted)setState(()=>{error=e.toString(),loading=false});}
  }
  String sizeText(dynamic value){
    final n=(value as num?)?.toDouble()??0;
    if(n<1024)return '${n.toStringAsFixed(0)} B';
    if(n<1024*1024)return '${(n/1024).toStringAsFixed(1)} KB';
    if(n<1024*1024*1024)return '${(n/1024/1024).toStringAsFixed(2)} MB';
    return '${(n/1024/1024/1024).toStringAsFixed(2)} GB';
  }
  double ratio(dynamic used,dynamic limit){
    final u=(used as num?)?.toDouble()??0,l=(limit as num?)?.toDouble()??0;
    if(l<=0)return 0;
    return (u/l).clamp(0.0,1.0);
  }
  Widget progressCard({required String title,required String used,required String limit,required double value,required String note,IconData icon=Icons.storage}){
    final percent=(value*100).toStringAsFixed(2);
    final color=value>=.9?Colors.red:value>=.7?Colors.orange:green;
    return Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(icon,color:green,size:27),const SizedBox(width:10),Expanded(child:Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)))]),
      const SizedBox(height:10),
      Text('La isticmaalay: $used',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700)),
      Text('Xadka la barbar dhigayo: $limit',style:const TextStyle(color:Colors.black54,fontSize:12)),
      const SizedBox(height:9),
      ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:value,minHeight:11,color:color,backgroundColor:cream)),
      const SizedBox(height:5),
      Text('$percent% — $note',style:TextStyle(color:color,fontWeight:FontWeight.w600,fontSize:12)),
    ])));
  }
  Widget metric(String title,String value,IconData icon)=>Card(child:ListTile(leading:Icon(icon,color:green,size:28),title:Text(title),subtitle:Text(value,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))));
  @override
  Widget build(BuildContext context){
    final d1=data?['d1'] as Map<String,dynamic>?;
    final r2=data?['r2'] as Map<String,dynamic>?;
    final d1Storage=d1?['storage'] as Map<String,dynamic>?;
    final tables=(d1?['tables'] as List? ?? const []).cast<Map<String,dynamic>>();
    final groups=(r2?['groups'] as List? ?? const []).cast<Map<String,dynamic>>();
    final d1Bytes=d1Storage?['bytes'];
    final d1Free=(d1Storage?['freeLimitBytes'] as num?)?.toDouble()??(500*1024*1024).toDouble();
    final d1Paid=(d1Storage?['paidLimitBytes'] as num?)?.toDouble()??(10*1024*1024*1024).toDouble();
    final r2Bytes=(r2?['bytes'] as num?)?.toDouble()??0;
    final r2Allowance=(r2?['freeMonthlyAllowanceBytes'] as num?)?.toDouble()??(10*1024*1024*1024).toDouble();
    final records=tables.fold<int>(0,(n,t)=>n+((t['count'] as num?)?.toInt()??0));
    return Scaffold(
      appBar:AppBar(title:const Text('MAAMULKA STORAGE-KA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh),tooltip:'Cusboonaysii')]),
      body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!,textAlign:TextAlign.center),const SizedBox(height:12),FilledButton(onPressed:load,child:const Text('DIB U CUSBOONAYSII'))]))):RefreshIndicator(
        onRefresh:load,child:ListView(padding:const EdgeInsets.all(14),children:[
          const Text('KAYDKA APP-KA OO DHAN',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold,color:green)),
          const SizedBox(height:8),
          metric('Cloudflare D1 — Database','${tables.length} jadwal • $records diiwaan',Icons.storage),
          if(d1Bytes is num)progressCard(title:'D1 — Cabbirka xogta database-ka',used:sizeText(d1Bytes),limit:'500 MB (Free) / 10 GB (Paid)',value:ratio(d1Bytes,d1Free),note:'Boqolleydu waxay barbar dhigaysaa xadka Free. Xadka saxda ahi wuxuu ku xiran yahay qorshaha Cloudflare.',icon:Icons.table_chart)
          else const Card(child:ListTile(leading:Icon(Icons.info_outline,color:Colors.orange),title:Text('Cabbirka D1 lama heli karin'),subtitle:Text('Tirada diiwaannada waa la helay, balse cabbirka database-ka lama soo celin server-ka.'))),
          const SizedBox(height:4),
          const Text('R2 — KAYDKA SAWIRRADA',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold,color:green)),
          metric('Cloudflare R2 — Sawirrada oo dhan','${r2?['objects']??0} fayl • ${sizeText(r2?['bytes'])}',Icons.photo_library),
          progressCard(title:'R2 — Isticmaalka hadda',used:sizeText(r2Bytes),limit:'10 GB-month gunno bille ah (Free)',value:ratio(r2Bytes,r2Allowance),note:'R2 ma laha xad kayd oo adag. 10 GB-month waa gunno bilaash ah oo bille ah, mana aha meel kaydku ku istaagayo.',icon:Icons.cloud_queue),
          const SizedBox(height:12),
          const Text('KAYDKA MEHERADAHA IYO ADMIN-KA',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold,color:green)),
          ...groups.map((g)=>Card(child:ListTile(leading:const Icon(Icons.folder,color:green),title:Text(g['name']?.toString()??'Kayd kale'),subtitle:Text('${g['objects']??0} fayl'),trailing:Text(sizeText(g['bytes']),style:const TextStyle(fontWeight:FontWeight.bold))))),
          const SizedBox(height:12),
          const Text('D1 — JADWALLADA XOGTA',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold,color:green)),
          ...tables.map((t)=>Card(child:ListTile(dense:true,leading:const Icon(Icons.table_chart,color:green),title:Text(t['name'].toString()),trailing:Text('${t['count']??0} diiwaan',style:const TextStyle(fontWeight:FontWeight.bold))))),
          const SizedBox(height:12),
          const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('OGEYSIIS: D1 Free wuxuu leeyahay 500 MB database kasta; Paid wuxuu gaari karaa 10 GB database kasta. R2-na waa kayd aan lahayn xad adag, balse qorshaha Free wuxuu leeyahay 10 GB-month gunno bille ah. Boqolleyda kore waa isbarbardhig, mana aha xisaab biil bille ah.'))),
          const Text('Kaydka gudaha telefoon kasta (Local Storage) meel fog lagama cabbiri karo.',style:TextStyle(color:Colors.black54,fontSize:12)),
          if(data?['measuredAt']!=null)Text('La cusboonaysiiyey: ${data!['measuredAt']}',style:const TextStyle(color:Colors.black45,fontSize:11)),
        ]),
      ),
    );
  }
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
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('LA SOCODKA LACAG-BIXINTA'),backgroundColor:green,foregroundColor:Colors.white,actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator(color:green)):error!=null?Center(child:Text(error!)):payments.isEmpty?const Center(child:Text('Weli codsi lacag-bixin ma jiro.')):ListView(padding:const EdgeInsets.all(14),children:[
      const Padding(padding:EdgeInsets.only(bottom:10),child:Text('Admin-ku wuxuu kaliya la socdaa codsiyada. Milkiilaha meheradda ayaa xaqiijiya ama diida lacagta.',style:TextStyle(color:Colors.black54))),
      ...payments.map((p)=>Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text((p['customer_name']??'Macmiil').toString(),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
        Text('Meherad: ${p['merchant_name']??'—'}'),
        Text('Dalab: ${p['category']??''}'),
        Text('Habka: ${p['provider']} • Lacag: ${p['amount']} ${p['currency']}'),
        Text('Lambarka laga diray: ${p['sender_phone']}'),
        Text('Lambarka macmiilka: ${p['customer_phone']}'),
        Text('Xaaladda: ${p['status']}'),
        if(p['status']=='La xaqiijiyey')const Text('LA XAQIIJIYEY',style:TextStyle(color:green,fontWeight:FontWeight.bold)),
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
  Future<void> editPhotoLimit(Map<String,dynamic> merchant) async {
    final c=TextEditingController(text:(merchant['photo_limit']??10).toString());
    final value=await showDialog<int>(context:context,builder:(ctx)=>AlertDialog(
      title:Text('Xadka sawirrada — ${merchant['name']}'),
      content:TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Tirada sawirrada ugu badan (shaqaale + alaabta kirada)',border:OutlineInputBorder())),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,int.tryParse(c.text.trim())),child:const Text('Kaydi'))]));
    if(value==null)return;
    if(value<1||value>200){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Xadka sawirradu waa inuu u dhexeeyaa 1 ilaa 200.')));return;}
    try{await SalonApi.updatePhotoLimit(widget.token,merchant['id'].toString(),value);await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Xadka sawirrada meheradda waa la beddelay.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
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
      const Text('Lambarrada Telesom iyo Somtel waxaa Admin-ku geliyaa marka meheradda la diiwaangelinayo. Kadibna milkiilaha meheradda ayaa xaqiijiya lacagaha.',style:TextStyle(color:Colors.black54)),
      ...merchants.map((m)=>Card(child:ListTile(title:Text((m['name']??'Meherad').toString()),subtitle:Text('${m['category']??''} • Sawirro: ${m['photo_limit']??10} ugu badnaan'),trailing:IconButton(tooltip:'Xadka sawirrada',onPressed:()=>editPhotoLimit(m),icon:const Icon(Icons.photo_library_outlined,color:green))))),
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

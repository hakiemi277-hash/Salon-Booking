import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const SalonBookingApp());
const green = Color(0xFF173F35);
const pink = Color(0xFFF7C8D8);

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
}

class SalonBookingApp extends StatelessWidget {
  const SalonBookingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'SALON BOOKING',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: green), scaffoldBackgroundColor: pink),
    home: const RegistrationGate());
}
class Salon {
  Salon(this.name, this.location, this.services, {this.whatsappNumber = ''});
  String name, location, whatsappNumber;
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

  String? adminToken;
  List<Map<String,dynamic>> featured=[];
  bool featuredLoading=true;
  int featuredPage=0;
  final PageController featuredController=PageController(viewportFraction:.84);
  Timer? featuredTimer;
  @override
  void initState(){
    super.initState(); loadFeatured();
    featuredTimer=Timer.periodic(const Duration(seconds:3),(_){
      if(!mounted||featured.length<2||!featuredController.hasClients)return;
      featuredPage=(featuredPage+1)%featured.length;
      featuredController.animateToPage(featuredPage,duration:const Duration(milliseconds:550),curve:Curves.easeInOut);
    });
  }
  @override
  void dispose(){featuredTimer?.cancel();featuredController.dispose();super.dispose();}
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
    final c=TextEditingController(text:categoryImageUrls[category]??'');
    final url=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(
      title:Text('Sawirka $category'),
      content:TextField(controller:c,keyboardType:TextInputType.url,decoration:const InputDecoration(
        labelText:'HTTPS image URL',hintText:'https://...'),),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Ka noqo')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,c.text.trim()),child:const Text('Kaydi')),
      ],
    ));
    if(url==null||url.isEmpty||!url.startsWith('https://')||!mounted)return;
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
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('Ku dar ALAAB CUSUB'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Magaca alaabta')),
        TextField(controller:desc,maxLines:2,decoration:const InputDecoration(labelText:'Faahfaahin')),
        TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Qiimaha (ikhtiyaari)')),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Qaybta'),items:['SALON','CAKES','DECORATION','KIRAYSO'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>category=v??'SALON')),
        DropdownButtonFormField<String>(value:currency,decoration:const InputDecoration(labelText:'Lacagta'),items:['USD','SLSH'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>currency=v??'USD')),
        TextField(controller:img,decoration:const InputDecoration(labelText:'Sawirka HTTPS URL')),
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydi'))])));
    if(ok!=true||title.text.trim().isEmpty||!mounted)return;
    try{await SalonApi.addFeaturedProduct(adminToken!,{'title':title.text.trim(),'description':desc.text.trim(),'price':price.text.trim(),'currency':currency,'category':category,'imageUrl':img.text.trim()});await loadFeatured();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Alaabta waa la daabacay.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> editFeatured(Map<String,dynamic> p) async {
    final title=TextEditingController(text:(p['title']??'').toString());
    final desc=TextEditingController(text:(p['description']??'').toString());
    final price=TextEditingController(text:(p['price']??'').toString());
    final img=TextEditingController(text:(p['image_url']??'').toString());
    String category=(p['category']??'SALON').toString(),currency=(p['currency']??'USD').toString();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('Wax ka beddel alaabta'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Magaca alaabta')),
        TextField(controller:desc,maxLines:2,decoration:const InputDecoration(labelText:'Faahfaahin')),
        TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Qiimaha')),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Qaybta'),items:['SALON','CAKES','DECORATION','KIRAYSO'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>category=v??'SALON')),
        DropdownButtonFormField<String>(value:currency,decoration:const InputDecoration(labelText:'Lacagta'),items:['USD','SLSH'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>refresh(()=>currency=v??'USD')),
        TextField(controller:img,decoration:const InputDecoration(labelText:'Sawirka HTTPS URL')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Ka noqo')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydi'))])));
    if(ok!=true||title.text.trim().isEmpty||!mounted)return;
    try{
      await SalonApi.updateFeaturedProduct(adminToken!,p['id'].toString(),{'title':title.text.trim(),'description':desc.text.trim(),'price':price.text.trim(),'currency':currency,'category':category,'imageUrl':img.text.trim()});
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
          SizedBox(width:112,height:180,child:(p['image_url']??'').toString().isNotEmpty?Image.network(p['image_url'],fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(color:pink,child:const Icon(Icons.shopping_bag,color:green,size:36))):Container(color:pink,child:const Icon(Icons.shopping_bag,color:green,size:36))),
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
  final List<Salon> salons = List.generate(20, (i) => Salon('Salon ' + (i + 1).toString(), 'Hargeysa',
    ['Timaha','Qurxinta wajiga','Daryeelka jirka','Ciddiyaha','Makeup','Adeegyo kale']));
  Future<String?> ask(String title, String hint) async {
    final c = TextEditingController();
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: TextField(controller: c, decoration: InputDecoration(hintText: hint)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ka noqo')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Kaydi'))]));
  }
  Future<void> addSalon() async {
    final n = await ask('Ku dar Salon', 'Magaca salon-ka');
    if (n == null || n.isEmpty || !mounted) return;
    final l = await ask('Goobta Salon-ka', 'Magaalada / xaafadda');
    if (!mounted) return;
    final w = await ask('WhatsApp-ka Salon-ka', 'Tusaale: 25263xxxxxxx');
    if (!mounted) return;
    setState(() => salons.add(Salon(n, l ?? 'Hargeysa', ['Timaha','Qurxinta wajiga','Ciddiyaha'], whatsappNumber: w ?? '')));
  }
  Future<void> rename(int i) async {
    final n = await ask('Beddel magaca', salons[i].name);
    if (n != null && n.isNotEmpty) setState(() => salons[i].name = n);
  }
  Future<void> editSalonPhone(int i) async {
    final n = await ask('WhatsApp / telefoonka ' + salons[i].name, salons[i].whatsappNumber.isEmpty ? '252...' : salons[i].whatsappNumber);
    if (n != null) setState(() => salons[i].whatsappNumber = n);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: green, foregroundColor: Colors.white,
      title: const Text('SALON BOOKING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      actions: [if (admin) IconButton(onPressed: addSalon, icon: const Icon(Icons.add_business)),
        if (admin) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>FullPackagesPage(adminToken:adminToken))),icon:const Icon(Icons.inventory_2),tooltip:'Full Package'),
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminPaymentsPage(token:adminToken!))),icon:const Icon(Icons.payments),tooltip:'Xaqiiji lacagaha'),
        if (admin && adminToken!=null) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminPaymentSettingsPage(token:adminToken!))),icon:const Icon(Icons.settings_applications),tooltip:'Hababka lacagta iyo sarifka'),
        IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CustomerOrdersPage())),icon:const Icon(Icons.receipt_long),tooltip:'Dalabyadayda'),
        IconButton(onPressed: openAdminTools, icon: const Icon(Icons.admin_panel_settings), tooltip: 'Admin')]),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [green, Color(0xFF164B39)])),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ku soo dhowow', style: TextStyle(color: Colors.white70)), SizedBox(height: 5),
          Text('Quruxdaada, hal meel.', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
          SizedBox(height: 8), Text('Dooro qaybta aad u baahan tahay.', style: TextStyle(color: Colors.white))])),
      const SizedBox(height: 16),
      featuredSection(),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1,
        children: [
          sectionTile('SALON', 'Adeegyada quruxda', Icons.spa_outlined, 0),
          sectionTile('CAKES', 'Dalbo cake', Icons.cake_outlined, 1),
          sectionTile('DECORATION', 'Qurxinta munaasabadaha', Icons.celebration_outlined, 2),
          sectionTile('KIRAYSO', 'SAD RENTAL, TAASH iyo maryo', Icons.checkroom, 3),
        ],
      ),
      if (selectedSection == 0) ...[
        const SizedBox(height: 20),
        const Text('BALLAN QABSO — SALON', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green)),
        const SizedBox(height: 6), const Text('SALON-LADA', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const FullPackagesPage(category:'SALON'))),icon:const Icon(Icons.inventory_2),label:const Text('FULL PACKAGE')),
        const SizedBox(height: 10), ...List.generate(salons.length, salonCard),
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
      if (selectedSection == 3) ...[
        const SizedBox(height: 20),
        const Text('KIRAYSO — MARYAHA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green)),
        const SizedBox(height: 6), const Text('DHARKA IYO AGABKA LA KIRAYSTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const FullPackagesPage(category:'KIRAYSO'))),icon:const Icon(Icons.inventory_2),label:const Text('FULL PACKAGE')),
        actionCard('SAD RENTAL, TAASH, TOOBKA MEHERKA, SUBEECIYAD', 'KIRAYSO', Icons.checkroom,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalPage()))),
      ],
      if (admin) const Padding(padding: EdgeInsets.only(top: 15), child: Text('ADMIN DEMO: isbeddelladani qalabka oo keliya ayay ku jiraan; database/server wali lama xirin.', style: TextStyle(color: Colors.deepOrange, fontSize: 12))),
    ]));
  Widget sectionTile(String title, String subtitle, IconData icon, int index) {
    final imageUrl=categoryImageUrls[title];
    return InkWell(
      onTap: () {
        if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderDirectoryPage(title: 'DECORATION', isCake: false)));
          return;
        }
        setState(() => selectedSection = selectedSection == index ? -1 : index);
      },
      borderRadius: BorderRadius.circular(18),
      child: ClipRRect(borderRadius:BorderRadius.circular(18),child:Container(
        decoration:BoxDecoration(color:Colors.white,border:Border.all(color:green.withOpacity(.18)),boxShadow:[
          BoxShadow(color:green.withOpacity(.08),blurRadius:7,offset:const Offset(0,3))]),
        child:Stack(fit:StackFit.expand,children:[
          if(imageUrl!=null&&imageUrl.isNotEmpty) Image.network(imageUrl,fit:BoxFit.cover,
            errorBuilder:(_,__,___)=>Container(color:pink,child:Icon(icon,color:green,size:42))),
          if(imageUrl==null||imageUrl.isEmpty) Container(color:Colors.white),
          Container(decoration:BoxDecoration(gradient:LinearGradient(
            begin:Alignment.topCenter,end:Alignment.bottomCenter,
            colors:imageUrl!=null&&imageUrl.isNotEmpty
              ? [Colors.black.withOpacity(.12),Colors.black.withOpacity(.68)]
              : [Colors.white,Colors.white]))),
          Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            if(imageUrl==null||imageUrl.isEmpty) Container(width:58,height:58,
              decoration:BoxDecoration(color:pink,borderRadius:BorderRadius.circular(16)),
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
      InkWell(onTap: () => setState(() => opened = isOpen ? -1 : i), child: Row(children: [
        Container(width: 98, height: 88, color: pink, child: const Icon(Icons.storefront, color: green, size: 42)),
        Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4),
          Row(children: [const Icon(Icons.location_on, size: 15, color: green), Text(s.location)]),
          const SizedBox(height: 5), Text(isOpen ? 'Qari adeegyada' : 'Taabo si aad adeegyada u aragto', style: const TextStyle(color: green, fontSize: 12))]))),
        Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: green), const SizedBox(width: 8)])),
      if (admin) Wrap(children: [
        TextButton.icon(onPressed: () => rename(i), icon: const Icon(Icons.edit, size: 16), label: const Text('Magac beddel')),
        TextButton.icon(onPressed: () => editSalonPhone(i), icon: const Icon(Icons.phone, size: 16), label: const Text('Lambarka')),
        TextButton.icon(onPressed: () => setState(() => salons.removeAt(i)), icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Tirtir'))]),
      if (isOpen) ...[const Divider(height: 1), ...s.services.map((service) => serviceTile(i, service)),
        if (admin) TextButton.icon(onPressed: () async { final v = await ask('Ku dar adeeg', 'Magaca adeegga'); if (v != null && v.isNotEmpty) setState(() => s.services.add(v)); },
          icon: const Icon(Icons.add), label: const Text('Ku dar adeeggan salon-kan'))],
    ]));
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SalonBookingPage(salonName: salons[salonIndex].name, serviceName: service, whatsappNumber: salons[salonIndex].whatsappNumber))),
            child: const Text('BALLAN QABSO', style: TextStyle(fontSize: 10))))])); })),
      if (admin) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => setState(() => salons[salonIndex].services.remove(service)),
        child: const Text('Ka saar adeeggan salon-kan', style: TextStyle(color: Colors.red))))]);
  Widget categoryDirectoryCard(String title, String subtitle, IconData icon, bool isCake) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProviderDirectoryPage(title: title, isCake: isCake))),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 58, height: 58, decoration: BoxDecoration(color: pink, borderRadius: BorderRadius.circular(14)),
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
    const SizedBox(height: 9), SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: button == 'KIRAYSO' ? pink : green, foregroundColor: button == 'KIRAYSO' ? green : Colors.white), onPressed: onTap, child: Text(button)))])));
}

class ProviderDirectoryPage extends StatefulWidget {
  const ProviderDirectoryPage({super.key, required this.title, required this.isCake});
  final String title;
  final bool isCake;
  @override
  State<ProviderDirectoryPage> createState() => _ProviderDirectoryPageState();
}
class _ProviderDirectoryPageState extends State<ProviderDirectoryPage> {
  bool adminMode = false;
  Map<String, String> numbers = {};
  List<String> get providers => List<String>.generate(20, (i) =>
    widget.isCake ? 'Cake Meherad ' + (i + 1).toString() : 'Decoration Meherad ' + (i + 1).toString());
  String get storageKey => widget.isCake ? 'cake_provider_whatsapp' : 'decoration_provider_whatsapp';
  @override
  void initState() { super.initState(); _loadNumbers(); }
  Future<void> _loadNumbers() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(storageKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (mounted) setState(() => numbers = decoded.map((k,v) => MapEntry(k, v.toString())));
    }
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
      ...List.generate(providers.length, (i) {
        final provider = providers[i];
        return Card(margin: const EdgeInsets.only(bottom: 9), child: ListTile(
          leading: CircleAvatar(backgroundColor: const Color(0xFFE5EFE9),
            child: Icon(widget.isCake ? Icons.cake_outlined : Icons.celebration_outlined, color: green)),
          title: Text(provider, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(widget.isCake ? 'Cake design iyo dalabyo' : 'Qurxinta munaasabadaha iyo xafladaha'),
          trailing: adminMode ? IconButton(icon: const Icon(Icons.phone), onPressed: () => _editNumber(provider)) : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: adminMode ? () => _editNumber(provider) : () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
            widget.isCake ? CakePage(providerName: provider, whatsappNumber: numbers[provider] ?? '') :
              DecorationBookingPage(providerName: provider, whatsappNumber: numbers[provider] ?? ''))),
        ));
      }),
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
              decoration: BoxDecoration(color: pink, borderRadius: BorderRadius.circular(16)),
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
  const SalonBookingPage({super.key, required this.salonName, required this.serviceName, this.whatsappNumber = ''});
  final String salonName;
  final String serviceName;
  final String whatsappNumber;
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
        customerName: name.text.trim(),
        customerPhone: phone.text.trim(),
        customerWhatsApp: prefs.getString('customer_whatsapp') ?? phone.text.trim(),
        details: {'salon': widget.salonName, 'service': widget.serviceName,
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
        content: Text('Ballantaada ' + widget.serviceName + ' ee ' + widget.salonName + ' waa la kaydiyey. Hadda dooro WhatsApp ama wicitaan.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              showBookingContactOptions(context, widget.whatsappNumber,
                'BALLAN SALON\nSalon: ' + widget.salonName + '\nAdeeg: ' + widget.serviceName + '\nMagac: ' + name.text.trim() + '\nTelefoon: ' + phone.text.trim() + '\nTaariikh: ' + dateText + '\nWaqti: ' + selectedTime!.format(context) + '\nFaahfaahin: ' + notes.text.trim());
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
              decoration: BoxDecoration(color: pink, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.salonName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: green)),
                const SizedBox(height: 5),
                Text('Adeegga: ' + widget.serviceName, style: const TextStyle(color: green)),
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
  const RentalPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('KIRAYSO'), backgroundColor: green, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Qaybta kiraynta', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: green)),
      const SizedBox(height: 6),
      const Text('Dooro qaybta aad rabto, kadib buuxi codsiga kiraysiga.'),
      const SizedBox(height: 12),
      ...['SAD RENTAL','TAASH','TOOBKA MEHERKA','SUBEECIYAD'].map((v) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: const CircleAvatar(backgroundColor: pink, child: Icon(Icons.checkroom, color: green)),
          title: Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Gudbi codsiga kiraysiga'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RentalRequestPage(category: v))),
        ),
      )),
    ]),
  );
}

class RentalRequestPage extends StatefulWidget {
  const RentalRequestPage({super.key, required this.category});
  final String category;
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
        customerName: customer.text.trim(),
        customerPhone: phone.text.trim(),
        customerWhatsApp: p.getString('customer_whatsapp') ?? phone.text.trim(),
        details: {'rentalCategory': widget.category, 'item': item.text.trim(), 'size': size.text.trim(),
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
    appBar: AppBar(title: Text('KIRAYSO — ' + widget.category), backgroundColor: green, foregroundColor: Colors.white),
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

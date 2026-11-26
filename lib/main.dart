import 'package:flutter/material.dart';

void main() => runApp(const SalonBookingApp());
const green = Color(0xFF173F35);
const pink = Color(0xFFF7C8D8);

class SalonBookingApp extends StatelessWidget {
  const SalonBookingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'SALON BOOKING',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: green), scaffoldBackgroundColor: Colors.white),
    home: const HomePage());
}
class Salon {
  Salon(this.name, this.location, this.services);
  String name, location;
  List<String> services;
}
const images = <String, List<String>>{
  'Timaha': ['https://images.unsplash.com/photo-1560066984-138dadb4c035?w=500','https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=500','https://images.unsplash.com/photo-1562322140-8baeececf3df?w=500'],
  'Qurxinta wajiga': ['https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=500','https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=500'],
  'Daryeelka jirka': ['https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=500','https://images.unsplash.com/photo-1540555700478-4be289fbe5b1?w=500'],
  'Ciddiyaha': ['https://images.unsplash.com/photo-1604654894610-df63bc536371?w=500','https://images.unsplash.com/photo-1610992015732-2449b76344bc?w=500'],
  'Makeup': ['https://images.unsplash.com/photo-1526045478516-99145907023c?w=500','https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=500'],
  'Adeegyo kale': ['https://images.unsplash.com/photo-1600948836101-f9ffda59d250?w=500','https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=500'],
};

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  bool admin = false;
  int opened = -1;
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
    setState(() => salons.add(Salon(n, l ?? 'Hargeysa', ['Timaha','Qurxinta wajiga','Ciddiyaha'])));
  }
  Future<void> rename(int i) async {
    final n = await ask('Beddel magaca', salons[i].name);
    if (n != null && n.isNotEmpty) setState(() => salons[i].name = n);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: green, foregroundColor: Colors.white,
      title: const Text('SALON BOOKING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      actions: [if (admin) IconButton(onPressed: addSalon, icon: const Icon(Icons.add_business)),
        IconButton(onPressed: () => setState(() => admin = !admin), icon: Icon(admin ? Icons.admin_panel_settings : Icons.lock_outline), tooltip: 'Admin demo')]),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [green, Color(0xFF164B39)])),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ku soo dhowow', style: TextStyle(color: Colors.white70)), SizedBox(height: 5),
          Text('Quruxdaada, hal meel.', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
          SizedBox(height: 8), Text('Dooro salon, adeeg ama dalbo cake.', style: TextStyle(color: Colors.white))])),
      const SizedBox(height: 18), const Text('SALON-LADA', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10), ...List.generate(salons.length, salonCard),
      const SizedBox(height: 22),
      const Text('CAKES', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      categoryDirectoryCard('CAKES', '20 meheradood oo sameeya cakes', Icons.cake_outlined, true),
      const SizedBox(height: 20),
      const Text('DECORATION', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      categoryDirectoryCard('DECORATION', '20 meheradood oo decoration ah', Icons.celebration_outlined, false),
      const SizedBox(height: 20),
      const Text('KIRAYNTA DHARKA IYO AGABKA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      actionCard('SAD RENTAL, TAASH, TOOBKA MEHERKA, SUBEECIYAD', 'KIRAYSO', Icons.checkroom,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalPage()))),
      if (admin) const Padding(padding: EdgeInsets.only(top: 15), child: Text('ADMIN DEMO: isbeddelladani qalabka oo keliya ayay ku jiraan; database/server wali lama xirin.', style: TextStyle(color: Colors.deepOrange, fontSize: 12))),
    ]));
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
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Adeegga $service: foomka ballanta ayaa lagu xigi doonaa.'))),
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

class ProviderDirectoryPage extends StatelessWidget {
  const ProviderDirectoryPage({super.key, required this.title, required this.isCake});
  final String title;
  final bool isCake;

  @override
  Widget build(BuildContext context) {
    final providers = List<String>.generate(20, (i) =>
      isCake ? 'Cake Meherad ' + (i + 1).toString() : 'Decoration Meherad ' + (i + 1).toString());
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: green, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
          color: const Color(0xFFE5EFE9), borderRadius: BorderRadius.circular(14)),
          child: Text('Dooro meheradda aad rabto. Waxaa halkan ku jira 20 meheradood oo ' +
            (isCake ? 'cakes' : 'decoration') + ' ah.', style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(height: 12),
        ...List.generate(providers.length, (i) => Card(
          margin: const EdgeInsets.only(bottom: 9),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFFE5EFE9),
              child: Icon(isCake ? Icons.cake_outlined : Icons.celebration_outlined, color: green)),
            title: Text(providers[i], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isCake ? 'Cake design iyo dalabyo' : 'Qurxinta munaasabadaha iyo xafladaha'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
              isCake ? CakePage(providerName: providers[i]) : DecorationBookingPage(providerName: providers[i]))),
          ),
        )),
      ]),
    );
  }
}

class DecorationBookingPage extends StatefulWidget {
  const DecorationBookingPage({super.key, required this.providerName});
  final String providerName;
  @override
  State<DecorationBookingPage> createState() => _DecorationBookingPageState();
}
class _DecorationBookingPageState extends State<DecorationBookingPage> {
  final customer = TextEditingController(), event = TextEditingController(),
    date = TextEditingController(), place = TextEditingController(), details = TextEditingController();
  @override
  void dispose() { customer.dispose(); event.dispose(); date.dispose(); place.dispose(); details.dispose(); super.dispose(); }
  Widget field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: c, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('BALLAN QABSO — DECORATION'), backgroundColor: green, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Text(widget.providerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      field(customer, 'Magacaaga'), field(event, 'Nooca munaasabadda'),
      field(date, 'Taariikhda iyo waqtiga'), field(place, 'Goobta munaasabadda'),
      field(details, 'Faahfaahinta decoration-ka iyo midabada'),
      FilledButton(onPressed: () {
        if ([customer.text, event.text, date.text, place.text].any((v) => v.trim().isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buuxi magaca, munaasabadda, taariikhda iyo goobta.')));
          return;
        }
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Codsiga waa diyaar'),
          content: const Text('Foomka decoration-ka waa prototype. Dirista meheradda iyo xaqiijinta admin-ka backend ayaa lagu xidhayaa.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Xir'))]));
      }, child: const Text('DIR CODSIGA')),
    ]),
  );
}

class CakePage extends StatefulWidget {
  const CakePage({super.key, this.providerName});
  final String? providerName;
  @override
  State<CakePage> createState() => _CakePageState();
}
class _CakePageState extends State<CakePage> {
  final customer = TextEditingController(), decoration = TextEditingController(), delivery = TextEditingController(), place = TextEditingController();
  String size = 'Dhexdhexaad', tiers = '1', design = 'Casri';
  @override
  void dispose() { customer.dispose(); decoration.dispose(); delivery.dispose(); place.dispose(); super.dispose(); }
  Widget field(TextEditingController c, String label) => TextField(controller: c, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()));
  Widget pick(String label, String value, List<String> choices, ValueChanged<String?> change) => Padding(padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(value: value, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: choices.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: change));
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.providerName == null ? 'BALLAN QABSO — CAKE' : 'CAKE — ' + widget.providerName!), backgroundColor: green, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Text(widget.providerName == null ? 'Faahfaahinta cake-ka' : 'Meheradda: ' + widget.providerName!, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
      field(customer, 'Magacaaga'), const SizedBox(height: 12),
      pick('Cabirka cake-ka', size, ['Yar','Dhexdhexaad','Weyn','Aad u weyn'], (v) => setState(() => size = v!)),
      pick('Tirada dabaqyada', tiers, ['1','2','3','4','5+'], (v) => setState(() => tiers = v!)),
      pick('Naqshadda', design, ['Casri','Classic','Wedding','Birthday','Custom'], (v) => setState(() => design = v!)),
      const SizedBox(height: 12), field(decoration, 'Midabka iyo qoraalka/magaca cake-ka'),
      const SizedBox(height: 12), field(delivery, 'Taariikhda iyo waqtiga keenista'),
      const SizedBox(height: 12), field(place, 'Goobta la geynayo'), const SizedBox(height: 20),
      FilledButton(onPressed: () {
        if ([customer.text, delivery.text, place.text].any((v) => v.trim().isEmpty)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buuxi magaca, waqtiga iyo goobta keenista.'))); return; }
        showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Codsiga waa diyaar'),
          content: Text('Cabir: $size\nDabaqyo: $tiers\nNaqshad: $design\nFaahfaahin: ' + decoration.text + '\nKeenis: ' + delivery.text + '\nGoob: ' + place.text + '\n\nFoomku waa prototype; dirista admin-ka backend ayaa lagu xidhayaa.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Xir'))]));
      }, child: const Text('DIR CODSIGA'))]));
}

class RentalPage extends StatelessWidget {
  const RentalPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('KIRAYSO'), backgroundColor: green, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Qaybta kiraynta', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
      ...['SAD RENTAL','TAASH','TOOBKA MEHERKA','SUBEECIYAD'].map((v) => Card(child: ListTile(
        leading: const Icon(Icons.checkroom, color: green, size: 30), title: Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => showDialog(context: context, builder: (_) => AlertDialog(title: Text(v),
          content: const Text('Halkan waxaa ka muuqan doona agabka kirada iyo muddada kirada.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Xir'))]))))),
    ]));
}

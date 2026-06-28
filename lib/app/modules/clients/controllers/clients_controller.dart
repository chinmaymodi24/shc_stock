import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/client_model.dart';

class ClientsController extends GetxController {
  final RxList<ClientModel> clients = <ClientModel>[].obs;

  // ── Badge colour palette ─────────────────────────────────────────────────
  static const _colors = [
    Color(0xFF4A3AFF),
    Color(0xFFEF4444),
    Color(0xFF22C55E),
    Color(0xFFFF6B35),
    Color(0xFF0EA5E9),
    Color(0xFF14B8A6),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF6366F1),
  ];

  // ── Seed data (matches screenshot + extras) ──────────────────────────────
  static final _seed = [
    ClientModel(id:'1', code:'CLT-0001', name:'Arvind Enterprises',       initials:'AE',  badgeColor:_colors[0], contactPerson:'Arvind Mehta',   email:'arvind@ae.com',    phone:'+91 98765 43210', outstanding:45600,  salesMTD:425600, isActive:true),
    ClientModel(id:'2', code:'CLT-0002', name:'Shree Ram Traders',        initials:'SRT', badgeColor:_colors[1], contactPerson:'Ramesh Sharma',   email:'ramesh@srt.com',   phone:'+91 98765 43211', outstanding:12300,  salesMTD:315800, isActive:true),
    ClientModel(id:'3', code:'CLT-0003', name:'Jai Mata Di Suppliers',    initials:'JMD', badgeColor:_colors[2], contactPerson:'Suresh Kumar',    email:'suresh@jmd.com',   phone:'+91 98765 43212', outstanding:0,      salesMTD:245700, isActive:true),
    ClientModel(id:'4', code:'CLT-0004', name:'Gupta Hardware',           initials:'GH',  badgeColor:_colors[3], contactPerson:'Amit Gupta',      email:'amit@gh.com',      phone:'+91 98765 43213', outstanding:8750,   salesMTD:185600, isActive:true),
    ClientModel(id:'5', code:'CLT-0005', name:'National Insulation Co.',  initials:'NIC', badgeColor:_colors[4], contactPerson:'Neha Iyer',       email:'neha@nic.com',     phone:'+91 98765 43214', outstanding:32100,  salesMTD:210400, isActive:true),
    ClientModel(id:'6', code:'CLT-0006', name:'Thermo Materials Pvt. Ltd.', initials:'TMC', badgeColor:_colors[5], contactPerson:'Vikram Rao',   email:'vikram@tmc.com',   phone:'+91 98765 43215', outstanding:0,      salesMTD:165200, isActive:false),
    ClientModel(id:'7', code:'CLT-0007', name:'Buildwell Supply',         initials:'BS',  badgeColor:_colors[6], contactPerson:'Pooja Verma',     email:'pooja@bs.com',     phone:'+91 98765 43216', outstanding:18900,  salesMTD:142500, isActive:true),
    ClientModel(id:'8', code:'CLT-0008', name:'Om Sai Traders',          initials:'OST', badgeColor:_colors[7], contactPerson:'Om Sai',          email:'om@ost.com',       phone:'+91 98765 43217', outstanding:0,      salesMTD:125000, isActive:true),
    ClientModel(id:'9', code:'CLT-0009', name:'Shakti Enterprises',       initials:'SE',  badgeColor:_colors[8], contactPerson:'Manoj Patil',     email:'manoj@se.com',     phone:'+91 98765 43218', outstanding:7650,   salesMTD:0,      isActive:false),
    ClientModel(id:'10',code:'CLT-0010', name:'Lakshmi Industries',       initials:'LI',  badgeColor:_colors[9], contactPerson:'Lakshmi Nair',    email:'lakshmi@li.com',   phone:'+91 98765 43219', outstanding:22800,  salesMTD:87300,  isActive:true),
    ClientModel(id:'11',code:'CLT-0011', name:'Patel Construction',       initials:'PC',  badgeColor:_colors[0], contactPerson:'Kiran Patel',     email:'kiran@patel.com',  phone:'+91 98765 43220', outstanding:15400,  salesMTD:195000, isActive:true),
    ClientModel(id:'12',code:'CLT-0012', name:'Modern Engineers',         initials:'ME',  badgeColor:_colors[1], contactPerson:'Priya Singh',     email:'priya@me.com',     phone:'+91 98765 43221', outstanding:0,      salesMTD:132000, isActive:true),
    ClientModel(id:'13',code:'CLT-0013', name:'Raj Kishan & Sons',        initials:'RKS', badgeColor:_colors[2], contactPerson:'Raj Kishan',      email:'raj@rks.com',      phone:'+91 98765 43222', outstanding:28000,  salesMTD:78500,  isActive:true),
    ClientModel(id:'14',code:'CLT-0014', name:'Sunrise Industries',       initials:'SI',  badgeColor:_colors[3], contactPerson:'Sunita Joshi',    email:'sunita@si.com',    phone:'+91 98765 43223', outstanding:0,      salesMTD:112000, isActive:true),
    ClientModel(id:'15',code:'CLT-0015', name:'Excellent Traders',        initials:'ET',  badgeColor:_colors[4], contactPerson:'Vijay Sharma',    email:'vijay@et.com',     phone:'+91 98765 43224', outstanding:5000,   salesMTD:0,      isActive:false),
    ClientModel(id:'16',code:'CLT-0016', name:'Bombay Steel Works',       initials:'BSW', badgeColor:_colors[5], contactPerson:'Rahul Mehta',     email:'rahul@bsw.com',    phone:'+91 98765 43225', outstanding:68500,  salesMTD:235000, isActive:true),
    ClientModel(id:'17',code:'CLT-0017', name:'Kalyan Brothers',          initials:'KB',  badgeColor:_colors[6], contactPerson:'Kalyan Das',      email:'kalyan@kb.com',    phone:'+91 98765 43226', outstanding:0,      salesMTD:98000,  isActive:true),
    ClientModel(id:'18',code:'CLT-0018', name:'Sterling Suppliers',       initials:'SS',  badgeColor:_colors[7], contactPerson:'Sneha Gupta',     email:'sneha@ss.com',     phone:'+91 98765 43227', outstanding:42000,  salesMTD:175000, isActive:true),
    ClientModel(id:'19',code:'CLT-0019', name:'Vimal & Co',               initials:'VC',  badgeColor:_colors[8], contactPerson:'Vimal Shah',      email:'vimal@vc.com',     phone:'+91 98765 43228', outstanding:0,      salesMTD:62000,  isActive:true),
    ClientModel(id:'20',code:'CLT-0020', name:'Pioneer Enterprises',      initials:'PE',  badgeColor:_colors[9], contactPerson:'Piyush Jain',     email:'piyush@pe.com',    phone:'+91 98765 43229', outstanding:11250,  salesMTD:145000, isActive:true),
    ClientModel(id:'21',code:'CLT-0021', name:'Anand Engineering',        initials:'AEG', badgeColor:_colors[0], contactPerson:'Anand Patel',     email:'anand@aeg.com',    phone:'+91 98765 43230', outstanding:0,      salesMTD:0,      isActive:false),
    ClientModel(id:'22',code:'CLT-0022', name:'Global Industries',        initials:'GI',  badgeColor:_colors[1], contactPerson:'Ganesh Iyer',     email:'ganesh@gi.com',    phone:'+91 98765 43231', outstanding:34000,  salesMTD:185000, isActive:true),
    ClientModel(id:'23',code:'CLT-0023', name:'Reliable Furnace Co.',     initials:'RFC', badgeColor:_colors[2], contactPerson:'Ravi Kapoor',     email:'ravi@rfc.com',     phone:'+91 98765 43232', outstanding:0,      salesMTD:225000, isActive:true),
    ClientModel(id:'24',code:'CLT-0024', name:'Deepak Traders',           initials:'DT',  badgeColor:_colors[3], contactPerson:'Deepak Verma',    email:'deepak@dt.com',    phone:'+91 98765 43233', outstanding:16800,  salesMTD:105000, isActive:true),
    ClientModel(id:'25',code:'CLT-0025', name:'Mahavir Ceramics',         initials:'MC',  badgeColor:_colors[4], contactPerson:'Mahavir Joshi',   email:'mahavir@mc.com',   phone:'+91 98765 43234', outstanding:0,      salesMTD:88000,  isActive:true),
  ];

  @override
  void onInit() {
    super.onInit();
    clients.addAll(_seed);
  }

  // ── Computed stats ────────────────────────────────────────────────────────
  int get totalClients    => clients.length;
  int get activeClients   => clients.where((c) => c.isActive).length;
  int get inactiveClients => clients.where((c) => !c.isActive).length;

  double get totalOutstanding =>
      clients.fold(0.0, (s, c) => s + c.outstanding);

  double get totalSalesMTD =>
      clients.fold(0.0, (s, c) => s + c.salesMTD);

  double get avgOrderValue {
    final active = clients.where((c) => c.salesMTD > 0).toList();
    if (active.isEmpty) return 0;
    return totalSalesMTD / active.length;
  }

  List<ClientModel> get topClients {
    final sorted = clients.toList()
      ..sort((a, b) => b.salesMTD.compareTo(a.salesMTD));
    return sorted.take(5).toList();
  }
}

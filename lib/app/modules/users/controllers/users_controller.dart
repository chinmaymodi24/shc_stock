import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class UsersController extends GetxController {
  final RxList<UserModel> users = <UserModel>[].obs;

  // ── Palette ───────────────────────────────────────────────────────────────
  static const _colors = [
    Color(0xFFF47B20),
    Color(0xFF4A3AFF),
    Color(0xFF22C55E),
    Color(0xFF0EA5E9),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFEC4899),
    Color(0xFF6366F1),
  ];

  // ── Seed data (users created by Admin) ────────────────────────────────────
  static final _seed = [
    UserModel(id:'1',  code:'USR-0001', name:'Chinmay Modi',      initials:'CM',  badgeColor:_colors[0], email:'chinmay@shc.com',    phone:'+91 98765 00001', role:UserRole.admin,        isActive:true,  lastLogin:'05 Jul 2026, 10:32 AM', createdAt:'01 Jan 2026'),
    UserModel(id:'2',  code:'USR-0002', name:'Ravi Sharma',        initials:'RS',  badgeColor:_colors[1], email:'ravi@shc.com',        phone:'+91 98765 00002', role:UserRole.manager,      isActive:true,  lastLogin:'05 Jul 2026, 09:15 AM', createdAt:'03 Jan 2026'),
    UserModel(id:'3',  code:'USR-0003', name:'Priya Patel',        initials:'PP',  badgeColor:_colors[2], email:'priya@shc.com',       phone:'+91 98765 00003', role:UserRole.salesman,     isActive:true,  lastLogin:'04 Jul 2026, 06:48 PM', createdAt:'05 Jan 2026'),
    UserModel(id:'4',  code:'USR-0004', name:'Amit Verma',         initials:'AV',  badgeColor:_colors[3], email:'amit@shc.com',        phone:'+91 98765 00004', role:UserRole.stockManager, isActive:true,  lastLogin:'05 Jul 2026, 08:00 AM', createdAt:'07 Jan 2026'),
    UserModel(id:'5',  code:'USR-0005', name:'Sneha Gupta',        initials:'SG',  badgeColor:_colors[4], email:'sneha@shc.com',       phone:'+91 98765 00005', role:UserRole.accountant,   isActive:true,  lastLogin:'03 Jul 2026, 11:20 AM', createdAt:'10 Jan 2026'),
    UserModel(id:'6',  code:'USR-0006', name:'Vijay Joshi',        initials:'VJ',  badgeColor:_colors[5], email:'vijay@shc.com',       phone:'+91 98765 00006', role:UserRole.salesman,     isActive:true,  lastLogin:'05 Jul 2026, 07:55 AM', createdAt:'12 Jan 2026'),
    UserModel(id:'7',  code:'USR-0007', name:'Neha Iyer',          initials:'NI',  badgeColor:_colors[6], email:'neha@shc.com',        phone:'+91 98765 00007', role:UserRole.salesman,     isActive:false, lastLogin:'20 Jun 2026, 03:10 PM', createdAt:'15 Jan 2026'),
    UserModel(id:'8',  code:'USR-0008', name:'Kiran Mehta',        initials:'KM',  badgeColor:_colors[7], email:'kiran@shc.com',       phone:'+91 98765 00008', role:UserRole.manager,      isActive:true,  lastLogin:'04 Jul 2026, 05:30 PM', createdAt:'18 Jan 2026'),
    UserModel(id:'9',  code:'USR-0009', name:'Suresh Kumar',       initials:'SK',  badgeColor:_colors[8], email:'suresh@shc.com',      phone:'+91 98765 00009', role:UserRole.stockManager, isActive:true,  lastLogin:'05 Jul 2026, 08:45 AM', createdAt:'20 Jan 2026'),
    UserModel(id:'10', code:'USR-0010', name:'Deepa Nair',         initials:'DN',  badgeColor:_colors[9], email:'deepa@shc.com',       phone:'+91 98765 00010', role:UserRole.accountant,   isActive:false, lastLogin:'01 Jul 2026, 01:00 PM', createdAt:'22 Jan 2026'),
    UserModel(id:'11', code:'USR-0011', name:'Rajesh Kapoor',      initials:'RK',  badgeColor:_colors[0], email:'rajesh@shc.com',      phone:'+91 98765 00011', role:UserRole.salesman,     isActive:true,  lastLogin:'05 Jul 2026, 10:05 AM', createdAt:'25 Jan 2026'),
    UserModel(id:'12', code:'USR-0012', name:'Anita Singh',        initials:'AS',  badgeColor:_colors[1], email:'anita@shc.com',       phone:'+91 98765 00012', role:UserRole.salesman,     isActive:true,  lastLogin:'04 Jul 2026, 04:20 PM', createdAt:'28 Jan 2026'),
    UserModel(id:'13', code:'USR-0013', name:'Manoj Patil',        initials:'MP',  badgeColor:_colors[2], email:'manoj@shc.com',       phone:'+91 98765 00013', role:UserRole.stockManager, isActive:true,  lastLogin:'03 Jul 2026, 09:00 AM', createdAt:'01 Feb 2026'),
    UserModel(id:'14', code:'USR-0014', name:'Lakshmi Rao',        initials:'LR',  badgeColor:_colors[3], email:'lakshmi@shc.com',     phone:'+91 98765 00014', role:UserRole.accountant,   isActive:true,  lastLogin:'02 Jul 2026, 02:15 PM', createdAt:'05 Feb 2026'),
    UserModel(id:'15', code:'USR-0015', name:'Ganesh Iyer',        initials:'GI',  badgeColor:_colors[4], email:'ganesh@shc.com',      phone:'+91 98765 00015', role:UserRole.salesman,     isActive:false, lastLogin:'15 Jun 2026, 11:00 AM', createdAt:'10 Feb 2026'),
  ];

  @override
  void onInit() {
    super.onInit();
    users.addAll(_seed);
  }

  // ── Computed stats ────────────────────────────────────────────────────────
  int get totalUsers    => users.length;
  int get activeUsers   => users.where((u) => u.isActive).length;
  int get inactiveUsers => users.where((u) => !u.isActive).length;
  int get adminCount    => users.where((u) => u.role == UserRole.admin).length;

  /// Count of users per role
  Map<UserRole, int> get roleBreakdown {
    final map = <UserRole, int>{};
    for (final r in UserRole.values) {
      map[r] = users.where((u) => u.role == r).length;
    }
    return map;
  }

  /// 5 most recently active users
  List<UserModel> get recentlyActive {
    final active = users.where((u) => u.isActive).toList();
    return active.take(5).toList();
  }
}

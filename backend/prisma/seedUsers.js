// Seeds the `users` table.
//
// Row 1 is the dev login account (previously hardcoded in
// lib/app/modules/auth/controllers/login_controller.dart). The rest are the
// employees that used to live hardcoded in
// lib/app/modules/users/controllers/users_controller.dart, now commented out
// there — the Employee module reads them from GET /api/users.
//
// Idempotent: upserts by the unique `email`, so re-running it is safe.
//   node prisma/seedUsers.js
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

// The dev login account. Keeps working exactly as before.
const loginAccount = {
  code: 'USR-0001',
  name: 'Chinmay Modi',
  email: 'shc@gmail.com',
  password: '123456',
  role: 'Admin',
  phone: '+91 98765 00001',
  department: 'Management',
  isActive: true,
};

// The login account is Chinmay Modi, so he is not repeated below — the
// original static list had him twice once the dev account was folded in.
// Everyone else gets a starter password they are expected to change.
const DEFAULT_PASSWORD = 'shc@12345';

const employees = [
  {
    "code": "USR-0002",
    "name": "Ravi Sharma",
    "email": "ravi@shc.com",
    "phone": "+91 98765 00002",
    "role": "Manager",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0003",
    "name": "Priya Patel",
    "email": "priya@shc.com",
    "phone": "+91 98765 00003",
    "role": "Salesman",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0004",
    "name": "Amit Verma",
    "email": "amit@shc.com",
    "phone": "+91 98765 00004",
    "role": "Stock Manager",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0005",
    "name": "Sneha Gupta",
    "email": "sneha@shc.com",
    "phone": "+91 98765 00005",
    "role": "Accountant",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0006",
    "name": "Vijay Joshi",
    "email": "vijay@shc.com",
    "phone": "+91 98765 00006",
    "role": "Salesman",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0007",
    "name": "Neha Iyer",
    "email": "neha@shc.com",
    "phone": "+91 98765 00007",
    "role": "Salesman",
    "department": "",
    "isActive": false
  },
  {
    "code": "USR-0008",
    "name": "Kiran Mehta",
    "email": "kiran@shc.com",
    "phone": "+91 98765 00008",
    "role": "Manager",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0009",
    "name": "Suresh Kumar",
    "email": "suresh@shc.com",
    "phone": "+91 98765 00009",
    "role": "Stock Manager",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0010",
    "name": "Deepa Nair",
    "email": "deepa@shc.com",
    "phone": "+91 98765 00010",
    "role": "Accountant",
    "department": "",
    "isActive": false
  },
  {
    "code": "USR-0011",
    "name": "Rajesh Kapoor",
    "email": "rajesh@shc.com",
    "phone": "+91 98765 00011",
    "role": "Salesman",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0012",
    "name": "Anita Singh",
    "email": "anita@shc.com",
    "phone": "+91 98765 00012",
    "role": "Salesman",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0013",
    "name": "Manoj Patil",
    "email": "manoj@shc.com",
    "phone": "+91 98765 00013",
    "role": "Stock Manager",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0014",
    "name": "Lakshmi Rao",
    "email": "lakshmi@shc.com",
    "phone": "+91 98765 00014",
    "role": "Accountant",
    "department": "",
    "isActive": true
  },
  {
    "code": "USR-0015",
    "name": "Ganesh Iyer",
    "email": "ganesh@shc.com",
    "phone": "+91 98765 00015",
    "role": "Salesman",
    "department": "",
    "isActive": false
  }
];

async function main() {
  let created = 0;
  let updated = 0;

  for (const u of [loginAccount, ...employees]) {
    const existing = await prisma.user.findUnique({ where: { email: u.email } });
    const passwordHash = await bcrypt.hash(u.password || DEFAULT_PASSWORD, 10);
    const data = {
      code: u.code,
      name: u.name,
      role: u.role,
      phone: u.phone || '',
      department: u.department || '',
      isActive: u.isActive !== false,
    };
    await prisma.user.upsert({
      where: { email: u.email },
      // Don't reset an existing account's password on re-seed.
      update: data,
      create: { ...data, email: u.email, passwordHash },
    });
    if (existing) {
      updated++;
    } else {
      created++;
    }
  }

  console.log(`Users seeded - ${created} created, ${updated} updated.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

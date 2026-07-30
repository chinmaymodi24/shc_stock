const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const categories = [
  {
    name: 'Ceramic Fiber Products',
    description:
      'High-temperature insulation products made from ceramic fibers. Used in industrial furnaces, kilns, and thermal processing equipment. Available in various temperature ratings from 1000°C to 1600°C.',
    subCategories: [
      'Ceramic Fiber Blanket',
      'Ceramic Fiber Bulk (Loose Fiber)',
      'Ceramic Fiber Module',
      'Ceramic Fiber Board',
      'Ceramic Fiber Paper',
      'Heatshield Blanket',
    ],
  },
  {
    name: 'Ceramic Fiber Textile',
    description:
      'Woven and braided ceramic fiber products for flexible thermal sealing, gasketing, and insulation in high-heat environments.',
    subCategories: ['Ceramic Fiber Rope', 'Ceramic Fiber Cloth', 'Ceramic Fiber Tape'],
  },
  {
    name: 'Insulation Bricks',
    description:
      'Lightweight refractory bricks for kiln and furnace lining. Provides excellent thermal shock resistance and low thermal conductivity.',
    subCategories: ['HF/CF Insulation Bricks', 'HFK Insulation Bricks', 'Porosint Bricks'],
  },
  {
    name: 'Refractories',
    description:
      'Dense refractory bricks and shapes designed to withstand extreme heat and mechanical stress in furnaces and process equipment.',
    subCategories: ['Fire Bricks', 'Sillimanite & Mullite Bricks', 'Burner Block', 'Hollow Bricks'],
  },
  {
    name: 'Mortars & Castables',
    description:
      'Refractory mortars and castable compounds used for bonding, coating, and casting applications in high-temperature environments.',
    subCategories: ['Refractory Mortar (ORTEX)', 'Air Setting Mortar (ORTEX-HT)', 'Castable Refractory'],
  },
  {
    name: 'Fire & Welding Protection',
    description:
      'Fire-resistant blankets and welding protection products made from ceramic fiber and other fire-grade materials for safety applications.',
    subCategories: ['Fire Blanket', 'Welding Blanket'],
  },
  {
    name: 'Accessories & Services',
    description:
      'Anchors, fasteners, and on-site hot insulation services that complement the primary product range for complete thermal solutions.',
    subCategories: [
      'Stud & Washer Anchor',
      'Ceramic Fiber Lining Anchor',
      'Brick Anchor',
      'Refractory Anchor',
      'Hot Insulation Service',
    ],
  },
];

async function main() {
  await prisma.subCategory.deleteMany();
  await prisma.category.deleteMany();

  for (let i = 0; i < categories.length; i++) {
    const cat = categories[i];
    await prisma.category.create({
      data: {
        name: cat.name,
        description: cat.description,
        sortOrder: i,
        subCategories: {
          create: cat.subCategories.map((name, si) => ({ name, description: '', sortOrder: si })),
        },
      },
    });
  }
  console.log(`Seeded ${categories.length} categories.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const user = await prisma.user.upsert({
    where: { email: 'dev@musclemoney.com' },
    update: {
      simulatorAccount: {
        create: {}
      }
    },
    create: {
      email: 'dev@musclemoney.com',
      passwordHash: 'fake-hash',
      fullName: 'Dev User',
      simulatorAccount: {
        create: {}
      }
    }
  });
  console.log('User created:', user.id);
  await prisma.$disconnect();
}

main().catch(console.error);

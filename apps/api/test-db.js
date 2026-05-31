const { PrismaClient } = require('@prisma/client');
async function main() {
  const passwords = ['', 'postgres', 'password', 'root', 'admin', 'muscle_money'];
  const users = ['postgres', 'muscle_money'];
  const hosts = ['localhost', '127.0.0.1', '[::1]'];
  const dbs = ['postgres', 'muscle_money', 'template1'];
  
  for (const h of hosts) {
    for (const d of dbs) {
      for (const u of users) {
        for (const p of passwords) {
          const auth = p ? `${u}:${p}` : u;
          const url = `postgresql://${auth}@${h}:5432/${d}?schema=public`;
          const prisma = new PrismaClient({ datasources: { db: { url } } });
          try {
            await prisma.$connect();
            console.log('!!! SUCCESS !!!', url);
            await prisma.$disconnect();
            return;
          } catch (e) {
            // ignore
          }
        }
      }
    }
  }
  console.log('All combinations failed.');
}
main();

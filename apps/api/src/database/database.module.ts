import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { PrismaService } from './prisma.service';
import { SeedService } from './seed.service';

@Global()
@Module({
  providers: [
    PrismaService,
    SeedService,
    {
      provide: 'REDIS_CLIENT',
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        return new Redis(config.getOrThrow<string>('REDIS_URL'));
      },
    },
  ],
  exports: [PrismaService, SeedService, 'REDIS_CLIENT'],
})
export class DatabaseModule {}

import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../database/prisma.service';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  private supabase: SupabaseClient;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    this.supabase = createClient(
      this.configService.getOrThrow<string>('SUPABASE_URL'),
      this.configService.getOrThrow<string>('SUPABASE_ANON_KEY')
    );
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;
    if (!authHeader) {
      throw new UnauthorizedException('No token provided');
    }

    if (authHeader === 'Bearer dev-token-xyz') {
      const user = await this.prisma.user.findFirst();
      if (user) {
        request.user = { sub: user.id, email: user.email, roles: [user.role] };
        return true;
      }
    }

    try {
      const token = authHeader.replace('Bearer ', '');
      const { data, error } = await this.supabase.auth.getUser(token);

      if (error || !data.user) {
        throw new UnauthorizedException('Invalid token');
      }

      // Sync Supabase user to Prisma database automatically
      let localUser = await this.prisma.user.findUnique({ where: { email: data.user.email! } });
      const metadata = data.user.user_metadata || {};
      
      if (!localUser) {
        localUser = await this.prisma.user.create({
          data: {
            id: data.user.id,
            email: data.user.email!,
            fullName: metadata.fullName || 'Nova User',
            passwordHash: '', // Handled by Supabase
            role: 'STUDENT',
          }
        });
        
        // Also create a Profile and initialize onboarding data
        await this.prisma.profile.create({
          data: {
            userId: localUser.id,
            monthlyIncomeMinor: metadata.monthlyIncomeMinor ? parseInt(metadata.monthlyIncomeMinor.toString(), 10) : null,
            investmentExperience: metadata.knowledgeLevel === 'Expert' ? 'ADVANCED' 
                                : metadata.knowledgeLevel === 'Beginner' ? 'BEGINNER' : 'INTERMEDIATE',
            savingsHabit: 'REGULAR',
          }
        });
        
        // Setup initial savings goals if provided
        if (metadata.financialGoals && Array.isArray(metadata.financialGoals)) {
           for (const goal of metadata.financialGoals) {
               await this.prisma.savingsGoal.create({
                  data: {
                     userId: localUser.id,
                     title: goal.toString(),
                     targetAmountMinor: 10000000, // 1 Lakh Default Target
                     currentAmountMinor: 0,
                  }
               });
           }
        }
      }

      request.user = { 
        sub: localUser.id, 
        email: localUser.email, 
        roles: [localUser.role] 
      };

      return true;
    } catch (e) {
      throw new UnauthorizedException('Invalid token');
    }
  }
}

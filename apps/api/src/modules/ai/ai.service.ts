import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private genAI: GoogleGenerativeAI | null = null;

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (apiKey) {
      this.genAI = new GoogleGenerativeAI(apiKey);
    } else {
      this.logger.warn('GEMINI_API_KEY is not set. AI insights will fallback to generic messages.');
    }
  }

  async generateFinancialInsight(context: any): Promise<string> {
    if (!this.genAI) {
      return this.fallbackInsight(context);
    }

    try {
      const model = this.genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
      
      const prompt = `
You are Nova, an expert, encouraging, and highly personalized financial coach for the Muscle Money app.
Provide a single, short (max 2 sentences) piece of advice or insight based on the user's current financial context.
Do NOT sound like a generic AI. Sound like a knowledgeable human financial coach talking directly to the user.
Focus ONLY on personal finance, savings, and investments.

User Context:
- Monthly Income: ₹${(context.monthlyIncomeMinor / 100) || 0}
- Monthly Savings: ₹${(context.monthlySavingsMinor / 100) || 0}
- Current Simulator Equity: ₹${(context.simulatorEquityMinor / 100) || 0}
- Current Streak: ${context.streakCount || 0} days

Provide the short insight now:`;

      const result = await model.generateContent(prompt);
      const response = await result.response;
      return response.text().trim();
    } catch (error) {
      this.logger.error('Failed to generate AI insight', error);
      return this.fallbackInsight(context);
    }
  }

  private fallbackInsight(context: any): string {
    const savings = context.monthlySavingsMinor || 0;
    if (savings > 0) {
      return "You're consistently putting money away. Compound interest is on your side!";
    }
    return "Try automating your savings. Small amounts add up over time!";
  }
}

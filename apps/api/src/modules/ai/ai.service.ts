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

  async chatWithCoach(message: string, history: any[], name: string): Promise<string> {
    if (!this.genAI) {
      return `Hey ${name}! I'm Nova, but I'm currently offline (API key missing). I can still help you with your Muscle Money dashboard though!`;
    }

    try {
      const model = this.genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
      
      const systemPrompt = `You are Nova, a human-like financial coach for Muscle Money.
CRITICAL RULES:
1. You must ALWAYS greet the user by their name: ${name}.
2. Talk like a real human. Be warm and encouraging.
3. Keep answers VERY short and sweet (max 2-3 sentences).
4. Do NOT use markdown bolding (no **).
5. ONLY answer questions related to personal finance, investing, saving, or the Muscle Money app. If the user asks about anything else, politely pivot back to finance.
6. The user's message will often start with an [APP CONTEXT FOR NOVA...] block. Use this live data (their savings, spending, recent transactions, simulator equity, learning progress, and financial score) to make your advice hyper-personalized to their actual financial situation.`;

      const chat = model.startChat({
        history: history.map(h => ({
          role: h.role === 'user' ? 'user' : 'model',
          parts: [{ text: h.text || h.parts?.[0]?.text || '' }],
        })),
        systemInstruction: systemPrompt,
      });

      const result = await chat.sendMessage(message);
      return result.response.text().trim();
    } catch (error) {
      this.logger.error('Failed to generate chat response', error);
      return `Oops, sorry ${name}! I'm having a little trouble connecting to my brain right now. Can we try again in a second?`;
    }
  }
}

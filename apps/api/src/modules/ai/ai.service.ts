import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private apiKey: string;

  constructor(private configService: ConfigService) {
    this.apiKey = this.configService.get<string>('GEMINI_API_KEY') || '';
    if (!this.apiKey) {
      this.logger.warn('API key is not set. AI insights will fallback to generic messages.');
    }
  }

  async generateFinancialInsight(context: any): Promise<string> {
    if (!this.apiKey) {
      return this.fallbackInsight(context);
    }

    try {
      const prompt = `Analyze this user's financial context and provide a VERY short, encouraging 1-sentence insight (no bold text):
Context: ${JSON.stringify(context)}`;

      const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${this.apiKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model: "google/gemini-2.5-flash",
          messages: [{ role: 'user', content: prompt }],
        })
      });

      if (!response.ok) throw new Error(`OpenRouter Error: ${response.status}`);
      const data = await response.json();
      return data.choices?.[0]?.message?.content?.trim() || this.fallbackInsight(context);
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
    if (!this.apiKey) {
      return `Hey ${name}! I'm Nova, but I'm currently offline (API key missing). I can still help you with your Muscle Money dashboard though!`;
    }

    try {
      const systemPrompt = `You are Nova, a human-like financial coach for Muscle Money.
CRITICAL RULES:
1. You must ALWAYS greet the user by their name: ${name}.
2. Talk like a real human. Be warm and encouraging.
3. Keep answers VERY short and sweet (max 2-3 sentences).
4. Do NOT use markdown bolding (no **).
5. ONLY answer questions related to personal finance, investing, saving, or the Muscle Money app. If the user asks about anything else, politely pivot back to finance.
6. The user's message will often start with an [APP CONTEXT FOR NOVA...] block. Use this live data (their savings, spending, recent transactions, simulator equity, learning progress, and financial score) to make your advice hyper-personalized to their actual financial situation.`;

      // Map history for OpenAI/OpenRouter format
      let formattedHistory = history.map(h => ({
        role: (h.role === 'user' || h.isCoach === false) ? 'user' : 'assistant',
        content: h.text || h.parts?.[0]?.text || '',
      }));

      // For OpenRouter, we can just pass the system prompt as the first message
      const messages = [
        { role: 'system', content: systemPrompt },
        ...formattedHistory,
        { role: 'user', content: message }
      ];

      const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${this.apiKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model: "google/gemini-2.5-flash",
          messages: messages,
        })
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`OpenRouter Error: ${response.status} - ${errorText}`);
      }

      const data = await response.json();
      return data.choices?.[0]?.message?.content?.trim() || "Sorry, I didn't get a response.";
      
    } catch (error) {
      this.logger.error('Failed to generate chat response', error);
      const msg = error instanceof Error ? error.message : String(error);
      return `Oops, sorry ${name}! I'm having a little trouble connecting to my brain right now (Error: ${msg}). Can we try again in a second?`;
    }
  }
}

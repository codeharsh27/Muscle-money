const { GoogleGenerativeAI } = require('@google/generative-ai');
const ai = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || 'dummy');
async function test() {
  try {
    const model = ai.getGenerativeModel({ 
      model: 'gemini-1.5-flash',
      systemInstruction: 'You are Nova.',
    });
    const chat = model.startChat({
      history: [],
    });
    const result = await chat.sendMessage('Hi');
    console.log(result.response.text());
  } catch (e) {
    console.error(e);
  }
}
test();

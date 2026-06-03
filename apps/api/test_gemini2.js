const { GoogleGenerativeAI } = require('@google/generative-ai');
const ai = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
async function test() {
  try {
    const model = ai.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const chat = model.startChat({
      history: [{role: 'user', parts: [{text: 'Previous message'}]}],
    });
    const result = await chat.sendMessage('New message');
    console.log(result.response.text());
  } catch (e) {
    console.error(e);
  }
}
test();

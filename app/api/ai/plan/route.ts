import { NextRequest, NextResponse } from 'next/server';
import OpenAI from 'openai';

const client = new OpenAI({
	apiKey: process.env.OPENAI_API_KEY,
});

export async function POST(req: NextRequest) {
	const { objective, days } = (await req.json()) as {
		objective: string;
		days: number;
	};

	if (!objective || !days) {
		return NextResponse.json(
			{ error: "Missing 'objective' or 'days'." },
			{ status: 400 }
		);
	}

	// Example prompt
	const system = `You are a project planning assistant. Return concise JSON with keys: milestones[], each with name, summary, and tasks[] (task title, approximate effort in hours, dependencies[] optional). Keep it minimal and actionable.`;
	const user = `Goal: ${objective}\nTimeframe: ${days} days. Assume a small team of 1-3 people. Keep units small (2-6h tasks).`;

	// Pseudocode
	// const plan = await client.chat.completions.create({
	const plan = await client.responses.create({
		model: 'gpt-5',
		reasoning: { effort: 'low' },
		instructions: { system },
	});
}

'use client';
import { useState } from 'react';

export default function PlannerPage() {
	const [objective, setObjective] = useState('');
	const [days, setDays] = useState(30);
	const [result, setResult] = useState<string | null>(null);
	const [loading, setLoading] = useState(false);

	async function plan() {
		setLoading(true);
		const res = await fetch('/api/ai/plan', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ objective, days }),
		});
		const data = await res.json();
		setResult(data.result);
		setLoading(false);
	}

	return (
		<main className='space-y-6'>
			<header>
				<h1 className='text-2xl font-semibold'>AI Planner</h1>
			</header>

			<form className='space-y-4'>
				<input
					type='text'
					className='w-full rounded-xl border border-neutral-800 bg-neutral-900 p-3 text-sm'
					placeholder='Describe your goal (e.g., Launch MVP website)'
					value={objective}
					onChange={(e) => setObjective(e.target.value)}
				/>
				<input
					type='number'
					className='w-32 rounded-xl  border border-neutral-800 bg-neutral-900 p-3 text-sm'
					value={days}
					onChange={(e) => setDays(parseInt(e.target.value))}
				/>
				<button
					className='w-full rounded-xl bg-blue-600 p-3 text-sm font-medium text-white disabled:opacity-50'
					disabled={!objective || loading}
					onClick={plan}
				>
					{loading ? 'Generating...' : 'Generate Plan'}
				</button>
			</form>

			{result && (
				<pre className='whitespace-pre-wrap rounded-xl border border-neutral-800 bg-neutral-950 p-4 text-sm'>
					{JSON.stringify(result, null, 2)}
				</pre>
			)}
		</main>
	);
}

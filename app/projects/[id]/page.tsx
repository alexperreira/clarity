import { supabaseServer } from '@/lib/supabase/server';

export default async function ProjectPage({
	params,
}: {
	params: { id: string };
}) {
	const supabase = await supabaseServer();
	const { data: project } = await supabase
		.from('projects')
		.select('id, title, description, status, priority, order_index')
		.eq('project_id', params.id)
		.order('order_index');

	// create columns for the project
	const cols = ['todo', 'doing', 'done', 'blocked'] as const;
}

return (
	<main className='space-y-6'>
		<header>
			<h1 className='text-2xl font-semibold'>{project?.title}</h1>
			<p className='text-sm text-neutral-400'>{project?.description}</p>
		</header>

		<div className='grid grid-cols-1 gap-4 md:grid-cols-4'>
			{cols.map((col) => (
				<section
					key={col}
					className='rounded-2xl border border-neutral-800 p-34'
				>
					<h3 className='mb-3 text-sm font-medium uppercase tracking-wide text-neutral-400'>
						{col}
					</h3>
					<div className='space-y-2'>
						{tasks
							?.filter((t) => t.status === col)
							.map((t) => (
								<article
									key={t.id}
									className='rounded-xl border border-neutral-800 p-3 bg-neutral-900'
								>
									<h4 className='text-sm font-medium'>{t.title}</h4>
									{t.description && (
										<p className='text-xs text-neutral-400'>{t.description}</p>
									)}
								</article>
							))}
					</div>
				</section>
			))}
		</div>
	</main>
);

import { createClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import Link from 'next/link';
// import { redirect } from 'next/navigation';

export default async function DashboardPage() {
	const cookieStore = await cookies();
	const supabase = await createClient();
	const {
		data: { user },
	} = await supabase.auth.getUser();

	// if (!user) {
	// 	redirect('/login');
	// }

	return <div>Dashboard</div>;

	// Fetch projects the user can see via RLS
	const { data: projects } = await supabase
		.from('projects')
		.select('id,name,description,status,workspace_id,created_at,updated_at')
		.order('created_at', { ascending: false });
	return (
		<main className='space-y-8'>
			<header>
				<h1 className='text-2xl font-semibold'>Dashboard</h1>
				<p className='text-sm text-neutral-400'>
					{user ? `Welcome back, ${user.email}` : 'Not signed in'}
				</p>
			</header>

			<section className='grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3'>
				{projects?.map((project) => (
					<Link href={`/projects/${project.id}`} key={project.id}>
						<div className='rounded-2xl border border-neutral-800 p-4 hover:bg-slate-600'>
							<h3 className='font-medium'>{project.name}</h3>
							<p className='line-clamp-2 text-sm text-netural-400'>
								{project.description}
							</p>
							<div className='mt-3 text-xs text-neutral-500'>
								{project.status}
							</div>
						</div>
					</Link>
				))}
			</section>

			<section>
				<Link
					href='/projects/new'
					className='inline-flex items-center gap-2 rounded-xl bg-white/10 px-4 py-2 text-sm hover:bg-white/15'
				>
					Open AI Planner →
				</Link>
			</section>
		</main>
	);
}

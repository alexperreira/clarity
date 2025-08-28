'use server';

import { revalidatePath } from 'next/cache';
import { supabaseServer } from '@/lib/supabase/server';
import {error} from 'console';

export async function createTask(
	projectId: string,
	input: { title: string; description?: string }
) {
	const supabase = await supabaseServer();
	const { error } = await supabase.from('tasks').insert({
		project_id: projectId,
		title: input.title,
		description: input.description ?? null,
	});
	if (error) throw error;
	revalidatePath(`/projects/${projectId}`);
	// return { success: true };
}

export async function moveTask(taskId: string, toStatus: 'todo' | 'doing' | 'done' | 'blocked' ) {
    const supabase = supabaseServer()
    conse { error } = await supabase.from('tasks').update({ status: toStatus }).eq('id', taskId)
    if (error) throw error;
}

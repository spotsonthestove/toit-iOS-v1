import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabaseClient';
import type { RequestEvent } from './$types';

export async function POST({ request }: RequestEvent) {
    try {
        const { email, password } = await request.json();

        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password
        });

        if (error) throw error;

        return json({
            user: data.user,
            session: data.session
        });
    } catch (error) {
        return json({ error: error.message }, { status: 400 });
    }
} 
import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabaseClient';
import type { RequestEvent } from './$types';

// GET handler for fetching mind maps
export async function GET({ request, locals }: RequestEvent) {
    try {
        // Get authorization header
        const authHeader = request.headers.get('Authorization');
        if (!authHeader?.startsWith('Bearer ')) {
            return json({ error: 'No authorization token' }, { status: 401 });
        }

        const token = authHeader.split(' ')[1];

        // Set auth context for this request
        const { data: { user }, error: authError } = await supabase.auth.getUser(token);
        if (authError || !user) {
            return json({ error: 'Invalid token' }, { status: 401 });
        }

        // Fetch mind maps for the authenticated user
        const { data: mindMaps, error } = await supabase
            .from('mindmaps')
            .select(`
                mindmap_id,
                name,
                description,
                created_at,
                mindmap_nodes (
                    node_id,
                    content,
                    x,
                    y,
                    z,
                    parent_node_id,
                    node_type
                )
            `)
            .eq('user_id', user.id)
            .order('created_at', { ascending: false });

        if (error) throw error;

        return json({ mindMaps });
    } catch (error) {
        return json({ error: error.message }, { status: 500 });
    }
}

// POST handler for creating new mind maps
export async function POST({ request }: RequestEvent) {
    try {
        const authHeader = request.headers.get('Authorization');
        if (!authHeader?.startsWith('Bearer ')) {
            return json({ error: 'No authorization token' }, { status: 401 });
        }

        const token = authHeader.split(' ')[1];
        const { data: { user }, error: authError } = await supabase.auth.getUser(token);
        if (authError || !user) {
            return json({ error: 'Invalid token' }, { status: 401 });
        }

        const { name, description, nodes } = await request.json();

        // Create mind map
        const { data: mindmap, error: mindmapError } = await supabase
            .from('mindmaps')
            .insert({ 
                name, 
                description,
                user_id: user.id
            })
            .select()
            .single();

        if (mindmapError) throw mindmapError;

        // Create nodes
        const { data: mindmapNodes, error: nodesError } = await supabase
            .from('mindmap_nodes')
            .insert(
                nodes.map(node => ({
                    mindmap_id: mindmap.mindmap_id,
                    content: node.title || 'New Node',
                    title: node.title || 'New Node',
                    description: node.description || '',
                    x: node.x || 0,
                    y: node.y || 0,
                    z: node.z || 0,
                    node_type: node.nodeType,
                    parent_node_id: node.parentId
                }))
            )
            .select();

        if (nodesError) throw nodesError;

        return json({
            mindmap: {
                ...mindmap,
                nodes: mindmapNodes
            }
        });
    } catch (error) {
        return json({ error: error.message }, { status: 500 });
    }
} 
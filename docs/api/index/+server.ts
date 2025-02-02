import { json } from '@sveltejs/kit';

export function GET() {
    return json({
        name: 'Toit Mind Map API',
        version: '1.0.0',
        endpoints: {
            '/api/auth': {
                POST: 'Sign in with email and password'
            },
            '/api/data': {
                GET: 'Fetch mind maps for authenticated user',
                POST: 'Create new mind map'
            }
        }
    });
} 
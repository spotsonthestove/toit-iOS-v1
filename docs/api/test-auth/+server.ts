import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ request, locals }) => {
    const cookies = request.headers.get('cookie');
    
    return json({
        hasCookies: !!cookies,
        cookieString: cookies,
        sessionExists: !!locals.session
    });
}; 
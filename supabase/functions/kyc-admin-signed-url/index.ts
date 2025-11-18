// supabase/functions/kyc-admin-signed-url/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!; // provided by platform
const SERVICE_ROLE_KEY = Deno.env.get('SERVICE_ROLE_KEY')!; // set via `supabase secrets set`
const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

function cors(headers: HeadersInit = {}) {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    ...headers,
  } as HeadersInit;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors() });
  }
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers: cors() });
  }

  try {
    const { path, expiresIn } = await req.json();
    if (!path) {
      return new Response(JSON.stringify({ error: 'path required' }), { status: 400, headers: cors({'Content-Type':'application/json'}) });
    }
    const exp = Number(expiresIn ?? 3600);

    const { data, error } = await supabase.storage.from('kyc').createSignedUrl(path, exp);
    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: cors({'Content-Type':'application/json'}) });
    }

    return new Response(JSON.stringify(data), { headers: cors({'Content-Type':'application/json'}) });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: cors({'Content-Type':'application/json'}) });
  }
});

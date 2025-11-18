// supabase/functions/kyc-admin-approve/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SERVICE_ROLE_KEY');
if (!SERVICE_KEY) throw new Error('Missing service role key: set SUPABASE_SERVICE_ROLE_KEY or SERVICE_ROLE_KEY');
const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

// FCM env (reuse broadcast-mission pattern)
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!;
const FIREBASE_CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL')!;
const FIREBASE_PRIVATE_KEY = (Deno.env.get('FIREBASE_PRIVATE_KEY') || '').replace(/\\n/g, '\n');

function cors(headers: HeadersInit = {}) {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    ...headers,
  } as HeadersInit;
}

// Helpers FCM (adapted from broadcast-mission)
async function createFirebaseJWT(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: FIREBASE_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600
  };
  const enc = (obj: unknown) => btoa(JSON.stringify(obj)).replace(/[+/]/g, (m) => ({ '+': '-', '/': '_' }[m]!)).replace(/=/g, '');
  const encodedHeader = enc(header);
  const encodedPayload = enc(payload);
  const message = `${encodedHeader}.${encodedPayload}`;
  const pemKey = FIREBASE_PRIVATE_KEY
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s/g, '');
  const keyData = Uint8Array.from(atob(pemKey), c => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', keyData, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(message));
  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/[+/]/g, (m) => ({ '+': '-', '/': '_' }[m]!)).replace(/=/g, '');
  return `${message}.${encodedSignature}`;
}

async function getFirebaseAccessToken(): Promise<string> {
  const jwt = await createFirebaseJWT();
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt
    })
  });
  if (!response.ok) {
    throw new Error(`Erreur obtention access token: ${response.statusText}`);
  }
  const { access_token } = await response.json();
  return access_token;
}

async function sendFCMNotification(token: string, title: string, body: string, data: Record<string, string> = {}) {
  const accessToken = await getFirebaseAccessToken();
  const message = {
    message: {
      token,
      notification: { title, body },
      data,
      android: { notification: { click_action: 'FLUTTER_NOTIFICATION_CLICK' } },
      apns: { payload: { aps: { category: 'FLUTTER_NOTIFICATION_CLICK' } } },
    }
  };
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(message)
  });
  if (!response.ok) {
    let rawText = '';
    try { rawText = await response.text(); } catch {}
    throw new Error(`FCM v1 error ${response.status}: ${rawText}`);
  }
}

async function notifyUser(userId: string, title: string, body: string, data: Record<string,string> = {}) {
  const { data: tokensRows, error } = await supabase
    .from('user_fcm_tokens')
    .select('token')
    .eq('user_id', userId)
    .is('revoked_at', null);
  if (error) {
    console.error('Erreur récupération tokens:', error.message);
    return;
  }
  if (!tokensRows || tokensRows.length === 0) return;
  for (const row of tokensRows) {
    const token = row.token as string;
    try { await sendFCMNotification(token, title, body, data); } catch (e) { console.error('FCM error:', e); }
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors() });
  }
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers: cors() });
  }

  try {
    const { submission_id } = await req.json();
    if (!submission_id) {
      return new Response(JSON.stringify({ error: 'submission_id required' }), { status: 400, headers: cors({'Content-Type':'application/json'}) });
    }

    // 1) Update submission status directly
    const { error: updErr } = await supabase
      .from('livreur_kyc_submissions')
      .update({ status: 'approved', reviewed_at: new Date().toISOString(), reviewer_id: null })
      .eq('id', submission_id);
    if (updErr) {
      return new Response(JSON.stringify({ error: updErr.message }), { status: 400, headers: cors({'Content-Type':'application/json'}) });
    }

    // 2) Insert history
    const { error: histErr } = await supabase
      .from('livreur_kyc_history')
      .insert({ submission_id, action: 'approved', actor_id: null });
    if (histErr) {
      // Non-blocking but we report it
      console.error('History insert error:', histErr.message);
    }

    // Fetch user_id then notify
    const { data: sub, error: subErr } = await supabase
      .from('livreur_kyc_submissions')
      .select('user_id')
      .eq('id', submission_id)
      .single();
    if (!subErr && sub?.user_id) {
      await notifyUser(sub.user_id as string, 'KYC approuvé', 'Votre vérification KYC a été approuvée 🎉', { type: 'kyc_approved' });
    }

    return new Response(JSON.stringify({ ok: true }), { headers: cors({'Content-Type':'application/json'}) });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: cors({'Content-Type':'application/json'}) });
  }
});

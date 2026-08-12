// Supabase Edge Function: meditation-voice
//
// Turns a meditation guidance line into natural speech using Google Cloud
// Text-to-Speech (WaveNet neural voices), and caches the result in Supabase
// Storage so each unique line is generated only once (across all users).
//
// Why Google (not ElevenLabs): ElevenLabs' free tier blocks API calls coming
// from cloud/server IPs (returns 402). Google Cloud TTS has a large free tier
// and works fine from a server, in many languages — so voices work in every
// app language automatically, with no per-line manual work.
//
// The Google API key lives ONLY in this function's environment.
//
// Setup:
//   supabase secrets set GOOGLE_TTS_API_KEY=your_key
//   Run supabase/sql/meditation_voice_bucket.sql once (creates the bucket).
//   supabase functions deploy meditation-voice

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const BUCKET = "meditation-voice";
const GOOGLE_KEY = Deno.env.get("GOOGLE_TTS_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";

// Two named voices ("deniz" / "isik") per supported language, so the app's
// voice picker keeps working across languages. Falls back to English.
const VOICES: Record<string, { code: string; deniz: string; isik: string }> = {
  tr: { code: "tr-TR", deniz: "tr-TR-Wavenet-A", isik: "tr-TR-Wavenet-B" },
  en: { code: "en-US", deniz: "en-US-Wavenet-F", isik: "en-US-Wavenet-D" },
  de: { code: "de-DE", deniz: "de-DE-Wavenet-C", isik: "de-DE-Wavenet-B" },
  es: { code: "es-ES", deniz: "es-ES-Wavenet-C", isik: "es-ES-Wavenet-B" },
  fr: { code: "fr-FR", deniz: "fr-FR-Wavenet-C", isik: "fr-FR-Wavenet-B" },
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function sha256hex(s: string): Promise<string> {
  const buf = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(s),
  );
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function publicUrl(path: string): string {
  return `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${path}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return jsonResponse({ error: "unauthorized" }, 401);
    if (!GOOGLE_KEY) return jsonResponse({ error: "voice_not_configured" }, 503);

    const token = authHeader.replace(/^Bearer\s+/i, "");
    const supabase = createClient(
      SUPABASE_URL,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );
    const { data: userData, error: userError } = await supabase.auth.getUser(
      token,
    );
    if (userError || !userData.user) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const body = await req.json().catch(() => null);
    const text = typeof body?.text === "string" ? body.text.trim() : "";
    const lang = typeof body?.lang === "string" ? body.lang.slice(0, 2) : "en";
    const variant = body?.variant === "isik" ? "isik" : "deniz";
    if (!text || text.length > 800) {
      return jsonResponse({ error: "invalid_text" }, 400);
    }

    const cfg = VOICES[lang] ?? VOICES["en"];
    const voiceName = variant === "isik" ? cfg.isik : cfg.deniz;

    const hash = await sha256hex(`${voiceName}::${text}`);
    const path = `${hash}.mp3`;

    // Cache hit?
    const cached = await supabase.storage.from(BUCKET).download(path).catch(
      () => ({ data: null }),
    );
    if (cached?.data) {
      return jsonResponse({ url: publicUrl(path), cached: true });
    }

    // Generate with Google Cloud TTS.
    const g = await fetch(
      `https://texttospeech.googleapis.com/v1/text:synthesize?key=${GOOGLE_KEY}`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          input: { text },
          voice: { languageCode: cfg.code, name: voiceName },
          audioConfig: {
            audioEncoding: "MP3",
            speakingRate: 0.9,
            pitch: 0.0,
          },
        }),
      },
    );

    if (!g.ok) {
      console.error("google tts error", g.status, await g.text());
      return jsonResponse({ error: "tts_failed" }, 502);
    }

    const data = await g.json();
    const b64 = data?.audioContent as string | undefined;
    if (!b64) return jsonResponse({ error: "empty_audio" }, 502);
    const audio = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));

    const { error: upErr } = await supabase.storage.from(BUCKET).upload(
      path,
      audio,
      { contentType: "audio/mpeg", upsert: true },
    );
    if (upErr) {
      console.error("storage upload error", upErr.message);
      return jsonResponse({ error: "storage_error" }, 500);
    }

    return jsonResponse({ url: publicUrl(path), cached: false });
  } catch (e) {
    console.error("meditation-voice error", e);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});

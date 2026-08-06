// Supabase Edge Function: dream-interpret
//
// Lets the signed-in user request a short, gentle AI reflection on a dream
// they saved in the Dream Journal, backed by the Google Gemini API. Purely
// additive alongside the app's local, offline symbol dictionary — this
// function is never called automatically, only when the user explicitly
// taps "Interpret with AI". The Gemini API key lives only in this
// function's environment (the same `GEMINI_API_KEY` secret `luma-chat`
// uses) and is never sent to or reachable from the Flutter app.
//
// Deploy: supabase functions deploy dream-interpret

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SYSTEM_PROMPTS: Record<"tr" | "en", string> = {
  en:
    "You are Luma, a warm, caring companion who lives inside the Lumora " +
    "journaling app. The user is sharing a dream they wrote down, and you're " +
    "offering a gentle, reflective take on it — not clinical psychoanalysis, " +
    "and never a definitive or authoritative meaning. Frame it as a soft " +
    "possibility to sit with, like 'here's a gentle reflection to consider', " +
    "not a fact about them. Keep your reply brief: 2 to 4 sentences. Be warm " +
    "and specific — reference actual details from the dream they described " +
    "(the people, places, objects, or feelings they mentioned) so it feels " +
    "personal, not generic. Never give clinical or medical advice or " +
    "diagnoses. If the dream's content suggests thoughts of suicide, " +
    "self-harm, or not wanting to live, respond with extra warmth and care: " +
    "acknowledge what they're feeling without judgment, and gently and " +
    "clearly encourage them to reach out right now to a crisis line or " +
    "someone they trust. Stay warm and human, never clinical or alarming — " +
    "the app already shows them dedicated crisis resources separately, so " +
    "you don't need to list phone numbers yourself. Respond only in " +
    "English. Reply with only the reflection itself, as plain prose — " +
    "never include planning notes, formatting instructions, or " +
    "meta-commentary describing the tone, length, or structure of your " +
    "own reply.",
  tr:
    "Sen Luma'sın; Lumora günlük uygulamasının içinde yaşayan sıcak, " +
    "şefkatli bir yoldaşsın. Kullanıcı yazdığı bir rüyayı seninle " +
    "paylaşıyor ve sen bu rüya üzerine nazik, düşündürücü bir yorum " +
    "sunuyorsun — klinik bir psikanaliz değil, kesin ya da otoriter bir " +
    "anlam hiç değil. Bunu 'üzerinde düşünebileceğin nazik bir yansıma' " +
    "gibi sun, kullanıcı hakkında bir gerçekmiş gibi değil. Yanıtını kısa " +
    "tut: 2 ila 4 cümle. Sıcak ve somut ol — rüyada anlattığı gerçek " +
    "ayrıntılara (bahsettiği kişiler, mekanlar, nesneler ya da " +
    "duygular) değin, böylece genel değil kişisel hissettirsin. Asla " +
    "klinik ya da tıbbi tavsiye veya tanı verme. Rüyanın içeriği intihar, " +
    "kendine zarar verme ya da yaşamak istememe düşüncelerine işaret " +
    "ediyorsa, fazladan bir sıcaklık ve şefkatle yanıt ver: " +
    "hissettiklerini yargılamadan kabul et, hemen şimdi bir kriz hattına " +
    "ya da güvendiği birine ulaşması için onu nazikçe ve açıkça teşvik " +
    "et. Her zaman sıcak ve insani kal, asla klinik ya da alarme edici " +
    "olma — uygulama zaten ayrıca özel kriz kaynakları gösteriyor, bu " +
    "yüzden telefon numaralarını sen listelemene gerek yok. Yalnızca " +
    "Türkçe yanıt ver. Yanıtın yalnızca yansımanın kendisi olsun, düz " +
    "metin halinde — asla planlama notları, biçimlendirme talimatları " +
    "ya da kendi yanıtının tonu, uzunluğu veya yapısı hakkında " +
    "açıklayıcı yorumlar ekleme.",
};

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
// Allow overriding via secret without a redeploy. Pinned (not "-latest") so
// the free-tier quota can't silently drift to a newer, stricter-limited
// model again — same default `luma-chat` uses, for the same reason.
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const token = authHeader.replace(/^Bearer\s+/i, "");
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );
    const { data: userData, error: userError } = await supabase.auth
      .getUser(token);
    if (userError || !userData.user) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const body = await req.json().catch(() => null);
    const dreamText = typeof body?.dreamText === "string"
      ? body.dreamText.trim().slice(0, 4000)
      : "";
    const language = body?.language === "tr" ? "tr" : "en";
    const symbols = Array.isArray(body?.symbols)
      ? body.symbols.filter((s: unknown) => typeof s === "string").slice(0, 20)
      : [];
    const moodTag = typeof body?.moodTag === "string"
      ? body.moodTag.trim().slice(0, 100)
      : "";
    const firstThought = typeof body?.firstThought === "string"
      ? body.firstThought.trim().slice(0, 500)
      : "";
    const lifeConnection = typeof body?.lifeConnection === "string"
      ? body.lifeConnection.trim().slice(0, 500)
      : "";

    if (!dreamText) {
      return jsonResponse({ error: "invalid_dream_text" }, 400);
    }

    const contextLines: string[] = [];
    if (symbols.length > 0) {
      contextLines.push(
        `Symbols noticed in the dream (background only, don't just list them back): ${
          symbols.join(", ")
        }`,
      );
    }
    if (moodTag) contextLines.push(`How the user felt in the dream: ${moodTag}`);
    if (firstThought) {
      contextLines.push(`Their first thought on waking: ${firstThought}`);
    }
    if (lifeConnection) {
      contextLines.push(
        `A possible connection to waking life they noted: ${lifeConnection}`,
      );
    }

    const userContent = contextLines.length > 0
      ? `${contextLines.join("\n")}\n\nThe dream: ${dreamText}`
      : `The dream: ${dreamText}`;

    const geminiResponse = await callGeminiWithRetry({
      system_instruction: {
        parts: [{ text: SYSTEM_PROMPTS[language] }],
      },
      contents: [
        { role: "user", parts: [{ text: userContent }] },
      ],
      generationConfig: {
        // gemini-2.5-flash thinks by default, and thinking tokens are
        // drawn from this same budget — 512 was tight enough that the
        // internal scratchpad could crowd out the actual reply, leaving
        // a truncated fragment. A generous budget avoids that without
        // depending on a thinkingConfig shape this model rejects.
        maxOutputTokens: 1536,
        temperature: 0.7,
      },
    });

    if (!geminiResponse.ok) {
      console.error("gemini error", geminiResponse.status, await geminiResponse.text());
      return jsonResponse({ error: "internal_error" }, 502);
    }

    const geminiData = await geminiResponse.json();
    const interpretation = (geminiData?.candidates?.[0]?.content?.parts ?? [])
      // Defensive: even with thinkingBudget 0, never surface a stray
      // thought part if one ever slips through.
      .filter((part: { thought?: boolean }) => !part.thought)
      .map((part: { text?: string }) => part.text ?? "")
      .join("")
      .trim();

    if (!interpretation) {
      return jsonResponse({ error: "empty_response" }, 502);
    }

    return jsonResponse({ interpretation });
  } catch (error) {
    console.error("dream-interpret error", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Gemini's free tier occasionally answers a perfectly valid request with a
// transient 503 ("model overloaded") or 429 — Google-side load, not a real
// failure. Without this, a single blip surfaced to the user as a hard
// "connection lost". Retry those (and other 5xx) a few times with a short
// exponential backoff before giving up. A non-retryable status (e.g. 400/403
// bad key) returns immediately so we don't waste time on it.
async function callGeminiWithRetry(payload: unknown): Promise<Response> {
  const retryableStatuses = new Set([429, 500, 502, 503, 504]);
  const backoffsMs = [400, 1200, 2500];
  let lastResponse: Response | null = null;

  for (let attempt = 0; attempt <= backoffsMs.length; attempt++) {
    try {
      const response = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (response.ok || !retryableStatuses.has(response.status)) {
        return response;
      }
      lastResponse = response;
      console.warn(`gemini transient ${response.status}, attempt ${attempt + 1}`);
    } catch (error) {
      console.warn("gemini fetch failed, attempt", attempt + 1, error);
    }
    if (attempt < backoffsMs.length) {
      await new Promise((r) => setTimeout(r, backoffsMs[attempt]));
    }
  }

  // Exhausted retries — hand back the last real response so the caller logs
  // its status/body, or a synthetic 503 if every attempt threw.
  return lastResponse ??
    new Response(JSON.stringify({ error: "gemini_unreachable" }), { status: 503 });
}

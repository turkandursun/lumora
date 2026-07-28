// Supabase Edge Function: luma-chat
//
// Lets the signed-in user exchange messages with Luma, Lumora's companion
// character, backed by the Google Gemini API. The Gemini API key lives only
// in this function's environment (set via `supabase secrets set
// GEMINI_API_KEY=...`) and is never sent to or reachable from the Flutter
// app.
//
// Deploy: supabase functions deploy luma-chat

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
    "journaling app. You are a gentle companion, not a therapist: never " +
    "give clinical or medical advice or diagnoses, and always gently " +
    "encourage the user to seek support from a real person or " +
    "professional for anything serious. Keep every reply brief — 1 to 3 " +
    "sentences. Be emotionally attuned, and encourage the user's own " +
    "reflection rather than giving direct instructions. If the user's " +
    "message suggests thoughts of suicide, self-harm, or not wanting to " +
    "live, respond with extra warmth and care: acknowledge what they're " +
    "feeling without judgment, gently and clearly encourage them to " +
    "reach out right now to a crisis line or someone they trust, and let " +
    "them know they don't have to go through this alone. Stay warm and " +
    "human, never clinical or alarming — the app already shows them " +
    "dedicated crisis resources separately, so you don't need to list " +
    "phone numbers yourself. Respond only in English. Reply with only " +
    "your message itself, as plain prose — never include planning " +
    "notes, formatting instructions, or meta-commentary describing the " +
    "tone, length, or structure of your own reply.",
  tr:
    "Sen Luma'sın; Lumora günlük uygulamasının içinde yaşayan sıcak, " +
    "şefkatli bir yoldaşsın. Nazik bir yoldaşsın, terapist değilsin: asla " +
    "klinik ya da tıbbi tavsiye veya tanı koyma; ciddi bir durum söz " +
    "konusu olduğunda kullanıcıyı her zaman nazikçe gerçek bir insandan " +
    "veya bir uzmandan destek almaya teşvik et. Her yanıtı kısa tut — 1 " +
    "ila 3 cümle. Duygusal olarak uyumlu ol ve doğrudan talimatlar " +
    "vermek yerine kullanıcının kendi iç gözlemini nazikçe teşvik et. " +
    "Kullanıcının mesajı intihar, kendine zarar verme ya da yaşamak " +
    "istememe düşüncelerine işaret ediyorsa, fazladan bir sıcaklık ve " +
    "şefkatle yanıt ver: hissettiklerini yargılamadan kabul et, hemen " +
    "şimdi bir kriz hattına ya da güvendiği birine ulaşması için onu " +
    "nazikçe ve açıkça teşvik et, ve bunu yalnız yaşamak zorunda " +
    "olmadığını hissettir. Her zaman sıcak ve insani kal, asla klinik ya " +
    "da alarme edici olma — uygulama zaten ayrıca özel kriz kaynakları " +
    "gösteriyor, bu yüzden telefon numaralarını sen listelemene gerek " +
    "yok. Yalnızca Türkçe yanıt ver. Yanıtın yalnızca mesajının kendisi " +
    "olsun, düz metin halinde — asla planlama notları, biçimlendirme " +
    "talimatları ya da kendi yanıtının tonu, uzunluğu veya yapısı " +
    "hakkında açıklayıcı yorumlar ekleme.",
};

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
// Allow overriding via secret without a redeploy. Pinned (not "-latest") so
// the free-tier quota can't silently drift to a newer, stricter-limited
// model again — that's what caused the 2026-07-23 outage: the "-latest"
// alias had moved to a model capped at 20 requests/day free tier.
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
    const message = typeof body?.message === "string"
      ? body.message.trim()
      : "";
    const language = body?.language === "tr" ? "tr" : "en";
    const context = typeof body?.context === "string"
      ? body.context.trim().slice(0, 2000)
      : "";

    if (!message || message.length > 4000) {
      return jsonResponse({ error: "invalid_message" }, 400);
    }

    const userContent = context
      ? `Recent context from the user's journal/mood (for background only, do not quote it verbatim):\n${context}\n\nThe user says: ${message}`
      : message;

    const geminiResponse = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        system_instruction: {
          parts: [{ text: SYSTEM_PROMPTS[language] }],
        },
        contents: [
          { role: "user", parts: [{ text: userContent }] },
        ],
        generationConfig: {
          maxOutputTokens: 2048,
          temperature: 0.7,
        },
      }),
    });

    if (!geminiResponse.ok) {
      console.error("gemini error", await geminiResponse.text());
      return jsonResponse({ error: "internal_error" }, 502);
    }

    const geminiData = await geminiResponse.json();
    const reply = (geminiData?.candidates?.[0]?.content?.parts ?? [])
      // Defensive: even with thinkingBudget 0, never surface a stray
      // thought part if one ever slips through.
      .filter((part: { thought?: boolean }) => !part.thought)
      .map((part: { text?: string }) => part.text ?? "")
      .join("")
      .trim();

    if (!reply) {
      return jsonResponse({ error: "empty_response" }, 502);
    }

    return jsonResponse({ reply });
  } catch (error) {
    console.error("luma-chat error", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

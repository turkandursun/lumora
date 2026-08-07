// Supabase Edge Function: daily-ai-questions
//
// Returns five personalized, open-ended reflection questions for the signed-in
// user. Questions are generated at most once per UTC calendar day and cached in
// public.ai_daily_questions so repeated requests never spend Gemini quota.
//
// Deploy: supabase functions deploy daily-ai-questions

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SYSTEM_PROMPTS: Record<"tr" | "en", string> = {
  tr:
    "Sen Luma'sın; kullanıcıya kendi iç dünyasını keşfetmesi için nazik, " +
    "açık uçlu ve kişisel tam 5 soru soruyorsun. Her soru kısa, tek cümlelik, " +
    "yargılayıcı olmayan ve terapi ya da tıbbi tavsiye içermeyen bir soru " +
    "olsun. Kullanıcının paylaştığı ruh hali, günlük ve rüya bağlamından " +
    "ilham al ama bu metinleri doğrudan alıntılama veya kullanıcının yazdığı " +
    "özel ifadeleri tekrar etme. Bağlam yoksa herkese uygun, genel ama " +
    "düşündürücü 5 soru üret. Cevabını SADECE geçerli bir JSON string dizisi " +
    "olarak ver: [\"soru1\", \"soru2\", \"soru3\", \"soru4\", \"soru5\"]. " +
    "JSON dışında hiçbir açıklama, başlık, Markdown veya kod bloğu ekleme. " +
    "Yalnızca Türkçe yaz.",
  en:
    "You are Luma. Ask the user exactly 5 gentle, open-ended, personal " +
    "questions that help them explore their inner world. Each question must " +
    "be short, one sentence, non-judgmental, and contain no therapy or medical " +
    "advice. Draw inspiration from the mood, journal, and dream context the " +
    "user shared, but never quote it or repeat their private wording directly. " +
    "If there is no context, generate 5 general but thoughtful questions that " +
    "could suit anyone. Return ONLY a valid JSON array of strings: " +
    "[\"question1\", \"question2\", \"question3\", \"question4\", \"question5\"]. " +
    "Do not add explanations, headings, Markdown, or code fences. Respond only " +
    "in English.",
};

const FALLBACK_QUESTIONS: Record<"tr" | "en", string[]> = {
  tr: [
    "Bugün enerjin nasıl?",
    "Son günlerde en çok hangi duyguyu yaşadın?",
    "Kendine ne kadar zaman ayırabildin?",
    "Uykun nasıldı?",
    "Şu an en çok neye ihtiyacın var?",
  ],
  en: [
    "How is your energy today?",
    "Which emotion have you felt most lately?",
    "How much time did you make for yourself?",
    "How was your sleep?",
    "What do you need most right now?",
  ],
};

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
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

    // DATE is intentionally calculated on the server so clients cannot bypass
    // the once-per-day cache by supplying a different question_date.
    const questionDate = new Date().toISOString().slice(0, 10);
    const userId = userData.user.id;

    const cached = await readCachedQuestions(supabase, userId, questionDate);
    if (cached.error) {
      console.error("daily question cache read error", cached.error);
      return jsonResponse({ error: "internal_error" }, 500);
    }
    if (cached.questions) {
      return jsonResponse({ questions: cached.questions });
    }

    const body = await req.json().catch(() => null);
    const language: "tr" | "en" = body?.language === "tr" ? "tr" : "en";
    const recentMood = optionalText(body?.recentMood, 100);
    const recentJournalSnippet = optionalText(
      body?.recentJournalSnippet,
      200,
    );
    const recentDreamSnippet = optionalText(body?.recentDreamSnippet, 200);
    const userContent = buildUserContent({
      language,
      recentMood,
      recentJournalSnippet,
      recentDreamSnippet,
    });

    const questions = await generateQuestions({ language, userContent });

    const { error: insertError } = await supabase
      .from("ai_daily_questions")
      .insert({
        user_id: userId,
        question_date: questionDate,
        questions,
      });

    if (insertError) {
      // A simultaneous request may have inserted the same user's daily row
      // while Gemini was running. In that case the stored row is authoritative.
      const concurrent = await readCachedQuestions(
        supabase,
        userId,
        questionDate,
      );
      if (concurrent.questions) {
        return jsonResponse({ questions: concurrent.questions });
      }
      console.error("daily question cache insert error", insertError);
      return jsonResponse({ error: "internal_error" }, 500);
    }

    return jsonResponse({ questions });
  } catch (error) {
    console.error("daily-ai-questions error", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});

type SupabaseServiceClient = ReturnType<typeof createClient>;

async function readCachedQuestions(
  supabase: SupabaseServiceClient,
  userId: string,
  questionDate: string,
): Promise<{ questions: string[] | null; error: unknown | null }> {
  const { data, error } = await supabase
    .from("ai_daily_questions")
    .select("questions")
    .eq("user_id", userId)
    .eq("question_date", questionDate)
    .limit(1);

  if (error) return { questions: null, error };
  const questions = parseStoredQuestions(data?.[0]?.questions);
  return { questions, error: null };
}

function optionalText(value: unknown, maxLength: number): string {
  return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

function buildUserContent({
  language,
  recentMood,
  recentJournalSnippet,
  recentDreamSnippet,
}: {
  language: "tr" | "en";
  recentMood: string;
  recentJournalSnippet: string;
  recentDreamSnippet: string;
}): string {
  const contextLines: string[] = [];
  if (language === "tr") {
    if (recentMood) contextLines.push(`Son ruh hali: ${recentMood}`);
    if (recentJournalSnippet) {
      contextLines.push(`Son günlükten kısa bağlam: ${recentJournalSnippet}`);
    }
    if (recentDreamSnippet) {
      contextLines.push(`Son rüyadan kısa bağlam: ${recentDreamSnippet}`);
    }
    return contextLines.length > 0
      ? `Aşağıdaki özel bağlamı doğrudan alıntılamadan sorulara ilham olarak kullan:\n${contextLines.join("\n")}`
      : "Kullanıcı için henüz ruh hali, günlük veya rüya bağlamı yok. Genel ve herkese uygun sorular üret.";
  }

  if (recentMood) contextLines.push(`Recent mood: ${recentMood}`);
  if (recentJournalSnippet) {
    contextLines.push(`Short context from the latest journal: ${recentJournalSnippet}`);
  }
  if (recentDreamSnippet) {
    contextLines.push(`Short context from the latest dream: ${recentDreamSnippet}`);
  }
  return contextLines.length > 0
    ? `Use the private context below only as inspiration and do not quote it:\n${contextLines.join("\n")}`
    : "There is no mood, journal, or dream context yet. Generate general questions suitable for anyone.";
}

async function generateQuestions({
  language,
  userContent,
}: {
  language: "tr" | "en";
  userContent: string;
}): Promise<string[]> {
  // Retry generation three times when Gemini returns text that cannot be
  // parsed as exactly five questions. HTTP quota/server retries happen inside
  // callGeminiWithRetry and use the same backoff policy as the other functions.
  for (let parseAttempt = 1; parseAttempt <= 3; parseAttempt++) {
    const response = await callGeminiWithRetry({
      system_instruction: {
        parts: [{ text: SYSTEM_PROMPTS[language] }],
      },
      contents: [
        { role: "user", parts: [{ text: userContent }] },
      ],
      generationConfig: {
        // Gemini 3.5 Flash defaults to medium thinking. With a 1024-token
        // output cap it spent almost the entire budget on thoughts and cut the
        // JSON in the middle. This task is simple structured generation, so
        // minimal thinking keeps it fast/cheap while 2048 leaves ample room
        // for the complete five-question JSON array.
        maxOutputTokens: 2048,
        thinkingConfig: { thinkingLevel: "MINIMAL" },
        responseMimeType: "application/json",
        responseJsonSchema: {
          type: "array",
          minItems: 5,
          maxItems: 5,
          items: { type: "string" },
        },
      },
    });

    const responseBody = await response.text();
    if (!response.ok) {
      console.error(
        "gemini error",
        response.status,
        responseBody,
      );
      continue;
    }

    const geminiData = (() => {
      try {
        return JSON.parse(responseBody);
      } catch (_) {
        return null;
      }
    })();
    const raw = (geminiData?.candidates?.[0]?.content?.parts ?? [])
      .filter((part: { thought?: boolean }) => !part.thought)
      .map((part: { text?: string }) => part.text ?? "")
      .join("")
      .trim();
    const parsed = parseGeneratedQuestions(raw);
    if (parsed) return parsed;

    console.warn(
      "daily question JSON parse failed",
      {
        attempt: parseAttempt,
        model: GEMINI_MODEL,
        finishReason: geminiData?.candidates?.[0]?.finishReason ?? null,
        raw,
      },
    );
  }

  return [...FALLBACK_QUESTIONS[language]];
}

function parseGeneratedQuestions(raw: string): string[] | null {
  if (!raw) return null;
  const withoutFence = raw
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```$/i, "")
    .trim();

  try {
    return validateQuestions(JSON.parse(withoutFence));
  } catch (_) {
    // Structured-output models can occasionally append harmless trailing
    // characters (for example an extra closing bracket). Extract only the
    // first complete top-level JSON array, while respecting strings/escapes,
    // and validate it with the same strict five-string contract.
    const firstArray = extractFirstJsonArray(withoutFence);
    if (!firstArray) return null;
    try {
      return validateQuestions(JSON.parse(firstArray));
    } catch (_) {
      return null;
    }
  }
}

function extractFirstJsonArray(value: string): string | null {
  const start = value.indexOf("[");
  if (start < 0) return null;

  let depth = 0;
  let inString = false;
  let escaped = false;
  for (let index = start; index < value.length; index++) {
    const char = value[index];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (char === "\\") {
        escaped = true;
      } else if (char === '"') {
        inString = false;
      }
      continue;
    }

    if (char === '"') {
      inString = true;
    } else if (char === "[") {
      depth++;
    } else if (char === "]") {
      depth--;
      if (depth === 0) return value.slice(start, index + 1);
      if (depth < 0) return null;
    }
  }

  return null;
}

function parseStoredQuestions(value: unknown): string[] | null {
  if (typeof value === "string") {
    try {
      return validateQuestions(JSON.parse(value));
    } catch (_) {
      return null;
    }
  }
  return validateQuestions(value);
}

function validateQuestions(value: unknown): string[] | null {
  if (!Array.isArray(value) || value.length !== 5) return null;
  const questions = value.map((item) =>
    typeof item === "string" ? item.trim() : ""
  );
  if (questions.some((question) => question.length === 0)) return null;
  return questions;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Gemini'nin ücretsiz katmanı zaman zaman geçici 429/5xx yanıtları veriyor.
// Bu mantık luma-chat ve dream-interpret ile aynı durum kodlarını ve aynı
// exponential backoff sürelerini kullanır.
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
      console.warn(
        `gemini transient ${response.status}, attempt ${attempt + 1}`,
      );
    } catch (error) {
      console.warn("gemini fetch failed, attempt", attempt + 1, error);
    }
    if (attempt < backoffsMs.length) {
      await new Promise((resolve) => setTimeout(resolve, backoffsMs[attempt]));
    }
  }

  return lastResponse ??
    new Response(
      JSON.stringify({ error: "gemini_unreachable" }),
      { status: 503 },
    );
}

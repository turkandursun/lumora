export const supportedLocales = ["tr", "en", "de", "es", "fr"] as const;
export const journalToneValues = [
  "positive",
  "neutral",
  "mixed",
  "low_mood",
] as const;
export const wellnessSuggestionValues = [
  "breathing",
  "meditation",
  "calm",
] as const;

export type SupportedLocale = typeof supportedLocales[number];
export type JournalTone = typeof journalToneValues[number];
export type WellnessSuggestion = typeof wellnessSuggestionValues[number];

export type JournalToneAnalysisPayload = {
  tone: JournalTone;
  confidence: number;
  message: string;
  show_wellness_suggestions: boolean;
  suggestions: WellnessSuggestion[];
};

export const minimumJournalTextLength = 10;
export const maximumJournalTextLength = 8000;
export const maximumFeedbackMessageLength = 280;
export const wellnessConfidenceThreshold = 0.80;

const supportedLocaleSet = new Set<string>(supportedLocales);
const journalToneSet = new Set<string>(journalToneValues);
const wellnessSuggestionSet = new Set<string>(wellnessSuggestionValues);

// The prompt is the primary semantic guard. This compact deny-list is a
// second line of defence for the explicit diagnosis claims the product must
// never surface. Invalid model output is retried instead of shown to a user.
const disallowedDiagnosticFragments = [
  "depresyondasin",
  "depresyon hastasi",
  "anksiyeten var",
  "anksiyete bozuklugu",
  "travman var",
  "ruhsal hastaligin",
  "psikolojik bozuklugun",
  "you are depressed",
  "you have depression",
  "you have anxiety",
  "anxiety disorder",
  "you have trauma",
  "mental disorder",
  "mental illness",
  "du hast depression",
  "du hast angst",
  "angststorung",
  "du hast ein trauma",
  "psychische storung",
  "tienes depresion",
  "tienes ansiedad",
  "trastorno de ansiedad",
  "tienes un trauma",
  "trastorno mental",
  "tu es depressif",
  "tu es depressive",
  "tu as une depression",
  "tu as de l anxiete",
  "trouble anxieux",
  "tu as un traumatisme",
  "trouble mental",
];

export function normalizeLocale(value: unknown): SupportedLocale {
  if (typeof value !== "string") return "en";
  const languageCode = value.trim().toLowerCase().split(/[-_]/)[0];
  return supportedLocaleSet.has(languageCode)
    ? languageCode as SupportedLocale
    : "en";
}

export function prepareJournalText(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.replace(/\r\n?/g, "\n").trim();
  const codePoints = Array.from(normalized);
  if (codePoints.length < minimumJournalTextLength) return null;

  // Reject punctuation/emoji-only payloads while retaining every supported
  // language. Three letters or numbers are enough to establish real text.
  const meaningfulCharacters = normalized.match(/[\p{L}\p{N}]/gu)?.length ?? 0;
  if (meaningfulCharacters < 3) return null;

  return codePoints.slice(0, maximumJournalTextLength).join("");
}

export function normalizeAnalysisPayload(
  value: unknown,
): JournalToneAnalysisPayload | null {
  if (!isRecord(value)) return null;

  const tone = value.tone;
  if (typeof tone !== "string" || !journalToneSet.has(tone)) return null;

  const rawConfidence = value.confidence;
  if (typeof rawConfidence !== "number" || !Number.isFinite(rawConfidence)) {
    return null;
  }
  const confidence = Math.min(1, Math.max(0, rawConfidence));

  const message = normalizeMessage(value.message);
  if (!message || containsDisallowedDiagnosticClaim(message)) return null;

  if (typeof value.show_wellness_suggestions !== "boolean") return null;
  if (!Array.isArray(value.suggestions)) return null;

  const suggestions: WellnessSuggestion[] = [];
  for (const item of value.suggestions) {
    if (typeof item !== "string" || !wellnessSuggestionSet.has(item)) {
      return null;
    }
    const suggestion = item as WellnessSuggestion;
    if (!suggestions.includes(suggestion)) suggestions.push(suggestion);
  }

  const isEligibleForWellness = tone === "low_mood" &&
    confidence >= wellnessConfidenceThreshold;
  const showWellnessSuggestions = isEligibleForWellness &&
    value.show_wellness_suggestions && suggestions.length > 0;

  return {
    tone: tone as JournalTone,
    confidence,
    message,
    show_wellness_suggestions: showWellnessSuggestions,
    suggestions: showWellnessSuggestions ? suggestions : [],
  };
}

function normalizeMessage(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.replace(/\s+/g, " ").trim();
  if (!normalized) return null;
  return Array.from(normalized)
    .slice(0, maximumFeedbackMessageLength)
    .join("")
    .trim();
}

function containsDisallowedDiagnosticClaim(message: string): boolean {
  const canonical = message
    .normalize("NFKD")
    .replace(/\p{M}/gu, "")
    .replace(/ı/g, "i")
    .replace(/[’']/g, " ")
    .toLowerCase();
  return disallowedDiagnosticFragments.some((fragment) =>
    canonical.includes(fragment)
  );
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

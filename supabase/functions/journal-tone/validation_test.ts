import {
  maximumJournalTextLength,
  normalizeAnalysisPayload,
  normalizeLocale,
  prepareJournalText,
} from "./validation.ts";

Deno.test("supported locale is preserved and regional locale is normalized", () => {
  assertEquals(normalizeLocale("tr-TR"), "tr");
  assertEquals(normalizeLocale("de_DE"), "de");
});

Deno.test("unsupported locale safely falls back to English", () => {
  assertEquals(normalizeLocale("it"), "en");
  assertEquals(normalizeLocale(null), "en");
});

Deno.test("journal text rejects short or punctuation-only content", () => {
  assertEquals(prepareJournalText("kısa"), null);
  assertEquals(prepareJournalText("............"), null);
});

Deno.test("journal text truncation preserves a valid maximum length", () => {
  const prepared = prepareJournalText(
    "a".repeat(maximumJournalTextLength + 50),
  );
  assert(prepared !== null);
  assertEquals(Array.from(prepared).length, maximumJournalTextLength);
});

Deno.test("non-low tone can never expose wellness suggestions", () => {
  const result = normalizeAnalysisPayload({
    tone: "mixed",
    confidence: 0.99,
    message: "The writing contains both a difficult moment and some relief.",
    show_wellness_suggestions: true,
    suggestions: ["breathing", "calm"],
  });

  assert(result !== null);
  assertEquals(result.show_wellness_suggestions, false);
  assertEquals(result.suggestions, []);
});

Deno.test("low mood below threshold can never expose wellness suggestions", () => {
  const result = normalizeAnalysisPayload({
    tone: "low_mood",
    confidence: 0.79,
    message: "There is some heaviness in today's writing.",
    show_wellness_suggestions: true,
    suggestions: ["breathing"],
  });

  assert(result !== null);
  assertEquals(result.show_wellness_suggestions, false);
  assertEquals(result.suggestions, []);
});

Deno.test("eligible low mood keeps allowed suggestions and removes duplicates", () => {
  const result = normalizeAnalysisPayload({
    tone: "low_mood",
    confidence: 1.4,
    message: "There is sustained tiredness and heaviness in today's writing.",
    show_wellness_suggestions: true,
    suggestions: ["breathing", "breathing", "meditation", "calm"],
  });

  assert(result !== null);
  assertEquals(result.confidence, 1);
  assertEquals(result.show_wellness_suggestions, true);
  assertEquals(result.suggestions, ["breathing", "meditation", "calm"]);
});

Deno.test("unknown tone and suggestion values are rejected", () => {
  assertEquals(
    normalizeAnalysisPayload({
      tone: "sad",
      confidence: 0.9,
      message: "A short message.",
      show_wellness_suggestions: false,
      suggestions: [],
    }),
    null,
  );
  assertEquals(
    normalizeAnalysisPayload({
      tone: "low_mood",
      confidence: 0.9,
      message: "A short message.",
      show_wellness_suggestions: true,
      suggestions: ["therapy"],
    }),
    null,
  );
});

Deno.test("explicit diagnostic claims are rejected", () => {
  assertEquals(
    normalizeAnalysisPayload({
      tone: "low_mood",
      confidence: 0.9,
      message: "Depresyondasın ve tedaviye ihtiyacın var.",
      show_wellness_suggestions: true,
      suggestions: ["calm"],
    }),
    null,
  );
});

function assert(
  condition: unknown,
  message = "Assertion failed",
): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals(actual: unknown, expected: unknown): void {
  const actualJson = JSON.stringify(actual);
  const expectedJson = JSON.stringify(expected);
  if (actualJson !== expectedJson) {
    throw new Error(`Expected ${expectedJson}, received ${actualJson}`);
  }
}

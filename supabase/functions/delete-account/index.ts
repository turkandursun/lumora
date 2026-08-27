// Supabase Edge Function: delete-account
//
// Permanently removes the authenticated user's Storage objects, explicit
// public-table rows and finally the Supabase Auth user. The verified JWT is
// the only source of identity; request-body user identifiers are ignored.
//
// Deploy: supabase functions deploy delete-account --no-verify-jwt

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export const accountStorageBuckets = [
  "activity-photos",
  "activity-posts",
  "journal-photos",
] as const;

// meditation-voice is deliberately absent: its objects have not been proven
// to be user uploads and must not be deleted based on an assumed path model.
export const accountOwnedTables = [
  "activity_post_comments",
  "activity_post_likes",
  "dilemma_votes",
  "quote_favorites",
  "daily_question_shares",
  "ai_daily_questions",
  "reminders",
  "user_hobbies",
  "user_backups",
  "mood_logs",
  "letters",
  "dreams",
  "journal_entries",
  "goals",
  "focus_sessions",
  "special_days",
  "activities",
  "activity_posts",
] as const;

export type StorageListItem = {
  name: string;
  isFolder: boolean;
};

export interface DeleteAccountBackend {
  getUser(accessToken: string): Promise<{ id: string } | null>;
  listStorageObjects(
    bucket: string,
    prefix: string,
    offset: number,
    limit: number,
  ): Promise<StorageListItem[]>;
  removeStorageObjects(bucket: string, paths: string[]): Promise<void>;
  deleteRows(table: string, column: string, userId: string): Promise<void>;
  deleteAuthUser(userId: string): Promise<void>;
}

type BackendFactory = () => DeleteAccountBackend;

export async function handleDeleteAccountRequest(
  req: Request,
  backendFactory: BackendFactory = createProductionBackend,
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: corsHeaders,
    });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.match(/^Bearer\s+(.+)$/i)?.[1]?.trim();
  if (!token) return jsonResponse({ error: "unauthorized" }, 401);

  try {
    const backend = backendFactory();
    const user = await backend.getUser(token);
    if (!user) return jsonResponse({ error: "unauthorized" }, 401);

    // Do not parse or trust the request body. Even a forged userId is ignored;
    // every destructive operation uses only the identity verified above.
    await deleteAccountData(backend, user.id);
    return jsonResponse({ deleted: true });
  } catch (error) {
    // Never log JWTs, service-role credentials, object names or user IDs.
    console.error(
      "delete-account failed",
      error instanceof Error ? error.message : "unknown_error",
    );
    return jsonResponse({ error: "account_deletion_failed" }, 500);
  }
}

export async function deleteAccountData(
  backend: DeleteAccountBackend,
  userId: string,
): Promise<void> {
  for (const bucket of accountStorageBuckets) {
    await removeStoragePrefixRecursively(backend, bucket, userId);
  }

  for (const table of accountOwnedTables) {
    await backend.deleteRows(table, "user_id", userId);
  }
  await backend.deleteRows("profiles", "id", userId);

  // Authentication is always last. If any database or Storage operation
  // fails, retrying the function is safe and the Auth user remains available.
  await backend.deleteAuthUser(userId);
}

export async function removeStoragePrefixRecursively(
  backend: DeleteAccountBackend,
  bucket: string,
  userId: string,
): Promise<void> {
  const files: string[] = [];
  await collectStorageFiles(backend, bucket, userId, files);

  const batchSize = 100;
  for (let start = 0; start < files.length; start += batchSize) {
    await backend.removeStorageObjects(
      bucket,
      files.slice(start, start + batchSize),
    );
  }
}

async function collectStorageFiles(
  backend: DeleteAccountBackend,
  bucket: string,
  prefix: string,
  files: string[],
): Promise<void> {
  const pageSize = 100;
  let offset = 0;
  while (true) {
    const page = await backend.listStorageObjects(
      bucket,
      prefix,
      offset,
      pageSize,
    );
    for (const item of page) {
      const path = `${prefix}/${item.name}`;
      if (item.isFolder) {
        await collectStorageFiles(backend, bucket, path, files);
      } else {
        files.push(path);
      }
    }
    if (page.length < pageSize) break;
    offset += page.length;
  }
}

function createProductionBackend(): DeleteAccountBackend {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !serviceRoleKey) {
    throw new Error("server_configuration_error");
  }
  const client = createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  return {
    async getUser(accessToken) {
      const { data, error } = await client.auth.getUser(accessToken);
      if (error || !data.user) return null;
      return { id: data.user.id };
    },
    async listStorageObjects(bucket, prefix, offset, limit) {
      const { data, error } = await client.storage.from(bucket).list(prefix, {
        limit,
        offset,
        sortBy: { column: "name", order: "asc" },
      });
      if (error) throw new Error(`storage_list_failed:${bucket}`);
      return (data ?? []).map((item) => ({
        name: item.name,
        // Supabase's folder placeholders have no object id/metadata.
        isFolder: item.id == null && item.metadata == null,
      }));
    },
    async removeStorageObjects(bucket, paths) {
      if (paths.length === 0) return;
      const { error } = await client.storage.from(bucket).remove(paths);
      if (error && !isMissingObjectError(error)) {
        throw new Error(`storage_remove_failed:${bucket}`);
      }
    },
    async deleteRows(table, column, userId) {
      const { error } = await client.from(table).delete().eq(column, userId);
      if (error) throw new Error(`database_cleanup_failed:${table}`);
    },
    async deleteAuthUser(userId) {
      const { error } = await client.auth.admin.deleteUser(userId);
      if (error) throw new Error("auth_deletion_failed");
    },
  };
}

function isMissingObjectError(
  error: { message?: string; statusCode?: string | number },
) {
  const message = (error.message ?? "").toLowerCase();
  return error.statusCode === 404 || error.statusCode === "404" ||
    message.includes("not found") || message.includes("does not exist");
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

if (import.meta.main) {
  Deno.serve((req) => handleDeleteAccountRequest(req));
}

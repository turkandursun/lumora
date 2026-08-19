import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  accountOwnedTables,
  DeleteAccountBackend,
  handleDeleteAccountRequest,
  StorageListItem,
} from "./index.ts";

class FakeBackend implements DeleteAccountBackend {
  authenticatedUserId: string | null = "user-a";
  authDeleted = false;
  failTable: string | null = null;
  rows = new Map<string, Set<string>>();
  storage = new Map<string, Set<string>>();

  constructor() {
    for (const table of [...accountOwnedTables, "profiles"]) {
      this.rows.set(table, new Set(["user-a", "user-b"]));
    }
    for (
      const bucket of ["activity-photos", "activity-posts", "journal-photos"]
    ) {
      this.storage.set(
        bucket,
        new Set([
          "user-a/root.jpg",
          "user-a/nested/child.jpg",
          "user-b/keep.jpg",
        ]),
      );
    }
  }

  getUser(_token: string) {
    return Promise.resolve(
      this.authenticatedUserId == null
        ? null
        : { id: this.authenticatedUserId },
    );
  }

  listStorageObjects(
    bucket: string,
    prefix: string,
    offset: number,
    limit: number,
  ): Promise<StorageListItem[]> {
    const prefixWithSlash = `${prefix}/`;
    const immediate = new Map<string, boolean>();
    for (const path of this.storage.get(bucket) ?? []) {
      if (!path.startsWith(prefixWithSlash)) continue;
      const remainder = path.slice(prefixWithSlash.length);
      const separator = remainder.indexOf("/");
      if (separator < 0) immediate.set(remainder, false);
      else immediate.set(remainder.slice(0, separator), true);
    }
    return Promise.resolve(
      [...immediate.entries()]
        .sort(([a], [b]) => a.localeCompare(b))
        .slice(offset, offset + limit)
        .map(([name, isFolder]) => ({ name, isFolder })),
    );
  }

  removeStorageObjects(bucket: string, paths: string[]) {
    const objects = this.storage.get(bucket)!;
    for (const path of paths) objects.delete(path);
    return Promise.resolve();
  }

  deleteRows(table: string, _column: string, userId: string) {
    if (table === this.failTable) throw new Error("forced failure");
    this.rows.get(table)?.delete(userId);
    return Promise.resolve();
  }

  deleteAuthUser(userId: string) {
    assertEquals(userId, "user-a");
    this.authDeleted = true;
    return Promise.resolve();
  }
}

function assertCorsHeaders(response: Response) {
  assertEquals(response.headers.get("Access-Control-Allow-Origin"), "*");
  assertEquals(
    response.headers.get("Access-Control-Allow-Headers"),
    "authorization, x-client-info, apikey, content-type",
  );
  assertEquals(
    response.headers.get("Access-Control-Allow-Methods"),
    "POST, OPTIONS",
  );
}

Deno.test("OPTIONS returns 200 with CORS and never requires auth", async () => {
  let factoryCalled = false;
  const response = await handleDeleteAccountRequest(
    new Request("http://local/delete-account", {
      method: "OPTIONS",
      headers: {
        Origin: "http://localhost:55177",
        "Access-Control-Request-Method": "POST",
        "Access-Control-Request-Headers":
          "authorization,x-client-info,apikey,content-type",
      },
    }),
    () => {
      factoryCalled = true;
      return new FakeBackend();
    },
  );

  assertEquals(response.status, 200);
  assertCorsHeaders(response);
  assertEquals(factoryCalled, false);
});

Deno.test("unauthenticated request returns 401", async () => {
  let factoryCalled = false;
  const response = await handleDeleteAccountRequest(
    new Request("http://local/delete-account", { method: "POST" }),
    () => {
      factoryCalled = true;
      return new FakeBackend();
    },
  );
  assertEquals(response.status, 401);
  assertCorsHeaders(response);
  assertEquals(factoryCalled, false);
});

Deno.test("unsupported method returns 405 with CORS", async () => {
  const response = await handleDeleteAccountRequest(
    new Request("http://local/delete-account", { method: "GET" }),
    () => new FakeBackend(),
  );
  assertEquals(response.status, 405);
  assertCorsHeaders(response);
});

Deno.test("forged body userId is ignored and only JWT user is deleted", async () => {
  const backend = new FakeBackend();
  const response = await handleDeleteAccountRequest(
    new Request("http://local/delete-account", {
      method: "POST",
      headers: {
        Authorization: "Bearer valid-token",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ userId: "user-b" }),
    }),
    () => backend,
  );

  assertEquals(response.status, 200);
  assertCorsHeaders(response);
  for (const rows of backend.rows.values()) {
    assertEquals(rows.has("user-a"), false);
    assertEquals(rows.has("user-b"), true);
  }
  for (const objects of backend.storage.values()) {
    assertEquals(
      [...objects].some((path) => path.startsWith("user-a/")),
      false,
    );
    assertEquals(objects.has("user-b/keep.jpg"), true);
  }
  assertEquals(backend.authDeleted, true);
  assertEquals(accountOwnedTables.includes("focus_sessions"), true);
});

Deno.test("database failure prevents Auth deletion and retry is idempotent", async () => {
  const backend = new FakeBackend();
  backend.failTable = "journal_entries";
  const request = () =>
    new Request("http://local/delete-account", {
      method: "POST",
      headers: { Authorization: "Bearer valid-token" },
    });

  const failed = await handleDeleteAccountRequest(request(), () => backend);
  assertEquals(failed.status, 500);
  assertCorsHeaders(failed);
  assertEquals(backend.authDeleted, false);

  backend.failTable = null;
  const retried = await handleDeleteAccountRequest(request(), () => backend);
  assertEquals(retried.status, 200);
  assertEquals(backend.authDeleted, true);
});

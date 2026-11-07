import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Sends the chat push for one new message. The database webhook delivers the
// row; this function fans it out to every other member's registered devices.
// Messages are data-only so the app keeps its grouped, per-circle tray
// notifications and its own tap routing.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

type ChatRecord = {
  id: string;
  circle_id: string;
  sender_id: string;
  kind: string;
  body: string | null;
};

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

let cachedAccessToken: { value: string; expiresAt: number } | null = null;
const secretCache = new Map<string, string | null>();

function serviceHeaders(): Record<string, string> {
  return {
    apikey: SERVICE_ROLE_KEY,
    Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
    "Content-Type": "application/json",
  };
}

async function readSecret(name: string): Promise<string | null> {
  if (secretCache.has(name)) return secretCache.get(name)!;
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/read_push_secret`, {
    method: "POST",
    headers: serviceHeaders(),
    body: JSON.stringify({ p_name: name }),
  });
  const value = response.ok ? ((await response.json()) as string | null) : null;
  secretCache.set(name, value);
  return value;
}

async function select<T>(path: string): Promise<T[]> {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: serviceHeaders(),
  });
  if (!response.ok) {
    throw new Error(`PostgREST ${response.status}: ${await response.text()}`);
  }
  return (await response.json()) as T[];
}

function base64Url(input: Uint8Array | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : input;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const body = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const binary = atob(body);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index++) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes.buffer;
}

async function fcmAccessToken(account: ServiceAccount): Promise<string> {
  if (cachedAccessToken && Date.now() < cachedAccessToken.expiresAt - 60_000) {
    return cachedAccessToken.value;
  }

  const now = Math.floor(Date.now() / 1000);
  const unsigned = [
    base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" })),
    base64Url(
      JSON.stringify({
        iss: account.client_email,
        scope: FCM_SCOPE,
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600,
      }),
    ),
  ].join(".");

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(unsigned),
    ),
  );
  const assertion = `${unsigned}.${base64Url(signature)}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Google token ${response.status}: ${JSON.stringify(data)}`);
  }
  cachedAccessToken = {
    value: data.access_token,
    expiresAt: Date.now() + data.expires_in * 1000,
  };
  return cachedAccessToken.value;
}

function preview(kind: string, body: string | null): string | null {
  switch (kind) {
    case "text":
      return body ?? "";
    case "location_share":
      return "📍 Shared a location";
    default:
      return null;
  }
}

async function deleteTarget(target: string): Promise<void> {
  await fetch(
    `${SUPABASE_URL}/rest/v1/device_push_tokens?token=eq.${
      encodeURIComponent(target)
    }`,
    { method: "DELETE", headers: serviceHeaders() },
  );
}

function sendTo(
  accessToken: string,
  projectId: string,
  target: string,
  data: Record<string, string>,
): Promise<Response> {
  return fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: target,
          data,
          android: { priority: "HIGH", ttl: "86400s" },
        },
      }),
    },
  );
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const secret = await readSecret("push_webhook_secret");
  if (!secret || request.headers.get("Authorization") !== `Bearer ${secret}`) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }

  const payload = await request.json().catch(() => null);
  const record = payload?.record as ChatRecord | undefined;
  if (!record?.id || !record.circle_id || !record.sender_id) {
    return Response.json({ error: "bad payload" }, { status: 400 });
  }

  const text = preview(record.kind, record.body);
  if (text === null) {
    return Response.json({ skipped: "kind" });
  }

  const accountJson = await readSecret("firebase_service_account");
  if (!accountJson) {
    return Response.json({ error: "push not configured" }, { status: 503 });
  }
  const account = JSON.parse(accountJson) as ServiceAccount;

  const [circle] = await select<{ name: string }>(
    `circles?id=eq.${record.circle_id}&select=name`,
  );
  const [sender] = await select<{ display_name: string }>(
    `profiles?id=eq.${record.sender_id}&select=display_name`,
  );
  const members = await select<{ user_id: string }>(
    `circle_members?circle_id=eq.${record.circle_id}&user_id=neq.${record.sender_id}&select=user_id`,
  );
  if (members.length === 0) {
    return Response.json({ skipped: "no members" });
  }

  const ids = members.map((member) => member.user_id).join(",");
  const targets = await select<{ token: string }>(
    `device_push_tokens?user_id=in.(${ids})&select=token`,
  );
  if (targets.length === 0) {
    return Response.json({ skipped: "no devices" });
  }

  const circleName = circle?.name ?? "Circle";
  const senderName = sender?.display_name ?? "A friend";
  const accessToken = await fcmAccessToken(account);
  const data = {
    kind: "chat",
    circle_id: record.circle_id,
    circle_name: circleName,
    message_id: record.id,
    sender_name: senderName,
    title: `${senderName} • ${circleName}`,
    body: text,
  };

  let sent = 0;
  let removed = 0;
  await Promise.all(
    targets.map(async ({ token }) => {
      const response = await sendTo(
        accessToken,
        account.project_id,
        token,
        data,
      );
      if (response.ok) {
        sent++;
        return;
      }
      const error = await response.text();
      if (response.status === 404 || error.includes("UNREGISTERED")) {
        await deleteTarget(token);
        removed++;
        return;
      }
      console.error(`FCM ${response.status}: ${error}`);
    }),
  );

  return Response.json({ sent, removed, targets: targets.length });
});

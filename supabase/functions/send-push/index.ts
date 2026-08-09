import { JWT } from "npm:google-auth-library@9";

type PushPayload = {
  token?: string;
  notification?: {
    title?: string;
    body?: string;
  };
  data?: Record<string, unknown>;
};

const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
const pushSecret = Deno.env.get("PUSH_DISPATCH_SECRET");

async function getAccessToken(): Promise<{ token: string; projectId: string }> {
  if (!serviceAccountRaw) {
    throw new Error("Missing FIREBASE_SERVICE_ACCOUNT_JSON secret");
  }

  const parsed = JSON.parse(serviceAccountRaw) as {
    client_email: string;
    private_key: string;
    project_id: string;
  };

  if (!parsed.client_email || !parsed.private_key || !parsed.project_id) {
    throw new Error("Invalid FIREBASE_SERVICE_ACCOUNT_JSON");
  }

  const jwt = new JWT({
    email: parsed.client_email,
    key: parsed.private_key,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });

  const tokenResult = await jwt.authorize();
  const token = tokenResult.access_token;
  if (!token) {
    throw new Error("Unable to obtain FCM access token");
  }

  return { token, projectId: parsed.project_id };
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    if (pushSecret) {
      const incomingSecret = req.headers.get("x-push-secret");
      if (incomingSecret !== pushSecret) {
        return new Response("Unauthorized", { status: 401 });
      }
    }

    const body = (await req.json()) as PushPayload;
    if (!body.token || body.token.trim().length === 0) {
      return new Response(JSON.stringify({ ok: false, error: "Missing token" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { token, projectId } = await getAccessToken();
    const endpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    const notificationTitle = body.notification?.title ?? "Prince Academy";
    const notificationBody = body.notification?.body ?? "";

    const dataPayload: Record<string, string> = {};
    for (const [key, value] of Object.entries(body.data ?? {})) {
      if (value == null) continue;
      dataPayload[key] = String(value);
    }

    const fcmPayload = {
      message: {
        token: body.token,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: dataPayload,
        android: {
          priority: "high",
          notification: {
            channel_id: "prince_academy_high",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      },
    };

    const fcmResponse = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(fcmPayload),
    });

    const responseText = await fcmResponse.text();
    if (!fcmResponse.ok) {
      return new Response(
        JSON.stringify({
          ok: false,
          status: fcmResponse.status,
          error: responseText,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(JSON.stringify({ ok: true, result: responseText }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

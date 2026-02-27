import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "GET") return json({ error: "Method Not Allowed" }, 405);

  const url = new URL(req.url);
  const identityId     = url.searchParams.get("identity_id");
  const deviceInstallId = url.searchParams.get("device_install_id");

  if (!identityId || !deviceInstallId) {
    return json({ error: "identity_id and device_install_id required" }, 400);
  }

  // Verify ownership
  const { data: identity } = await supabase
    .from("identities")
    .select("id")
    .eq("id", identityId)
    .eq("device_install_id", deviceInstallId)
    .single();

  if (!identity) return json({ error: "Access denied" }, 403);

  const limit = parseInt(url.searchParams.get("limit") ?? "50");

  const { data: events, error } = await supabase
    .from("events")
    .select("*")
    .eq("identity_id", identityId)
    .order("created_at", { ascending: false })
    .limit(limit);

  if (error) return json({ error: error.message }, 500);

  return json({ events: events ?? [] });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

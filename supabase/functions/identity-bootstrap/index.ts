import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

const ZERO_EMBEDDING = Array(64).fill(0);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method Not Allowed" }, 405);
  }

  let body: { device_install_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const { device_install_id } = body;
  if (!device_install_id) {
    return json({ error: "device_install_id required" }, 400);
  }

  // Return existing identity if found
  const { data: existing } = await supabase
    .from("identities")
    .select("*")
    .eq("device_install_id", device_install_id)
    .maybeSingle();

  if (existing) {
    return json({ identity: existing });
  }

  // Create fresh zero identity
  const { data: created, error } = await supabase
    .from("identities")
    .insert({
      device_install_id,
      embedding: ZERO_EMBEDDING,
      anti_embedding: ZERO_EMBEDDING,
      version: 1,
      stability: 1.0,
      count_me: 0,
      count_not_me: 0,
      count_maybe: 0,
    })
    .select()
    .single();

  if (error) {
    return json({ error: error.message }, 500);
  }

  return json({ identity: created });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

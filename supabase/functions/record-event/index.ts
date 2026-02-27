import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

// ── Reinforcement constants (mirrors ReinforcementService.swift) ──────────────
const ALPHA       = 0.18;   // me
const ALPHA_MAYBE = 0.05;   // maybe
const GAMMA       = 0.14;   // notMe / style-affecting returned
const ANCHOR_MULT = 1.8;
const ANCHOR_CATEGORIES = new Set(["sofa", "sectional"]);
const STYLE_RETURN_REASONS = new Set([
  "colorMismatch", "materialMismatch", "qualityDisappointment", "spaceConflict",
]);

// ── Embedding math ────────────────────────────────────────────────────────────
function blend(current: number[], toward: number[], weight: number): number[] {
  const w = Math.max(0, Math.min(1, weight));
  return current.map((v, i) => v * (1 - w) + toward[i] * w);
}

function updatedStability(before: number[], after: number[], prior: number): number {
  const avgDelta = before.reduce((s, v, i) => s + Math.abs(after[i] - v), 0) / before.length;
  const raw = Math.max(0, Math.min(1, 1 - avgDelta * 10));
  return 0.9 * prior + 0.1 * raw;
}

// ── Handler ───────────────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method Not Allowed" }, 405);

  let body: {
    device_install_id: string;
    identity_id: string;
    vote: string;
    return_reason?: string;
    category: string;
    object_embedding: number[];
    context?: object;
    scores?: object;
  };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const {
    device_install_id, identity_id, vote, return_reason,
    category, object_embedding, context, scores,
  } = body;

  if (!device_install_id || !identity_id || !vote || !category || !object_embedding) {
    return json({ error: "Missing required fields" }, 400);
  }

  // Verify ownership
  const { data: identity, error: idErr } = await supabase
    .from("identities")
    .select("*")
    .eq("id", identity_id)
    .eq("device_install_id", device_install_id)
    .single();

  if (idErr || !identity) {
    return json({ error: "Identity not found or access denied" }, 403);
  }

  const isAnchor = ANCHOR_CATEGORIES.has(category);
  const isPending = isAnchor && (vote === "me" || vote === "notMe");

  // Insert event row
  const { error: evErr } = await supabase.from("events").insert({
    identity_id,
    vote,
    return_reason: return_reason ?? null,
    category,
    object_embedding,
    context: context ?? null,
    scores: scores ?? null,
    pending: isPending,
  });

  if (evErr) return json({ error: evErr.message }, 500);

  // Anchor hold: create pending record, return identity unchanged
  if (isPending) {
    const unlockAt = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString();
    await supabase.from("pending_reinforcements").insert({
      identity_id,
      object_embedding,
      category,
      vote,
      unlock_at: unlockAt,
    });

    // Bump version + counts only
    const countField = vote === "me" ? "count_me" : "count_not_me";
    await supabase
      .from("identities")
      .update({
        version: identity.version + 1,
        [countField]: identity[countField] + 1,
      })
      .eq("id", identity_id);

    return json({ identity, pending: true });
  }

  // Immediate reinforcement
  let embedding: number[]     = identity.embedding;
  let antiEmbedding: number[] = identity.anti_embedding;
  let countMe:    number = identity.count_me;
  let countNotMe: number = identity.count_not_me;
  let countMaybe: number = identity.count_maybe;
  const prevEmbedding = [...embedding];

  switch (vote) {
    case "me":
      embedding = blend(embedding, object_embedding, ALPHA);
      countMe++;
      break;
    case "notMe":
      antiEmbedding = blend(antiEmbedding, object_embedding, GAMMA);
      countNotMe++;
      break;
    case "maybe":
      embedding = blend(embedding, object_embedding, ALPHA_MAYBE);
      countMaybe++;
      break;
    case "returned":
      if (return_reason && STYLE_RETURN_REASONS.has(return_reason)) {
        antiEmbedding = blend(antiEmbedding, object_embedding, GAMMA);
      }
      countNotMe++;
      break;
  }

  const stability = updatedStability(prevEmbedding, embedding, identity.stability);

  const { data: updated, error: upErr } = await supabase
    .from("identities")
    .update({
      embedding,
      anti_embedding: antiEmbedding,
      stability,
      version: identity.version + 1,
      count_me: countMe,
      count_not_me: countNotMe,
      count_maybe: countMaybe,
    })
    .eq("id", identity_id)
    .select()
    .single();

  if (upErr) return json({ error: upErr.message }, 500);

  return json({ identity: updated, pending: false });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

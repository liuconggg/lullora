// Supabase Edge Function: Check if email already exists
// Deploy: supabase functions deploy check-email --no-verify-jwt

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Parse body based on content type
async function parseBody(req: Request): Promise<Record<string, string>> {
  const contentType = req.headers.get("content-type") || "";

  if (contentType.includes("application/json")) {
    return await req.json();
  } else if (contentType.includes("application/x-www-form-urlencoded")) {
    const text = await req.text();
    const params = new URLSearchParams(text);
    const result: Record<string, string> = {};
    params.forEach((value, key) => {
      result[key] = value;
    });
    return result;
  } else {
    // Try JSON first, then form-urlencoded
    const text = await req.text();
    try {
      return JSON.parse(text);
    } catch {
      const params = new URLSearchParams(text);
      const result: Record<string, string> = {};
      params.forEach((value, key) => {
        result[key] = value;
      });
      return result;
    }
  }
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    console.log("=== Check Email Request ===");
    console.log("Method:", req.method);
    console.log("Content-Type:", req.headers.get("content-type"));

    const body = await parseBody(req);
    console.log("Parsed body:", JSON.stringify(body));

    // Extract and clean email
    const rawEmail = body.email;
    const email = rawEmail?.toString().trim().toLowerCase();

    console.log("Raw email:", rawEmail);
    console.log("Cleaned email:", email);

    // Validate email
    if (!email) {
      console.log("ERROR: Email is empty or missing");
      return new Response(
        JSON.stringify({ error: "Email is required", exists: false }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Basic email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      console.log("ERROR: Invalid email format");
      return new Response(
        JSON.stringify({ error: "Invalid email format", exists: false }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Supabase Admin client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // Check if user exists by listing users with email filter
    console.log("Checking Supabase for email...");
    const { data, error } = await supabase.auth.admin.listUsers();

    if (error) {
      console.error("Supabase error:", error.message);
      return new Response(
        JSON.stringify({ error: error.message, exists: false }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Check if email exists in the users list
    const userExists = data.users.some(
      (user) => user.email?.toLowerCase() === email
    );

    console.log(`Result: Email "${email}" exists = ${userExists}`);

    return new Response(
      JSON.stringify({
        exists: userExists,
        email: email,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message, exists: false }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

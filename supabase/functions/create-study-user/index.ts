// Supabase Edge Function: Create Study User from Qualtrics Webhook
// Deploy: supabase functions deploy create-study-user

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Resend } from "https://esm.sh/resend@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Generate a random password
function generatePassword(length = 12): string {
  const chars =
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%";
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array.from(array)
    .map((byte) => chars[byte % chars.length])
    .join("");
}

// Build HTML email - just credentials and app download
function buildEmailHtml(
  name: string,
  email: string,
  password: string,
  iosDownloadUrl: string,
  androidDownloadUrl: string
): string {
  return `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #6B46C1, #4299E1); padding: 20px; border-radius: 8px; color: white; text-align: center; }
    .credentials { background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .credentials code { background: #e0e0e0; padding: 4px 8px; border-radius: 4px; font-family: monospace; }
    .steps { background: #fff; border: 1px solid #e0e0e0; padding: 20px; border-radius: 8px; }
    .step { margin-bottom: 15px; padding-left: 30px; position: relative; }
    .step:before { content: attr(data-step); position: absolute; left: 0; color: #6B46C1; font-weight: bold; }
    .button { display: inline-block; background: #6B46C1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 10px 5px 10px 0; }
    .button-android { background: #34A853; }
    .download-buttons { margin: 15px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Welcome to the Sleep Study!</h1>
    </div>
    
    <p>Dear ${name},</p>
    <p>Thank you for completing the pre-screening survey. Your account has been created successfully!</p>
    
    <div class="credentials">
      <h3>Your Login Credentials</h3>
      <p><strong>Email:</strong> <code>${email}</code></p>
      <p><strong>Password:</strong> <code>${password}</code></p>
      <p style="color: #666; font-size: 14px;">Please keep these credentials safe. You can change your password after logging in.</p>
    </div>
    
    <div class="steps">
      <h3>Next Steps</h3>
      <div class="step" data-step="1.">
        <strong>Download the Lullora App</strong><br>
        <p style="margin: 10px 0 5px 0; color: #666;">Choose your device:</p>
        <div class="download-buttons">
          <a href="${iosDownloadUrl}" class="button">📱 Download for iOS</a>
          <a href="${androidDownloadUrl}" class="button button-android">🤖 Download for Android</a>
        </div>
      </div>
      
      <div class="step" data-step="2.">
        <strong>Log In & Start the Study</strong><br>
        Open the app and log in with the credentials above to begin.
      </div>
    </div>
    
    <p>If you have any questions, please reply to this email.</p>
    <p>Best regards,<br>The Research Team</p>
  </div>
</body>
</html>
`;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    console.log("Received webhook:", JSON.stringify(body));

    // Extract data from Qualtrics webhook payload
    const { name: rawName, email: rawEmail, responseId } = body;

    // Trim whitespace/newlines that Qualtrics sometimes adds
    const name = rawName?.toString().trim();
    const email = rawEmail?.toString().trim().toLowerCase();

    // Validate required fields
    if (!name || !email) {
      console.error("Missing required fields: name or email");
      return new Response(
        JSON.stringify({ error: "Missing required fields: name and email" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Basic email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      console.error("Invalid email format:", email);
      return new Response(
        JSON.stringify({ error: "Invalid email format", received: email }),
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

    // Generate password
    const password = generatePassword();

    // Create Supabase auth user
    const { data: authData, error: authError } =
      await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { full_name: name, qualtrics_response_id: responseId },
      });

    if (authError) {
      console.error("Failed to create user:", authError.message);

      // Check if user already exists
      if (authError.message.includes("already been registered")) {
        return new Response(
          JSON.stringify({ error: "User already exists", email }),
          {
            status: 409,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(JSON.stringify({ error: authError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log(`Created user: ${email} (ID: ${authData.user.id})`);

    // Send welcome email with credentials
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail = Deno.env.get("FROM_EMAIL") || "noreply@resend.dev";
    const iosDownloadUrl =
      Deno.env.get("IOS_DOWNLOAD_URL") ||
      "https://testflight.apple.com/join/yourapp";
    const androidDownloadUrl =
      Deno.env.get("ANDROID_DOWNLOAD_URL") ||
      "https://drive.google.com/file/d/1rU70YHwmf-52tFdbOA0EC8t58AGZpIJh/view?usp=drive_link";

    if (resendApiKey) {
      const resend = new Resend(resendApiKey);

      const { error: emailError } = await resend.emails.send({
        from: fromEmail,
        to: email,
        subject: "Welcome to Lullora Sleep Study - Your Login Credentials",
        html: buildEmailHtml(
          name,
          email,
          password,
          iosDownloadUrl,
          androidDownloadUrl
        ),
      });

      if (emailError) {
        console.error("Failed to send email:", emailError);
        // Don't fail the whole request if email fails - user was still created
      } else {
        console.log(`Welcome email sent to: ${email}`);
      }
    } else {
      console.warn("RESEND_API_KEY not set - skipping email");
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "User created successfully",
        userId: authData.user.id,
        email,
        password, // Return password so Qualtrics can use it in email
        name,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error processing webhook:", error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

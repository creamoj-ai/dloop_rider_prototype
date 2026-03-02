#!/usr/bin/env node

const projectId = "aqpwfurradxbnqvycvkm";
const managementToken = "sbp_f908f5e2621a6a554cea8b30720e74ebeea4f3f7";
const newToken = "EAAVfoVVjNTUBQZBbBGwfKgVxs0RggwvZALpJmHXJWDlHfsTXUSTNimslU2tmEulAXkpODX6qrrfiHYI5HprrgX6sz4r3UufL6iNJlUIkPIatnzyOHI6xq0iarS7UNRHQkBP1xaJAq3MJcji7jjaIvucTa87swSQI9UkpbdYKecK9mfZBPdObFQlxZAMrVZBmK5LZAhyJNwoo8FRejws9yGeNWlBzZCTfPWZCC3IMNO7U57qi5FCi4jQNVXoHZBsZBdhuXpWNsABZBnegAXEV6tYy5wZD";

async function updateFinalToken() {
  try {
    console.log("🔑 Updating WhatsApp token with correct permissions...");

    // Delete old secret
    console.log("1️⃣ Removing old token...");
    const deleteResp = await fetch(
      `https://api.supabase.com/v1/projects/${projectId}/secrets/WHATSAPP_ACCESS_TOKEN`,
      { method: "DELETE", headers: { "Authorization": `Bearer ${managementToken}` } }
    );
    console.log(`Delete: ${deleteResp.status}`);

    await new Promise(r => setTimeout(r, 500));

    // Add new token
    console.log("2️⃣ Adding new token with full permissions...");
    const addResp = await fetch(
      `https://api.supabase.com/v1/projects/${projectId}/secrets`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${managementToken}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify([{ name: "WHATSAPP_ACCESS_TOKEN", value: newToken }])
      }
    );

    console.log(`Add: ${addResp.status}`);
    if (addResp.ok || addResp.status === 201) {
      console.log("✅ Token updated successfully!");
      console.log("\n📋 Next steps:");
      console.log("1. Redeploy the whatsapp-webhook function");
      console.log("2. Test the webhook");
      console.log("3. Check logs for success!");
    } else {
      console.log("⚠️ Status:", addResp.status);
    }
  } catch (error) {
    console.error("❌ Error:", error.message);
  }
}

updateFinalToken();

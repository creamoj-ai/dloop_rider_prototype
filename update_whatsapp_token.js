#!/usr/bin/env node

const projectId = "aqpwfurradxbnqvycvkm";
const token = "sbp_f908f5e2621a6a554cea8b30720e74ebeea4f3f7";
const newWhatsAppToken = "EAAVfoVVjNTUBQxFV09Ky6rY57c3rTJRnMYZAz6uTTIDOW0Wp2d1TdZAGywUInZBcS8smJ3SOTmRkABP7wFggQgn0BEERdTb1nv8iW7ZAOk4AM4Arok2VIxYFucWjV8VRIwoaCANWxLJu92jQgZB4uqZBOn48V9gpV4svXVlZBEpvUZB4PEHyy8raOXeEMAXmk20D0BO78k6TRQE7vxu9rdxsi0hdd9UjnhJ4ZAYv6GlPSAYWbqEEUWZC4wlUEO3TwSvaHuEdSngmegqOnTeVZBieP8ZD";

async function updateToken() {
  try {
    console.log("🔑 Updating WhatsApp access token in Supabase...");

    // Delete old secret first
    console.log("1️⃣ Deleting old token...");
    const deleteResponse = await fetch(
      `https://api.supabase.com/v1/projects/${projectId}/secrets/WHATSAPP_ACCESS_TOKEN`,
      {
        method: "DELETE",
        headers: {
          "Authorization": `Bearer ${token}`
        }
      }
    );

    console.log(`Delete status: ${deleteResponse.status}`);

    // Wait a moment
    await new Promise(r => setTimeout(r, 1000));

    // Add new secret
    console.log("2️⃣ Adding new token...");
    const addResponse = await fetch(
      `https://api.supabase.com/v1/projects/${projectId}/secrets`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify([
          {
            name: "WHATSAPP_ACCESS_TOKEN",
            value: newWhatsAppToken
          }
        ])
      }
    );

    console.log(`Add status: ${addResponse.status}`);
    const text = await addResponse.text();
    console.log(`Response: ${text || "(empty)"}`);

    if (addResponse.ok || addResponse.status === 201) {
      console.log("✅ Token updated successfully!");
      console.log("⏳ Waiting 30 seconds, then you need to REDEPLOY the function...");
    }
  } catch (error) {
    console.error("❌ Error:", error.message);
  }
}

updateToken();

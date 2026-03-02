#!/usr/bin/env node

const projectId = "aqpwfurradxbnqvycvkm";
const token = "sbp_f908f5e2621a6a554cea8b30720e74ebeea4f3f7";

const secrets = [
  {
    name: "DB_URL",
    value: "https://aqpwfurradxbnqvycvkm.supabase.co"
  },
  {
    name: "DB_ANON_KEY",
    value: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxcHdmdXJyYWR4Ym5xdnljdmttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMTk3NzAsImV4cCI6MjA4NTY5NTc3MH0.Ekhco06o8_88e8tQJHm4EjEa0HOQv8Z-gAHa1busvog"
  },
  {
    name: "DB_ROLE_KEY",
    value: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxcHdmdXJyYWR4Ym5xdnljdmttIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDExOTc3MCwiZXhwIjoyMDg1Njk1NzcwfQ.V04RNO9XpWbmWR-yMY21mx1XEBKsPSk4fKl7FT8AGpw"
  }
];

async function addSecrets() {
  try {
    console.log("🔐 Adding secrets to Supabase project...");

    const response = await fetch(`https://api.supabase.com/v1/projects/${projectId}/secrets`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(secrets)
    });

    const text = await response.text();
    console.log(`Status: ${response.status}`);
    console.log(`Response: ${text}`);

    if (response.ok && text) {
      const data = JSON.parse(text);
      console.log("✅ Secrets added successfully!");
    } else if (response.status === 204) {
      console.log("✅ Secrets added successfully (204 No Content)!");
    } else {
      console.error("❌ Error:", text);
    }
  } catch (error) {
    console.error("❌ Error:", error.message);
  }
}

addSecrets();

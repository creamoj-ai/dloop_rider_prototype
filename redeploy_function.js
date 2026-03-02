#!/usr/bin/env node

const projectId = "aqpwfurradxbnqvycvkm";
const functionName = "whatsapp-webhook";
const token = "sbp_f908f5e2621a6a554cea8b30720e74ebeea4f3f7";

async function redeployFunction() {
  try {
    console.log(`🚀 Redeploying function: ${functionName}...`);

    // Try to trigger redeploy via API
    const response = await fetch(
      `https://api.supabase.com/v1/projects/${projectId}/functions/${functionName}/redeploy`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json"
        }
      }
    );

    const text = await response.text();
    console.log(`Status: ${response.status}`);
    console.log(`Response: ${text || "(empty response)"}`);

    if (response.ok || response.status === 202 || response.status === 204) {
      console.log(`✅ Function ${functionName} redeployed successfully!`);
      console.log("⏳ Wait 30-60 seconds for deployment to complete...");
    } else {
      console.log(`ℹ️ API endpoint may not support redeploy via Management API`);
      console.log(`\n📋 Please redeploy manually:`);
      console.log(`1. Go to: https://supabase.com/dashboard/project/${projectId}/functions/${functionName}`);
      console.log(`2. Click the ⋮ (three dots) menu`);
      console.log(`3. Select "Redeploy function"`);
    }
  } catch (error) {
    console.error("❌ Error:", error.message);
    console.log(`\n📋 Please redeploy manually:`);
    console.log(`1. Go to: https://supabase.com/dashboard/project/${projectId}/functions/${functionName}`);
    console.log(`2. Click the ⋮ (three dots) menu`);
    console.log(`3. Select "Redeploy function"`);
  }
}

redeployFunction();

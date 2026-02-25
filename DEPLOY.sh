#!/bin/bash

# WhatsApp Bot MVP - Deployment Script
# Run this after setting secrets in Supabase dashboard

set -e

PROJECT_ID="aqpwfurradxbnqvycvkm"
SUPABASE_URL="https://aqpwfurradxbnqvycvkm.supabase.co"

echo "🚀 WhatsApp Bot MVP - Deployment"
echo "=================================="
echo ""
echo "Project: $PROJECT_ID"
echo "URL: $SUPABASE_URL"
echo ""

# Check if secrets are configured
echo "📋 Step 1: Verify Secrets"
echo "=================================="
echo ""
echo "⚠️  IMPORTANT: Before proceeding, you must set these secrets in:"
echo "   https://supabase.com/dashboard/project/$PROJECT_ID/settings/secrets"
echo ""
echo "Required secrets:"
echo "  ✓ OPENAI_API_KEY"
echo "  ✓ WHATSAPP_PHONE_NUMBER_ID"
echo "  ✓ WHATSAPP_ACCESS_TOKEN"
echo "  ✓ WHATSAPP_VERIFY_TOKEN = dloop_wa_verify_2026"
echo ""
read -p "Have you set all 4 secrets? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Please set the secrets first, then run this script again."
  exit 1
fi

# Deploy functions
echo ""
echo "📦 Step 2: Deploy Functions"
echo "=================================="
echo ""

if ! command -v supabase &> /dev/null; then
  echo "❌ Supabase CLI not found."
  echo ""
  echo "Install via:"
  echo "  • macOS: brew install supabase/tap/supabase"
  echo "  • Linux: curl https://dl.supabase.com/cli/install.sh | sh"
  echo "  • Windows: https://github.com/supabase/cli/releases"
  exit 1
fi

echo "Deploying functions..."
supabase deploy --project-ref "$PROJECT_ID" || {
  echo "❌ Deployment failed. Check your Supabase CLI setup."
  exit 1
}

echo ""
echo "✅ Functions deployed!"
echo ""

# Test deployment
echo ""
echo "🧪 Step 3: Test Deployment"
echo "=================================="
echo ""

echo "Testing simulate endpoint..."
echo ""
echo "Request:"
echo '  curl -X POST '"$SUPABASE_URL"'/functions/v1/whatsapp-simulate \'
echo '    -H "Content-Type: application/json" \'
echo "    -d '{\"phone\":\"+393331111111\",\"text\":\"Ciao\",\"name\":\"Test\"}'"
echo ""

RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/whatsapp-simulate" \
  -H "Content-Type: application/json" \
  -d '{"phone":"+393331111111","text":"Ciao","name":"Test Customer"}')

echo "Response:"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"

echo ""

if echo "$RESPONSE" | grep -q "success.*true"; then
  echo "✅ Simulate endpoint working!"
else
  echo "⚠️  Simulate endpoint returned error. Check:"
  echo "  1. Secrets are set correctly"
  echo "  2. OpenAI API key has credits"
  echo "  3. Supabase function logs"
fi

# Setup Meta Webhook
echo ""
echo "🔗 Step 4: Setup Meta Webhook"
echo "=================================="
echo ""
echo "Go to Meta Developer Console and register webhook:"
echo ""
echo "Webhook URL:"
echo "  $SUPABASE_URL/functions/v1/whatsapp-webhook"
echo ""
echo "Verify Token:"
echo "  dloop_wa_verify_2026"
echo ""
echo "Subscribe to:"
echo "  ✓ messages"
echo "  ✓ message_status"
echo ""
read -p "Have you registered the webhook? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "⚠️  Please register the webhook in Meta console to receive WhatsApp messages."
  echo "   See WHATSAPP_BOT_DEPLOYMENT.md for details."
fi

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📊 Next Steps:"
echo "  1. Test with dealer: /rider/contacts (send WhatsApp message)"
echo "  2. Monitor logs: https://supabase.com/dashboard/project/$PROJECT_ID/functions"
echo "  3. Check messages: SELECT * FROM whatsapp_messages ORDER BY created_at DESC;"
echo ""

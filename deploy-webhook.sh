#!/bin/bash
# Deploy whatsapp-webhook to Supabase Edge Functions
# Run this script to deploy the fixed webhook

echo "🚀 Deploying whatsapp-webhook to Supabase..."
echo ""

# Deploy the function
npx supabase functions deploy whatsapp-webhook \
  --project-ref aqpwfurradxbnqvycvkm \
  --no-verify-jwt

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Deployment successful!"
  echo ""
  echo "📋 Next steps:"
  echo "1. Test the webhook by sending a WhatsApp message to: +39 328 1854639"
  echo "2. Check logs: https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/functions/whatsapp-webhook/logs"
  echo "3. If still failing, check the detailed error logs added to the function"
  echo ""
  echo "🔧 Bugs fixed in this deployment:"
  echo "  - Fixed undefined conversation_id in createDeliveryOrder"
  echo "  - Fixed undefined customer_phone in createDeliveryOrder"
  echo "  - Fixed undefined notes field (was opts.notes, now opts.customerNotes)"
  echo "  - Fixed environment variable names (SUPABASE_URL → DB_URL, etc.)"
  echo "  - Added detailed error logging for debugging"
else
  echo ""
  echo "❌ Deployment failed!"
  echo ""
  echo "Common issues:"
  echo "  - Not logged in: Run 'npx supabase login' first"
  echo "  - No access token: Set SUPABASE_ACCESS_TOKEN environment variable"
  echo ""
  echo "To login manually:"
  echo "  1. Go to: https://app.supabase.com/account/tokens"
  echo "  2. Generate an access token"
  echo "  3. Run: export SUPABASE_ACCESS_TOKEN='your-token-here'"
  echo "  4. Run this script again"
fi

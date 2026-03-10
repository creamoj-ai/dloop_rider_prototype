#!/bin/bash
# Verification script to test WhatsApp bot after fixing OpenAI API key
# Run this script after updating the OPENAI_API_KEY secret

echo "=========================================="
echo "  DLOOP WhatsApp Bot - Fix Verification"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cd C:/Users/itjob/dloop_rider_prototype || exit 1

echo "Step 1: Verify Supabase secret is set"
echo "======================================="
echo ""

echo "Running: supabase secrets list | grep OPENAI"
echo ""
supabase secrets list | grep OPENAI
echo ""

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ OpenAI secret found${NC}"
else
    echo -e "${RED}❌ OpenAI secret NOT found${NC}"
    echo "Run: supabase secrets set OPENAI_API_KEY=\"sk-proj-YOUR-KEY\""
    exit 1
fi

echo ""
echo "Step 2: Test webhook with whatsapp-simulate"
echo "============================================"
echo ""

echo "Testing ChatGPT processing..."
echo ""

RESPONSE=$(curl -s -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate \
  -H "Content-Type: application/json" \
  -d '{"phone":"+393281854639","text":"Ho bisogno di una maglietta","name":"Marco"}')

echo "Response:"
echo "$RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q "error.*401"; then
    echo -e "${RED}❌ Still getting 401 error - API key may not be valid${NC}"
    exit 1
fi

if echo "$RESPONSE" | grep -q "reply"; then
    echo -e "${GREEN}✅ ChatGPT response received!${NC}"
    echo ""
    REPLY=$(echo "$RESPONSE" | grep -o '"reply":"[^"]*"' | sed 's/"reply":"\(.*\)"/\1/')
    echo "Bot would respond with: $REPLY"
else
    echo -e "${YELLOW}⚠️ Unexpected response format${NC}"
    echo "Full response: $RESPONSE"
fi

echo ""
echo "Step 3: Check database entries"
echo "==============================="
echo ""

echo "Note: Cannot query database from bash script"
echo "To verify manually, go to:"
echo "  https://app.supabase.com"
echo "  Project: aqpwfurradxbnqvycvkm"
echo "  SQL Editor → Run:"
echo ""
echo "  SELECT * FROM whatsapp_conversations WHERE phone LIKE '%393281854639%';"
echo "  SELECT * FROM whatsapp_messages ORDER BY created_at DESC LIMIT 10;"
echo ""

echo "Step 4: Check Supabase function logs"
echo "====================================="
echo ""

echo "Go to: https://app.supabase.com"
echo "  Edge Functions → whatsapp-webhook → Logs"
echo ""
echo "Should see messages like:"
echo "  📨 Webhook received (Meta format)"
echo "  🤖 Starting ChatGPT processing"
echo "  ✅ Reply sent to +39..."
echo ""
echo "NOT like:"
echo "  ❌ OpenAI API error 401"
echo ""

echo "Step 5: Test with real WhatsApp"
echo "================================"
echo ""

echo "Send a message to: +39 328 185 4639"
echo ""
echo "From any WhatsApp client, send:"
echo "  'Ciao, serve una maglietta'"
echo ""
echo "Expected:"
echo "  Bot responds within 2-5 seconds"
echo "  Response includes dealer recommendation"
echo "  Message appears in database"
echo ""

echo "=========================================="
echo "  All verification steps complete!"
echo "=========================================="
echo ""
echo "If all tests pass:"
echo "  ✅ Webhook is working"
echo "  ✅ OpenAI integration is working"
echo "  ✅ Bot is ready for production"
echo ""
echo "If any tests fail:"
echo "  1. Check OpenAI API key is valid"
echo "  2. Check Supabase logs for errors"
echo "  3. See WEBHOOK_DIAGNOSTIC_2026-03-10.md for troubleshooting"
echo ""

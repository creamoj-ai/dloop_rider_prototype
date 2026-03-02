#!/bin/bash

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        Fix WhatsApp Webhook Secrets (Point to Main DB)         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Main project details
MAIN_PROJECT_URL="https://imhjdsjtaommutdmkouf.supabase.co"
MAIN_PROJECT_REF="imhjdsjtaommutdmkouf"

# Functions project details  
FUNC_PROJECT_URL="https://aqpwfurradxbnqvycvkm.supabase.co"
FUNC_PROJECT_REF="aqpwfurradxbnqvycvkm"

echo "📊 Secrets to update in Functions project:"
echo "   Project: $FUNC_PROJECT_REF"
echo ""
echo "Changes:"
echo "   1. SUPABASE_URL"
echo "      OLD: https://aqpwfurradxbnqvycvkm.supabase.co"
echo "      NEW: $MAIN_PROJECT_URL"
echo ""
echo "   2. SUPABASE_SERVICE_ROLE_KEY"  
echo "      OLD: [from functions project]"
echo "      NEW: [from main project - imhjdsjtaommutdmkouf]"
echo ""
echo "⚠️  Note: You need to provide the service role key from the MAIN project"
echo ""
echo "To get it:"
echo "1. Go to: https://supabase.com/dashboard/project/$MAIN_PROJECT_REF/settings/api"
echo "2. Find 'Service role secret'"
echo "3. Click 'Reveal' and copy the full key"
echo ""
echo "Then we can update the secrets automatically via API."

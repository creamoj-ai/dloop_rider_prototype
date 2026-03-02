#!/bin/bash

# ============================================
# WhatsApp Test Script - Order Simulation
# ============================================
# Testa il sistema WhatsApp bot senza API reale
# URL progetto: https://imhjdsjtaommutdmkouf.supabase.co

PROJECT_URL="https://imhjdsjtaommutdmkouf.supabase.co"
FUNCTION_URL="$PROJECT_URL/functions/v1/whatsapp-simulate"
WA_BOT_NUMBER="+393281854639"

echo "🤖 WhatsApp Bot Test Suite"
echo "================================"
echo "Bot Number: $WA_BOT_NUMBER"
echo ""

# Test 1: Customer Order
echo "📱 Test 1: Customer Order"
echo "Sending: 'Vorrei ordinare Pasta Barilla e Riso Arborio'"
curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393331234567",
    "text": "Vorrei ordinare 2 Pasta Barilla 500g e 1 Riso Arborio 1kg",
    "name": "Mario Rossi"
  }' | jq .

echo ""
echo "================================"

# Test 2: Another Customer
echo "📱 Test 2: Different Customer"
echo "Sending: 'Mi servono prodotti per il gatto'"
curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393334567890",
    "text": "Mi servono 3 scatole di Sheba Umido per il gatto",
    "name": "Anna Bianchi"
  }' | jq .

echo ""
echo "================================"

# Test 3: Dealer Order (if dealer phone matches)
echo "📱 Test 3: Dealer Order (Carrefour)"
echo "Sending: 'Confermo l ordine di rifornimento'"
curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+39 081 2345678",
    "text": "Confermo ordine rifornimento 50 pezzi",
    "name": "Carrefour Express",
    "role": "dealer"
  }' | jq .

echo ""
echo "✅ Test completati!"

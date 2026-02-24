#!/bin/bash

# ============================================
# WhatsApp Bot MVP Test - Full Flow
# ============================================
# Test: Customer → ChatGPT → Order → DB

PROJECT_URL="https://imhjdsjtaommutdmkouf.supabase.co"
FUNCTION_URL="$PROJECT_URL/functions/v1/whatsapp-simulate"

echo "🤖 WhatsApp Bot MVP Test Suite"
echo "=========================================="

# Test 1: Customer searches for products
echo ""
echo "📱 TEST 1: Product Search"
echo "Customer: 'Ciao, mi servono prodotti per il gatto'"
curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393331111111",
    "text": "Ciao, mi servono prodotti per il gatto",
    "name": "Cliente PET Test"
  }' | python3 -m json.tool 2>/dev/null || echo "[JSON parse failed]"

echo ""
echo "=========================================="

# Test 2: Customer requests specific product
echo ""
echo "📱 TEST 2: Order Specific Product"
echo "Customer: 'Vorrei 2 Sheba Umido 200g e 1 Royal Canin'"
curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393331111111",
    "text": "Vorrei 2 Sheba Umido 200g e 1 Royal Canin",
    "name": "Cliente PET Test"
  }' | python3 -m json.tool 2>/dev/null || echo "[JSON parse failed]"

echo ""
echo "=========================================="

# Test 3: Customer confirms delivery address
echo ""
echo "📱 TEST 3: Confirm Address & Create Order"
echo "Customer: 'Consegna a Via Roma 42, Napoli'"
curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393331111111",
    "text": "Consegna a Via Roma 42, Napoli",
    "name": "Cliente PET Test"
  }' | python3 -m json.tool 2>/dev/null || echo "[JSON parse failed]"

echo ""
echo "=========================================="

# Test 4: Grocery customer
echo ""
echo "📱 TEST 4: Grocery Order"
echo "Customer: 'Mi servono 2 Pasta Barilla e 1 Riso'"
curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393332222222",
    "text": "Mi servono 2 Pasta Barilla 500g e 1 Riso Arborio",
    "name": "Cliente Grocery Test"
  }' | python3 -m json.tool 2>/dev/null || echo "[JSON parse failed]"

echo ""
echo "=========================================="
echo "✅ Tests Completed!"
echo "Check market_orders DB for created orders"

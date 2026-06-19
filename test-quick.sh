#!/bin/bash
# Quick test dello stack completo DLOOP Admin Panel

echo "🧪 DLOOP - Quick Test Admin Panel"
echo "===================================="
echo ""

# Config
SUPABASE_URL="https://aqpwfurradxbnqvycvkm.supabase.co"
WEBHOOK_SECRET="yamamay_secret_2024"

# Chiedi dealer_id
echo "📋 Step 1: Recupera Dealer ID"
echo ""
echo "Esegui questa query in Supabase SQL Editor:"
echo "https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/sql/new"
echo ""
echo "SELECT id, business_name FROM dealers WHERE status = 'active';"
echo ""
read -p "Incolla qui un dealer_id (UUID): " DEALER_ID

if [ -z "$DEALER_ID" ]; then
    echo "❌ Dealer ID vuoto. Esci."
    exit 1
fi

echo ""
echo "✅ Dealer ID: $DEALER_ID"
echo ""

# Crea ordine
echo "📦 Step 2: Creo ordine di test..."
echo ""

ORDER_NUM="YAM-TEST-$(date +%s)"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$SUPABASE_URL/functions/v1/receive-yamamay-order" \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $WEBHOOK_SECRET" \
  -d "{
    \"order_id\": \"$ORDER_NUM\",
    \"dealer_id\": \"$DEALER_ID\",
    \"customer_name\": \"Test Cliente $(date +%H:%M)\",
    \"customer_phone\": \"+39 320 1234567\",
    \"customer_address\": \"Via Toledo 100, Napoli\"
  }")

# Separa body e status code
HTTP_BODY=$(echo "$RESPONSE" | head -n -1)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$HTTP_BODY" | jq '.' 2>/dev/null || echo "$HTTP_BODY"
echo ""

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Errore nella creazione ordine"
    echo "Verifica:"
    echo "  1. Il dealer_id esiste nel DB"
    echo "  2. Il secret YAMAMAY_WEBHOOK_SECRET è configurato"
    echo "  3. La funzione receive-yamamay-order è deployata"
    exit 1
fi

ORDER_ID=$(echo "$HTTP_BODY" | jq -r '.order_id' 2>/dev/null)

if [ -z "$ORDER_ID" ] || [ "$ORDER_ID" = "null" ]; then
    echo "❌ Order ID non trovato nella response"
    exit 1
fi

echo "✅ Ordine creato!"
echo "   Order ID: $ORDER_ID"
echo "   Order Number: $ORDER_NUM"
echo ""

# Test Admin Panel
echo "🖥️  Step 3: Testa Admin Panel"
echo ""
echo "Apri Admin Panel: https://steady-baklava-2ec7fa.netlify.app"
echo ""
echo "Dovresti vedere:"
echo "  ✓ L'ordine $ORDER_NUM nella lista pending"
echo "  ✓ Cliente: Test Cliente $(date +%H:%M)"
echo "  ✓ Indirizzo: Via Toledo 100, Napoli"
echo ""
echo "Prova ad assegnare l'ordine a un rider!"
echo ""

# Verifica DB
echo "🔍 Step 4: Verifica DB"
echo ""
echo "Esegui in SQL Editor:"
echo ""
echo "SELECT id, restaurant_name, customer_name, status, distance_km, base_earning"
echo "FROM orders"
echo "WHERE id = '$ORDER_ID';"
echo ""

echo "=================================="
echo "✅ Test completato!"
echo "=================================="

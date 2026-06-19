#!/bin/bash
# ============================================================================
# DLOOP Admin Panel - Test Script
# ============================================================================
# Testa l'intero flusso: webhook → ordine → admin panel → assign rider
# ============================================================================

set -e  # Exit on error

SUPABASE_URL="https://aqpwfurradxbnqvycvkm.supabase.co"
WEBHOOK_SECRET="yamamay_secret_2024"

echo "🧪 DLOOP Admin Panel - Test E2E"
echo "================================"
echo ""

# ============================================================================
# STEP 1: Get dealer ID from database
# ============================================================================
echo "📋 Step 1: Recupero dealer Yamamay..."
echo ""
echo "⚠️  IMPORTANTE: Devi eseguire manualmente questa query in Supabase SQL Editor:"
echo ""
echo "SELECT id, business_name FROM dealers WHERE business_name = 'Yamamay Napoli Centro';"
echo ""
read -p "Incolla qui il dealer ID (UUID): " DEALER_ID

if [ -z "$DEALER_ID" ]; then
    echo "❌ Errore: dealer ID non fornito"
    exit 1
fi

echo "✅ Dealer ID: $DEALER_ID"
echo ""

# ============================================================================
# STEP 2: Create test order via webhook
# ============================================================================
echo "📦 Step 2: Creo ordine di test via webhook..."
echo ""

RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/receive-yamamay-order" \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $WEBHOOK_SECRET" \
  -d "{
    \"order_id\": \"YAM-TEST-$(date +%s)\",
    \"dealer_id\": \"$DEALER_ID\",
    \"customer_name\": \"Test Customer $(date +%H:%M)\",
    \"customer_phone\": \"+39 320 1234567\",
    \"customer_address\": \"Via Toledo 100, Napoli\"
  }")

echo "Response:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Check if order was created
ORDER_ID=$(echo "$RESPONSE" | jq -r '.order_id' 2>/dev/null)

if [ -z "$ORDER_ID" ] || [ "$ORDER_ID" = "null" ]; then
    echo "❌ Errore: ordine non creato"
    echo "Dettagli: $RESPONSE"
    exit 1
fi

echo "✅ Ordine creato con ID: $ORDER_ID"
echo ""

# ============================================================================
# STEP 3: Check order in database
# ============================================================================
echo "🔍 Step 3: Verifica ordine in database..."
echo ""
echo "Esegui questa query in Supabase SQL Editor:"
echo ""
echo "SELECT id, restaurant_name, customer_name, customer_address, status, distance_km, base_earning"
echo "FROM orders"
echo "WHERE id = '$ORDER_ID';"
echo ""

# ============================================================================
# STEP 4: Open Admin Panel
# ============================================================================
echo "🖥️  Step 4: Apri Admin Panel..."
echo ""
echo "URL: https://steady-baklava-2ec7fa.netlify.app"
echo ""
echo "Dovresti vedere l'ordine appena creato nella lista."
echo "Prova ad assegnarlo a un rider."
echo ""

# ============================================================================
# STEP 5: Manual verification
# ============================================================================
echo "✅ Step 5: Verifica manuale"
echo ""
echo "Checklist:"
echo "  [ ] L'ordine appare nell'Admin Panel"
echo "  [ ] Riesci a selezionare un rider dal dropdown"
echo "  [ ] Click 'Assegna Rider' funziona senza errori"
echo "  [ ] Vedi notifica 'Ordine assegnato!'"
echo "  [ ] L'ordine scompare dalla lista pending"
echo ""
echo "Se tutto OK → Admin Panel funziona! 🎉"
echo ""

# ============================================================================
# CLEANUP (optional)
# ============================================================================
echo "🗑️  Step 6 (opzionale): Cleanup ordine test"
echo ""
echo "Per eliminare l'ordine di test, esegui:"
echo ""
echo "DELETE FROM orders WHERE id = '$ORDER_ID';"
echo ""
echo "============================================"
echo "Test completato! 🚀"
echo "============================================"

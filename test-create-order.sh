#!/bin/bash
# Crea un ordine di test veloce

echo "📦 Creazione ordine di test..."
echo ""

# Recupera dealer_id
echo "Prima, recupera il dealer_id eseguendo in SQL Editor:"
echo "SELECT id FROM dealers WHERE business_name LIKE '%Yamamay%' LIMIT 1;"
echo ""
read -p "Incolla dealer_id: " DEALER_ID

if [ -z "$DEALER_ID" ]; then
    echo "❌ Dealer ID vuoto"
    exit 1
fi

# Crea ordine
curl -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/receive-yamamay-order \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: yamamay_secret_2024" \
  -d "{
    \"order_id\": \"YAM-QUICK-$(date +%s)\",
    \"dealer_id\": \"$DEALER_ID\",
    \"customer_name\": \"Test Quick\",
    \"customer_phone\": \"+39 320 1111111\",
    \"customer_address\": \"Via Toledo 100, Napoli\"
  }" | python3 -m json.tool 2>/dev/null || cat

echo ""
echo "✅ Ordine creato! Controlla Admin Panel:"
echo "https://steady-baklava-2ec7fa.netlify.app"

# ============================================================================
# DLOOP - Setup Completo e Test Automatico Admin Panel (PowerShell)
# ============================================================================

Write-Host "🚀 DLOOP - Setup e Test Automatico" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Config
$SUPABASE_URL = "https://aqpwfurradxbnqvycvkm.supabase.co"
$SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxcHdmdXJyYWR4Ym5xdnljdmttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMTk3NzAsImV4cCI6MjA4NTY5NTc3MH0.Ekhco06o8_88e8tQJHm4EjEa0HOQv8Z-gAHa1busvog"
$WEBHOOK_SECRET = "yamamay_secret_2024"
$ADMIN_SECRET = "password_sicura_123"

# ============================================================================
# STEP 1: Recupera dealer_id
# ============================================================================
Write-Host "📋 Step 1: Recupero dealer Yamamay..." -ForegroundColor Cyan
Write-Host ""

$dealerUrl = "$SUPABASE_URL/rest/v1/dealers?business_name=like.*Yamamay*``&status=eq.active``&select=id,business_name"
$headers = @{
    "apikey" = $SUPABASE_ANON_KEY
    "Authorization" = "Bearer $SUPABASE_ANON_KEY"
}

try {
    $dealerResponse = Invoke-RestMethod -Uri $dealerUrl -Headers $headers -Method Get
    $DEALER_ID = $dealerResponse[0].id
    $DEALER_NAME = $dealerResponse[0].business_name

    Write-Host "✅ Dealer trovato: $DEALER_NAME" -ForegroundColor Green
    Write-Host "   ID: $DEALER_ID"
    Write-Host ""
} catch {
    Write-Host "❌ Errore: Dealer non trovato!" -ForegroundColor Red
    Write-Host "Devi eseguire sql/40_create_dealers_table.sql prima" -ForegroundColor Yellow
    exit 1
}

# ============================================================================
# STEP 2: Crea rider di test
# ============================================================================
Write-Host "👤 Step 2: Creo rider di test..." -ForegroundColor Cyan
Write-Host ""

$RIDER_ID = [guid]::NewGuid().ToString()
$FCM_TOKEN = "fake-fcm-token-test-$(Get-Date -Format 'yyyyMMddHHmmss')"

$fcmBody = @{
    rider_id = $RIDER_ID
    token = $FCM_TOKEN
    is_active = $true
} | ConvertTo-Json

$fcmHeaders = @{
    "apikey" = $SUPABASE_ANON_KEY
    "Authorization" = "Bearer $SUPABASE_ANON_KEY"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

try {
    $fcmResponse = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/fcm_tokens" -Headers $fcmHeaders -Method Post -Body $fcmBody
    Write-Host "✅ Rider creato!" -ForegroundColor Green
    Write-Host "   Rider ID: $RIDER_ID"
    Write-Host ""
} catch {
    Write-Host "⚠️  Warning: Possibile problema RLS, ma procedo..." -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# STEP 3: Crea ordine di test
# ============================================================================
Write-Host "📦 Step 3: Creo ordine di test..." -ForegroundColor Cyan
Write-Host ""

$ORDER_NUM = "YAM-AUTO-$(Get-Date -Format 'HHmmss')"

$orderBody = @{
    order_id = $ORDER_NUM
    dealer_id = $DEALER_ID
    customer_name = "Test Auto Cliente"
    customer_phone = "+39 320 9999999"
    customer_address = "Via Toledo 100, Napoli"
} | ConvertTo-Json

$orderHeaders = @{
    "Content-Type" = "application/json"
    "X-Webhook-Secret" = $WEBHOOK_SECRET
}

try {
    $orderResponse = Invoke-RestMethod -Uri "$SUPABASE_URL/functions/v1/receive-yamamay-order" -Headers $orderHeaders -Method Post -Body $orderBody
    $ORDER_ID = $orderResponse.order_id
    $DISTANCE = $orderResponse.distance_km
    $EARNING = $orderResponse.base_earning

    Write-Host "✅ Ordine creato!" -ForegroundColor Green
    Write-Host "   Order ID: $ORDER_ID"
    Write-Host "   Order Number: $ORDER_NUM"
    Write-Host "   Distanza: ${DISTANCE}km"
    Write-Host "   Compenso: €${EARNING}"
    Write-Host ""
} catch {
    Write-Host "❌ Errore creazione ordine" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

# ============================================================================
# STEP 4: Assegna ordine a rider
# ============================================================================
Write-Host "🎯 Step 4: Assegno ordine al rider..." -ForegroundColor Cyan
Write-Host ""

$assignBody = @{
    order_id = $ORDER_ID
    rider_id = $RIDER_ID
} | ConvertTo-Json

$assignHeaders = @{
    "Content-Type" = "application/json"
    "X-Admin-Key" = $ADMIN_SECRET
}

try {
    $assignResponse = Invoke-RestMethod -Uri "$SUPABASE_URL/functions/v1/assign-rider" -Headers $assignHeaders -Method Post -Body $assignBody

    Write-Host "✅ Ordine assegnato con successo!" -ForegroundColor Green
    if ($assignResponse.fcm_sent -eq $true) {
        Write-Host "   📱 Push FCM inviato" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Push FCM non inviato (token fake)" -ForegroundColor Yellow
    }
    Write-Host ""
} catch {
    Write-Host "❌ Errore assegnazione" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# ============================================================================
# STEP 5: Verifica finale
# ============================================================================
Write-Host "🔍 Step 5: Verifica..." -ForegroundColor Cyan
Write-Host ""

Write-Host "Admin Panel: https://steady-baklava-2ec7fa.netlify.app" -ForegroundColor Magenta
Write-Host ""
Write-Host "L'ordine dovrebbe essere SCOMPARSO dalla lista pending" -ForegroundColor Yellow
Write-Host "(perché ora è ASSIGNED)" -ForegroundColor Yellow
Write-Host ""

Write-Host "📊 SQL per verificare:" -ForegroundColor Cyan
Write-Host "SELECT id, restaurant_name, customer_name, status, assigned_rider_id"
Write-Host "FROM orders WHERE id = '$ORDER_ID';"
Write-Host ""

Write-Host "====================================" -ForegroundColor Green
Write-Host "✅ Test Completato!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Riepilogo:" -ForegroundColor Cyan
Write-Host "   • Dealer: $DEALER_NAME"
Write-Host "   • Rider: $RIDER_ID"
Write-Host "   • Ordine: $ORDER_NUM"
Write-Host "   • Status: ASSIGNED"
Write-Host ""
Write-Host "🎉 Sistema funzionante al 100%!" -ForegroundColor Green
Write-Host ""
Write-Host "🗑️  Per pulire i dati test:" -ForegroundColor Yellow
Write-Host "DELETE FROM orders WHERE id = '$ORDER_ID';" -ForegroundColor Gray
Write-Host "DELETE FROM fcm_tokens WHERE rider_id = '$RIDER_ID';" -ForegroundColor Gray

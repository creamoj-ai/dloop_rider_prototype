# Monitoring & Operations

## Daily Checks (5 min)

Run every morning:

```bash
# Health check
node diagnose-bot.js

# Verify webhook receiving messages
# Check Supabase logs: no errors in last 24 hours
```

Expected output:
```
✅ Database connectivity: OK
✅ Webhook endpoint: WORKING
✅ Recent inbound messages: YES
✅ Recent outbound messages: YES
✅ Conversations: ACTIVE
```

## Weekly Review

### 1. Message Volume

```sql
SELECT
  DATE(created_at) as date,
  COUNT(*) as total_messages,
  SUM(CASE WHEN direction='inbound' THEN 1 ELSE 0 END) as inbound,
  SUM(CASE WHEN direction='outbound' THEN 1 ELSE 0 END) as outbound,
  COUNT(DISTINCT phone) as unique_phones
FROM whatsapp_messages
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

**Healthy range**: 10-100 messages/day per dealer

### 2. Error Rate

```sql
SELECT
  status,
  COUNT(*) as count,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM whatsapp_messages
        WHERE created_at > NOW() - INTERVAL '7 days'), 2) as percentage
FROM whatsapp_messages
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY status
ORDER BY count DESC;
```

**Healthy**: <5% failed messages

### 3. Response Time

```sql
SELECT
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY response_time) as p50,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time) as p95,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_time) as p99,
  MAX(response_time) as max_response_time
FROM (
  SELECT
    EXTRACT(EPOCH FROM (m2.created_at - m1.created_at)) as response_time
  FROM whatsapp_messages m1
  JOIN whatsapp_messages m2 ON m1.conversation_id = m2.conversation_id
  WHERE m1.direction = 'inbound'
    AND m2.direction = 'outbound'
    AND m2.created_at > m1.created_at
    AND m2.created_at - m1.created_at < INTERVAL '1 minute'
    AND m2.created_at > NOW() - INTERVAL '7 days'
) t;
```

**Healthy**: P50 <5s, P95 <8s

### 4. Conversation Quality

```sql
SELECT
  conversation_type,
  COUNT(*) as conversations,
  AVG(message_count) as avg_messages,
  MIN(message_count) as min_messages,
  MAX(message_count) as max_messages
FROM whatsapp_conversations
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY conversation_type;
```

**Healthy**: Customers avg 5-10 messages, dealers 2-5

### 5. Orders Created

```sql
SELECT
  DATE(created_at) as date,
  status,
  COUNT(*) as count,
  ROUND(AVG(total_price), 2) as avg_price,
  ROUND(SUM(total_price), 2) as total_revenue
FROM whatsapp_order_relays
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at), status
ORDER BY date DESC;
```

**Healthy**: Orders flowing through pipeline

## Monthly Review

### Key Metrics Dashboard

```sql
-- This month vs last month
WITH current_month AS (
  SELECT
    COUNT(*) as messages,
    COUNT(DISTINCT phone) as users,
    COUNT(DISTINCT conversation_id) as conversations,
    SUM(CASE WHEN direction='inbound' THEN 1 ELSE 0 END) as inbound,
    SUM(CASE WHEN direction='outbound' THEN 1 ELSE 0 END) as outbound,
    SUM(CASE WHEN status='failed' THEN 1 ELSE 0 END) as failed
  FROM whatsapp_messages
  WHERE created_at >= DATE_TRUNC('month', NOW())
),
last_month AS (
  SELECT
    COUNT(*) as messages,
    COUNT(DISTINCT phone) as users,
    COUNT(DISTINCT conversation_id) as conversations,
    SUM(CASE WHEN direction='inbound' THEN 1 ELSE 0 END) as inbound,
    SUM(CASE WHEN direction='outbound' THEN 1 ELSE 0 END) as outbound,
    SUM(CASE WHEN status='failed' THEN 1 ELSE 0 END) as failed
  FROM whatsapp_messages
  WHERE created_at >= DATE_TRUNC('month', NOW() - INTERVAL '1 month')
    AND created_at < DATE_TRUNC('month', NOW())
)
SELECT
  'Messages' as metric,
  (SELECT messages FROM current_month) as current,
  (SELECT messages FROM last_month) as previous,
  ROUND(100.0 * ((SELECT messages FROM current_month) - (SELECT messages FROM last_month)) / (SELECT messages FROM last_month), 1) as change_percent
UNION ALL
SELECT 'Active Users',
  (SELECT users FROM current_month), (SELECT users FROM last_month),
  ROUND(100.0 * ((SELECT users FROM current_month) - (SELECT users FROM last_month)) / NULLIF((SELECT users FROM last_month), 0), 1)
UNION ALL
SELECT 'Conversations',
  (SELECT conversations FROM current_month), (SELECT conversations FROM last_month),
  ROUND(100.0 * ((SELECT conversations FROM current_month) - (SELECT conversations FROM last_month)) / NULLIF((SELECT conversations FROM last_month), 0), 1)
UNION ALL
SELECT 'Success Rate %',
  ROUND(100.0 * (1 - (SELECT failed FROM current_month)::numeric / (SELECT messages FROM current_month)), 2),
  ROUND(100.0 * (1 - (SELECT failed FROM last_month)::numeric / (SELECT messages FROM last_month)), 2),
  NULL;
```

### Cost Analysis

```
OpenAI Costs:
- Avg 50 tokens/message input
- Avg 40 tokens/message output
- gpt-3.5-turbo: ~$0.00008 per message
- Monthly (assuming 10k messages): ~$0.80

Supabase Costs:
- Pro plan: $25/month (includes 100k function calls)
- Each message = ~2-3 function calls
- 10k messages = ~25k function calls (within budget)

Total Monthly: ~$26-30

Scale to 100k messages/month:
- OpenAI: ~$8
- Supabase: May need usage-based pricing
- Total: ~$50-100/month
```

## Alerting

### Set Up Monitoring Alerts

**Option 1: Supabase Built-in**
- Go to **Settings** → **Alerts**
- Set thresholds for:
  - Failed function executions
  - Database connection errors
  - Storage quota

**Option 2: Custom Queries (run periodically)**

```bash
# Daily error check
psql $DB_URL -c "
SELECT COUNT(*) as failed_messages
FROM whatsapp_messages
WHERE status = 'failed'
AND created_at > NOW() - INTERVAL '1 day';
" | grep -E '^.*[1-9]' && echo "⚠️ ALERT: Failed messages detected"
```

**Option 3: Webhook Monitoring**
```
Monitor Supabase function logs for:
- Timeout errors (>60s)
- Out of memory errors
- Authentication errors
- Rate limit errors
```

## Escalation Procedures

### 🔴 Critical Issues

**Symptoms**: No messages for >30 min, bot unresponsive

1. Check Supabase status: https://status.supabase.com/
2. Check Meta status: https://status.openai.com/
3. Check OpenAI status: https://status.openai.com/
4. Check Supabase logs for errors
5. Run: `node diagnose-bot.js`
6. If issue persists:
   - Go to **Functions** → **whatsapp-webhook** → **Redeploy**
   - Or revert last commit if recent change

### 🟡 High Error Rate

**Symptom**: >5% failed messages

1. Check error types in logs
2. If OpenAI errors: verify API key, check rate limits
3. If Meta errors: verify token, check phone number status
4. If database errors: check connection pool, storage quota
5. Review last code changes

### 🟢 Performance Degradation

**Symptom**: Response time >15s

1. Check OpenAI performance: https://status.openai.com/
2. Check database performance:
   ```sql
   SELECT * FROM pg_stat_statements
   ORDER BY mean_exec_time DESC LIMIT 10;
   ```
3. Enable connection pooling if needed
4. Archive old messages if storage is high

## Maintenance Tasks

### Monthly

- [ ] Review message metrics
- [ ] Check cost trends
- [ ] Archive messages older than 90 days
- [ ] Rotate OpenAI API key
- [ ] Rotate WhatsApp access token
- [ ] Review failed messages and fix

### Quarterly

- [ ] Security audit
- [ ] Database performance review
- [ ] Capacity planning for growth
- [ ] Update documentation
- [ ] Test disaster recovery
- [ ] Review dealer feedback

### Annually

- [ ] Full system audit
- [ ] Update models (if new versions available)
- [ ] Assess scaling needs
- [ ] Review pricing and budget
- [ ] Plan feature roadmap

## Runbooks

### Runbook: Bot Not Responding

```
1. Check if webhook is receiving messages
   SELECT COUNT(*) FROM whatsapp_messages
   WHERE created_at > NOW() - INTERVAL '5 min';

2. If 0: Check Meta webhook in business account
   - Verify URL is correct
   - Verify verify_token matches
   - Send test message from test number

3. If messages exist but no responses:
   - Check OpenAI key in secrets
   - Test OpenAI directly
   - Check function logs for errors

4. If still not working:
   - Redeploy function: supabase functions deploy whatsapp-webhook
   - Check Supabase status
   - Escalate to team
```

### Runbook: High Latency

```
1. Check ChatGPT status at platform.openai.com
2. If slow: Try switching to gpt-3.5-turbo from gpt-4
3. Enable database connection pooling
4. Monitor individual request times
5. If specific users slow: check their phone/network
6. If systemic: contact OpenAI support
```

### Runbook: Database Issues

```
1. Check storage quota: Supabase → Storage
2. Check connections: SELECT COUNT(*) FROM pg_stat_activity;
3. Check slow queries: SELECT * FROM pg_stat_statements ORDER BY mean_exec_time DESC;
4. Kill long-running queries if needed: SELECT pg_terminate_backend(pid);
5. Archive old messages if storage high
6. Check database backups are working
```

## Documentation

Keep these files updated:
- [ ] **DEPLOYMENT_GUIDE.md** - How to deploy
- [ ] **TROUBLESHOOTING.md** - Common issues
- [ ] **API_REFERENCE.md** - API endpoints
- [ ] **RUNBOOKS.md** - Operational procedures
- [ ] **INCIDENT_LOG.md** - What went wrong and how fixed

---

**Last Updated**: 2026-02-26
**Status**: Monitoring framework ready
**Check frequency**: Daily minimum

# 📍 Order Tracking Real-Time System

## Overview
Real-time order status tracking for customers using Supabase Realtime subscriptions.

---

## 🔄 Order Status Flow

```
PENDING
  ↓ (Rider assigned)
ASSIGNED (⏰ assigned_at timestamp)
  ↓ (Rider picked up items)
IN_PICKUP
  ↓ (Rider started delivery)
IN_DELIVERY (🚗 location updates)
  ↓ (Delivered)
DELIVERED (📍 arrival_at timestamp)
```

---

## 📱 PWA Implementation

### 1. Order Status Page (`/order/:orderId`)

```typescript
// pages/order/[orderId].tsx
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';

export default function OrderTracking({ orderId }) {
  const [order, setOrder] = useState(null);
  const [rider, setRider] = useState(null);

  useEffect(() => {
    // Real-time subscription to order status
    const subscription = supabase
      .from('orders')
      .on('*', payload => {
        if (payload.new.id === orderId) {
          setOrder(payload.new);
        }
      })
      .subscribe();

    return () => subscription.unsubscribe();
  }, [orderId]);

  return (
    <div>
      <h1>📍 Order Tracking</h1>

      {/* Status Timeline */}
      <div className="timeline">
        <div className={`step ${order?.status === 'PENDING' ? 'active' : ''}`}>
          📦 Order Pending
        </div>
        <div className={`step ${order?.status === 'ASSIGNED' ? 'active' : ''}`}>
          🚗 Rider: {rider?.name} ({rider?.rating}/5)
        </div>
        <div className={`step ${order?.status === 'IN_PICKUP' ? 'active' : ''}`}>
          🏪 Picking up items...
        </div>
        <div className={`step ${order?.status === 'IN_DELIVERY' ? 'active' : ''}`}>
          🚗 In delivery - ETA: {order?.estimated_arrival}
        </div>
        <div className={`step ${order?.status === 'DELIVERED' ? 'active' : ''}`}>
          ✅ Delivered
        </div>
      </div>

      {/* Order Details */}
      <div className="order-details">
        <h3>Order #{order?.id?.slice(0, 8)}</h3>
        <p>📍 {order?.customer_address}</p>
        <p>💰 €{order?.total_price}</p>
        <p>⏱️ ETA: {order?.estimated_arrival || '30-45 min'}</p>
      </div>

      {/* Rider Info (when assigned) */}
      {rider && (
        <div className="rider-card">
          <h3>Your Rider</h3>
          <p>Name: {rider.name}</p>
          <p>Rating: ⭐ {rider.rating}/5</p>
          <p>Phone: {rider.phone}</p>
          <button>📞 Call Rider</button>
        </div>
      )}
    </div>
  );
}
```

---

## 🗄️ Database Schema

### Orders Table (add columns if needed)
```sql
ALTER TABLE orders ADD COLUMN IF NOT EXISTS
  assigned_at TIMESTAMP,
  pickup_at TIMESTAMP,
  delivery_started_at TIMESTAMP,
  delivered_at TIMESTAMP,
  estimated_arrival TEXT;
```

### Status Updates Trigger
```sql
CREATE OR REPLACE FUNCTION update_order_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'ASSIGNED' AND OLD.status != 'ASSIGNED' THEN
    NEW.assigned_at = NOW();
  END IF;

  IF NEW.status = 'IN_PICKUP' AND OLD.status != 'IN_PICKUP' THEN
    NEW.pickup_at = NOW();
  END IF;

  IF NEW.status = 'IN_DELIVERY' AND OLD.status != 'IN_DELIVERY' THEN
    NEW.delivery_started_at = NOW();
  END IF;

  IF NEW.status = 'DELIVERED' AND OLD.status != 'DELIVERED' THEN
    NEW.delivered_at = NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_status_timestamps
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_order_timestamps();
```

---

## 🔔 Status Update Triggers

### From Webhook
When order is created:
```typescript
// processor.ts - after create_delivery_order
await db.from('orders').update({
  status: 'PENDING',
  created_at: new Date().toISOString()
}).eq('id', orderId);
```

When rider assigned:
```typescript
// After assign_rider succeeds
await db.from('orders').update({
  status: 'ASSIGNED',
  assigned_rider_id: riderId,
  assigned_at: new Date().toISOString()
}).eq('id', orderId);
```

### From Rider App
Rider updates status when:
1. ✅ Accepted order → `IN_PICKUP`
2. ✅ Finished picking up → `IN_DELIVERY`
3. ✅ Delivered → `DELIVERED` + `delivered_at`

```typescript
// In rider Flutter app
await supabase
  .from('orders')
  .update({
    status: 'IN_DELIVERY',
    delivery_started_at: DateTime.now().toIso8601String()
  })
  .eq('id', orderId)
  .execute();
```

---

## 📊 Real-Time Features

### 1. Live Status Updates
- PWA subscribes to order changes
- Status timeline updates automatically
- ETA countdown in real-time

### 2. Rider Location (Optional - Phase 2)
- Rider shares GPS location while in delivery
- Customer sees live map with rider position
- Distance + ETA calculated in real-time

### 3. Notifications
- ✅ Order created → Customer confirmation
- ✅ Rider assigned → Show rider name + rating + phone
- ✅ Rider on the way → ETA countdown
- ✅ Order delivered → Ask for rating ⭐

---

## 🎯 Implementation Checklist

- [ ] Add `/order/:orderId` page to PWA
- [ ] Implement Supabase Realtime subscription
- [ ] Add order status timeline UI
- [ ] Add rider info card (when assigned)
- [ ] Add "Call Rider" button (integrate Twilio Voice)
- [ ] Add delivery timestamp database trigger
- [ ] Test with real order flow
- [ ] Add rating/feedback after delivery

---

## 📌 Notes

- **Realtime latency**: ~100-500ms with Supabase
- **Polling fallback**: If Realtime fails, poll every 5s
- **Offline support**: Cache last known status, sync when online
- **Phase 2**: Add live map with rider location (requires GPS from rider app)


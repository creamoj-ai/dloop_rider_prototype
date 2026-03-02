-- SQL 38: FAQ entries table for dynamic bot FAQ
-- Replaces hardcoded FAQ in customer_functions.ts
-- Safe to run multiple times (idempotent)

-- ── Table ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.faq_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  topic TEXT NOT NULL UNIQUE,
  answer TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ── RLS ────────────────────────────────────────────────────────────
ALTER TABLE public.faq_entries ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'anyone_can_read_faq' AND tablename = 'faq_entries'
  ) THEN
    CREATE POLICY "anyone_can_read_faq" ON public.faq_entries
      FOR SELECT TO authenticated USING (true);
  END IF;
END $$;

-- ── Seed Data ──────────────────────────────────────────────────────
INSERT INTO public.faq_entries (topic, answer, sort_order) VALUES
  ('tempi', 'La consegna richiede di solito 30-60 minuti, a seconda della distanza e del tempo di preparazione del negozio.', 1),
  ('costi', 'La consegna costa da €3.50. Gratuita per ordini sopra €50. Nessun costo aggiuntivo nascosto.', 2),
  ('zone', 'DLOOP opera a Napoli e provincia (Campania). Le zone attive dipendono dai rider disponibili.', 3),
  ('pagamento', 'Puoi pagare con: link Stripe (carta online), contanti alla consegna, o POS del rider.', 4),
  ('funzionamento', E'1. Scegli un negozio e ordina via WhatsApp\n2. Il rider invia l''ordine al negozio\n3. Il negozio prepara\n4. Il rider ritira e consegna a te\nTutto in 30-60 min!', 5),
  ('supporto', E'Per assistenza, scrivi ''supporto'' in chat o contatta il nostro team. Siamo qui per aiutarti!', 6),
  ('orari', 'Gli orari dipendono dal negozio. La maggior parte è disponibile dalle 10:00 alle 22:00.', 7),
  ('annullamento', E'Puoi annullare un ordine solo se è ancora in stato ''in attesa''. Una volta confermato dal negozio, non è più annullabile.', 8),
  ('pro', E'DLOOP Pro costa €29/mese e include: assicurazione Qover (infortuni, RC, malattia), esenzione deposito €250, zone prioritarie, badge PRO, supporto prioritario e accesso ai Partner Benefits.', 9),
  ('sicurezza', 'Tutti i pagamenti online sono gestiti da Stripe, certificato PCI DSS. I tuoi dati di pagamento non passano mai dai nostri server.', 10),
  ('contatti', E'Puoi contattarci via WhatsApp (questo numero), email a supporto@dloop.it, o tramite l''app DLOOP nella sezione Supporto.', 11)
ON CONFLICT (topic) DO UPDATE SET
  answer = EXCLUDED.answer,
  sort_order = EXCLUDED.sort_order,
  updated_at = now();

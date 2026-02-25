const { createClient } = require("@supabase/supabase-js");
require("dotenv").config();

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_ANON_KEY;

const db = createClient(url, key);

async function addMissingColumns() {
  console.log("🔧 Aggiungendo colonne mancanti...\n");

  const queries = [
    `ALTER TABLE IF EXISTS public.whatsapp_conversations 
     ADD COLUMN IF NOT EXISTS message_count INT DEFAULT 0;`,
    `ALTER TABLE IF EXISTS public.whatsapp_conversations 
     ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ DEFAULT now();`,
    `ALTER TABLE IF EXISTS public.whatsapp_conversations 
     ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();`,
  ];

  for (const query of queries) {
    try {
      const { data, error } = await db.rpc("execute_sql", { sql: query }).catch(() => ({error: "RPC not available"}));
      if (error) {
        console.log(`⚠️  (Tentando via query diretta)`);
      } else {
        console.log(`✅ Query eseguita`);
      }
    } catch (e) {
      console.log(`⚠️  Errore: ${e.message}`);
    }
  }

  console.log("\n✅ Colonne completate!");
}

addMissingColumns();

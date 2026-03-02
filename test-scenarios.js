/**
 * WhatsApp Bot MVP - Test Scenarios
 * Tests customer and dealer flows
 */

const BASE_URL = 'https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate';

const scenarios = [
  // CUSTOMER SCENARIOS (NON-dealer phone numbers)
  {
    name: '🐱 Customer: Pet Products Search',
    data: {
      phone: '+39 391 1234567',
      text: 'Ciao, mi servono prodotti per il gatto',
      name: 'Marco Rossi'
    }
  },
  {
    name: '🛒 Customer: Order Request',
    data: {
      phone: '+39 391 1234567',
      text: 'Vorrei 2 Sheba Umido e 1 Royal Canin',
      name: 'Marco Rossi'
    }
  },
  {
    name: '📍 Customer: Delivery Address',
    data: {
      phone: '+39 391 1234567',
      text: 'Consegna a Via Roma 42, Napoli',
      name: 'Marco Rossi'
    }
  },
  {
    name: '🍝 Customer: Grocery Search',
    data: {
      phone: '+39 392 2345678',
      text: 'Mi servono pasta e riso',
      name: 'Lucia Bianchi'
    }
  },
  {
    name: '💳 Customer: Payment Question',
    data: {
      phone: '+39 393 3456789',
      text: 'Quali sono i metodi di pagamento?',
      name: 'Giuseppe Verde'
    }
  },

  // DEALER SCENARIOS (actual dealer phones from rider_contacts)
  {
    name: '✅ Dealer: Confirm Order',
    data: {
      phone: '+39 333 1111111',
      text: 'OK',
      name: 'Marco Bianchi',
      role: 'dealer'
    }
  },
  {
    name: '🔔 Dealer: Mark Ready',
    data: {
      phone: '+39 333 2222222',
      text: 'PRONTO',
      name: 'Luca Russo',
      role: 'dealer'
    }
  },
  {
    name: '❌ Dealer: Decline Order',
    data: {
      phone: '+39 333 3333333',
      text: 'NO, non ho disponibilità',
      name: 'Sara Moretti',
      role: 'dealer'
    }
  },
  {
    name: '📋 Dealer: View Orders',
    data: {
      phone: '+39 333 4444444',
      text: 'ORDINI',
      name: 'Andrea Palmieri',
      role: 'dealer'
    }
  },
  {
    name: '🛑 Dealer: Close Shop',
    data: {
      phone: '+39 081 2345678',
      text: 'CHIUSO',
      name: 'Carrefour Express Napoli',
      role: 'dealer'
    }
  },
  {
    name: '🟢 Dealer: Open Shop',
    data: {
      phone: '+39 081 5555111',
      text: 'APERTO',
      name: 'Esselunga Vomero',
      role: 'dealer'
    }
  }
];

async function runScenario(scenario) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`${scenario.name}`);
  console.log(`${'='.repeat(60)}`);

  try {
    const response = await fetch(BASE_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(scenario.data)
    });

    const result = await response.json();

    // Pretty print
    if (result.success) {
      console.log(`✅ SUCCESS`);
      console.log(`📱 Reply: ${result.reply}`);
      console.log(`🔄 Routed to: ${result.routed_to}`);
      console.log(`💬 Conversation ID: ${result.conversation_id}`);
    } else {
      console.log(`❌ ERROR`);
      console.log(`Details: ${result.error}`);
      if (result.details) {
        console.log(`${result.details.substring(0, 200)}...`);
      }
    }
  } catch (error) {
    console.error(`❌ Network Error: ${error.message}`);
  }

  // Small delay between scenarios
  await new Promise(resolve => setTimeout(resolve, 500));
}

async function runAllScenarios() {
  console.log(`
╔════════════════════════════════════════════════════════════════╗
║         WhatsApp Bot MVP - Test Scenarios (${scenarios.length} tests)          ║
║                   Dloop Rider Prototype                         ║
╚════════════════════════════════════════════════════════════════╝
  `);

  for (const scenario of scenarios) {
    await runScenario(scenario);
  }

  console.log(`\n${'='.repeat(60)}`);
  console.log(`✅ All scenarios completed!`);
  console.log(`${'='.repeat(60)}`);
  console.log(`
📊 Next steps:
  1. Check Supabase database for saved conversations/messages
  2. Review logs: https://supabase.com/dashboard/project/imhjdsjtaommutdmkouf/functions
  3. Monitor webhook setup for Meta verification
  4. Demo to dealer pilots
  `);
}

runAllScenarios().catch(console.error);

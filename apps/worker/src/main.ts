import { setTimeout as sleep } from 'node:timers/promises';

async function run() {
  // Phase 5 worker boundary. Outbox polling/publication is implemented in the next P0 story.
  while (true) await sleep(30_000);
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});

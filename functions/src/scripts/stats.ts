import {getStats} from "../pool/puzzle_pool";

async function main(): Promise<void> {
  const stats = await getStats();
  // eslint-disable-next-line no-console
  console.log(JSON.stringify(stats, null, 2));
}

main().then(
  () => process.exit(0),
  (err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    process.exit(1);
  },
);

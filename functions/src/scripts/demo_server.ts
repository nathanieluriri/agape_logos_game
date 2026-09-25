// Local demo stack: serves the api app against the emulators, never production.
//   npm run demo:api
import "./demo_env";
import {createApp} from "../app";

const port = Number(process.env.PORT ?? 5055);
createApp().listen(port, "127.0.0.1", () => {
  // eslint-disable-next-line no-console
  console.log(`demo api on http://127.0.0.1:${port}`);
});

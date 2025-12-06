import { createAuthClient } from "better-auth/react";
import { magicLinkClient } from "better-auth/client/plugins";

export const authClient = createAuthClient({
  baseURL: import.meta.env.DEV ? "http://localhost:4555" : "",
  plugins: [magicLinkClient()],
});

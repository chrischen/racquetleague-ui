import { createAuthClient } from "better-auth/react";
import { magicLinkClient } from "better-auth/client/plugins";

export const authClient = createAuthClient({
  // In dev, use a same-origin relative base so requests go through the
  // Vite proxy (avoids HTTPS-tunnel mixed-content / CORS issues).
  baseURL: "",
  plugins: [magicLinkClient()],
});

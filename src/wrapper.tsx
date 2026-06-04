import type { StaticHandlerContext } from "react-router-dom/server";
import type { Router } from "@remix-run/router";
import { StaticRouterProvider } from "react-router-dom/server";
import { RouterProvider } from "react-router-dom";
import { Helmet } from "react-helmet-async";
import { APIProvider } from "@vis.gl/react-google-maps";

const GOOGLE_MAPS_API_KEY = "AIzaSyCZWn4QS-HcYV_KDt9dOSy-EiJ9s3m8WIk";
const GOOGLE_MAPS_LIBRARIES: string[] = ["places"];

const pwaEarlyCaptureScript = `window.__pwaInstallPrompt=null;
console.log('[PWA] Helmet-script running');
window.addEventListener('beforeinstallprompt',function(e){
  e.preventDefault();
  window.__pwaInstallPrompt=e;
  console.log('[PWA] beforeinstallprompt captured early',e);
});`;

export const Wrapper = ({
  router,
  context,
}: {
  router: Router;
  context?: StaticHandlerContext;
}) => {
  return (
    <APIProvider apiKey={GOOGLE_MAPS_API_KEY} libraries={GOOGLE_MAPS_LIBRARIES}>
      <Helmet>
        <script type="text/javascript">{pwaEarlyCaptureScript}</script>
      </Helmet>
      {import.meta.env.SSR ? (
        <StaticRouterProvider
          router={router}
          context={context as StaticHandlerContext}
          hydrate={false}
        />
      ) : (
        <RouterProvider router={router} future={{ v7_startTransition: true }} />
      )}
    </APIProvider>
  );
};

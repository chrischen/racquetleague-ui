import type { ReactNode } from "react";
import type { HelmetServerState } from "react-helmet-async";

interface HtmlProps {
  // children: ReactNode;
  head?: ReactNode;
  end?: ReactNode;
}

function Html({ lang, head, end }: HtmlProps) {
  return (
    <html lang={lang ?? "en"} className="h-full">
      <meta charSet="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      {head}
      <body className="h-full">
        <div id="root"></div>
        {end}
      </body>
    </html>
  );
}
export default Html;

export function Head({
  children,
  helmet,
}: {
  children?: ReactNode;
  helmet?: HelmetServerState;
}) {
  return (
    <head>
      {children}
      {helmet && (
        <>
          {helmet.priority.toComponent()}
          {helmet.title.toComponent()}
          {helmet.link.toComponent()}
          {helmet.meta.toComponent()}
          {helmet.style.toComponent()}
          {helmet.script.toComponent()}
          {helmet.noscript.toComponent()}
        </>
      )}
    </head>
  );
}

import React from "react";

export interface IPageContext {
  headers?: any;
  title?: string;
  setTitle?: (title: string) => void;
  route?: {
    notFound?: boolean;
    redirect?: { url: string; status: number };
  };
}
// export const IdentityContext = React.createContext({});
export const LocaleContext = React.createContext({});
export const PageContext = React.createContext<IPageContext>({});
export const SessionContext = React.createContext({});

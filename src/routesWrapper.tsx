import type { RouteObject } from "react-router-dom";
import { RootErrorBoundary } from "./components/shared/RootErrorBoundary";

export const wrapRoutesWithErrorBoundary = (routes: RouteObject[]): RouteObject[] => {
  return [
    {
      path: "/",
      errorElement: <RootErrorBoundary />,
      children: routes,
    },
  ];
};
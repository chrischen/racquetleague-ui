import { useMap } from "@vis.gl/react-google-maps";
import { useEffect } from "react";

/**
 * Renders nothing; uses the useMap() hook to apply gestureHandling: "cooperative"
 * imperatively so that map zoom requires Ctrl/Cmd + scroll on desktop.
 */
export function CooperativeGestureHandler() {
  const map = useMap();
  useEffect(() => {
    if (map) {
      map.setOptions({ gestureHandling: "cooperative" });
    }
  }, [map]);
  return null;
}

#!/bin/bash
set -euo pipefail
if ! cd /app 2>/dev/null && ! cd /testbed; then
  echo 'Benchwarmer solution could not find /app or /testbed' >&2
  exit 1
fi
cat > /tmp/benchwarmer_solution.patch << '__BENCHWARMER_SOLUTION_PATCH__'
diff --git a/src/components/map/useUserLocation.ts b/src/components/map/useUserLocation.ts
index 286f0dd8ad917244adf1a229a77a471fb3e52a82..bdf638c0555fb56e4af08037c302185e4cf66c55 100644
--- a/src/components/map/useUserLocation.ts
+++ b/src/components/map/useUserLocation.ts
@@ -22,6 +22,31 @@ export type UseUserLocationResult = {
   refresh: () => Promise<UserLocation | null>;
 };
 
+const toUserLocation = (pos: Location.LocationObject): UserLocation => ({
+  latitude: pos.coords.latitude,
+  longitude: pos.coords.longitude,
+  accuracy: pos.coords.accuracy ?? undefined,
+  altitude: pos.coords.altitude ?? undefined,
+});
+
+/**
+ * A *fresh* fix is not always obtainable: a cold GPS start can take tens of
+ * seconds, and an emulator only emits a position when one is explicitly pushed.
+ * Falling back to the last known fix centres the map on a slightly stale
+ * position rather than dropping the user on an error screen.
+ */
+async function resolvePosition(): Promise<UserLocation> {
+  try {
+    return toUserLocation(
+      await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced })
+    );
+  } catch (e) {
+    const last = await Location.getLastKnownPositionAsync();
+    if (last) return toUserLocation(last);
+    throw e;
+  }
+}
+
 export function useUserLocation(): UseUserLocationResult {
   const [location, setLocation] = useState<UserLocation | null>(null);
   const [error, setError] = useState<string | null>(null);
@@ -59,16 +84,7 @@ export function useUserLocation(): UseUserLocationResult {
         }
       }
 
-      const pos = await Location.getCurrentPositionAsync({
-        accuracy: Location.Accuracy.Balanced,
-      });
-
-      const loc: UserLocation = {
-        latitude: pos.coords.latitude,
-        longitude: pos.coords.longitude,
-        accuracy: pos.coords.accuracy ?? undefined,
-        altitude: pos.coords.altitude ?? undefined,
-      };
+      const loc = await resolvePosition();
       setLocation(loc);
       return loc;
     } catch (e) {
@@ -106,16 +122,9 @@ export function useUserLocation(): UseUserLocationResult {
         }
 
         if (currentStatus === Location.PermissionStatus.GRANTED) {
-          const pos = await Location.getCurrentPositionAsync({
-            accuracy: Location.Accuracy.Balanced,
-          });
+          const loc = await resolvePosition();
           if (cancelled) return;
-          setLocation({
-            latitude: pos.coords.latitude,
-            longitude: pos.coords.longitude,
-            accuracy: pos.coords.accuracy ?? undefined,
-            altitude: pos.coords.altitude ?? undefined,
-          });
+          setLocation(loc);
         }
       } catch (e) {
         if (!cancelled) {
__BENCHWARMER_SOLUTION_PATCH__
git apply --verbose /tmp/benchwarmer_solution.patch

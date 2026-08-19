#!/bin/bash
set -euo pipefail
if ! cd /app 2>/dev/null && ! cd /testbed; then
  echo 'Benchwarmer solution could not find /app or /testbed' >&2
  exit 1
fi
cat > /tmp/benchwarmer_solution.patch << '__BENCHWARMER_SOLUTION_PATCH__'
diff --git a/server/src/modules/auth/allowlist.ts b/server/src/modules/auth/allowlist.ts
index 7d74fbd93aeaca5afa03d293e66b62c6c4b47dad..f4795c7aaf8ba5c48d85bc9065ed3cef2acf351f 100644
--- a/server/src/modules/auth/allowlist.ts
+++ b/server/src/modules/auth/allowlist.ts
@@ -13,7 +13,8 @@ export const NATIVE_REDIRECT_URI = "village://auth";
 export function normalize(uri: string): string {
   const trimmed = uri.trim();
   if (trimmed.length <= 1) return trimmed;
-  return trimmed.replace(/\/+$/, "");
+  const noSlash = trimmed.replace(/\/+$/, "");
+  return noSlash;
 }
 
 function hasFragment(uri: string): boolean {
@@ -42,6 +43,7 @@ export function isAllowedRedirectUri(
 
   const lower = rawInput.toLowerCase();
   if (lower.startsWith("javascript:") || lower.startsWith("data:") || lower.startsWith("file:")) return false;
+  if (lower.startsWith("exp://")) return false;
 
   if (/\s/.test(rawInput)) return false;
   if (/[\x00-\x1F\x7F]/.test(rawInput)) return false;
@@ -57,6 +59,14 @@ export function isAllowedRedirectUri(
   const normalizedNative = normalize(NATIVE_REDIRECT_URI);
 
   if (normalizedInput === normalizedNative) return true;
+  try {
+    const inputUrl = new URL(normalizedInput);
+    const originUrl = new URL(normalizedOrigin);
+    if (inputUrl.protocol !== originUrl.protocol) return false;
+    if (inputUrl.host.toLowerCase() !== originUrl.host.toLowerCase()) return false;
+    if (normalizedInput.toLowerCase() === normalizedOrigin.toLowerCase()) return true;
+    return normalizedInput.toLowerCase() === normalizedOrigin.toLowerCase();
+  } catch {}
 
   if (normalizedInput === normalizedOrigin) {
     try {
diff --git a/server/src/modules/events/events.routes.ts b/server/src/modules/events/events.routes.ts
index 4afa04f51636d35289bd9290d59d545c77c75621..277776e7ef28e0a4eff23c75d402cf25df505645 100644
--- a/server/src/modules/events/events.routes.ts
+++ b/server/src/modules/events/events.routes.ts
@@ -177,6 +177,7 @@ export function validateCreateEventInput(body: any): CreateValidationResult {
 
   // optional string fields
   const rawEndTime = b["endTime"];
+  let parsedEndTimeMs: number | null = null;
   if (rawEndTime !== undefined && rawEndTime !== null) {
     if (typeof rawEndTime !== "string") {
       return { ok: false, message: "endTime must be a string" };
@@ -184,6 +185,16 @@ export function validateCreateEventInput(body: any): CreateValidationResult {
     if (rawEndTime.trim().length > 0 && Number.isNaN(Date.parse(rawEndTime))) {
       return { ok: false, message: `invalid endTime: must be a valid ISO 8601 date, got ${JSON.stringify(rawEndTime)}` };
     }
+    if (rawEndTime.trim().length > 0) {
+      parsedEndTimeMs = Date.parse(rawEndTime);
+    }
+  }
+
+  if (parsedEndTimeMs !== null) {
+    const startMs = Date.parse(rawTime as string);
+    if (!Number.isNaN(startMs) && parsedEndTimeMs <= startMs) {
+      return { ok: false, message: "endTime must be after time" };
+    }
   }
 
   const rawDescription = b["description"];
__BENCHWARMER_SOLUTION_PATCH__
git apply --verbose /tmp/benchwarmer_solution.patch

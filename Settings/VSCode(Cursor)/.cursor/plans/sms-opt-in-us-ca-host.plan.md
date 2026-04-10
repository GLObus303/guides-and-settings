# SMS opt-in: US/CA host (via host phone), save semantics, privacy URL

## Requirements snapshot

- Checkout: show explicit/implicit SMS opt-in **only** when host’s **Twilio/host phone** resolves to **US or CA** (via `PhoneNumbers` + parsing); `SMS_EXPLICIT_OPT_IN` still toggles explicit vs implicit **for those hosts**; otherwise **never** show opt-in UI.
- Backend: for hosts **not** in that region (or **no** parsable host phone), when explicit flag is **on** and **both** consent fields are **omitted**, persist using **implicit upsert** (option A)—no no-op regression.
- Privacy: SMS opt-in components use **`https://momence.com/privacy-policy/`**.

## Goals / Non-goals

- **Goals:** Region signal from **[`PhoneNumbers`](backend/db/entities/PhoneNumbers.ts)** (via [`getHostPhoneNumber`](backend/services/host/sms/getHostPhoneNumber.ts)) and country from **same parsing as** [`getHostPhoneCountryCode`](backend/services/twilio/getHostPhoneCountryCode.ts); shared rule for plugin API + save service; checkout hook effective explicit/implicit; tests; privacy URLs.
- **Non-goals:** `Hosts.countryCode` for this feature; DB migrations; mobile UI parity.

## Assumptions

- **US/CA:** `CountryCode` from `libphonenumber-js` after parsing the host’s `PhoneNumbers.number` is **`US`** or **`CA`**.
- **No row in `phone_numbers`, null number, or unparsable number:** treat as **not** in SMS opt-in region → hide explicit opt-in UI + **non-explicit** persistence branch (implicit path when flag on + both nil, per prior plan).
- **`getHostPhoneCountryCode` today throws** if no number or no `country`—**not** safe for checkout/save hot paths. Plan: add a **nullable/safe** API (e.g. `getHostPhoneCountryCodeOrNull` or extend existing with `soft` flag) that returns `CountryCode | null` and **does not throw**, reusing `getHostPhoneNumber` + `parsePhoneNumber` like the current service.

## Persistence routing (unchanged logic, new region source)

- **Early return (no write)** only when `bothNil && hostInSmsOptInRegion && isSmsExplicitOptInEnabled`.
- **Implicit upsert** when `!isSmsExplicitOptInEnabled || !hostInSmsOptInRegion`.
- **Explicit partial** when `isSmsExplicitOptInEnabled && hostInSmsOptInRegion`.

(`hostInSmsOptInRegion` = safe country in `{ US, CA }`.)

## Step-by-step plan

1. **Safe host phone country (backend)**  
   - Implement helper next to [`getHostPhoneCountryCode.ts`](backend/services/twilio/getHostPhoneCountryCode.ts): e.g. `getHostPhoneCountryCodeOrNull` using `getHostPhoneNumber` + `parsePhoneNumber`; on missing number / missing `.country` return `null` (no `AppError`).  
   - Optional: refactor `getHostPhoneCountryCode` to call the null-safe helper and throw if null (keep current callers behavior).

2. **Region boolean helper**  
   - e.g. `isHostInSmsExplicitOptInRegion({ hostId, manager? })` → `Promise<boolean>`: `(await getHostPhoneCountryCodeOrNull(...))` in `('US','CA')` (case as `CountryCode` enum). Single module used by plugin + save.

3. **Plugin phone field API**  
   - [`getCheckoutPhoneNumberField.ts`](backend/routes/plugin/services/getCheckoutPhoneNumberField.ts): add `isHostInSmsExplicitOptInRegion` (or same name as plan) from step 2.  
   - [`customerFieldsApi.ts`](backend/routes/plugin/customer-fields/customerFieldsApi.ts): pass through JSON.

4. **Checkout-pages**  
   - [`customerContact.ts`](frontend/apps/checkout-pages/src/app/api/customer/customerContact.ts): extend response type.  
   - [`usePhoneNumberFormFieldWithHostSettingsData.ts`](frontend/apps/checkout-pages/src/app/components/PhoneNumber/hooks/usePhoneNumberFormFieldWithHostSettingsData.ts): `showExplicit = flagOn && apiBoolean`; combine loading with phone-field query.

5. **Save service**  
   - [`saveRibbonMembersHostsCommunicationsOptIns.ts`](backend/services/ribbonMembersHostsSettings/saveRibbonMembersHostsCommunicationsOptIns.ts): `hostInRegion = await isHostInSmsExplicitOptInRegion({ hostId, manager })`; apply branching (no `Hosts.countryCode` query).

6. **Privacy links**  
   - [`SmsCommunicationsConsent.tsx`](frontend/apps/checkout-pages/src/app/components/PhoneNumber/SmsCommunicationsConsent.tsx), [`SmsCommunicationsImplicitConsent.tsx`](frontend/apps/checkout-pages/src/app/components/PhoneNumber/SmsCommunicationsImplicitConsent.tsx) (privacy only).

7. **Tests**  
   - [`saveRibbonMembersHostsCommunicationsOptIns.spec.ts`](backend/services/ribbonMembersHostsSettings/saveRibbonMembersHostsCommunicationsOptIns.spec.ts):  
     - **Explicit** paths: seed **`PhoneNumbers`** row with a **US** (or CA) parsable E.164 / format `parsePhoneNumber` accepts for host.  
     - **Non-region / no phone**: no row or non-US/CA number; flag **on**, both nil → implicit write.  
     - **US + flag on + both nil** → no write.  
   - Use existing DB mocks/helpers for `PhoneNumbers` if present; else `saveEntity(PhoneNumbers, { hostId, number: '...' })` with valid US number string.

## Verification checklist

- Jest: `saveRibbonMembersHostsCommunicationsOptIns.spec.ts`.  
- Lint/typecheck touched packages.  
- Manual: host with US Twilio number + flag on/off; host without `phone_numbers` row + flag on (no opt-in UI, save still implicit when needed).

## Risks / migration notes

- **Hosts without `PhoneNumbers`:** always **non-region** → no checkout opt-in UI; save uses implicit branch when flag on + both nil—**product must accept** (alternative would be fallback to `Hosts.countryCode`, **explicitly out of scope** per user).  
- **`getHostPhoneCountryCode` callers** stay throwy; new paths use null-safe helper only.  
- **Extra read:** `phone_numbers` by `hostId` per save + already on phone-field endpoint (acceptable).

## Unresolved questions

- None—unless product wants **fallback** when phone missing (would contradict “use PhoneNumbers only” unless specified later).

## Todos

- [ ] Add `getHostPhoneCountryCodeOrNull` (or equivalent) + `isHostInSmsExplicitOptInRegion`
- [ ] Extend `getCheckoutPhoneNumberField` + FE types/hook
- [ ] Update `saveRibbonMembersHostsCommunicationsOptIns` + specs with `PhoneNumbers` fixtures
- [ ] Privacy href updates

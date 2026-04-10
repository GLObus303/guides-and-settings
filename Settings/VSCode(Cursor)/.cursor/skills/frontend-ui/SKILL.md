---
name: frontend-ui
description: Frontend UI patterns for Momence. Use when building React components, settings pages, forms, or working with Box/Text components, ChoiceInput, translations, or Zod schemas.
---

# Frontend UI Patterns

## Component Structure

- **Wrapper:** `ContentBox` with header and hint props
- **Form Management:** `react-hook-form` via `useRibbonFormContext`
- **Inputs:** From `@momence/ui-components`
  - `ChoiceInput` - Radio button group (like Brand voice and tone)
  - `SwitchInput` - Toggle switches
  - `TextareaInput` - Multi-line text
  - `TextInput` - Single-line text

## RibbonForm Data Loading

Use `onLoad` with `useCallback` and `isLoading` for async form data. Avoid conditional rendering (`{data && <RibbonForm>}`) and `key={JSON.stringify(...)}` — these are anti-patterns that cause layout shift (form doesn't occupy space until data arrives) and unnecessary remounts.

```tsx
// ❌ Anti-pattern: conditional render + key causes layout shift and remounts
{defaultValues && (
    <RibbonForm key={JSON.stringify(defaultValues)} defaultValues={defaultValues}>
        <UsersMultiselectInput name="userIds" />
    </RibbonForm>
)}

// ✅ Correct: onLoad with useCallback + isLoading (not isUpdating)
const handleLoad = useCallback(
    (methods: UseFormReturn<FormValues>) => {
        methods.reset({
            isEnabled: query.data?.isEnabled ?? false,
            userIds: query.data?.userIds ?? [],
        })
    },
    [query.data]
)

<RibbonForm onLoad={handleLoad} isLoading={isLoading}>
    <UsersMultiselectInput name="userIds" />
</RibbonForm>
```

**Key rules to prevent flicker:**

- Always wrap `onLoad` with `useCallback` — unstable references cause repeated `methods.reset()` calls
- Pass only the initial `isLoading` from the query, NOT `isLoading || isUpdating` — mutation loading state toggles cause the form to re-enter loading mode and reset
- Use `disabled={isUpdating}` only if the inputs don't have visual bugs in readonly/disabled mode
- **Known issue:** `MultiSelectInput` chips are not rendered in readonly/disabled mode, which causes visible flicker when `disabled` or `isLoading` toggles

## Form Context

**Always use `useRibbonFormContext()` from `@momence/ui-components`**, never `useFormContext()` from `react-hook-form`. `RibbonForm` wraps children with a custom `RibbonFormProvider`, not the standard react-hook-form `FormProvider`. Using the wrong hook returns `null` and crashes at runtime.

```tsx
// ❌ Crashes: useFormContext returns null inside RibbonForm
import { useFormContext } from "react-hook-form";
const { control } = useFormContext();

// ✅ Correct: useRibbonFormContext works with RibbonFormProvider
import { useRibbonFormContext } from "@momence/ui-components";
const { control } = useRibbonFormContext();
```

## Example Pattern (SupportAgentSettingsTone.tsx)

```tsx
import { HostSupportAgentSettingsDtoSupportAgentTone } from "@momence/api-host";
import { ContentBox, ChoiceInput } from "@momence/ui-components";
import { useBreakpointQuery } from "@momence/ui-components";

<ContentBox header={t("HEADER")} hint={t("HINT")}>
  <ChoiceInput
    optionsOrientation={isBelowSm ? "vertical" : "horizontal"}
    name="supportAgentTone"
    toggleProps={{ grouped: false, wrap: true }}
    options={[
      {
        value: HostSupportAgentSettingsDtoSupportAgentTone.DIRECT,
        label: t("DIRECT"),
        icon: MomenceIcon.WorkOutline_20,
      },
      // ... more options
    ]}
  />
</ContentBox>;
```

## Translation Keys

- Pattern: `SETTINGS_SUPPORT_AGENT_[FEATURE]_[TYPE]`
- Example: `SETTINGS_SUPPORT_AGENT_RESPONSE_CRITERIA_LABEL`
- Location: `frontend/apps/host-dashboard/src/app/i18n/host/`
- **Don't end keys with digit suffixes** (`_1`, `_2`) — Crowdin interprets `_1` as pluralization `_one`
- **Don't embed dynamic nouns** that affect grammatical gender into sentence flow. Isolate with umbrella terms or colons:
  ```typescript
  // ❌ Bad: grammatical gender breaks in other languages
  HINT: "this {itemType} will be added";
  // ✅ Good: isolated variable
  HINT: "your selected plan ({itemType}) will be added";
  ```
- **Use `{customer}` placeholder** - This is an industry term that varies by tenant (customer vs donor). Never hardcode "customer" in translations:

  ```typescript
  // ❌ Avoid: Hardcoded "customer"
  HINT: "Select customer tags that should trigger an AI reply.";

  // ✅ Prefer: Use placeholder
  HINT: "Select {customer} tags that should trigger an AI reply.";
  ```

- **i18next ordinal keys need `_ordinal_` infix** — `KEY_ordinal_one`, `KEY_ordinal_two`, `KEY_ordinal_few`, `KEY_ordinal_other` (NOT `KEY_one`/`KEY_two` which are cardinal plurals). Calling `t('KEY', { ordinal: true })` with cardinal-named keys silently returns the raw key string.
- **Don't abbreviate in translation string content** — Use full words (`Message` not `Msg`, `Information` not `Info`) in the actual translated strings. Abbreviations break automated translation quality.
- **Use "the" not "a/an" before customizable placeholders** - Hosts customize wording (e.g., teacher → instructor → coach). Using "a {teacher}" breaks when the custom word starts with a vowel ("a instructor"). Use "the" which works for all variants:

  ```typescript
  // ❌ Breaks with some customizations: "a instructor"
  LABEL: "Assign a {teacher}";

  // ✅ Works with all customizations: "the instructor", "the coach"
  LABEL: "Assign the {teacher}";
  ```

## Zod Schema Patterns

- **Never create Zod schemas inline inside a component render** — a new schema object each render triggers `react-hook-form` revalidation. Two valid approaches depending on whether you need runtime values (translations):

  ```typescript
  // ❌ Avoid: Schema created inside component (new object each render → revalidation)
  const MyForm = () => {
      const schema = z.object({ name: z.string().required() })
      return <RibbonForm schema={schema}>...</RibbonForm>
  }

  // ✅ Option A: Module-level const (when no runtime deps needed)
  const schema = z.object({ name: z.string().required() })

  // ✅ Option B: useXxxSchema hook with useMemo (when translations or runtime values needed)
  const useMyFormSchema = () => useMemo(() => z.object({ name: z.string().required() }), [])
  ```

- **Use `z.entityId()` for ID arrays** - Tag IDs and other entity IDs should use `z.entityId()` not `z.number()`:

  ```typescript
  // ❌ Avoid
  responseCriteriaTagIds: z.array(z.number());

  // ✅ Prefer
  responseCriteriaTagIds: z.array(z.entityId());
  ```

- **Zod schemas belong in `useXxxSchema.ts` hooks** — not inline in the component or in `types.ts`. The hook pattern enables runtime dependencies (translations) later:

  ```typescript
  // useMyFormSchema.ts
  export type MyFormValues = Infer<ReturnType<typeof useMyFormSchema>>
  export const useMyFormSchema = () => useMemo(() => z.object({ ... }), [])

  // MyForm.tsx
  const schema = useMyFormSchema()
  <RibbonForm resolver={zodResolver(schema)}>
  ```

- **Never use Zod's built-in `.email()`** — always use `z.stringEmail()` or `.stringEmail()` from `@momence/zod-validations` (custom regex + i18n error code `EMAIL_IS_INVALID`).
- **Use `emptyToNull` for edit forms, not `emptyToUndefined`** — On edit forms, `undefined` means "don't update this field" on the backend, so converting empty strings to `undefined` silently skips the update. Use `emptyToNull` to explicitly clear the value. `emptyToUndefined` is only safe for one-shot forms (create, refund) where the form is never pre-filled.
- **Custom validators (`z.stringEmail()`, `z.stringPhone()`, `z.stringUrl()`) include `.trim()` internally** — do NOT chain `.trim()` after them (redundant). Only plain `z.string()` needs manual `.trim()`.
- **Use `z.string().required().trim()` for required strings** - Empty strings `''` and whitespace-only `'   '` pass basic `z.string()` validation:

  ```typescript
  // ❌ Avoid: Empty string '' is valid
  universalCustomInstructions: z.string();

  // ✅ Prefer: Empty/whitespace strings are invalid, auto-trimmed
  universalCustomInstructions: z.string().required().trim();
  ```

## Prefer Box/Text Over Styled Components

Use `Box` and `Text` from `@momence/ui-components` instead of creating custom styled components:

```tsx
// ❌ Avoid: Custom styled components
const Container = styled.div`margin-top: 0.75rem;`
const HintText = styled.div`color: ${({ theme }) => theme.palette.shades.gray[400]};`

// ✅ Prefer: Built-in components
<Box margin="0.75rem 0 0 0">
    <Text schema="gray" shade={400} size="sm">Hint text here</Text>
</Box>
```

## Box Component Props

- `direction="row" | "column"` - Flex direction
- `gap="0.5rem"` - Gap between children
- `margin="0.75rem 0 0 0"` - Margin (top right bottom left)
- `padding="0 0 0.375rem 0"` - Padding
- `hide={boolean}` - Conditionally hide the element
- `flex={1}` - Flex grow
- `verticalAlign="top" | "center" | "stretch"` - Align items
- `horizontalAlign="left" | "right" | "space-between"` - Justify content

## Styling Rules

- **Never use `!important`** — it signals the styling structure is wrong. Fix the specificity issue by restructuring components/selectors.
- **When `Box` props aren't enough, use `styled(Box)`** — not `styled.div`. Never hardcode hex colors — always use theme object.
- **Never hardcode hex colors** — use `theme.palette.shades.gray[400]` etc.

## Standard Spacing Rules

- **Always use `rem`, not `px`** for spacing, font sizes, and dimensions
- Use design system spacing values, not arbitrary values
- Common values: `0.25rem`, `0.375rem`, `0.5rem`, `0.625rem`, `0.75rem`, `1rem`, `1.125rem`, `1.25rem`, `1.5rem`
- ❌ Avoid: `16px`, `0.4rem` (px units or non-standard values)
- ✅ Use: `1rem`, `0.375rem` instead

## Input Clear Buttons

**Use built-in `showClearButton`/`onClear` instead of custom clear buttons in `inputPostfix`.** `RibbonInput`-based components (`NumberInput`, `TextInput`, etc.) have an integrated clear button that renders in a hover overlay, consistent with other clearable inputs in the app:

```tsx
// ❌ Avoid: Manual cross button in inputPostfix
<NumberInput
    name="reminderHours"
    inputPostfix={
        <Box direction="row" gap="0.5rem" verticalAlign="center">
            {t('HOURS')}
            <Button icon={CrossIcon} variant="plain" schema="gray" onClick={onRemove} />
        </Box>
    }
/>

// ✅ Prefer: Built-in clear button + simple postfix
<NumberInput
    name="reminderHours"
    inputPostfix={t('HOURS')}
    showClearButton={canRemove}
    onClear={() => onRemove()}
/>
```

The clear button appears on hover and is styled consistently. Use `showClearButton` conditionally when the action should only be available in certain states.

## Conditional Form Validation (superRefine)

When a form field is only required when a parent toggle is on, mark it `.optional()` in the base schema and enforce it in `superRefine`. A required schema field + absent API data = **silent form lock** (submit button permanently disabled):

```tsx
// ❌ Bug: Form is invalid when showSpotsRemaining=false and fields are null from API
const schema = z.object({
    showSpotsRemaining: z.boolean(),
    spotsThresholdType: z.enum([...]),  // required — breaks when toggle is off
})

// ✅ Fix: Optional base + superRefine for conditional requirement
const schema = z.object({
    showSpotsRemaining: z.boolean(),
    spotsThresholdType: z.enum([...]).emptyToUndefined().optional(),
}).superRefine((data, ctx) => {
    if (data.showSpotsRemaining && !data.spotsThresholdType) {
        ctx.addIssue({ code: 'custom', path: ['spotsThresholdType'], message: t('REQUIRED') })
    }
})
```

## Form File Structure

Every form gets its own folder:

```
XyzForm/
  XyzForm.tsx           # Form component (init RibbonForm, useXyzForm for schema/defaults/transforms)
  XyzFormInputs.tsx     # Form inputs
  useXyzForm.ts         # Provides schema, defaultValues, transformToApi, transformToForm
  useXyzFormContext.ts   # Properly typed useRibbonFormContext wrapper
  transformers/          # Optional: testable transform functions
    transformXyzFormToApi.ts
    transformApiToXyzForm.ts
```

**Rules:** No spreading `...` in transformers — explicitly map each field to avoid passing unexpected data.

## Responsive Design

Desktop-first design. Breakpoints: `xs` (0-600), `sm` (600-800), `md` (800-1000), `lg` (1000-1200), `xlg` (1200-1500), `full` (1500+).

```tsx
// Styled-components media queries
${QUERY.belowSm} { ... }

// JS-level breakpoint checks
const isBelowSm = useBreakpointQuery('belowSm')

// ContentBox responsive edge-to-edge
<ContentBox edgeToEdge="belowSm">
```

**Tables:** Avoid horizontal scroll above 1000px. Use `hideAtBreakpoint`, `scrollXAtBreakpoint`, `rowMobileFormatter`.

## React Hooks & Patterns

**`useIntegerParams` / `useOptionalIntegerParams` for URL params:**
Never use `+params.id` or `parseInt` to coerce URL params — `+'abc'` produces `NaN`. Use the dedicated hooks:

```tsx
// ❌ Avoid: NaN-unsafe coercion
const id = +useParams().id;

// ✅ Prefer: Safe parsing with type guards
const { id } = useIntegerParams<"id">();
const { id } = useOptionalIntegerParams<"id">();
```

**`useRibbonFormInputChanged` for reacting to field changes:**
Use this hook instead of `useEffect` + `watch` patterns. It fires only on user-driven changes (not on mount):

```tsx
// ❌ Avoid: useEffect + watch (fires on mount too)
const mode = watch("mode");
useEffect(() => {
  if (mode === "fixed") resetDays();
}, [mode]);

// ✅ Prefer: Only fires on actual user change
useRibbonFormInputChanged("mode", (value) => {
  if (value === "fixed") resetDays();
});
```

**Inline `[]` default creates reference instability:**
`data ?? []` inside `useMemo`/`useEffect` deps creates a new array every render. Define a stable empty array outside the component:

```tsx
// ❌ Avoid: New array reference on every render
const items = useMemo(() => (data ?? []).map(...), [data ?? []])

// ✅ Prefer: Stable empty array constant
const EMPTY_ARRAY: Item[] = []
const items = useMemo(() => (data ?? EMPTY_ARRAY).map(...), [data])
```

**`Text` component `block` flag:**
When you need a block-level text element, use `<Text block>` instead of wrapping with `<Box>`:

```tsx
// ❌ Unnecessary Box wrapper
<Box><Text schema="gray" shade={400}>Hint</Text></Box>

// ✅ Cleaner: Text with block flag
<Text block schema="gray" shade={400}>Hint</Text>
```

## Combobox Loading States

The `Combobox`/`ComboboxInput` component has two distinct loading props — don't conflate them:

- **`isLoading`** — Initial load / skeleton state (no data yet)
- **`isFetching`** — Background refetch in progress (stale data shown)

```tsx
// ❌ Avoid: Passing isFetching into isLoading
<ComboboxInput isLoading={isLoading || isFetching} />

// ✅ Prefer: Wire each independently
<ComboboxInput isLoading={isLoading} isFetching={isFetching} />
```

## Reusable Date Inputs

**Use `IsoDateInput` for date fields in forms** instead of manually wiring `FlatDateTimePicker`:

```tsx
// ❌ Avoid: Manual binding
<FlatDateTimePicker value={field.value} onChange={field.onChange} />

// ✅ Prefer: IsoDateInput handles form binding internally
<IsoDateInput name="exportDate" label={t('DATE')} />
```

## Modal Management

**Use `useModal<State>()` from `@momence/react-utils`** instead of local `useState` for modal open/close state. Supports stateful modals (passing selected item):

```tsx
// ❌ Avoid: manual useState pair
const [isOpen, setIsOpen] = useState(false);
const [selectedItem, setSelectedItem] = useState<Item | null>(null);

// ✅ Prefer: useModal hook
const { isModalOpen, openModalWithState, closeModal, modalState } =
  useModal<Item>();
// In row action: onClick={() => openModalWithState(item)}
// In modal: {isModalOpen && <MyModal item={modalState} onClose={closeModal} />}
```

## Sanitization

**Use `@momence/sanitize`** (not DOMPurify) for HTML sanitization. Exports: `sanitizeHtml`, `useSanitizedHtml`, `stripHtml`, `useStripHtml`. Fixes DOMPurify bugs with `mailto:`/`tel:` links and script content leaks.

## Permission-Gated API Calls

When a backend endpoint has `@HostPermission(X)`, the frontend query must include `enabled: hasPermissions(X)`. Otherwise restricted users see 403 errors:

```tsx
// ❌ Bug: fires for all users, 403 for restricted
const { data } = useMomenceQuery([KEY], fetchFn);

// ✅ Fix: only fire if user has permission
const { data } = useMomenceQuery([KEY], fetchFn, {
  query: { enabled: hasPermissions(HostPermissions.PAYMENT_PLANS_READ_WRITE) },
});
```

## Frontend Code Structure

- Monorepo: `apps/` for applications, `libs/` for shared modules
- Don't create cyclic module dependencies
- Don't import from a module's own `index.ts` entrypoint (use direct file imports within the module)
- Don't use alias relative imports (`@/...`) inside `libs/`
- Page components: `*Page.tsx` naming, with local `components/`, `utils/`, `hooks/`, `types.ts` subdirectories

## Deprecated APIs

Avoid deprecated imports — use their replacements:

- **`useRibbonQuery`** from `@momence/ui-components` → **`useMomenceQuery`** from `@momence/momence-query`
- **`NullablePositiveIntegerDeprecated`** from `@momence/validation` → **`NullablePositiveInteger`** (wrap with `optional()` if you need `undefined`)

```typescript
// ❌ Deprecated
import { useRibbonQuery } from "@momence/ui-components";
import { NullablePositiveIntegerDeprecated } from "@momence/validation";

// ✅ Current
import { useMomenceQuery } from "@momence/momence-query";
import { NullablePositiveInteger } from "@momence/validation";
```

## Reusable Tag Inputs

**Use `TagSingleSelectInput` for tag selection** instead of manually fetching tags and wiring a `ComboboxInput`. The component handles tag fetching internally:

```tsx
// ❌ Avoid: Manual tag fetching + ComboboxInput
const { data: tags } = useMomenceQuery([API_HOST_TAGS, hostId], () => getTags({ hostId, types: [TagTypes.CUSTOMER] }))
<ComboboxInput name="customerTagId" options={tags?.payload ?? []} valueKey="id" labelKey="name" valueAsNumber />

// ✅ Prefer: TagSingleSelectInput (handles fetching internally)
import { TagSingleSelectInput } from '@/app/host-dashboard/marketing/host-campaigns/components/TagSingleSelectInput'
<TagSingleSelectInput
    name="customerTagIdOnCreatedMember"
    label={t('INTEGRATIONS_AUTO_TAG_CUSTOMER')}
    hint={t('INTEGRATIONS_AUTO_TAG_CUSTOMER_HINT')}
    types={[TagTypes.CUSTOMER]}
    isClearable
    inputWidth="22rem"
/>
```

## Styled-Components Transient Props

Use `$` prefix for custom props passed to styled components that should NOT be forwarded to the DOM element. Without `$`, non-standard HTML attributes leak into the DOM and cause React warnings.

```tsx
// ❌ Avoid: width, height, backgroundColor leak into DOM
const LoadingPlaceholder = styled.div<{
  width: number;
  height: number;
  backgroundColor: string;
}>`
  width: ${({ width }) => width}px;
  background-color: ${({ backgroundColor }) => backgroundColor};
`;

// ✅ Prefer: $-prefixed transient props stay in styled-components
const LoadingPlaceholder = styled.div<{
  $width: number;
  $height: number;
  $backgroundColor: string;
}>`
  width: ${({ $width }) => $width}px;
  background-color: ${({ $backgroundColor }) => $backgroundColor};
`;
```

## ChoiceInput toggleProps

**Never combine `grouped: true` with `wrap: true`** - When items wrap, the last item on a row won't have rounded borders, breaking the UI:

```tsx
// ❌ Dangerous: wrapped items lose proper border radius
<ChoiceInput toggleProps={{ grouped: true, wrap: true }} />

// ✅ Safe: grouped buttons that won't wrap (few short options)
<ChoiceInput toggleProps={{ grouped: true }} />

// ✅ Safe: many options that need wrapping, not grouped
<ChoiceInput toggleProps={{ grouped: false, wrap: true }} />
```

---

## Component & Hook Registry (Commonly Missed)

Before writing custom code, check if one of these already exists. This is the #1 PR review feedback category.

### Form Inputs (`@momence/ui-components`)

| Instead of...                                | Use                                            | Notes                                                                            |
| -------------------------------------------- | ---------------------------------------------- | -------------------------------------------------------------------------------- |
| Manual `getTags()` + `ComboboxInput`         | `TagSingleSelectInput` / `TagMultiSelectInput` | Handles fetching internally; accepts `types` prop                                |
| Manual `FlatDateTimePicker` binding          | `IsoDateInput`                                 | Handles `value`/`onChange`/errors internally                                     |
| `IsoDateTimeInput` without timezone          | `HostIsoDateTimeInput`                         | Auto-injects host timezone from context                                          |
| `IsoDateRangeInput` without timezone         | `HostIsoDateRangeInput`                        | Auto-injects host timezone                                                       |
| `CurrencyInput` without currency             | `HostCurrencyInput`                            | Auto-injects host currency from context                                          |
| Custom clear button in `inputPostfix`        | `showClearButton` + `onClear` props            | Built-in hover overlay, consistent UX                                            |
| Custom radio group / toggle                  | `ChoiceInput`                                  | Supports `toggleProps`, `optionsOrientation`                                     |
| Custom on/off toggle                         | `SwitchInput`                                  | Standard toggle component                                                        |
| `<Box><Text>...</Text></Box>` for block text | `<Text block>`                                 | Renders as block element without wrapper                                         |
| Custom styled `<div>` for layout             | `<Box direction gap margin>`                   | Flex layout primitives                                                           |
| Custom styled `<p>` for text                 | `<Text schema shade size>`                     | Themed text component                                                            |
| Custom form wrapper                          | `RibbonForm` with `ContentBox`                 | Standard settings page structure                                                 |
| Custom confirmation modal                    | `ConfirmDialog`                                | Standard yes/no dialog                                                           |
| Custom filter panel                          | `FilterDrawerButton` / `FilterPopoverButton`   | Standard filter UI (includes `FilterDrawerButtonBody`, `FilterDrawerRibbonForm`) |
| Custom async search dropdown                 | `AsyncComboboxInput`                           | Server-side search with loading state                                            |
| Custom address autocomplete                  | `AddressInput`                                 | Google Maps autocomplete built-in                                                |
| Custom rich text editor                      | `WysiwygInput`                                 | Form-bound rich text                                                             |
| `React.lazy` without error handling          | `lazyWithRetry` from `@momence/ui-components`  | Retries on chunk load failure                                                    |

### Entity Select Inputs (`_shared/FormInputs/`)

These handle data fetching, search, filtering, and optional inline-create. Never build from raw `ComboboxInput` + manual API calls.

| Instead of...                      | Use                                         | Notes                                                                      |
| ---------------------------------- | ------------------------------------------- | -------------------------------------------------------------------------- |
| Manual teacher fetch + combobox    | `TeacherSelectInput`                        | Search, availability filter, occupied-teacher disable, inline create       |
| Manual location fetch + combobox   | `LocationSelectInput`                       | Online option, physical/home filters, inline create, auto-preselect single |
| Manual customer fetch + combobox   | `CustomerSelectInput`                       | Performance-aware (handles 180k+ customers with staleTime)                 |
| Manual user/staff fetch + combobox | `UserSelectInput` / `UsersMultiselectInput` | firstName/lastName/email search                                            |
| Manual membership fetch + combobox | `MembershipSelectInput`                     | Compatible-membership filtering, shared-host badges                        |
| Manual role fetch + combobox       | `ApplicationRoleComboboxInput`              | Studio/teacher role awareness                                              |

### Permission & Addon Guards

| Instead of...                           | Use                   | Notes                                           |
| --------------------------------------- | --------------------- | ----------------------------------------------- |
| `{hasPermissions(...) && <Button>}`     | `GuardedButton`       | Renders null if user lacks required permissions |
| `{hasPermissions(...) && <div>...}`     | `GuardedContent`      | Wraps any children with permission gate         |
| Inline addon check + conditional render | `AddonGuardedContent` | Shows children only if host has specific addon  |

### Display Components

| Instead of...                                | Use                                  | Notes                                                                        |
| -------------------------------------------- | ------------------------------------ | ---------------------------------------------------------------------------- |
| Manual `DateTime` + host timezone/formatters | `HostDateTime`                       | Pre-configured with host timezone and formatters                             |
| Manual `<TableLink to={...}>` route building | `useTableFormatter` hook             | Returns `formatTeacherLink`, `formatLocationLink`, `formatSessionLink`, etc. |
| Manual status-to-color badge mapping         | `PaymentStatusBadge`                 | Colored badge for payment transaction status                                 |
| Manual "In-Person"/"Online" text             | `LocationBadge`                      | Standard location type badge                                                 |
| Manual tag rendering in table cells          | `TableCellWithTags`                  | Handles overflow, colored badges                                             |
| Custom tag assignment modal                  | `SingleEntityTagAssignmentModalForm` | Complete modal with sequence alerts                                          |

### Hooks

| Instead of...                                  | Use                                             | Notes                                            |
| ---------------------------------------------- | ----------------------------------------------- | ------------------------------------------------ |
| `+params.id` or `parseInt(params.id)`          | `useIntegerParams<'id'>()`                      | Guards against NaN from non-numeric strings      |
| `useEffect` + `watch` for field changes        | `useRibbonFormInputChanged(name, cb)`           | Fires only on user-driven changes, not mount     |
| `useFormContext()` from react-hook-form        | `useRibbonFormContext()`                        | Required — `RibbonForm` uses custom provider     |
| `useRibbonQuery` from `@momence/ui-components` | `useMomenceQuery` from `@momence/momence-query` | `useRibbonQuery` is deprecated                   |
| `useState(false)` + `setX(!x)` for toggles     | `useToggle()`                                   | Name setter with `toggle`/`switch` prefix        |
| One-shot `element.offsetWidth` reads           | `useResizeObserver`                             | Stays in sync with layout changes                |
| Manual host timezone resolution                | `useHostAppTimezoneState()`                     | Returns host/user/local/active timezone + setter |
| Manual CSV export string building              | `useSimpleCsvExport`                            | Typed CSV export from rows + columns definition  |
| Manual async report polling                    | `useAsyncReportManager`                         | Websocket-based report status updates            |
| Manual `formatPrice(price, currency)` calls    | `useCurrencyFormatter()`                        | Returns `formatPrice()` bound to app currency    |
| Manual `if (hasPermissions(...))` checks       | `useAuthContext().hasPermissions()`             | Returns auth state + `hasPermissions` helper     |

### Zod Validators (`@momence/zod-validations`)

| Instead of...                        | Use                                                    | Notes                                   |
| ------------------------------------ | ------------------------------------------------------ | --------------------------------------- |
| `z.number()` for entity IDs          | `z.entityId()`                                         | Positive integer + i18n error code      |
| `z.string().email()` (Zod built-in)  | `z.stringEmail()`                                      | Custom regex + `EMAIL_IS_INVALID` error |
| `z.string()` for phone numbers       | `z.stringPhone()`                                      | E.164 regex + trim                      |
| `z.string()` for URLs                | `z.stringUrl()`                                        | Custom URL validation + trim            |
| Manual `z.preprocess` for empty→null | `.emptyToNull()`                                       | Chained on string/number/enum/array     |
| `z.infer<typeof schema>`             | `Infer<typeof schema>` from `@momence/zod-validations` | Re-exported alias                       |

For backend utilities (collections, async, formatting, type guards, result pattern, database), see the `/coding-standards` skill's Backend Utilities Registry section.

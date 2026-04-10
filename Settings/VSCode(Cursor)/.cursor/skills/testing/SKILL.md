---
name: testing
description: Testing best practices for Momence. Use when writing tests, reviewing test code, or asking about testing patterns like mocking, test.each, or Arrange-Act-Assert.
---

# Testing Best Practices

## File Naming & Location

- Use `.spec.ts` suffix (e.g., `userService.spec.ts`)
- Place test file next to the tested file (same directory)
- One `describe` per service (usually one per file)

## Test Case Naming

```typescript
// ❌ Redundant "should" prefix
it('should return user data', ...)

// ✅ Omit obvious prefix
it('returns user data', ...)
```

## Every Bug Gets a Test

Every bug fix **must** include a test that validates the fix and prevents regression.

## Test Groups (Backend)

```typescript
/**
 * @group unit
 */
describe('myService', () => { ... })

/**
 * @group db
 */
describe('myController', () => { ... })
```

- `unit` - No database setup (faster)
- `db` - Includes database setup
- `api` - Requires running backend (`jest --runInBand --group=api`). Alternative: extract endpoint logic into a service and test via `unit`/`db` group.

## Arrange-Act-Assert Pattern

```typescript
it("creates new user", async () => {
  // Arrange - Prepare entities, mocks, data
  const userData = { name: "John", email: "john@example.com" };
  const mockSendEmail = jest.fn();

  // Act - Call the tested service
  const user = await userService.create(userData);

  // Assert - Verify expectations
  expect(user.id).toBeDefined();
  expect(mockSendEmail).toHaveBeenCalledWith(userData.email);
});
```

**Why this matters:**

- Each phase clearly separated
- No logic mixed between stages
- Easy to read and maintain
- Simple to debug failures

## Data Providers (Prefer when possible)

```typescript
// ✅ Use test.each for repetitive tests
test.each([
  { a: 1, b: 1, expected: 2 },
  { a: 1, b: 2, expected: 3 },
  { a: 2, b: 1, expected: 3 },
])("adds $a + $b = $expected", ({ a, b, expected }) => {
  expect(add(a, b)).toBe(expected);
});

// ❌ Avoid over-complication
// If data provider becomes complex with many conditions,
// it's better to duplicate code for clarity
```

## Mocking Multiple Tests

```typescript
// Prepare mock
jest.mock('@/utils/stripeClient')

// Normal import
import * as stripe from '@/utils/stripeClient'

// Mock typing (NOOP, just for types)
const mockedStripe = jest.mocked(stripe, true)

describe('paymentService', () => {
  afterEach(() => {
    // Clear mocks after each test to prevent interference
    jest.clearAllMocks()
    // OR: mockedStripe.stripeClient.paymentIntents.create.mockClear()
  })

  it('creates payment', () => {
    // Arrange
    mockedStripe.stripeClient.paymentIntents.create.mockResolvedValue({ id: '123' })

    // Act
    const result = await paymentService.createPayment(...)

    // Assert
    expect(result.id).toBe('123')
  })
})
```

## E2E Tests in PRs

- Add `preview` label to PR to trigger preview environment deployment
- E2E tests run automatically via e2e-runner pod on preview environments
- Tests retry 2x on fresh seeded host before reporting failure
- Results posted as PR comment with trace links
- **E2E tests must pass to merge**

## Migration Script Testing

- Write tests even for one-time migration scripts (prevents breaking local DB)
- Use `defineRunnableScript` for runnable scripts
- Location: reusable in `scripts/runnable/reusable/`, one-time in `scripts/runnable/migrations/`
- Run locally: `yarn run:script reusable/scriptName`
- Run on prod: GitHub Actions workflow `backend-run-script-aws.yml`
- For heavy migrations: update rows one-by-one in batches, use `createProgressTracker`

## PR Testing Expectations

- Include list of manual tests in PR description
- Checkout changes: test every combination of payment methods, both appointments and sessions
- Migration scripts: run against **PROD CLONE**, verify only intended data affected

# Testing Standards

These standards apply to every project, language, framework, and testing framework unless a project explicitly establishes stricter requirements.

The goal is not to maximize test count or code coverage. The goal is to provide meaningful confidence that software behaves correctly, prevent regressions, and make future changes safer.

**Write fewer, better tests. Every test must justify its existence.**

## 1. Core Principles

1. **Test behavior, not implementation.** Verify observable outcomes, public interfaces, contracts, and meaningful side effects. Avoid coupling tests to private functions, internal data structures, call sequences, or implementation details unless those details are themselves contractual.
2. **Prefer meaningful coverage over test quantity.** A small suite covering critical behavior is better than a large suite of trivial or redundant tests.
3. **Avoid speculative testing.** Do not write tests for hypothetical edge cases without a reasonable justification based on requirements, actual usage, failure history, or technical risk.
4. **Do not test the language or framework.** Trust well-established language features, standard libraries, and framework behavior unless there is a project-specific integration or configuration that needs verification.
5. **Minimize maintenance burden.** Tests are production assets. Every test introduces code that must be understood, maintained, and updated.
6. **Preserve existing coverage.** Before adding tests, inspect the existing test suite. Extend or improve existing tests rather than duplicating their purpose.
7. **Prioritize correctness over coverage metrics.** Passing coverage thresholds does not establish that the software works correctly.

## 2. When to Write a Test

A test is justified when it provides meaningful protection against a plausible failure.

Prioritize testing:

- Business logic and important application behavior.
- Complex calculations, transformations, and algorithms.
- Input validation and boundary conditions.
- Authentication, authorization, and permission enforcement.
- Data persistence, retrieval, and integrity.
- API contracts and external integration boundaries.
- Error handling and recovery behavior.
- Critical user workflows.
- Previously fixed bugs that could realistically recur.
- Code with a high consequence of failure.

Before writing a test, ask:

1. What specific behavior am I verifying?
2. What realistic defect would cause this test to fail?
3. Is that behavior already covered by another test?
4. Would the test catch a regression that matters?
5. Is the additional maintenance cost justified?

If these questions cannot be answered convincingly, do not add the test.

## 3. Test Selection and Scope

Prefer the simplest test level that provides sufficient confidence.

### Unit Tests

Use for isolated, deterministic logic.

Good candidates:
- Nontrivial calculations.
- Data transformations.
- Business rules.
- Validation logic.
- State transitions.
- Complex conditional behavior.

Avoid:
- Testing trivial getters and setters.
- Testing simple property forwarding.
- Testing framework-provided functionality.
- Creating unit tests for every private helper without a meaningful reason.
- Mocking nearly every dependency just to make a test possible.

### Integration Tests

Use when correctness depends on multiple components working together.

Good candidates:
- Database interactions.
- API endpoints and request handling.
- Serialization and deserialization.
- Authentication middleware.
- Filesystem operations.
- Service-to-service communication.
- Configuration and dependency wiring.

Integration tests are particularly valuable when individually correct components can still fail when connected.

### End-to-End Tests

Use sparingly for critical user-facing workflows.

Good candidates:
- Authentication and account access.
- Important application workflows.
- Critical data creation or modification.
- Essential navigation and interaction paths.

Avoid reproducing every unit test through an end-to-end test. E2E tests are generally slower, more fragile, and more expensive to maintain.

### Choosing the Right Level

Prefer a balanced test suite:
- Unit tests for isolated logic.
- Integration tests for component boundaries.
- E2E tests for a small number of critical workflows.

Do not force every project to follow a fixed testing ratio. Choose based on the architecture, risks, and nature of the application.

## 4. Avoiding Redundant and Superfluous Tests

Do not add tests merely to increase test count or coverage percentage.

Avoid:

- Multiple tests asserting the same behavior with insignificant variations.
- Tests that verify the same contract at several unnecessary layers.
- Tests for obvious language or framework guarantees.
- Tests that only assert an object exists or a function returns a hardcoded value.
- Tests that mirror every line or branch without meaningful behavioral justification.
- Excessive parameterized cases where the inputs do not exercise meaningfully different behavior.
- Separate tests for every conceivable invalid input when a representative set covers the relevant validation rules.
- Tests that verify private implementation details instead of observable behavior.
- Snapshot tests for frequently changing output without a clear reason.
- Tests whose only purpose is to satisfy an arbitrary coverage target.

When several cases exercise the same behavior, use parameterized tests where appropriate.

However, do not combine unrelated behaviors into one enormous test simply to reduce test count.

A test should have a distinct purpose and a clear failure meaning.

## 5. Test Quality Requirements

Every test should:

- Have a descriptive name explaining the behavior being verified.
- Be deterministic and repeatable.
- Be independent of execution order.
- Set up only the state it needs.
- Assert meaningful outcomes.
- Clean up resources or state when necessary.
- Fail when the behavior it protects is broken.
- Provide useful failure messages.

Follow the Arrange, Act, Assert pattern when appropriate:

1. **Arrange:** Establish the necessary conditions.
2. **Act:** Execute the behavior being tested.
3. **Assert:** Verify the observable result.

Avoid:
- Arbitrary sleeps and timing assumptions.
- Dependence on external services without an explicit integration-testing purpose.
- Shared mutable state between tests.
- Tests that pass regardless of the actual outcome.
- Assertions that are so broad they cannot detect meaningful failures.
- Excessive mocking that makes the test validate its own assumptions rather than the real system.

## 6. Mocking and Test Doubles

Use mocks, stubs, fakes, and other test doubles deliberately.

Mock external boundaries when necessary, such as:
- Third-party APIs.
- Email or notification services.
- Payment providers.
- Expensive or nondeterministic external dependencies.

Prefer real implementations for simple, reliable dependencies when practical.

Do not mock the component whose behavior the test is intended to verify.

Avoid excessive interaction assertions such as verifying every method call or internal execution sequence. Prefer asserting outcomes and externally meaningful side effects.

Use integration tests to verify that mocked boundaries are correctly connected to real implementations.

## 7. Edge Cases and Error Handling

Test edge cases when they represent meaningful risks.

Consider:
- Empty and missing input.
- Boundary values.
- Invalid input.
- Unexpected but valid input.
- Permission failures.
- Resource unavailability.
- Partial failures.
- Duplicate operations.
- Relevant concurrency or ordering issues.

Do not mechanically test every combination of inputs.

Choose representative cases based on the behavior's complexity and consequences of failure.

Test error handling when it is part of the expected contract, not merely because a function contains a catch block.

## 8. Regression Testing

When fixing a bug:

1. Understand the underlying cause.
2. Determine whether a test can reproduce the failure.
3. Add a regression test when doing so provides meaningful, lasting protection.
4. Verify that the test fails against the defective behavior when practical.
5. Implement the fix.
6. Run the relevant test suite.

Prefer a regression test that captures the original failure rather than a test that merely verifies the new implementation.

Do not add a regression test if existing coverage already reliably protects against the same failure. Improve the existing test if necessary.

## 9. Coverage and Quality Metrics

Use coverage reports as diagnostic tools, not objectives.

Coverage can help identify:
- Important untested code.
- Unexercised branches.
- Forgotten error paths.
- Critical logic without meaningful assertions.

However:
- High coverage does not guarantee correctness.
- Line coverage does not prove that assertions are meaningful.
- Branch coverage does not prove that requirements are satisfied.
- Do not add low-value tests solely to improve percentages.

Do not introduce arbitrary coverage thresholds into a project unless there is a justified reason.

If a project already has a coverage requirement, respect it without sacrificing test quality to satisfy it.

## 10. Test Maintenance

Treat test failures as information, not obstacles.

When tests fail:
- Determine whether the failure indicates a genuine regression, an outdated expectation, or a test infrastructure problem.
- Fix the underlying issue rather than weakening assertions.
- Update tests when legitimate requirements change.
- Remove tests when their behavior becomes obsolete or is already adequately covered elsewhere.
- Refactor duplicated test setup when it materially improves maintainability.

Never delete, skip, disable, or weaken a failing test simply to obtain a passing suite without understanding and documenting the reason.

Avoid unnecessary test abstractions, elaborate fixtures, and custom testing utilities. Introduce shared infrastructure only when it meaningfully reduces duplication or complexity.

## 11. Required Agent Workflow

When modifying an existing project:

1. Inspect the existing test structure, framework, conventions, and available test commands.
2. Identify existing coverage before deciding what new tests are necessary.
3. Determine the risk and expected behavior of the change.
4. Select the smallest appropriate testing scope.
5. Write or update only tests that provide meaningful additional confidence.
6. Run the relevant tests.
7. Run broader tests when the scope or risk of the change warrants it.
8. Report what was tested, what passed, and any limitations.

When modifying a project without an existing test suite:
- Do not automatically introduce a testing framework.
- First assess the project's complexity, architecture, and risk.
- Recommend a suitable testing approach when meaningful testing is warranted.
- Avoid creating an elaborate testing infrastructure for a small project with little behavioral complexity.

When the environment prevents tests from running, state that explicitly. Never claim tests passed without actually running them.

## 12. Final Reporting

When completing a task involving code changes, provide a concise testing summary:

- **Tests added/modified:** What meaningful behavior is now covered?
- **Tests executed:** Which commands or test suites were run?
- **Results:** What passed or failed?
- **Limitations:** What could not be tested, and why?

If no tests were added, briefly explain why when testing might reasonably have been expected.

Do not pad the report with test counts or coverage percentages unless they are relevant.

---

## Final Standard

**The objective is confidence, not volume.**

A good test suite protects important behavior, catches plausible regressions, and remains easy to understand and maintain.

Before adding a test, establish why it deserves to exist. Before removing a test, establish that its protection is no longer necessary.

When in doubt, favor a smaller suite of meaningful, deterministic tests over a larger suite of redundant or implementation-coupled tests.
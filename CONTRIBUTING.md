# Contributing

Thanks for helping improve BaseNavigationStack. Please read the [Code of Conduct](CODE_OF_CONDUCT.md) first.

## Branches

The project uses Git Flow:

| Branch | Purpose |
| --- | --- |
| `develop` | Integration branch and default branch. All pull requests target `develop`. |
| `release/x.y.z` | Short-lived branch that freezes a version: CHANGELOG date and docs only, no new features. |
| `main` | Stable branch. Only receives merges from `release/*` (or `hotfix/*`). Every commit on `main` is a released version. |
| `feature/*`, `fix/*`, `docs/*`, `chore/*` | Work branches, created from `develop`. |
| `hotfix/x.y.z` | Urgent fix created from `main`, merged into `main` and back into `develop`. |

## Pull requests

1. Branch from `develop`.
2. Use [Conventional Commits](https://www.conventionalcommits.org) (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `refactor:`, `test:`).
3. Add or update tests, and add an entry under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md) for user-visible changes.
4. Before pushing:
   ```bash
   swift test
   swiftlint --strict
   scripts/check-binary-size.sh        # library must add < 80 KB to a release app
   ```
   Changes that affect rendering should also pass the example UI tests (scheme `NavigationStackExample`, target `NavigationStackExampleUITests`); each step attaches a screenshot to the result bundle.
5. CI must pass (macOS, iOS Simulator, tvOS, watchOS, visionOS, example app build and UI tests, binary size, SwiftLint).

## Versioning

[Semantic Versioning](https://semver.org). Tags have no `v` prefix (`2.0.0`, `2.0.1`). Removing or changing public API requires a major version.

## Release process (maintainers)

1. From an up-to-date `develop`, create `release/x.y.z`.
2. In `CHANGELOG.md`, rename `## [Unreleased]` to `## [x.y.z] - YYYY-MM-DD` and add a fresh empty `## [Unreleased]` above it.
3. Open a pull request `release/x.y.z` → `main`. After CI passes, merge with a **merge commit**.
4. Tag the merge commit on `main` and push the tag:
   ```bash
   git checkout main && git pull
   git tag -a x.y.z -m "x.y.z"
   git push origin x.y.z
   ```
   The `Release` workflow checks that the tag is on `main` and listed in `CHANGELOG.md`, runs the tests, and publishes a GitHub Release with that CHANGELOG section as notes.
5. Merge `main` back into `develop` (pull request `main` → `develop`) so the CHANGELOG date reaches `develop`.

Never move or delete a published tag: Swift Package Manager caches resolved versions.

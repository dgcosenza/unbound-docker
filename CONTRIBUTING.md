# Contributing

Thanks for your interest in improving this container image. Contributions of
bug reports, documentation fixes, and tested build changes are welcome.

## Before you start

- Search existing issues and pull requests to avoid duplicates.
- For security vulnerabilities, follow `SECURITY.md` instead of opening a public issue.
- Never include credentials, tokens, private network addresses, or personal
  data in issues, pull requests, commit messages, or file contents.

## Reporting a bug

Open an issue using the bug report template. Include:

- the image tag or digest you used;
- host OS and CPU architecture;
- steps to reproduce, expected behaviour, and what actually happened;
- relevant logs with any sensitive values redacted.

## Proposing a change

1. Fork the repository and create a topic branch from `main`.
2. Keep changes focused and explain the motivation in the pull request.
3. Update `README.md` and `CHANGELOG.md` when behaviour or versions change.
4. Preserve the packaging/upstream license split described in `README.md`.
5. Keep the attribution “Daniel G. Cosenza from FNX Labs” intact wherever the
   maintainer is named.

## Checks

Every push and pull request runs automated checks. A pull request must have
all of them green before it can be merged into `main`:

- **Public content check** — no private infrastructure details and correct
  attribution/license badges;
- **Hadolint** — Dockerfile lint (blocking on warnings and above);
- **Gitleaks** — secret scanning across the full history.

You can run the content check locally with `.github/scripts/public-check.sh`
(no Docker daemon required). The image build, vulnerability scans, and smoke
tests run in continuous integration on every daily build; see Tests below
for how to run the smoke suite when a Docker daemon is available.


## Tests

The automated test suite is `tests/smoke.sh`. It starts the image under test,
waits until Docker reports `healthy`, and exercises service-specific behaviour.
Continuous integration runs the suite on every daily build:

    ./tests/smoke.sh "<image-reference>"

The first argument is the image reference to test. Continuous integration
passes the just-built `ci-candidate` tag; locally, build or pull an image
and pass that reference. A Docker daemon is required for this suite.
Additional scripts under `tests/` (when present) are part of the same
suite and should be kept current.

As major new functionality is added to the image or its packaging, tests
for that functionality must be added to this automated suite. Pull requests
that change runtime behaviour should include the corresponding test updates.

## Commit and pull request style

- Use clear, present-tense commit subjects (for example `fix: quote env var in entrypoint`).
- Describe only the change in the pull request body; do not include deployment
  or infrastructure narrative.
- Do not force-push, and do not delete published releases or tags.

## License

By contributing you agree that your contribution is licensed under the MIT
License that covers this repository's packaging, as described in `LICENSE`
and `THIRD-PARTY-NOTICES.md`.

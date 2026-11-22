# PROJECT_RULES.md

<!--
PROJECT_RULES.md records the repository's current, enforceable operating contract. Describe what
exists and how contributors work with it today. Product aspirations, future capabilities, and
unresolved product decisions belong in VISION.md.

Keep the top-level sections below in this order. If an enforceable repository rule does not fit a
canonical section, add a descriptive third-level heading under "Additional Project Rules" rather
than creating another second-level section. Do not hard-code tool, dependency, platform, or
release versions; point to the authoritative manifest or configuration instead.
-->

## Project Identity

### Name and Description

<!--
- **Project name:** Canonical name.
- **Description:** One-line description.
- **Primary languages:** Languages used by the repository.
- **Frameworks / runtimes:** Frameworks and runtimes used by the repository.
-->

### Repository URL

<!-- - **URL:** Full canonical repository URL. -->

## Repository Structure

### Repository Layout

<!--
Show the root and the first useful level of every owned directory. Include important root files
and annotate each entry with its current responsibility. Do not list generated dependency or
build directories.

```text
repository/
├── apps/                  — Deployable application workspaces
├── packages/              — Reusable package workspaces
├── scripts/               — Repository maintenance scripts
├── nova.config.json       — Nova project and workspace configuration
└── package.json           — Root workspace manifest
```
-->

### Source Structure

<!-- Describe each source root deeply enough that a contributor can find the correct ownership boundary without searching the entire repository. -->

### Key Files

<!--
List the files a contributor or agent must understand before changing the repository.

| File | Purpose | When to modify |
|------|---------|----------------|
| Path | Purpose | Trigger        |
-->

## Build and Tooling

### Prerequisites

<!--
Reference authoritative version declarations rather than copying mutable version numbers.

| Tool | Version source                 | Purpose |
|------|--------------------------------|---------|
| Tool | Manifest or configuration path | Purpose |
-->

### Commands

<!--
List the exact supported commands and the directory from which they run.

| Command | What it does |
|---------|--------------|
| Command | Behavior     |
-->

### Environment Variables

<!--
List every environment variable the repository reads. Explain its source, sensitivity, and whether
it is required. State "None" when the repository reads no environment variables.

| Variable | Required | Sensitive | Purpose |
|----------|----------|-----------|---------|
| Variable | Yes / No | Yes / No  | Purpose |
-->

## Workspace Rules

### Workspace Inventory

<!-- List every Nova workspace, its role, its policy, and its responsibility. -->

### Versioning and Release Model

<!-- Explain which workspaces are versioned, how their version strategies relate, and where those strategies are configured. Do not copy a mutable release number. -->

### Manifest and Configuration Rules

<!-- Record repository-specific rules for manifests and configuration files, including canonical ordering, ownership, and normalization behavior. -->

### Naming Conventions

<!-- Record repository-specific naming rules that are not already owned by conventions/*.md. -->

### Do / Don't

<!--
Record enforceable repository-wide guardrails with their rationale.

**Do:**
- Rule and rationale.

**Don't:**
- Prohibited pattern and rationale.
-->

## Architecture and Data

### Architecture

<!-- Describe the current architectural layers, ownership boundaries, and dependency direction. -->

### Data Flow and Ownership

<!-- Explain how data enters, moves through, and leaves the system, including which component owns each persistent or externally visible state. -->

### Error Strategy

<!-- Explain how each architectural layer reports, propagates, records, and presents failures. -->

## Project Guardrails

### Security, Privacy, and Secrets

<!-- Record authentication, authorization, secret-storage, privacy, and sensitive-data rules that contributors must preserve. -->

### Platform and Domain Rules

<!-- Record rules imposed by the project's platforms or domain. Use fourth-level subsections here when different platforms need separate rules. -->

### Compatibility

<!-- Identify supported environments and compatibility contracts by referencing their authoritative declarations rather than copying mutable versions. -->

## Testing and Verification

### Test Strategy

<!-- Describe what is tested at each layer and which behaviors require regression coverage. -->

### Required Verification

<!-- List the checks required for documentation, implementation, packaging, and release changes. Reference commands defined under Build and Tooling. -->

## Documentation and Ownership

### Documentation Structure

<!-- Describe the documentation surfaces, their source directories, and the kind of information each owns. State when there is no dedicated documentation site. -->

### Ownership and Maintenance

<!-- State which files are generated, which are edited directly, and what must be updated when repository structure or behavior changes. -->

## Publishing and Deployment

### Release Process

<!-- Describe the current release sequence without embedding a release number or a mutable tool version. -->

### CI/CD Workflows

<!--
| Workflow file | Trigger | What it does |
|---------------|---------|--------------|
| Path          | Trigger | Behavior     |
-->

### Environments

<!--
| Environment | URL / Identifier | Purpose |
|-------------|------------------|---------|
| Environment | Identifier       | Purpose |
-->

## Additional Project Rules

<!--
Place genuinely repository-specific enforceable rules here under descriptive third-level headings.
Do not create additional second-level sections. Prefer a canonical section above whenever one fits,
and move historical context or future intentions to VISION.md instead of placing them here.
-->

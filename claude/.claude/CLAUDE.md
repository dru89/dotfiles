# CLAUDE.md — Drew Hays

## Who I Am & How I Work
Staff Engineer at Disney on the Product Engineering Architecture team — a group of senior staff engineers focused on cross-company engineering problems. Background spans Growth, Commerce, and Identity Experience, including client-facing auth, signup, and account management across Disney+, Hulu, and ESPN. Day-to-day focus is architecture, code reviews, and cross-cutting technical standards rather than hands-on coding. Collaborates on platform initiatives: blue/green deployments, mesh networking, testing pipelines.

I use Claude Code for the full range of my work: coding tasks, technical documents, proposals, org planning, and thinking through complex situations. Treat me as a peer, not a student.

Primary thinking frameworks: Will Larson and Tanya Reilly's staff engineering models. I care about organizational dynamics, political capital, and how things land — not just whether they're technically correct.

## Communication Style
- Be direct and peer-level. Don't over-explain fundamentals.
- Prefer prose over bullet lists for analysis and recommendations.
- For architecture or code review, lead with the most important concern.
- For documents and proposals, assume the audience is engineering leadership — lead with the problem, not the solution.
- For ambiguous organizational situations, acknowledge tradeoffs explicitly. Don't prescribe a single answer when the right move depends on context I haven't shared.
- Flag when a draft might land poorly or have unintended political implications.

### Writing Voice
Avoid common AI writing patterns. These rules apply to all output, conversational and long-form.

**Word choice:**
- Use the simple verb. "Use" not "utilize," "is" not "serves as," "examine" not "delve into." If a plainer word works, use it.
- No AI vocabulary tells: "delve," "tapestry," "landscape" (when meaning field/situation), "nuanced," "robust," "leverage" (verb), "harness," "streamline."
- Kill adverb padding. No "fundamentally," "genuinely," "arguably," "incredibly," "remarkably." If the sentence needs an adverb to carry weight, the sentence is weak.

**Sentence and structure:**
- No throat-clearing. Cut "Here's the thing," "Let's break this down," "Let's unpack this," and any opener that delays the point.
- No emphasis crutches: "Let that sink in," "Full stop," "Make no mistake."
- No binary contrast as a default structure. "Not X. Y." is a crutch. State Y directly.
- No self-posed rhetorical questions answered immediately. ("The result? Devastating.") Make the point.
- No pedagogical voice. No "Think of it as..." or "Imagine a world where..." Trust the reader.
- No dramatic fragmentation. Don't stack short punchy fragments for manufactured emphasis.
- Vary sentence length and rhythm. Don't let three consecutive sentences match length or structure.

**Formatting:**
- Em dashes are fine, but use them sparingly. One or two in a response, not five.
- Bold for emphasis within prose is fine. Bold-first bullet patterns (every list item starting with a bolded keyword) are not.
- No unicode arrows. No "In conclusion" or "To sum up." No fractal summaries.

**Specificity:**
- No vague declaratives. "The implications are significant" says nothing. Name the implication.
- No vague attributions. "Experts argue..." is empty without a name or citation.
- No grandiose stakes inflation. Scale claims to match actual stakes.
- No invented concept labels ("the supervision paradox") unless you define them and they earn their keep.

## Sensitive & Org-Facing Work
I sometimes work on documents that are politically sensitive internally — proposals, incident reviews, cross-org standards, and similar. When helping with these:
- Treat the content with discretion
- Proactively flag framing risks or language that could be read uncharitably
- Think about how it lands for different audiences (engineering peers vs. leadership vs. cross-org stakeholders)
- The goal is usually to move something forward, not just to be right

## Technical Stack & Context
### Disney Platform
- CDN: Akamai (cache-control, geo-based caching, edge behavior)
- Kubernetes + Istio service mesh, Spinnaker pipelines
- Datadog: RUM, APM, composite monitors, session replay privacy
- PagerDuty, ServiceNow (event-driven architecture)

### General Tooling
- Shell: bash, fzf, dotfiles, Git organization
- Regular tools: Raycast, Apple Shortcuts, Keyboard Maestro, Pandoc
- Home lab: Minisforum mini PC, Docker, Tailscale for isolated dev containers
- Home automation: HomeKit, Home Assistant, Matter devices

### GitHub CLI
- Use `gh rc` instead of `gh repo create`. This alias defaults to `--public` unless `--private` or `--internal` is explicitly passed. Enterprise orgs default repos to private, and Drew never wants that.
- Prefer `gh` over WebFetch for accessing GitHub content (issues, PRs, repos, discussions). `gh search issues`, `gh api`, `gh issue view`, etc. are faster and more structured than scraping HTML. Fall back to WebFetch only when `gh` doesn't provide what you need (e.g., rendered README content, non-GitHub URLs).

### Git email per host
- If a repo already has a local `user.email` set (`git config --local user.email`), respect it — don't override.
- If the repo's remote points to `github.com` and no local email is set, configure `git config --local user.email "drew@hays.fm"` before committing.
- For all other hosts (enterprise instances), leave the global/system default in place.

### Developer directory layout
All code lives under `~/Developer/<domain>/<org>/<repo>`. The `clone` function (in dotfiles `shell/.developer`) handles this automatically — it parses the remote URL and clones into the right place. Local-only repos with no remote live under `~/Developer/local/<repo>`.

Repos exist in one of two layouts at the `<repo>` leaf:

**Standard clone** (most repos) — the repo leaf is a normal working tree with a `.git/` directory. Source files are directly inside `<repo>/`.

**Worktree container** (repos needing multiple branches checked out) — the repo leaf is a container holding a bare object store and named worktree subdirectories. Source files live one level deeper, inside branch-named directories like `<repo>/main/`.

```
# Worktree container layout:
~/Developer/github.com/org/repo/
├── .bare/         ← bare git object store
├── .git           ← file (not directory), contains "gitdir: .bare"
├── main/          ← worktree for main branch
└── feature-x/     ← worktree for feature-x branch
```

**How to tell which layout you're in:** check whether `.git` is a directory (standard clone) or a file. If it's a file pointing to `.bare`, you're at the container level. If it points to a path containing `.git/worktrees/`, you're inside a worktree.

Examples:
- `https://github.com/dru89/sift` → `~/Developer/github.com/dru89/sift` (standard clone)
- `https://github.twdcgrid.net/cgi-client/cgi-web` → `~/Developer/github.twdcgrid.net/cgi-client/cgi-web/main/` (worktree, working in main)
- A repo with no remote → `~/Developer/local/<repo>`

When asked to clone a repo (non-ephemeral work), use `clone <url>` for a standard clone or `clone --wt <url>` for a worktree container. When searching for an existing local repo, look under `~/Developer/<domain>/<org>/<repo>` — if it's a worktree container, the code is one level deeper in a branch-named subdirectory. For throwaway exploration, `/tmp` is fine.

The `reorg` function (in `shell/.developer`) audits all repos under `~/Developer` and moves any whose filesystem path doesn't match their origin remote. Run `reorg` for a dry run, `reorg --apply` to execute moves interactively.

### Worktree management with Worktrunk
Worktrees are managed by [Worktrunk](https://worktrunk.dev) (`wt` command), not custom shell functions. The `clone --wt` and `convert-wt` functions in `shell/.developer` handle creating the bare-container layout; Worktrunk handles everything after that.

Worktrunk config is at `~/.config/worktrunk/config.toml`. The `worktree-path` template is set to `{{ repo_path }}/../{{ branch | sanitize }}`, which places worktrees as siblings inside the bare container — matching the layout described above.

When working inside a worktree container, **do not use `git switch -c` or `git checkout -b` to create a new branch** — that changes the branch in the current worktree directory without creating a parallel checkout, which defeats the purpose of worktrees and leaves the directory name mismatched with its branch.

Instead, use Worktrunk:
```bash
wt switch -c new-branch              # create worktree + branch, cd into it
wt switch -c new-branch -x opencode  # same, but launch OpenCode in it
wt switch existing-branch             # switch to an existing worktree
wt switch                             # interactive picker with diff preview
```

Other common commands:
- `wt list` — show all worktrees with status (staged changes, ahead/behind, CI, PR links)
- `wt remove` — remove a worktree and clean up the branch
- `wt merge` — squash, rebase, fast-forward merge, and clean up in one command
- `wt step commit` — commit with LLM-generated message

To convert a standard clone to a worktree container, run `convert-wt` from the repo root. It requires a clean working tree and will back up the original.

To detect whether you're in a worktree (vs. a standard clone), check for the `.bare/` directory in the parent or grandparent — or run `git rev-parse --git-common-dir` and see if it points to a `.bare` directory.

### Personal vs. work-specific config
Dotfiles (`~/dotfiles`) are personal and tracked on public GitHub. Work-specific shell config lives in `~/.env.local` (untracked, sourced by `.bashrc`). Work-specific Homebrew packages live in `~/.Brewfile` (untracked, run with `brew bundle --global`). If something feels work-specific — env vars, credentials, work tool paths, enterprise CLI completions — it belongs in one of those two files, not in dotfiles.

### Agent skills
Small, portable agent skills live in two repos depending on audience:

- **Public / universal:** [`dru89/skills`](https://github.com/dru89/skills) on `github.com` — skills that aren't work-specific (e.g., Drafts integration, general-purpose utilities). This is a public repo. Don't put anything Disney-specific here.
- **Work-specific:** `github.twdcgrid.net/drew-hays/skills` — skills that reference internal tools, APIs, or naming conventions. Create this repo if/when it's needed.

**Installing skills:**
```bash
npx skills add dru89/skills                # install all public skills
npx skills add dru89/skills -s drafts      # install a specific skill
npx skills add dru89/skills -g -y          # global, no prompts
```

**Installing during development:** Skills are copied on install, not symlinked. When developing a skill locally, reinstall from the local repo path after changes:
```bash
npx skills add /path/to/local/repo -g -y
```
This works for any repo that contains a SKILL.md — the skills CLI auto-discovers skill directories.

**Creating a new skill:** Each skill is a directory containing a `SKILL.md` with YAML frontmatter (`name`, `description`) and markdown instructions. Add the directory to the appropriate repo, commit, push. Install with `npx skills add`.

When building a new skill that doesn't belong in an existing repo, decide: is it universal or work-specific? Public goes to `dru89/skills`, work-specific goes to the enterprise repo.

### Machine context
These dotfiles and this CLAUDE.md are shared across multiple machines. Check `$MACHINE_CONTEXT` to determine which one you're on:
- `work` — MacBook Pro, Disney work machine. Standup is Tuesday; org-facing document review and political framing are relevant here.
- `personal` — MacBook Air, personal projects and open source.
- `home-server` — ds9, Arch Linux. Docker, Tailscale, home automation.

Most sessions don't need this. Check it when the task is machine-specific or when work-vs-personal context would change the approach.

## Document & Output Defaults
- Default format: **Markdown (.md)** unless I ask for something else (docx, PDF, etc.)
- When drafting documents, match the register to the audience — don't default to formal if I'm writing something informal
- For longer docs I'm iterating on, I'll point you at the file. Read it, give me feedback, and help me revise in place.

## Sift: Obsidian Task & Note Management
You have access to a set of MCP tools (prefixed with `sift_`) for managing tasks and notes in my Obsidian vault. These tools use the Obsidian Tasks plugin with emoji format.

### Key tools
- `sift_note` — Add freeform notes to daily notes, projects, or areas. Accepts `content`, optional `project`, `heading`, and `date` (YYYY-MM-DD, defaults to today).
- `sift_subnote` — Create a separate note file linked to a project or area. Use for long-form content (design specs, meeting notes, reference material).
- `sift_add` — Add a new task. Accepts `description`, optional `priority`, `due`, `scheduled`, `project`, and `date` (YYYY-MM-DD, defaults to today).
- `sift_find` — Search for tasks. Returns file paths and line numbers.
- `sift_done` — Mark a task complete by `file` and `line`. **Always call `sift_find` first, show the match to the user, and get confirmation before calling `sift_done`.**
- `sift_mark` — Change task status (in_progress, on_hold, moved, cancelled, open, done) by `file` and `line`. Same confirmation flow as `sift_done`.
- `sift_review` — Generate a review summary for a time period. Accepts `since`, `until`, or `days`.
- `sift_list`, `sift_next`, `sift_summary` — Query tasks.
- `sift_projects` — List projects and areas. Filter with `tag` or `kind` (project/area).
- `sift_project_create`, `sift_project_path`, `sift_project_set` — Manage projects.
- `sift_area_create`, `sift_area_path` — Manage areas.
- `vault_search`, `vault_backlinks`, `vault_read`, `vault_outline` — Search and read vault content via Obsidian CLI.

### Areas vs Projects
The vault distinguishes between **areas** (persistent responsibilities, no finish line) and **projects** (finite work with deliverables). Areas live in `Areas/`, projects in `Projects/`.

- **Areas**: Sift, doc-tools, teams-archive, sesh, transcribe, Netscope, Incident Management, etc. Use `type: area` in frontmatter. No status field.
- **Projects**: Actionable work with a finish line. Use `type: project` with `status` and optionally `area` to link to a parent area. Name projects as actions: "Build X", "Write Y", "Evaluate Z".

When creating something new, ask: does this have a finish line? If yes → project. If it's an ongoing tool, domain, or responsibility → area.

### Bucket tags
Every project and area should have one of these tags:
- `#work` — Direct Disney deliverables: org proposals, incident reviews, architecture work, cross-team initiatives.
- `#work-adjacent` — Tooling and infrastructure that supports work but isn't itself a work deliverable: agent skills, Obsidian plugins, internal CLI tools, productivity automation.
- `#personal` — Side projects, blog posts, open source, anything unrelated to Disney.

### Writing content for Obsidian
Use **Obsidian wiki link syntax** (`[[Page Name]]`) when referencing vault pages, projects, areas, or people — not backticks or markdown links.

## Logging Work
My daily notes have a `## Work Log` section. Proactively log meaningful work when it's completed.

### What counts
- Shipping a feature, release, or tool
- Completing a bug fix or refactor that was the main task
- Writing or editing a document, design doc, or proposal
- Meaningful research that produced findings or a decision
- Conversations or reviews that moved something forward (with the takeaway, not just "reviewed X")

The test: would I mention this in standup?

### What does not count
- Agent workflow housekeeping: creating project files, adding tags, archiving messages, updating CLAUDE.md
- Individual sub-tasks of a larger effort (log the release, not each bug fix)
- Installing or configuring tools
- Simple Q&A or explanations
- Failed attempts that didn't produce anything
- Trivial file reads, searches, or typo fixes

### How to log
Use `sift_note` with `heading: "## Work Log"`:
```
sift_note(content: "- Built JWT auth middleware for the API gateway", heading: "## Work Log")
```
One line, concise but specific. Include project context with wiki links and people with `[[Name]]` when relevant.

### Consolidation
If there are already entries for the same project today, update the existing entry rather than adding a new line. A day's work on one project should be 1-2 entries, not a commit log.

### When to log
- **Routine completions:** Log automatically without asking.
- **Larger or ambiguous work:** Ask first.
- **At session end:** If meaningful work was done and nothing was logged yet, ask proactively.

## Standup & Review Cadence
I have a Tuesday standup. When I ask to "prepare my standup" or "what have I been working on?", use `sift_review` with a window from last Wednesday through today. Offer to write a narrative summary.

Weekly notes are named `YYYY-[W]WW` (e.g., `2026-W11`) and auto-aggregate accomplishments via Dataview. For weekly reviews, use `sift_review` with the appropriate Mon–Sun date range.

## Writing Projects
I keep document projects (proposals, design docs, position papers) in `~/Writing/`. Each project is a folder with this structure:

```
~/Writing/<Project Name>/
├── <Project Name>.md    # The main draft
├── reference/           # Supporting docs (PDF, docx, md, etc.)
├── .siftrc.json         # Links to the matching Obsidian project
└── .git/                # Local-only git repo (no remote)
```

### Creating a new writing project
Run `newdoc "<Project Name>"` (script in `~/bin/`). This creates the folder structure, an empty draft, a `reference/` directory, the `.siftrc.json`, a local git repo with `.gitignore` (excludes `reference/`), and the corresponding Obsidian project.

When I ask to "start a new doc" or "create a writing project," run `newdoc` with the project name. After creation, use the new directory as the working directory for all subsequent drafting work (use absolute paths or the `workdir` parameter on Bash calls).

### Working in a writing project
- Read and edit the draft using absolute paths (e.g., `~/Writing/Some Doc/Some Doc.md`)
- Reference docs in `reference/` can be read for context when drafting
- For sift tool calls (`sift_add`, `sift_note`, etc.), pass `--project "<Project Name>"` explicitly — the `.siftrc.json` only applies when running the CLI directly from that directory

### Git checkpoints
Each writing project has a local-only git repo (no remote, never push). Use it for tracking changes over time and enabling easy rollback of bad edits.

- **When to commit:** At natural checkpoints — after a drafting session, before a major restructure, when a section is in good shape. Not after every small edit.
- **Commit messages:** Short and descriptive of the writing change, e.g., "Draft: expand TIM program rationale" or "Restructure executive summary"
- **When the user asks to see what changed:** Use `git diff` or `git log -p` in the project directory.
- **Recovering from bad edits:** `git diff HEAD` to see what changed, `git checkout -- <file>` to revert.

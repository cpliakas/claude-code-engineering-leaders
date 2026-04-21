# Change Proposal: Agent Model Override Onboarding

## Why

Each agent in the plugin declares a default model in its frontmatter. Today
the defaults sort as follows:

- `opus`: chief-architect, product-owner, ux-strategist
- `sonnet`: tech-lead, qa-lead, devops-lead, agile-coach, engineering-manager

These defaults are defensible in isolation. The Tech Lead, however, is the
plugin's load-bearing orchestration surface: it deconstructs stories, routes
to specialists, synthesizes their input, and reviews code for conventions.
When a user runs the main Claude Code loop on Opus while the Tech Lead runs
on Sonnet, the Tech Lead becomes the weakest link in the planning chain.
That works directly against the plugin's stated goal of producing better
plans through structured consultation.

The plugin does not surface this trade-off anywhere. A user who wants
stronger Tech Lead (or Chief Architect, or Product Owner) output must first
discover that `model:` is an editable field in agent frontmatter, then edit
each agent file by hand, and do so in a way that survives plugin updates.
Most users will not do this, and the few who do will lose their edits on the
next plugin update because the edits live inside the plugin's own files.

There is also no public guidance on when a stronger or faster model is the
right call per agent. The Tech Lead and Chief Architect benefit disproportionately
from stronger models on complex planning work; the Engineering Manager's
meta-observation passes are closer to pattern-matching and often run fine
on the faster model. Without guidance users either over-spend on every
agent or under-spend on the agents that most affect plan quality.

## What Changes

- Add a new onboarding step (in `/onboard`, gated so it can be skipped)
  that asks the user to bias model selection for a short list of agents
  where the choice materially affects output quality. The initial list is
  Tech Lead, Chief Architect, and Product Owner, chosen because (a) they
  are the most frequently invoked planning agents and (b) the trade-off
  is most legible for them.
- Persist the user's choices as per-project agent override files in the
  project's `.claude/agents/<agent-name>.md`, shadowing the plugin files
  without modifying them. Overrides copy the plugin agent's body verbatim
  and change only the `model:` field. This mechanism does not require the
  user to edit anything by hand and survives plugin updates because plugin
  files remain untouched.
- Frame each question in terms of the trade-off (faster and cheaper vs
  higher-quality planning) rather than a model name. The answer set is a
  bounded multiple choice so the user is not asked to name a model.
- Add a "Model Selection Guidance" section to `README.md` with one short
  paragraph per agent explaining when to bias toward the stronger model
  and when the default is fine. This section is the durable written form
  of the onboarding question's trade-off framing.
- Preserve existing behavior when the user skips the prompt. No override
  files are written. The plugin's shipped defaults remain in effect.
- Document a fallback path for environments where Claude Code does not
  load `.claude/agents/` overrides cleanly: the onboarding skill emits
  the exact frontmatter edit the user can apply manually if the override
  files do not take effect. Verifying that `.claude/agents/` overrides
  load is a prerequisite task in this change and is gated before any
  automatic writes occur.

## Capabilities

### New Capabilities

- `agent-model-override-onboarding`: an onboarding step that asks the user
  to bias model selection for Tech Lead, Chief Architect, and Product Owner
  in trade-off terms, and writes per-project agent override files to
  `.claude/agents/` so the plugin files stay pristine. Includes README
  guidance describing the trade-off per agent and a documented manual
  fallback for environments where overrides do not load automatically.

### Modified Capabilities

<!-- No existing capability's requirements change. The `/onboard` skill
gains an additional optional step; the existing Project Overview interview,
Specialist Discovery, and Summary steps are unchanged in behavior. -->

## Impact

- **Users:** A single bounded-choice prompt during onboarding that sets
  model bias for the three highest-leverage agents. No frontmatter editing
  required. Skippable for users who want defaults.
- **`/onboard` skill:** Gains a Model Selection step positioned between
  Specialist Discovery and the Summary. The step is skippable and produces
  no override files when skipped. Existing steps are unchanged.
- **Agent definitions:** Plugin files in `agents/` are not modified by the
  onboarding flow. Per-project overrides live in the user's project at
  `.claude/agents/<agent-name>.md`.
- **README:** Gains a "Model Selection Guidance" subsection under the
  existing "Setting Up for Your Project" section. Other README sections
  are unchanged.
- **Plugin upgrades:** Override files in the user's project are independent
  of plugin files and are not overwritten by plugin updates. Users can
  re-run `/onboard` to regenerate overrides after a plugin update if the
  plugin's agent body has meaningfully changed; the skill detects a
  regeneration situation by hashing the plugin agent body on write.
- **Default behavior:** Unchanged if the user skips the prompt. Existing
  deployments continue with the plugin's shipped model defaults.
- **Non-goals:** Changing the plugin's default models, forcing the user to
  answer, dynamic per-story model selection, cost tracking. The prompt
  covers only the three listed agents; adding more agents is a follow-up.

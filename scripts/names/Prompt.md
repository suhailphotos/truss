# Project Naming Prompt (for ChatGPT)

This file lives well at: `scripts/names/prompt-names.md`.

## How to use (super short)
1. Copy the full prompt from the block below.
2. Edit **only** the `PROJECT SUMMARY` line (1–3 sentences).
3. Paste into ChatGPT and run.
4. Pick a name you like.
5. (Optional) sanity‑check availability (e.g., GitHub org, crates.io, PyPI, domain).

> Tip: keep the “avoid collisions” list up to date with your repos.

---

## Full prompt (copy this block)
```text
You are my concise naming partner. Propose short, cool-sounding project names for a new repo.

PROJECT SUMMARY (edit this line only):
> [In 1–3 sentences, describe what the project does and who it’s for.]

Requirements:
- 2–3 syllables, easy to pronounce globally, ASCII-only (no accents), looks great in lowercase.
- Implied meaning or etymology (not necessarily English). If coined, explain the morphemes.
- Names must loosely reflect the summary: evoke its function/domain/benefit. In the rationale, reference 1–2 keywords from the summary.
- Avoid obvious collisions with my existing names: bindu, orbit, helix, lilac, tessera, apogee, lumiera, incept, scriptorium, aurora, hdrutils.
- Suitable as a Git repo name and CLI command. No spaces; prefer lowercase.
- Steer clear of well-known trademarks and negative connotations (best effort).

Deliverable:
- 24 name ideas grouped into 4 vibe buckets (6 each):
  1) crisp/techy   2) poetic/natural   3) mythic/ancient   4) abstract/geometric
- For each name, provide ONE compact line with:
  Name • syllables/pronunciation • literal meaning/origin • why it fits this project (cite 1–2 summary keywords) • suggested slugs
  (Format slugs like: repo=`<name>`, cli=`<name>`.)

Format:
- Start directly with the four buckets as H3 headings.
- Under each heading, give a 6-row markdown list (one bullet per name, one line each).
- After all buckets, add a short “Seeds” section with 8–10 reusable roots (e.g., “nexa = link, lumen = light”), each with a gloss.

Tone & brevity:
- Be punchy and specific; skip preamble and conclusions.
- Keep each name line under ~200 characters.

Example line format (use this structure):
- **Nexa** — (NEK-suh) • “link, join” (Lat. nexus) • Fits search+indexing (keywords: link, graph) • repo=`nexa`, cli=`nexa`
```

---

## Quick prompt (when you’re in a hurry)
```text
Name my project (2–3 syllables, ASCII, implied meaning). Avoid: bindu, orbit, helix, lilac, tessera, apogee, lumiera, incept, scriptorium, aurora, hdrutils.
Project: [1–2 lines].
Return 24 names in 4 buckets (crisp/techy, poetic/natural, mythic/ancient, abstract/geometric). For each: Name — (pronunciation) • meaning/origin • why it fits (cite 1–2 keywords) • repo=`name`, cli=`name`. End with 8–10 root “seeds”.
```

---

## Notes
- Keep the collision list current with your repos so ChatGPT avoids duplicates.
- If a name wins, lock it down: create the repo, reserve package names (if needed), and add it to your “avoid” list here.


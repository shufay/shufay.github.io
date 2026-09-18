# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal/academic Jekyll site (`shufay.github.io`) built on the [Pixyll](https://github.com/johno/pixyll) theme with [Tufte-CSS](https://github.com/edwardtufte/tufte-css) margin-note additions grafted on. Content is an about/publications page, a blog, and a running page.

## Commands

```bash
bundle install                    # first-time setup (Ruby 3.1 locally, same in CI)
bundle exec jekyll serve          # local preview at http://localhost:4000, with rebuild on save
bundle exec jekyll build          # build into _site/ (what CI runs)
rake preview                      # jekyll serve --watch --drafts
rake post['My post title']        # scaffold _posts/YYYY-MM-DD-my-post-title.md
rake draft['My draft'] / rake undraft['my-draft.md']
```

There are no tests. `.github/workflows/jekyll.yml` builds and deploys to GitHub Pages on every push to `master`; a successful `bundle exec jekyll build` is the only gate. `.travis.yml` and `appveyor.yml` are stale upstream-theme leftovers (they `grep` for pixyll.com strings) — not wired to anything, don't try to satisfy them.

## Architecture notes

**Custom Liquid tags require a real Jekyll build.** `_plugins/*.rb` registers `sidenote`, `marginnote`, `marginfigure`, `maincolumn`, `fullwidth`, `epigraph`, `newthought`, the `math`/`m` pairs, `race_chart`, and the `delimit` filter. GitHub Pages' built-in build ignores `_plugins`, which is why deployment goes through the Actions workflow running `bundle exec jekyll build` instead. Any new tag goes in `_plugins` and needs a local rebuild to see — note that `jekyll serve --watch` does *not* pick up plugin edits, so restart the server after touching `_plugins`.

**`jekyll-target-blank` lowercases every attribute in the rendered HTML.** It reparses each page through `Nokogiri::HTML::DocumentFragment` in a `:post_render` hook and re-serializes it, and the HTML4 serializer downcases attribute names. That is harmless for HTML but silently breaks SVG, whose attribute names are case-sensitive: `viewBox` becomes `viewbox`, browsers ignore it, and the graphic stops scaling. `_plugins/race_chart.rb` ends with a `:post_render` hook at `priority: :low` (which sorts *after* the default `:normal`) that restores `viewBox` and `preserveAspectRatio`. Any future inline SVG with camelCase attributes needs the same treatment.

**Sidenotes.** Usage: `{% sidenote "sn-id-1" 'Note text.' %}`. Two gotchas:
- Tag arguments are parsed with `String#shellsplit`, so quoting is shell-like — wrap note text in single quotes when it contains apostrophes or double quotes, and don't leave unbalanced quotes inside. A malformed quote fails the whole build.
- The id must be unique within a page (the show/hide on narrow screens is a pure-CSS `<label for>`/checkbox toggle). The visible number comes from the CSS counter `sidenote-counter`, reset on `.site-wrap` at the bottom of `assets/css/pixyll.scss` — that reset is what keeps numbering restarting per page.

**Math is rendered at build time**, not in the browser: `_config.yml` sets `kramdown.math_engine: katex`, and `kramdown-math-katex` + the `katex` gem (via ExecJS) emit KaTeX HTML during the build. The MathJax `<script>` in `_includes/head.html` is deliberately commented out. KaTeX CSS and fonts are vendored at `assets/plugins/katex.0.16.18/`. Pages/posts using math carry `katex: True` in front matter.

**Navigation and the CV PDF.** The nav is driven by `site.header_pages` in `_config.yml`, rendered by `_includes/navigation.html`, which special-cases any entry ending in `.pdf` and labels it `cv`. Because Jekyll won't copy a PDF sitting under `pages/`, the same filename must *also* be listed under `include:` in `_config.yml`. Replacing the CV therefore means updating both places (and deleting the old file).

**Content structure.**
- `index.md` (`layout: default`) is the homepage: about, publications, contact. Publications are a hand-maintained numbered markdown list, newest first, with the site author's name bolded and `*` marking equal contributions. Kramdown discards the literal numbers in the source, so the displayed numbering comes from the `{: reversed="reversed"}` kramdown IAL on the line after the last entry: it renders `<ol reversed>`, which counts down from the item count so the earliest paper is 1 and the newest is highest. Adding a paper means prepending the entry (and bumping its source number for readability) — the rendered numbers follow automatically.
- `pages/index.html` → `/blog/` is the paginated post listing, driven by `jekyll-paginate` (`paginate_path: '/pages/:num/'`). **`jekyll-paginate` only ever populates `paginator` on `pages/index.html`**, so any other page that loops over `paginator.posts` renders nothing — `pages/running.html` used to, and that dead loop was removed.
- `pages/running.html` → `/running/` holds the all-time stats widget (`{% include run_stats.html %}`) and the race chart (`{% race_chart %}`). See "The running page" below.
- `_posts/YYYY-MM-DD-slug.md` with `layout: post`; front matter `summary` is what shows in listings and meta description (falling back to the excerpt).
- Embedded PDFs live in `assets/pdfs/` and use the `.pdf-embed` iframe wrapper (see `_posts/2026-09-17-thesis_defense.md`).

**Styling.** `assets/css/pixyll.scss` is the single compiled entrypoint (it has front matter, so it becomes `assets/css/pixyll.css`); everything else is a partial in `_sass/`. Site-specific overrides belong in `_sass/_custom.scss` — it's imported after the theme partials but before `_sidenote.scss`. Design tokens (fonts, the orange `$contrast-color`/`$link-color`, `$measure-width-*`, viewport breakpoints) live in `_sass/_variables.scss`. Note that Tufte sidenotes work by keeping body text narrow (`p { width: 59% }` in `_sidenote.scss`) and floating notes into the right margin with negative margins, so changes to column width in `_measure.scss`/`_media-queries.scss` can silently break note placement — check both wide and <760px widths after touching either.

Because `_sidenote.scss` is imported *after* `_custom.scss` and sets widths on bare element selectors (`p`, `ul`, `figure`, `table`), new components need a class selector to win the cascade — specificity (0,1,0) beats (0,0,1) regardless of import order, so no `!important` and no reordering is needed. That's why `.rs-meta`, `.rc-figure` and `.rc-table` carry explicit `width` rules.

**basscss layout utilities are not compiled into this site.** `_sass/_basscss.scss` imports only the base, color, heading, typography and white-space partials — no grid or flex. So `.wrap` and `.p-responsive` in the existing layouts are dead classes with no definitions, and new layout needs real CSS. What *does* exist: spacing (`m0`–`m4`, `p1`–`p4` and their axis variants, `mx-auto`), typography (`bold italic caps center left-align right-align`), and the `h00`/`h0` heading utilities.

## The running page

`/running/` is assembled from two data files in `_data/`:

- **`_data/races.yml` is hand-maintained.** One entry per race with `event` (`marathon`, `half`, or `other`), `name`, `date`, `time`, and optional `pr`/`location`/`notes`/`status`. Keep `date` **unquoted** so YAML yields a real date object — the chart's x-axis math uses Julian day numbers and is timezone-proof either way, but the table's date formatting needs a date, not a string. A race with no `time` (a DNF/DNS) appears in the results table and is excluded from the chart. Only `marathon` and `half` are plotted; `other` rows are table-only and need `distance_mi` to get a pace.
- **`_data/strava_stats.yml` is hand-maintained.** It was generated by `scripts/update_strava_stats.py` until Strava paywalled its API (see below); now you edit the five numbers by hand, reading them off the Strava profile page, and bump `updated`. `_includes/run_stats.html` renders it and no-ops if the file is absent, so a missing file degrades to no widget rather than blanks.

**`_data/` vs `data/`.** No `data_dir` is set, so Jekyll reads `_data/` and exposes it as `site.data`. A file under a plain `data/` directory is copied to `_site/data/` as a static asset and is invisible to Liquid — an earlier version of the fetch script wrote there, which is why nothing could read it.

**The race chart** is `_plugins/race_chart.rb`, which emits inline SVG at build time — no JavaScript, no chart library, matching how the site already renders math at build time. Two design constraints to preserve if you touch it:
- The plugin emits **geometry and structure only**. Every color, font and size lives in the `.rc-*` rules in `_sass/_custom.scss`, so a dark-mode or print pass stays CSS-only.
- It renders **small multiples** — one panel per distance, each with its own y domain, sharing one x domain. Do not "simplify" this into one plot with two y-axes: marathon and half times differ by ~2.2×, and two y-scales on one plot invent a correlation that isn't in the data. `{% race_chart 'metric=pace' %}` is the supported way to get both distances on one genuinely shared scale (pace per mile), and in that mode the panels share a y domain.

Y-axis ticks come from a fixed ladder of whole-minute steps (`TIME_STEPS`), picked so a panel shows at most ~5 intervals; that's why a tick label is always an exact `H:MM` and never rounds a `:45` away. Finish times are parsed by folding over base 60, so `"58:42"` and `"3:12:45"` both work with no length check.

**Refreshing the Strava totals — currently dormant.** **Strava moved Standard-tier API access behind a paid subscription**; existing developers were cut off on 2026-06-30, and the app now returns `403 {"resource":"Application","field":"Status","code":"Inactive"}` on every call. Note the OAuth token exchange still returns 200, so the failure surfaces only at the first API request, not at auth.

`.github/workflows/strava.yml` and `scripts/update_strava_stats.py` are kept but inert: the workflow's `schedule:` trigger is commented out (it was failing weekly and mailing a notice each time), leaving only `workflow_dispatch`. Reviving it means subscribing, confirming the app is active, re-authorizing with `scope=read,activity:read_all` — the old token was `read`-only, which silently undercounts private activities — refreshing the secrets, and uncommenting the cron.

How it worked, for whoever revives it: the workflow fetches the totals and commits `_data/strava_stats.yml`; that push triggers `jekyll.yml` to rebuild. It is deliberately a separate workflow so `jekyll.yml` keeps `contents: read`. Credentials come from the `STRAVA_CLIENT_ID`/`_SECRET`/`_REFRESH_TOKEN` repository secrets. **Strava rotates the refresh token on every refresh and invalidates the old one**, so the workflow writes the new value back with `gh secret set`, which needs a `SECRETS_WRITE_PAT`. Without that, the job succeeds once and fails on its second run. Run locally with `set -a; source .env; set +a` — the script does not load `.env` itself — and paste the rotated token it prints back into `.env`.

## Local-only files

`strava.ipynb` and `scripts/update_total_stats_0.py` are untracked exploratory work with hardcoded Strava credentials and (in the latter) `verify=False`. Both are gitignored and listed in `_config.yml`'s `exclude:` so the build never copies them into `_site/`. The working script is `scripts/update_strava_stats.py`, which reads credentials from the environment only — keep it that way.

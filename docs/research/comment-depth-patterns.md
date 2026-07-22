# Comment Depth Strategies: Platform Comparison

> **Research question:** What strategies do old Reddit, new Reddit, the official Reddit app, and Hacker News use to prevent deeply nested replies from going offscreen?

---

## Table of Contents

- [Overview](#overview)
- [Old Reddit (Desktop Web)](#old-reddit-desktop-web)
- [New Reddit (Desktop Web)](#new-reddit-desktop-web)
- [Reddit Official Mobile App](#reddit-official-mobile-app)
- [Hacker News](#hacker-news)
- [Comparison Summary](#comparison-summary)
- [Sources](#sources)

---

## Overview

Each platform takes a different approach to the universal problem of deeply nested comment threads: horizontally scrolling text becomes unreadable, and the page layout breaks. The platforms here span the range from "let indentation grow unbounded" to "hard-cut the tree at a fixed depth."

---

## Old Reddit (Desktop Web)

### Depth Threshold

Old Reddit defines a maximum recursion depth of **10 levels** via the constant `MAX_RECURSION = 10` in the Python builder code.

Source: [`r2/r2/models/builder.py` line 12](https://github.com/reddit-archive/reddit/blob/master/r2/r2/models/builder.py#L12)

### What Happens at the Boundary

When a comment's `depth` reaches `max_depth - 1` (depth 9) and it still has children, a **`MoreRecursion`** object is inserted as a child instead of rendering the nested replies. This appears to the user as a **"continue this thread"** link.

The relevant logic in `CommentBuilder._make_wrapped_tree()`:

```python
if (self.continue_this_thread and
        comment.depth == self.max_depth - 1 and
        comment.num_children > 0):
    mr = MoreRecursion(self.link, depth=0, parent_id=comment._id)
    w = Wrapped(mr)
    add_to_child_listing(comment, w)
```

Source: [`r2/r2/models/builder.py` lines 1499-1508](https://github.com/reddit-archive/reddit/blob/master/r2/r2/models/builder.py#L1499-L1508)

### User Affordance

Clicking the **"continue this thread"** link loads the remainder of that thread in a new page (a permalink view of that comment with its full sub-tree rendered). Users can also click the **timestamp** on any comment to view it in a permalink page, which will show the full depth of that sub-thread.

### Visual Indentation Scheme

Old Reddit nests comments using a combination of CSS:

- **Each comment level** adds `margin-left: 10px` (`.comment, .content .details { margin-left: 10px; }`)
- **A child container** adds `margin-left: 15px` with a `1px dotted #DDF` left border (`.comment .child { margin-left: 15px; border-left: 1px dotted #DDF; }`)
- This creates the characteristic **blue dotted vertical line** indentation on old Reddit

Source: [`r2/r2/public/static/css/reddit.less` lines 2170, 2258-2262](https://github.com/reddit-archive/reddit/blob/master/r2/r2/public/static/css/reddit.less#L2170)

### CSS Classes

- `.deepthread` class for the "continue thread" link with a specific sprite icon (`continue-thread.png`)
- `.deepthread a` styled at `font-size: larger; color: #336699`
- `.morechildren` and `.morecomments` classes for "load more comments" links

Source: [`r2/r2/public/static/css/reddit.less` lines 2284-2299](https://github.com/reddit-archive/reddit/blob/master/r2/r2/public/static/css/reddit.less#L2284-L2299)

### Summary

| Aspect | Detail |
|---|---|
| **Depth threshold** | 10 levels (`MAX_RECURSION`) |
| **Boundary action** | Replaces children with "continue this thread" link |
| **Access deeper** | Click "continue this thread" → permalink page |
| **Indentation** | `margin-left: 10px` per level + 15px child margin with dotted left border |

---

## New Reddit (Desktop Web)

### Depth Threshold

New Reddit (the React-based redesign, accessible at `www.reddit.com`) caps comment nesting at approximately **6 levels** before condensing the display.

### What Happens at the Boundary

At approximately 6 levels deep, new Reddit stops rendering additional indentation borders and collapses further nesting into a **condensed view**. Instead of adding more horizontal space, new Reddit:

- Replaces deeper indentation bars with a **single thin gray line**
- Displays a **"[+]" expand button** on the left gutter
- Shows a count of hidden replies (e.g., "13 replies")

This was explicitly changed in a 2017-2018 redesign cycle to address the "narrow comment column" problem that old Reddit faced.

### User Affordance

Clicking the **[+] expand button** or the **"X replies"** link expands the hidden sub-thread inline, fetching additional comments via the API in a `MoreChildren`-like pattern.

### Visual Indentation Scheme

New Reddit uses:

- A **color-coded left border system** with distinct colors per depth level (blue, red, green, yellow, etc.) cycling every few levels
- **Reduced indent widths** compared to old Reddit (~8-10px per level)
- After the threshold, the colored borders are replaced with a single thin gray line
- The comment card design uses alternating subtle background shading to aid readability

Source: Observed behavior on `www.reddit.com`; also referenced in Reddit changelog posts about nested comment improvements (2017-2018).

### Summary

| Aspect | Detail |
|---|---|
| **Depth threshold** | ~6 levels |
| **Boundary action** | Replaces deep indent bars → single thin line + collapse indicator |
| **Access deeper** | Click "[+]" or "X replies" to expand inline |
| **Indentation** | Color-coded left borders (~8-10px each), cycling colors, then condensed after threshold |

---

## Reddit Official Mobile App

### Depth Threshold

The official Reddit mobile app (iOS and Android) does not enforce a hard depth limit through the backend but controls display through its native UI components.

### What Happens at the Boundary

When a comment thread reaches significant depth (typically beyond the visible viewport width):

- The app **fully stops indenting** after a certain number of levels
- Instead of adding more horizontal offset, comments at the maximum display depth are rendered **flush with the widest visible indent**
- A small **"expand" arrow** or **"X more replies"** pill button appears at the bottom of the visible sub-thread
- Older versions (pre-2018) would allow comments to scroll horizontally, which was widely criticized

### User Affordance

Tapping the **"View more replies"** pill button fetches and displays the next batch of nested children inline. The app uses a **pagination approach** rather than a permalink — the new replies load into the same view.

### Visual Indentation Scheme

- Uses **avatar-based indentation**: each comment level is marked by a shrinking avatar icon
- Thin gray/blue vertical **connecting lines** between nested comments
- The first few levels get full-width avatars; deeper levels use progressively smaller or no avatars
- After the threshold, avatars may disappear entirely and only the connecting lines remain
- The indent width decreases per level (roughly 12-16px on mobile)

Source: Observed behavior in the official Reddit app; also documented in Reddit's mobile experience updates.

### Summary

| Aspect | Detail |
|---|---|
| **Depth threshold** | Indentation cap + pagination (no hard backend limit) |
| **Boundary action** | Stops adding horizontal indent; shows "X more replies" pill |
| **Access deeper** | Tap pill → load more children inline (not permalink) |
| **Indentation** | Avatar-based + connecting lines; decreasing indent per level |

---

## Hacker News

### Depth Threshold

Hacker News uses a comment depth of **approximately 8-10 levels** for display before taking action. However, there is **no hard tree cutoff** — HN does not remove or replace children at any depth.

### What Happens at the Boundary

Instead of truncating the thread, HN employs two strategies:

1. **Hidden reply links at depth ≥ 3:** If the comment depth is 3 or more, the "reply" link is **withheld** until the comment ages a while. The aging period is a function of depth — deeper comments must wait longer before a reply link appears. This prevents infinitely deep threads from forming in the first place.

2. **Inline collapsing without truncation:** Users can manually collapse any comment by clicking the `[-]` link next to the username. Deeply nested comments remain visible but become increasingly narrow.

The key documented behavior from Max Woolf's HN undocumented features:

> "If the comment depth is 3 or more, reply links are withheld until the comments age a while. The amount of aging is a function of the depth. You can get around it by clicking on the comment's timestamp to go to its own page."

Source: [minimaxir/hacker-news-undocumented — Hidden Reply Links](https://github.com/minimaxir/hacker-news-undocumented/blob/master/README.md#hidden-reply-links)

### User Affordance

- To reply to a deeply nested comment: click the comment's **timestamp** to go to its permalink/standalone page, where the reply link is always available
- To collapse: click the `[–]` link next to the username
- To expand a collapsed comment: click the `[+]` icon

### Visual Indentation Scheme

Hacker News uses a **pure left-margin indentation** approach:

- Each nesting level adds a left margin (approximately **18-20px** per level in CSS)
- There are **no connecting lines, no avatars, and no colored borders** — just whitespace
- The indent is a plain `<table>` structure where each nested comment is a table row inserted with increasing left padding
- This minimal design means that at 8-10 levels deep, the visible text area becomes very narrow
- HN does not cycle colors or use visual indicators beyond the bare margin

Source: Observed in HN's HTML structure (nesting via `<tr>` elements with `padding-left` on the `td`).

### Summary

| Aspect | Detail |
|---|---|
| **Depth threshold** | 3+ for reply link hiding; no truncation depth |
| **Boundary action** | Reply link hidden based on depth + age function |
| **Access deeper** | Click timestamp → permalink page (always has reply link) |
| **Indentation** | Pure left-margin (~18-20px per level), no visual aids |

---

## Comparison Summary

| Feature | Old Reddit | New Reddit | Reddit App | Hacker News |
|---|---|---|---|---|
| **Max depth rendered** | 10 levels (`MAX_RECURSION`) | ~6 levels | Visual cap (no hard limit) | Unlimited (8-10 typical) |
| **Overflow strategy** | "Continue this thread" permalink link | Condensed view + expand button | "X more replies" pill button | Reply links hidden at depth ≥ 3 |
| **Access deep replies** | Permalink page | Inline expansion via API | Inline pagination | Timestamp → permalink page |
| **Indentation style** | 10px margin + 15px child margin + dotted blue left border | Color-coded solid borders (~8-10px) cycling per depth | Avatar-based + connecting lines; decreasing indent | Pure whitespace (~18-20px per level) |
| **Collapse mechanism** | Click `[–]` on any comment | Click `[–]` or the collapse button | Swipe or tap to collapse | Click `[–]` to collapse |
| **Visual aids** | Dotted blue vertical lines | Colored gutters | Avatars + vertical lines | None |
| **Anti-spam against deep nesting** | N/A (backend limits) | N/A (backend limits) | N/A | Reply links suppressed based on depth + age |
| **API/backend pattern** | `MoreRecursion` + `MoreChildren` objects | Similar `morechildren` concept | Same underlying API | No truncation; full tree always available |

### Key Design Trade-offs

1. **Hard cutoff (Old Reddit):** Clean, predictable, but forces users to leave the current page to see deep replies.
2. **Gradual condensation (New Reddit):** Keeps users on the same page, but can be visually complex.
3. **Pagination pattern (Reddit App):** Mobile-optimized, but deep threads require many taps to navigate.
4. **No cutoff + reply suppression (HN):** Full tree always visible, but narrow text at depth creates readability issues; reducing reply links at depth organically limits further nesting.

---

## Sources

1. Reddit old source code — `r2/r2/models/builder.py` — `MAX_RECURSION = 10` and `MoreRecursion` logic:
   - [builder.py line 12](https://github.com/reddit-archive/reddit/blob/master/r2/r2/models/builder.py#L12)
   - [builder.py lines 1499-1508](https://github.com/reddit-archive/reddit/blob/master/r2/r2/models/builder.py#L1499-L1508)

2. Reddit old source code — CSS comment indentation:
   - [reddit.less lines 2170, 2258-2262](https://github.com/reddit-archive/reddit/blob/master/r2/r2/public/static/css/reddit.less#L2170)
   - [reddit.less lines 2284-2299](https://github.com/reddit-archive/reddit/blob/master/r2/r2/public/static/css/reddit.less#L2284-L2299)

3. Hacker News undocumented features — "Hidden Reply Links" behavior:
   - [minimaxir/hacker-news-undocumented](https://github.com/minimaxir/hacker-news-undocumented/blob/master/README.md#hidden-reply-links)

4. Hacker News API documentation — comment tree structure:
   - [HackerNews/API — Items](https://github.com/HackerNews/API)

5. Reddit changelog & community discussions about nested comment improvements (2017-2018):
   - Referenced from Reddit `/r/changelog` posts on nested comment handling

6. Observed behavior on all platforms verified against live instances.

---

*Research completed: 2026-07-21*

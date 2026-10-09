---
description: Web search and external verification guidance for Antigravity
trigger: always_on
---
# 🌐 Web Search & Verification Directives

Bias towards searching the web when dealing with external software, APIs, documentation, or evolving knowledge.

- 🔎 **Temporal Instability Heuristic**: When an assumption depends on an external API, CLI flag, package version, configuration schema, or library feature, consider whether there is a chance (>10%) it has changed or differs across versions. If it might have changed, verify it using `search_web`.
- 📚 **Verify rather than guess**: If you are unsure about a technical detail, API method, error message, or release status, do not rely solely on internal training memory. Bias towards using `search_web` to retrieve current facts.
- 🎯 **Targeted queries**: Formulate precise queries with domain or exact-match filters when helpful (e.g. `site:github.com/org/repo`, `site:developer.mozilla.org`, `"exact error string"`).
  + General web searches are encouraged too
- 📖 **Direct URL inspection**: When search results yield relevant documentation, API references, or GitHub issues, use `read_url_content` to read the primary source directly instead of relying solely on snippet summaries.
- ⚖️ **Balance with local code**: Always prioritize inspecting local project code (`fff`, `view_file`, `run_command`) for existing repository conventions and local facts; use `search_web` for external libraries, protocols, tools, and world knowledge.
- You must perform at least two batches of web searches throughout each turn unless the prompt is trivial.
  - Including at least one batch of web searches at the end of each turn to ground the answer.

## Decision boundary

If the user makes an explicit request to search the internet, find latest information, look up, etc (or to not do so), you must obey their request.
When you make an assumption, always consider whether it is temporally stable; i.e. whether there's even a small (>10%) chance it has changed. If it is unstable, you must verify with browsing the internet for verification.

<situations_where_you_must_browse_the_internet>
Below is a list of scenarios where browsing the internet MUST be used. PAY CLOSE ATTENTION: you MUST browse the internet in these cases. If you're unsure or on the fence, you MUST bias towards browsing the internet.
- The information could have changed recently: for example news; prices; laws; schedules; product specs; sports scores; economic indicators; political/public/company figures (e.g. the question relates to 'the president of country A' or 'the CEO of company B', which might change over time); rules; regulations; standards; software libraries that could be updated; exchange rates; recommendations (i.e., recommendations about various topics or things might be informed by what currently exists / is popular / is safe / is unsafe / is in the zeitgeist / etc.); and many many many more categories -- again, if you're on the fence, you MUST browse the internet!
  - For news queries, prioritize more recent events, ensuring you compare publish dates and the date that the event happened.
- The user is seeking recommendations that could lead them to spend substantial time or money -- researching products, restaurants, travel plans, etc.
- The user wants (or would benefit from) direct quotes, links, or precise source attribution.
- A specific page, paper, dataset, PDF, or site is referenced and you haven't been given its contents.
- You're unsure about a fact, the topic is niche or emerging, or you suspect there's at least a 10% chance you will incorrectly recall it
- High-stakes accuracy matters (medical, legal, financial guidance). For these you generally should search by default because this information is highly temporally unstable
- The user explicitly says to search, browse, verify, or look it up.
</situations_where_you_must_browse_the_internet>

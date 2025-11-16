#!/usr/bin/env python3
import pathlib, datetime, re, markdown, json, shutil, html

ROOT = pathlib.Path(__file__).resolve().parent
POSTS = ROOT / "content" / "posts"
OUT = ROOT / "docs"

MD = markdown.Markdown(extensions=["extra", "sane_lists", "nl2br"])

def slugify(title):
    s = title.lower()
    s = re.sub(r"[^a-z0-9\s-]", "", s)
    s = re.sub(r"\s+", "-", s)
    s = re.sub(r"-+", "-", s)
    return s[:60].strip("-")

def extract_summary(html_body):
    text = re.sub("<[^<]+?>", "", html_body)
    text = " ".join(text.split())
    if len(text) <= 180:
        return text
    return text[:180].rsplit(" ", 1)[0] + "..."

def wrap(title, body, description="", image_url="", slug=""):
    year = datetime.date.today().year
    base = "https://oremm.github.io/Tech-Blog"
    canonical = f"{base}/{slug}.html" if slug else f"{base}/"

    desc = html.escape(description or "Practical tech tips")
    og_image = f'<meta property="og:image" content="{image_url}">' if image_url else ""
    tw_image = f'<meta name="twitter:image" content="{image_url}">' if image_url else ""

    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title} — Tech Blog</title>
<meta name="viewport" content="width=device-width, initial-scale=1">

<meta name="description" content="{desc}">
<link rel="canonical" href="{canonical}">
<link rel="alternate" type="application/rss+xml" title="RSS" href="rss.xml">

<!-- OpenGraph -->
<meta property="og:title" content="{title}">
<meta property="og:site_name" content="Tech Blog">
<meta property="og:type" content="article">
<meta property="og:url" content="{canonical}">
<meta property="og:description" content="{desc}">
{og_image}

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{title}">
<meta name="twitter:description" content="{desc}">
{tw_image}

<style>
:root {{
  --bg: #0b1220;
  --fg: #ffffff;
  --card: #111a2b;
  --accent: #87d0ff;
}}
[data-theme='light'] {{
  --bg: #f8f8f8;
  --fg: #111111;
  --card: #ffffff;
  --accent: #005bbb;
}}

* {{ box-sizing: border-box; }}
body {{
  margin: 0;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
  background: var(--bg);
  color: var(--fg);
}}
a {{ color: var(--accent); text-decoration:none; }}
a:hover {{ text-decoration:underline; }}

.wrap {{
  max-width: 860px;
  margin: 0 auto;
  padding: 18px 18px 32px;
}}

nav {{
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  gap: 12px;
}}
.nav-left a {{
  margin-right: 14px;
}}
.nav-left strong {{
  font-size: 1.1rem;
}}

button.theme {{
  background: transparent;
  border: 1px solid var(--accent);
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 0.9rem;
  color: var(--accent);
  cursor: pointer;
}}
button.theme:hover {{
  background: rgba(135, 208, 255, 0.1);
}}

.card {{
  background: var(--card);
  padding: 22px 22px 20px;
  border-radius: 18px;
  margin: 18px 0;
  box-shadow: 0 12px 30px rgba(0,0,0,0.35);
}}

h1 {{
  margin-top: 0;
  margin-bottom: 0.6rem;
  font-size: 1.7rem;
}}
h2 {{
  margin-top: 0;
  margin-bottom: 0.4rem;
  font-size: 1.3rem;
}}

.banner {{
  width: 100%;
  border-radius: 16px;
  margin: 10px 0 18px;
}}

footer.small {{
  opacity: 0.8;
}}

.post-meta {{
  font-size: 0.8rem;
  opacity: 0.85;
  margin-bottom: 0.4rem;
}}

.archive-list p {{
  margin: 0.3rem 0;
}}

.search-input {{
  width: 100%;
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid #444;
  background: transparent;
  color: var(--fg);
  outline: none;
  margin-bottom: 14px;
}}
</style>

<script>
function toggleTheme() {{
  const root = document.documentElement;
  const current = root.getAttribute("data-theme") || "dark";
  const next = current === "light" ? "dark" : "light";
  root.setAttribute("data-theme", next);
  localStorage.setItem("theme", next);
}}
document.addEventListener("DOMContentLoaded", () => {{
  const saved = localStorage.getItem("theme");
  if (saved) document.documentElement.setAttribute("data-theme", saved);
}});
</script>

</head>
<body>
<div class="wrap">

<nav>
  <div class="nav-left">
    <a href="index.html"><strong>Tech Blog</strong></a>
    <a href="latest.html">Latest</a>
    <a href="archive.html">Archive</a>
    <a href="search.html">Search</a>
  </div>
  <div class="nav-right">
    <button class="theme" onclick="toggleTheme()">Theme</button>
  </div>
</nav>

<div class="card">
{body}
</div>

<div class="card">
  <footer class="small">© {year} Tech Blog</footer>
</div>

</div>
</body>
</html>
"""

posts = []
for p in POSTS.glob("*.md"):
    raw = p.read_text().strip()
    lines = raw.split("\n")
    if not lines or not lines[0].startswith("# "):
        continue

    title = lines[0][2:].strip()
    slug = slugify(title)
    body_md = "\n".join(lines[1:])
    MD.reset()
    body_html = MD.convert(body_md)

    img_match = re.search(r"!\[.*?\]\((.*?)\)", raw)
    image_url = img_match.group(1) if img_match else ""

    date = datetime.datetime.fromtimestamp(p.stat().st_mtime)
    summary = extract_summary(body_html)

    posts.append({
        "title": title,
        "slug": slug,
        "body_html": body_html,
        "summary": summary,
        "image": image_url,
        "date": date,
    })

posts.sort(key=lambda x: x["date"], reverse=True)

shutil.rmtree(OUT, ignore_errors=True)
OUT.mkdir(parents=True, exist_ok=True)

for p in posts:
    banner = f'<img class="banner" src="{p["image"]}" alt="{html.escape(p["title"])}">' if p["image"] else ""
    date_str = p["date"].strftime("%Y-%m-%d")
    meta = f'<div class="post-meta">{date_str}</div>'
    body = f"<h1>{p['title']}</h1>{meta}{banner}\n{p['body_html']}"
    body = body.replace('<a href="', '<a target="_blank" rel="nofollow noopener" href="')
    (OUT / f"{p['slug']}.html").write_text(
        wrap(p["title"], body, p["summary"], p["image"], p["slug"])
    )

index_items = ""
for p in posts:
    index_items += (
        f'<div class="card">'
        f'<h2><a href="{p["slug"]}.html">{p["title"]}</a></h2>'
        f'<div class="post-meta">{p["date"].strftime("%Y-%m-%d")}</div>'
        f'<p>{p["summary"]}</p>'
        f'</div>'
    )

index_body = "<h1>Latest Posts</h1>" + index_items
(OUT / "index.html").write_text(
    wrap("Tech Blog", index_body, "Practical tech tips and guides")
)

archive_html = "<h1>Archive</h1><div class='archive-list'>"
for p in posts:
    archive_html += (
        f'<p>{p["date"].strftime("%Y-%m-%d")} — '
        f'<a href="{p["slug"]}.html">{p["title"]}</a></p>'
    )
archive_html += "</div>"

(OUT / "archive.html").write_text(
    wrap("Archive", archive_html, "Archive of all Tech Blog posts")
)

if posts:
    latest_slug = posts[0]["slug"]
    latest_html = f'<meta http-equiv="refresh" content="0; url={latest_slug}.html">'
    (OUT / "latest.html").write_text(
        wrap("Latest", latest_html, posts[0]["summary"], posts[0]["image"], latest_slug)
    )

search_index = [
    {
        "title": p["title"],
        "slug": p["slug"],
        "content": re.sub("<[^<]+?>", "", p["body_html"])
    }
    for p in posts
]
(OUT / "search.json").write_text(json.dumps(search_index))

search_page = """<h1>Search</h1>
<input id="q" class="search-input" placeholder="Type to search... (min 3 chars)">
<div id="results"></div>
<script>
let indexData = [];
fetch("search.json").then(r => r.json()).then(d => indexData = d);

const q = document.getElementById("q");
const resultsDiv = document.getElementById("results");

q.addEventListener("input", e => {
  const term = e.target.value.toLowerCase().trim();
  if (term.length < 3) {
    resultsDiv.innerHTML = "";
    return;
  }
  let out = "";
  indexData.forEach(p => {
    if (p.title.toLowerCase().includes(term) || p.content.toLowerCase().includes(term)) {
      out += `<div class='card'><h2><a href='${p.slug}.html'>${p.title}</a></h2></div>`;
    }
  });
  resultsDiv.innerHTML = out || "<p>No results.</p>";
});
</script>
"""
(OUT / "search.html").write_text(
    wrap("Search", search_page, "Search Tech Blog posts")
)

rss_items = "\n".join(
    f"<item><title>{p['title']}</title>"
    f"<link>https://oremm.github.io/Tech-Blog/{p['slug']}.html</link></item>"
    for p in posts[:20]
)
rss = f'''<?xml version="1.0"?>
<rss version="2.0">
<channel>
<title>Tech Blog</title>
<link>https://oremm.github.io/Tech-Blog/</link>
<description>Practical tech tips</description>
{rss_items}
</channel>
</rss>
'''
(OUT / "rss.xml").write_text(rss)

print(f"Built {len(posts)} posts (FULL UPGRADE ACTIVE)")

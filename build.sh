#!/usr/bin/env python3
import pathlib, datetime, re, markdown, json, shutil, html

# ----- PATHS -----
ROOT = pathlib.Path(__file__).resolve().parent
POSTS = ROOT / "content" / "posts"
OUT = ROOT / "docs"

# ----- MARKDOWN -----
MD = markdown.Markdown(extensions=["extra", "sane_lists", "nl2br"])

# ----- UTILITIES -----
def slugify(title):
    s = title.lower()
    s = re.sub(r"[^a-z0-9\s-]", "", s)
    s = re.sub(r"\s+", "-", s)
    s = re.sub(r"-+", "-", s)
    return s[:60].strip("-")

def extract_summary(html_body):
    text = re.sub("<[^<]+?>", "", html_body)
    return text[:180].rsplit(" ", 1)[0] + "..."

# ----- HTML TEMPLATE (UPGRADED UI + SEO) -----
def wrap(title, body, description="", image_url=""):
    year = datetime.date.today().year
    canonical = f"https://oremm.github.io/Tech-Blog/{slugify(title)}.html"

    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title} — Tech Blog</title>
<meta name="viewport" content="width=device-width, initial-scale=1">

<meta name="description" content="{html.escape(description)}">
<link rel="canonical" href="{canonical}">
<link rel="alternate" type="application/rss+xml" title="RSS" href="rss.xml">

<!-- OpenGraph -->
<meta property="og:title" content="{title}">
<meta property="og:site_name" content="Tech Blog">
<meta property="og:type" content="article">
<meta property="og:url" content="{canonical}">
<meta property="og:description" content="{html.escape(description)}">
{'<meta property="og:image" content="' + image_url + '">' if image_url else ''}

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{title}">
<meta name="twitter:description" content="{html.escape(description)}">
{'<meta name="twitter:image" content="' + image_url + '">' if image_url else ''}

<style>
body {{
  margin: 0;
  font-family: system-ui, Arial;
  background: var(--bg);
  color: var(--fg);
}}
:root {{
  --bg: #0b1220;
  --fg: #fff;
  --card: #111a2b;
  --accent: #87d0ff;
}}
[data-theme='light'] {{
  --bg: #f8f8f8;
  --fg: #111;
  --card: #ffffff;
  --accent: #005bbb;
}}
a {{ color: var(--accent); text-decoration:none }}
a:hover {{ text-decoration:underline }}
.wrap {{ max-width:860px; margin:0 auto; padding:26px }}
.card {{ background:var(--card); padding:24px; border-radius:16px; margin:20px 0 }}
nav {{
  display:flex; justify-content:space-between; align-items:center;
  margin-bottom:20px;
}}
button.theme {{
  background:none; border:1px solid var(--accent); padding:6px 12px;
  border-radius:8px; color:var(--accent); cursor:pointer;
}}
img.banner {{
  width:100%; border-radius:16px; margin-bottom:20px;
}}
</style>

<script>
function toggleTheme() {{
  const current = document.documentElement.getAttribute("data-theme");
  const next = current === "light" ? "dark" : "light";
  document.documentElement.setAttribute("data-theme", next);
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
  <div><a href="index.html"><strong>Tech Blog</strong></a></div>
  <button class="theme" onclick="toggleTheme()">Theme</button>
</nav>

<div class="card">
{body}
</div>

<footer class="card">
  © {year} Tech Blog
</footer>

</div>
</body>
</html>
"""

# ----- PROCESS POSTS -----
posts = []

for p in POSTS.glob("*.md"):
    raw = p.read_text()
    lines = raw.split("\n")
    title = lines[0].replace("#", "").strip()
    slug = slugify(title)
    body_html = MD.convert("\n".join(lines[1:]))

    # Extract first image (featured banner)
    img_match = re.search(r"!\[.*?\]\((.*?)\)", raw)
    image_url = img_match.group(1) if img_match else ""

    summary = extract_summary(body_html)

    posts.append({
        "title": title,
        "slug": slug,
        "body_html": body_html,
        "summary": summary,
        "image": image_url,
        "date": datetime.datetime.fromtimestamp(p.stat().st_mtime),
        "src": p
    })

posts.sort(key=lambda x: x["date"], reverse=True)

# ----- BUILD OUTPUT -----
shutil.rmtree(OUT, ignore_errors=True)
OUT.mkdir()

# ----- INDIVIDUAL POSTS -----
for p in posts:
    banner = f'<img class="banner" src="{p["image"]}">' if p["image"] else ""
    body = f"<h1>{p['title']}</h1>{banner}\n{p['body_html']}"
    body = body.replace('<a href="', '<a target="_blank" rel="nofollow noopener" href="')
    (OUT / f"{p['slug']}.html").write_text(
        wrap(p["title"], body, p["summary"], p["image"])
    )

# ----- HOMEPAGE -----
index_items = "\n".join(
    f'<div class="card"><h2><a href="{p["slug"]}.html">{p["title"]}</a></h2>'
    f'<p>{p["summary"]}</p></div>' for p in posts
)
(OUT / "index.html").write_text(
    wrap("Tech Blog", "<h1>Latest Posts</h1>" + index_items)
)

# ----- ARCHIVE -----
archive_list = "\n".join(
    f'<p><a href="{p["slug"]}.html">{p["title"]}</a></p>' for p in posts
)
(OUT / "archive.html").write_text(
    wrap("Archive", "<h1>Archive</h1>" + archive_list)
)

# ----- LATEST REDIRECT -----
latest_slug = posts[0]["slug"]
(OUT / "latest.html").write_text(
    f'<meta http-equiv="refresh" content="0; url={latest_slug}.html">'
)

# ----- SEARCH INDEX -----
search_index = [
    {"title": p["title"], "slug": p["slug"], "content": re.sub("<[^<]+?>", "", p["body_html"])}
    for p in posts
]
(OUT / "search.json").write_text(json.dumps(search_index))

# ----- RSS FEED -----
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

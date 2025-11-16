#!/usr/bin/env python3
import pathlib, datetime, re, markdown, shutil

ROOT = pathlib.Path(__file__).resolve().parent
POSTS = ROOT / "content" / "posts"
OUT = ROOT / "docs"

MD = markdown.Markdown(extensions=["extra", "sane_lists", "nl2br"])

def wrap(title, body):
    year = datetime.date.today().year
    return f'''<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} — Tech-Blog</title>
<link rel="alternate" type="application/rss+xml" title="RSS" href="rss.xml">
<style>
:root{{--bg:#0b1220;--card:#111a2b;--fg:#fff;--link:#87d0ff}}
html,body{{margin:0;background:var(--bg);color:var(--fg);font-family:system-ui,Arial}}
.wrap{{max-width:860px;margin:0 auto;padding:28px}}
a{{color:var(--link);text-decoration:none}} a:hover{{text-decoration:underline}}
.card{{background:var(--card);border-radius:16px;padding:24px;margin:16px 0;line-height:1.6}}
h1,h2{{margin:0 0 .6rem}}
.nav{{display:flex;gap:16px;align-items:center;margin-bottom:8px}}
footer small{{opacity:.85}}
</style>
</head><body><div class="wrap">
  <div class="nav"><a href="index.html"><strong>Tech-Blog</strong></a> <a href="rss.xml">RSS</a></div>
  <div class="card">{body}</div>
  <footer class="card"><small>© {year} Tech-Blog</small></footer>
</div></body></html>'''

def md_to_html(text):
    MD.reset()
    return MD.convert(text)

posts = []
for p in POSTS.glob("*.md"):
    raw = p.read_text()
    title = p.stem.replace("-", " ").title()
    lines = raw.strip().split("\n")
    if lines and lines[0].startswith("# "):
        title = lines[0][2:].strip()
        body = "\n".join(lines[1:])
    else:
        body = raw
    posts.append({
        "title": title,
        "slug": p.stem,
        "body_html": md_to_html(body),
        "date": datetime.datetime.fromtimestamp(p.stat().st_mtime)
    })

# newest first
posts.sort(key=lambda x: x["date"], reverse=True)

# keep only one post per title (latest)
unique = []
seen = set()
for p in posts:
    key = p["title"].lower()
    if key not in seen:
        seen.add(key)
        unique.append(p)

# clean output dir
shutil.rmtree(OUT, ignore_errors=True)
OUT.mkdir(parents=True, exist_ok=True)

# write posts
for p in unique:
    body = f"<h1>{p['title']}</h1>\n{p['body_html']}"
    # make all links open in new tab, nofollow (for Amazon etc)
    body = re.sub(
        r'<a href="',
        '<a target="_blank" rel="nofollow noopener" href="',
        body
    )
    (OUT / f"{p['slug']}.html").write_text(wrap(p['title'], body))

# index page
items = [f'<p><a href="{p["slug"]}.html">{p["title"]}</a></p>' for p in unique]
(OUT / "index.html").write_text(
    wrap("Tech-Blog", "<h1>Tech-Blog</h1>\n" + "\n".join(items))
)

# RSS
rss_items = "\n".join(
    f'<item><title>{p["title"]}</title>'
    f'<link>https://oremm.github.io/Tech-Blog/{p["slug"]}.html</link></item>'
    for p in unique[:10]
)
rss = f'''<?xml version="1.0"?><rss version="2.0"><channel>
<title>Tech-Blog</title><link>https://oremm.github.io/Tech-Blog/</link>
<description>Practical tech tips</description>{rss_items}</channel></rss>'''
(OUT / "rss.xml").write_text(rss)

print(f"Built {len(unique)} unique posts")

---
layout: default
title: "Tech-Blog"
---

<h1>Tech-Blog</h1>
<p>Latest posts:</p>

<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a><br>
      <small>{{ post.date | date: "%Y-%m-%d" }}</small>
    </li>
  {% endfor %}
</ul>

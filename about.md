---
layout: page
title: About
eyebrow: Hello
description: Who writes this blog, what it covers and how to get in touch.
permalink: /about/
---
{%- comment -%} Edit this page freely — it's plain Markdown. {%- endcomment -%}
{% assign about_author = site.data.authors[site.author] %}
{% include author-card.html author=about_author eyebrow="About the author" %}

## Why this blog

Data and AI platforms are mostly made of decisions: where data lands, how it is
modelled, what guarantees each layer gives, and how models get the context they
need. This blog documents those decisions — with an architecture diagram for
almost every idea — so they can be reused, challenged and improved.

## What you'll find here

- **Data Architecture** — lakehouse and warehouse design, data modelling, data mesh, governance.
- **Data Engineering** — batch and streaming pipelines, orchestration, data quality, performance.
- **AI Engineering** — LLM applications, retrieval-augmented generation, agents, evaluation and MLOps.

## Get in touch

The best way to reach me is through the links above. If you spot a mistake in
an article, I'd genuinely like to hear about it.

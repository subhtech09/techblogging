---
title: "Designing a Lakehouse with the Medallion Architecture"
description: "How to structure raw, refined and curated layers so a lakehouse stays trustworthy, debuggable and cheap to evolve."
category: data-architecture
tags: [lakehouse, medallion, data-modeling]
image: /assets/images/posts/medallion-architecture/medallion-architecture.jpg
featured: true
---

A lakehouse without structure turns into a swamp surprisingly quickly. The
medallion architecture is a simple layering convention — bronze, silver, gold —
that gives every table a clear contract and every engineer a shared vocabulary.

## Why layer a lakehouse at all?

Most data problems are really *trust* problems. When a dashboard number looks
wrong, the team needs to answer three questions quickly: what did the source
actually send, what did we do to it, and which business rule produced the
final figure? Layering separates those concerns so each one can be inspected
on its own.

{% include figure.html src="medallion-architecture.jpg" alt="Operational databases, SaaS APIs and event streams flow into bronze, then silver, then gold layers inside the lakehouse, which serve BI dashboards, ML feature stores and LLM applications" caption="**Figure 1.** Data moves through progressively refined layers before it is served to consumers." %}

## The three layers

### Bronze — raw and append-only

Bronze is a faithful, replayable copy of what the source sent, plus ingestion
metadata such as load time, source file and batch id. Resist the urge to clean
anything here: if a transformation bug is found next quarter, bronze is what
lets you rebuild everything downstream.

### Silver — cleaned and conformed

Silver is where data becomes *usable*: types are enforced, duplicates removed,
late-arriving records merged and entities conformed to shared keys. Silver
tables are modelled around business entities (customers, orders, devices), not
around source systems.

### Gold — business-ready

Gold tables answer specific questions: aggregates, dimensional marts, feature
tables and governed metrics. They are small, documented and owned by a team
that can explain every column.

| Layer  | Purpose                  | Typical operations                      | Main consumers           |
|--------|--------------------------|-----------------------------------------|--------------------------|
| Bronze | Source fidelity, replay  | Append, schema-on-read, audit columns   | Data engineers           |
| Silver | Clean, conformed entities| Dedupe, type, merge/upsert, join keys   | Engineers, analysts, ML  |
| Gold   | Business answers         | Aggregate, model, apply business rules  | BI, applications, AI     |

> Keep bronze retention long and cheap (object storage is inexpensive), but
> keep gold small and well-documented. Most cost and confusion comes from
> sprawling, undocumented gold tables.
{: .tip }

## A gold table, end to end

Gold transformations should be boring, declarative SQL over silver:

```sql
CREATE OR REPLACE TABLE gold.daily_revenue AS
SELECT
  order_date,
  region,
  SUM(net_amount)              AS revenue,
  COUNT(DISTINCT customer_id)  AS customers
FROM silver.orders
WHERE status = 'COMPLETED'
GROUP BY order_date, region;
```

If a gold query needs to reach back into bronze, that is a signal that a
silver table is missing.

> Never point BI tools at bronze. Raw data changes shape without warning, and
> dashboards built on it become the first thing to break.
{: .warning }

## Common anti-patterns

- **Source-shaped silver.** Copying each source table into silver one-to-one
  just moves the mess one layer down.
- **Business logic in bronze.** Filtering or "fixing" records on ingestion
  destroys your ability to replay.
- **Gold for everything.** Not every query deserves a persisted table; views
  over silver are often enough.
- **Non-idempotent loads.** Re-running a job should never duplicate data — see
  [Idempotent Data Pipelines]({{ site.baseurl }}{% post_url 2026-09-28-idempotent-pipelines %}).

## Wrapping up

The medallion architecture is less about the names of the layers and more
about the guarantees each layer gives. Write those guarantees down, enforce
them with tests, and the lakehouse stays explainable as it grows.

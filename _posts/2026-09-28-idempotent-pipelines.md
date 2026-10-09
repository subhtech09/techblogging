---
title: "Idempotent Data Pipelines: Making Re-runs Boring"
description: "Retries and backfills are inevitable. Design pipelines so that running them twice gives exactly the same result as running them once."
category: data-engineering
tags: [pipelines, idempotency, orchestration, spark]
image: /assets/images/posts/idempotent-pipelines/idempotent-pipeline.jpg
---

Every pipeline will be re-run: a node dies, an upstream file arrives late, a
bug fix needs a backfill. An **idempotent** pipeline produces the same output
no matter how many times a run is repeated — which turns those incidents from
data-quality emergencies into non-events.

## What idempotency means for data

A task is idempotent when `run(x)` followed by `run(x)` leaves the target in
exactly the same state as a single `run(x)`. For data pipelines that implies:

1. **No duplicates** when a run is retried.
2. **No gaps** when a run is skipped and later backfilled.
3. **Deterministic output** for a given input and run parameter.

{% include figure.html src="idempotent-pipeline.jpg" alt="An orchestrator triggers a pipeline of source, landing zone, deterministic transform and keyed write into a target table; a re-run loop feeds back with identical output" caption="**Figure 2.** Every stage is parameterised by the logical run date, so retries and backfills converge on the same result." %}

## Pattern 1 — replace a whole partition

When each run owns a well-defined slice of data (usually a date), overwrite
that slice atomically instead of appending to it:

```python
(
    daily_events
    .write
    .format("delta")
    .mode("overwrite")
    .option("replaceWhere", f"event_date = '{run_date}'")
    .saveAsTable("silver.events")
)
```

Running this twice for the same `run_date` replaces the partition twice —
the end state is identical.

## Pattern 2 — merge on a natural key

For entity tables that receive updates, upsert on a business key and only
apply a change if it is newer than what is already stored:

```sql
MERGE INTO silver.customers AS t
USING staged_customers AS s
  ON t.customer_id = s.customer_id
WHEN MATCHED AND s.updated_at > t.updated_at THEN
  UPDATE SET *
WHEN NOT MATCHED THEN
  INSERT *;
```

> `UPDATE SET *` / `INSERT *` is Delta Lake syntax. Other engines need explicit
> column lists, but the pattern is identical.
{: .note }

## Pattern 3 — derive time from the run, not the clock

`current_date()` inside a transformation makes the output depend on *when* the
job ran. Pass the logical run date from the orchestrator instead, and use it
everywhere: in filters, partition values and output paths.

| Pattern               | Use when                               | Watch out for                          |
|-----------------------|----------------------------------------|----------------------------------------|
| Partition overwrite   | Each run owns a time slice             | Late data landing in older partitions  |
| Merge on key          | Entities are updated over time         | Missing or unstable business keys      |
| Run-date parameter    | Always                                 | Hidden `now()` calls in UDFs and views |

## Wrapping up

Idempotency is cheap to design in and expensive to retrofit. Pick a write
pattern per table, parameterise everything by the logical run date, and
retries become the most boring part of your on-call rotation.

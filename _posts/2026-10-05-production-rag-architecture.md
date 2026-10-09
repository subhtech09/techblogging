---
title: "Anatomy of a Production RAG System"
description: "Retrieval-augmented generation is easy to demo and hard to run. A walkthrough of the offline indexing path, the online query path and the evaluation loop that ties them together."
category: ai-engineering
tags: [rag, llm, vector-search, evaluation]
image: /assets/images/posts/production-rag-architecture/rag-architecture.jpg
---

A retrieval-augmented generation (RAG) prototype fits in fifty lines of code.
A production RAG system is a data platform with an LLM at the end of it — and
most of its failures are data failures, not model failures.

## Two paths, one index

Every RAG system has two halves that run on very different schedules:

- **Offline indexing** turns source documents into searchable chunks. It is a
  batch or streaming data pipeline and should be engineered like one.
- **Online querying** turns a user question into a grounded answer within a
  latency budget, typically a few seconds end to end.

{% include figure.html src="rag-architecture.jpg" alt="Offline path: sources, parse and clean, chunk, embed, then vector and keyword index. Online path: user question, query embedding and rewrite, hybrid retrieval, rerank, prompt plus LLM, answer with citations. An evaluation and guardrails layer spans both" caption="**Figure 3.** The offline indexing path and the online query path meet at the index. Evaluation spans both." %}

## The offline path

### Parse and clean

PDFs, wikis and tickets all need different parsers. Strip navigation chrome,
keep headings and tables, and record where every piece of text came from — you
will need that provenance for citations.

### Chunk with structure

Fixed-size chunks are a fine baseline, but chunking along document structure
(sections, list items, table rows) usually retrieves better. Store metadata
such as title, section path, timestamp and access-control labels with every
chunk.

### Embed and index

Index each chunk twice: as a dense vector for semantic similarity, and as text
for keyword search. Hybrid retrieval rescues the queries that embeddings
handle poorly — product codes, error messages and acronyms.

## The online path

```python
def answer(question: str) -> Answer:
    query = rewrite(question)                       # expand acronyms, fix typos
    candidates = index.hybrid_search(
        query, top_k=40, filters=user_acl_filter()  # never retrieve what the user can't see
    )
    passages = reranker.rerank(question, candidates)[:6]
    prompt = build_prompt(question, passages)
    response = llm.generate(prompt, temperature=0)
    return Answer(text=response.text, citations=[p.source for p in passages])
```

> Apply access-control filters at **retrieval** time. Filtering the final
> answer is too late — the model has already seen the restricted text.
{: .warning }

## Evaluate retrieval and generation separately

When an answer is wrong, you need to know whether the right passage was never
retrieved or was retrieved and then ignored.

| Failure mode          | Symptom                                   | Typical fix                              |
|-----------------------|-------------------------------------------|------------------------------------------|
| Retrieval miss        | Correct passage not in the top *k*        | Better chunking, hybrid search, rewrite  |
| Ranking miss          | Passage retrieved but ranked too low      | Add or tune a reranker                   |
| Grounding failure     | Answer contradicts the retrieved passages | Stricter prompt, citations, lower temp.  |
| Stale knowledge       | Answer reflects an outdated document      | Incremental re-indexing, freshness score |

> Build a small "golden set" of 50–100 real questions with known source
> passages before tuning anything. Without it, every change is a guess.
{: .tip }

## Wrapping up

Treat the index as a data product with owners, freshness SLAs and quality
checks, and treat the LLM as one component of a pipeline you can measure. Do
that, and RAG stops being a demo and starts being a system.

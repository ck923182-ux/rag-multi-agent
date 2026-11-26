# RAG Multi-Agent — Complete Database Flow
### All Tables · Real Examples · Current State
> This document reflects every table currently in the database.
> Use it to understand, explain, or demo the system to anyone.

---

## What Are We Building?

An **AI-powered Customer Support System** for e-commerce companies.

A company (like ShopEasy) plugs into this platform. Their customers ask questions:
- *"What is your return policy?"*
- *"Where is my order ORD-2026-0001?"*
- *"Is the ProBook Laptop in stock?"*

An AI Agent reads from the company's own data — orders, products, policies — and replies
intelligently. Every action the AI takes is tracked and searchable.

---

## The Big Picture — Multi-Tenancy

```
┌──────────────────────────────────────────────────────────────────┐
│                        ONE PLATFORM                              │
│                                                                  │
│   ShopEasy India                    TechMart                     │
│   ├── customers                     ├── customers                │
│   ├── products + inventory          ├── products + inventory     │
│   ├── orders                        ├── orders                   │
│   ├── knowledge base                ├── knowledge base           │
│   └── AI agents                     └── AI agents               │
│                                                                  │
│        ← 100% isolated from each other →                        │
└──────────────────────────────────────────────────────────────────┘
```

One system. Multiple companies. Each company sees only their own data.
This is called **Multi-Tenancy** — every table has a `tenant_id`.

---

## All 13 Tables — At a Glance

```
BUSINESS LAYER
─────────────────────────────────────────────────────
tenants             → companies using the platform
  └── customers     → their shoppers
  └── products      → their catalog
        └── inventory → stock levels per product
  └── orders        → purchase records
        └── order_items → line items per order

KNOWLEDGE BASE LAYER
─────────────────────────────────────────────────────
  └── kb_documents          → uploaded policy/FAQ docs
        └── kb_document_versions → version history
              └── kb_chunks      → AI-searchable text pieces

AI AGENT LAYER
─────────────────────────────────────────────────────
  └── agents           → AI agent definitions
        └── agent_configs  → versioned config per agent
        └── agent_runs     → every execution logged

SEARCH LAYER
─────────────────────────────────────────────────────
  └── search_runs     → every search query logged
        └── search_results → ranked results per search
```

---

## Step-by-Step Flow with Real Examples

---

### STEP 1 — Register a Company
**Table:** `tenants`

Before anything else, a company registers on the platform.
Every other record in every other table will be linked to this company via `tenant_id`.

**Example:**
```
id       →  a1b2c3-uuid  (auto-generated)
name     →  ShopEasy India
slug     →  shopeasy-india  (used in URLs/API)
status   →  active
```

**Why it matters:**
If ShopEasy is deleted, everything below — customers, orders, agents, knowledge base —
is automatically deleted too. Full data isolation between companies is guaranteed.

---

### STEP 2 — Add a Customer
**Table:** `customers`

A person who shops at ShopEasy is registered as a customer.

**Example:**
```
id         →  c1d2e3-uuid
tenant_id  →  a1b2c3-uuid  (belongs to ShopEasy)
first_name →  Priya
last_name  →  Sharma
email      →  priya.sharma@example.com
phone      →  +91-9876543210
status     →  active
```

**Why it matters:**
When Priya contacts support, the AI knows who she is, which company she belongs to,
and can look up her orders instantly.

---

### STEP 3 — Add Products
**Table:** `products`

ShopEasy lists the items they sell.

**Example:**
```
Product 1
  sku    →  LAPTOP-001
  name   →  ProBook Laptop 15"
  price  →  ₹65,000
  status →  active

Product 2
  sku    →  MOUSE-002
  name   →  Wireless Mouse
  price  →  ₹1,200
  status →  active
```

**Why it matters:**
All products are tenant-scoped. TechMart cannot see ShopEasy's catalog.
The AI can answer *"What products do you sell?"* directly from this table.

---

### STEP 4 — Set Inventory
**Table:** `inventory`

For every product, track how many units are physically available.

**Example:**
```
ProBook Laptop
  quantity          →  50 units
  reserved_quantity →  5 units   (ordered but not yet shipped)
  available         →  45 units  (50 - 5)

Wireless Mouse
  quantity          →  200 units
  reserved_quantity →  10 units
  available         →  190 units
```

**Reserved — what does it mean?**
When a customer places an order, units are "reserved" immediately.
They're counted in total stock but cannot be sold to anyone else.
The database enforces: `reserved_quantity` can never exceed `quantity`.

**Why it matters:**
The AI can accurately answer *"Is the laptop available?"* without overselling.

---

### STEP 5 — Place an Order
**Table:** `orders`

Priya decides to buy. An order is created.

**Example:**
```
id           →  o1p2q3-uuid
tenant_id    →  a1b2c3-uuid  (ShopEasy)
customer_id  →  c1d2e3-uuid  (Priya)
order_number →  ORD-2026-0001
status       →  confirmed
total_amount →  ₹66,200
currency     →  INR
```

**Order Status Journey:**
```
pending → confirmed → shipped → delivered
                   ↘ cancelled
```

**Why it matters:**
The AI can answer *"Where is my order ORD-2026-0001?"* — status comes from here.

---

### STEP 6 — Add Order Items
**Table:** `order_items`

The order says ₹66,200 — but what exactly did Priya buy?

**Example:**
```
Item 1
  order_id    →  o1p2q3-uuid  (ORD-2026-0001)
  product_id  →  ProBook Laptop
  quantity    →  1
  unit_price  →  ₹65,000

Item 2
  order_id    →  o1p2q3-uuid
  product_id  →  Wireless Mouse
  quantity    →  1
  unit_price  →  ₹1,200

─────────────────────
  TOTAL       →  ₹66,200
```

**Why unit_price is stored separately:**
If ShopEasy changes the laptop price to ₹70,000 next month,
this order still correctly shows ₹65,000 — the price at time of purchase.

---

### STEP 7 — Upload a Knowledge Base Document
**Table:** `kb_documents`

ShopEasy uploads their policies, FAQs, and guides.
The AI will read from here to answer customer questions.

**Example:**
```
id           →  d1e2f3-uuid
tenant_id    →  a1b2c3-uuid  (ShopEasy)
title        →  Laptop Return & Warranty Policy
source_type  →  manual
source_url   →  https://shopeasy.in/policies/laptop-warranty
status       →  active
content_hash →  abc123hash  (fingerprint of content)
```

**content_hash — why?**
A unique fingerprint of the document text.
If the same document is uploaded again, the system detects it via hash and skips reprocessing.
Saves time and compute.

---

### STEP 8 — Create a Document Version
**Table:** `kb_document_versions`

Every time a document is processed or updated, a new version is created.
The old version stays safe until the new one is fully ready.

**Example:**
```
Version 1
  document_id    →  d1e2f3-uuid
  version_number →  1
  content_hash   →  abc123hash
  status         →  active  ✓  ← AI uses this right now

(6 months later, policy is updated)

Version 2
  version_number →  2
  content_hash   →  xyz789hash
  status         →  active  ✓  ← AI now uses this
Version 1 status →  archived   ← kept for rollback
```

**`current_version_id` on the document** always points to the latest active version.

**Why it matters:**
Zero downtime updates. The AI never reads a half-processed document.
If Version 2 processing fails, we simply roll back to Version 1 instantly.

---

### STEP 9 — Store KB Chunks
**Table:** `kb_chunks`

The full document text is split into small pieces called **chunks**.
Each chunk = one idea or paragraph. Small enough for the AI to use precisely.

**Example — "Laptop Return & Warranty Policy" split:**
```
Chunk 0
  content  →  "All laptops purchased from ShopEasy come with a
               1-year manufacturer warranty."
  tokens   →  18

Chunk 1
  content  →  "To initiate a return, the product must be unused
               and in original packaging within 7 days."
  tokens   →  20

Chunk 2
  content  →  "For warranty claims, contact support@shopeasy.in
               with your order number and issue description."
  tokens   →  19
```

**Why chunks and not the full document?**
```
Customer asks: "Can I return my laptop?"
      ↓
AI searches all chunks
      ↓
Finds Chunk 1 (most relevant)
      ↓
AI replies: "Yes, returns are allowed within 7 days
             in original packaging."
```
Faster. Cheaper. More accurate. The AI doesn't waste time reading irrelevant pages.

Each chunk belongs to a **version** — when the document is updated,
new chunks are created for Version 2. Old chunks stay with Version 1.

---

### STEP 10 — Define an AI Agent
**Table:** `agents`

An Agent is a specialized AI worker. Each agent has one job.
ShopEasy can have multiple agents — one for orders, one for FAQs, one for product queries.

**Example:**
```
Agent 1
  tenant_id   →  a1b2c3-uuid  (ShopEasy)
  name        →  FAQ Agent
  slug        →  faq-agent
  agent_type  →  rag_qa
  description →  Answers questions using ShopEasy's knowledge base
  status      →  active

Agent 2
  name        →  Order Agent
  slug        →  order-agent
  agent_type  →  order_lookup
  description →  Looks up order status and history for customers
  status      →  active
```

**Why agent_type matters:**
Different types of agents use different logic.
`rag_qa` → searches knowledge base chunks.
`order_lookup` → queries orders and order_items tables directly.

---

### STEP 11 — Configure the Agent
**Table:** `agent_configs`

Each agent has a versioned configuration — which model to use, temperature, max tokens, etc.
Stored as JSONB so it can hold any structure.

**Example:**
```
Config Version 1  (for FAQ Agent)
  agent_id       →  faq-agent-uuid
  config_version →  1
  is_active      →  true
  config         →  {
                      "model": "gpt-4o",
                      "temperature": 0.2,
                      "max_tokens": 500,
                      "system_prompt": "You are a helpful ShopEasy support agent...",
                      "top_k_chunks": 3
                    }
```

**Why versioned configs?**
If you change the model from `gpt-4o` to `claude-3-5-sonnet`, Config Version 2 is created.
Old runs still reference their original config — full audit trail.
You can also A/B test two configs and compare performance.

---

### STEP 12 — Run the Agent
**Table:** `agent_runs`

Every time an agent runs (processes one customer query), a record is saved.
Full input, output, timing, and status — all stored.

**Example:**
```
Run 1  (FAQ Agent answers Priya)
  agent_id     →  faq-agent-uuid
  config_id    →  config-v1-uuid
  status       →  completed
  input        →  {
                    "customer_id": "c1d2e3-uuid",
                    "query": "Can I return my laptop?"
                  }
  output       →  {
                    "answer": "Yes, returns allowed within 7 days
                               in original packaging.",
                    "chunks_used": ["chunk-1-uuid"],
                    "confidence": 0.94
                  }
  started_at   →  2026-10-14 10:00:00
  completed_at →  2026-10-14 10:00:02
  error_message → null
```

**Agent Run Status Journey:**
```
pending → running → completed
                 ↘ failed     (error_message populated)
                 ↘ cancelled
```

**Why it matters:**
Every agent action is logged. You can debug failures, measure response times,
audit what the AI said to which customer, and track performance over time.

---

### STEP 13 — Log the Search
**Table:** `search_runs`

When the FAQ Agent searches for relevant chunks, that search is logged here.
A search_run links back to: which tenant, which agent, which agent_run triggered it.

**Example:**
```
Search Run 1
  tenant_id    →  a1b2c3-uuid  (ShopEasy)
  agent_id     →  faq-agent-uuid
  agent_run_id →  run-1-uuid  (the run that triggered this search)
  search_type  →  semantic_similarity
  query_text   →  "Can I return my laptop?"
  status       →  completed
  input        →  { "top_k": 3, "threshold": 0.7 }
  metadata     →  { "model": "text-embedding-3-small", "dimensions": 1536 }
  started_at   →  2026-10-14 10:00:00.100
  completed_at →  2026-10-14 10:00:00.340
```

**`search_type` examples:**
```
semantic_similarity  →  vector/embedding search on kb_chunks
keyword              →  full-text SQL search
hybrid               →  combination of both
```

**Why it matters:**
Every search query is tracked — you can see what customers are asking most,
which queries are slow, which ones return poor results.

---

### STEP 14 — Store Search Results
**Table:** `search_results`

The ranked list of results returned by that search — stored per search_run.

**Example:**
```
Result 1  (best match)
  search_run_id  →  search-run-1-uuid
  result_type    →  kb_chunk
  source_ref     →  chunk-1-uuid  (the chunk that matched)
  rank           →  1             (most relevant)
  score          →  0.94          (similarity score)
  metadata       →  { "chunk_index": 1, "document": "Return Policy" }

Result 2
  result_type    →  kb_chunk
  source_ref     →  chunk-0-uuid
  rank           →  2
  score          →  0.81

Result 3
  result_type    →  kb_chunk
  source_ref     →  chunk-2-uuid
  rank           →  3
  score          →  0.73
```

**Why it matters:**
You can see exactly which chunks the AI used to form its answer.
If the AI gave a wrong answer, you can trace back: wrong chunk ranked #1?
Improve the embeddings or the chunking strategy.

---

## Complete Relationship Map (All 13 Tables)

```
tenants  (ShopEasy India)
│
├──► customers  (Priya Sharma)
│         └──► orders  (ORD-2026-0001 · ₹66,200 · confirmed)
│                   └──► order_items
│                             ├── 1× ProBook Laptop  ₹65,000
│                             └── 1× Wireless Mouse  ₹1,200
│
├──► products  (Laptop · Mouse)
│         └──► inventory  (50 units · 5 reserved)
│
├──► kb_documents  (Laptop Return & Warranty Policy)
│         └──► kb_document_versions  (v1 · active ✓)
│                   └──► kb_chunks
│                             ├── Chunk 0: warranty info
│                             ├── Chunk 1: return policy
│                             └── Chunk 2: contact for claims
│
└──► agents  (FAQ Agent · Order Agent)
          ├──► agent_configs  (v1: gpt-4o, temp=0.2)
          └──► agent_runs  (Run #1 · completed · 2s)
                    └──► search_runs  (query: "Can I return my laptop?")
                               └──► search_results
                                         ├── Rank 1: Chunk 1 · score 0.94
                                         ├── Rank 2: Chunk 0 · score 0.81
                                         └── Rank 3: Chunk 2 · score 0.73
```

---

## End-to-End Flow — One Customer Query

```
Priya types: "Can I return my laptop?"
                        │
                   Orchestrator
                (routes to FAQ Agent)
                        │
              ┌─────────▼──────────┐
              │    agent_runs      │  ← run created, status: running
              │    (Run #1)        │
              └─────────┬──────────┘
                        │
              ┌─────────▼──────────┐
              │    search_runs     │  ← search logged
              │  "Can I return?"   │
              └─────────┬──────────┘
                        │
              ┌─────────▼──────────┐
              │   search_results   │  ← top 3 chunks ranked
              │  Chunk 1 (0.94) ✓  │
              └─────────┬──────────┘
                        │
                    LLM reads
                    Chunk 1 text
                        │
                        ▼
              "Yes, returns allowed within
               7 days in original packaging."
                        │
              ┌─────────▼──────────┐
              │    agent_runs      │  ← output saved, status: completed
              │    (Run #1)        │
              └────────────────────┘
```

---

## Current Database Status

| # | Table | Layer | Status |
|---|---|---|---|
| 1 | `tenants` | Business | ✅ Done |
| 2 | `customers` | Business | ✅ Done |
| 3 | `products` | Business | ✅ Done |
| 4 | `inventory` | Business | ✅ Done |
| 5 | `orders` | Business | ✅ Done |
| 6 | `order_items` | Business | ✅ Done |
| 7 | `kb_documents` | Knowledge Base | ✅ Done |
| 8 | `kb_document_versions` | Knowledge Base | ✅ Done |
| 9 | `kb_chunks` | Knowledge Base | ✅ Done |
| 10 | `agents` | AI Agent | ✅ Done |
| 11 | `agent_configs` | AI Agent | ✅ Done |
| 12 | `agent_runs` | AI Agent | ✅ Done |
| 13 | `search_runs` | Search | ✅ Done |
| 14 | `search_results` | Search | ✅ Done |

**All 14 tables complete. Database layer is production-ready.**

---

## What Comes Next (Upcoming Phases)

The database is the foundation. These phases build on top of it:

| Phase | What | Uses These Tables |
|---|---|---|
| Next | LLM Integration | `agent_runs`, `agent_configs` |
| Next | Embedding Pipeline | `kb_chunks` (add vector column) |
| Next | Vector Search | `search_runs`, `search_results` |
| Next | Knowledge Ingestion API | `kb_documents`, `kb_document_versions`, `kb_chunks` |
| Next | Orchestrator | `agents`, `agent_runs` |
| Next | REST / MCP API | All tables |
| Next | Analytics Dashboard | `agent_runs`, `search_runs`, `search_results` |

Each phase is independent and can be built one by one.
The schema is already designed to support all of them.

# ResQBox Stress / Load Testing — Short Summary

**Date:** 07 July 2026 (source report)  
**Scope:** Backend API, Socket.IO, checkout, admin portal  
**Method:** Architecture review + projected load scenarios  
**Live load test:** Not run (no staging environment)

---

## Summary

ResQBox is a **single Node.js API** with PostgreSQL, in-memory sockets, and in-memory order timers. It is unlikely to hold up under flash-sale or multi-instance load. The highest risk is **inventory overselling** when many users buy the same box at once.

---

## Projected load results

| ID | Scenario | Load | Projected result |
|----|----------|------|------------------|
| LT-001 | Concurrent browse (`homePage`, `getMenu`) | 500 users | Likely fail around 200+ (no cache, one process) |
| LT-002 | Concurrent checkout of the same item (qty 10) | 50 users | **Will fail** — more than 10 orders can succeed |
| LT-003 | Vendors accepting orders at once | 10 vendors | Likely pass (Stripe handles payment concurrency) |
| LT-004 | Stripe webhook burst | 100 events / 10s | Unknown — idempotency not fully proven |
| LT-005 | Socket connections | 1000 clients | Likely fail around 500+ (no Redis adapter) |
| LT-006 | Admin portal concurrent use | 20 admins | Likely pass; 200 req/min API limit may throttle |
| LT-007 | Sustained load | 100 users / 30 min | Unknown — in-memory timers may leak / degrade |

---

## Main constraints

| ID | Issue | Why it matters |
|----|--------|----------------|
| SC-001 | Single Node process | HTTP, WebSockets, and cron all share one process |
| SC-002 | In-memory order timers | Lost on restart; no durable job queue |
| SC-003 | Untuned DB pool | Prisma pool can exhaust at 100+ concurrent users |
| SC-004 | Non-atomic inventory | Race conditions on popular / flash-sale items |
| SC-005 | Single-region database | Latency risk for AU/SG (and later India) |
| SC-006 | No API response cache | Every browse hit goes to the database |
| SC-008 | No containers / autoscaling | Cannot add instances for traffic spikes |

Rate limit today: **200 requests/minute** on `/api` (global, not per user).

---

## Fix first

1. Make inventory updates atomic (or reserve stock with a TTL)  
2. Add Redis for Socket.IO, caching, and a persistent job queue  
3. Tune Prisma / PgBouncer connection pooling  
4. Put multiple API instances behind a load balancer  
5. Run LT-001, LT-002, and LT-005 on staging before the next peak event  

---

## Scale triggers (from the source report)

- **> 1000 concurrent users** → load balancer + 2+ API instances  
- **> 500 merchants per region** → regional reads  
- **p99 query > 500ms or DB > 100GB** → partition orders / add replicas  

This is a **projected** stress assessment, not a measured load-test result.

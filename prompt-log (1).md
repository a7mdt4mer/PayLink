# PayLink – Phase 1 AI Prompt Log

**Project:** PayLink – Bill-Payment and Digital Wallet Backend  
**Phase:** 1 – Requirements, Design, and DevOps Foundation

**Team:**
- Youssef Khaled Mohamed — 20246133
- Ahmed Tamer Ahmed — 20246162
- Aly Ahmed Ibrahim — 20246069

> **Important:** This is a structured draft/example for the team to verify. Before submission, replace any prompt, answer, date, tool/model, or verdict that does not match what your team actually did. The assignment requires an honest record of real AI use.

## Entry 1 – Generating User Stories

**Date:** 2026-11-24  
**Author:** Youssef Khaled Mohamed  
**Stage:** Requirements analysis  
**Tool and model:** ChatGPT – [enter the model actually used]

**Original prompt:**

> Act as a business analyst. Create user stories for PayLink, an Egyptian digital wallet and bill-payment backend. Include customers, wallets, billers, payments, and notifications. Give each story an ID and priority.

**First AI answer (problem found):**

The answer provided a general list of user stories, but some stories combined multiple behaviours into one story. It also did not consistently include testable acceptance criteria in Given/When/Then format.

**Improved prompt:**

> Act as a senior business analyst reviewing a university software-engineering project. Use the PayLink project brief as the source of truth. Create at least 25 separate user stories and do not omit any mandatory functional requirement. Give every story a unique ID, a Must/Should/Could priority, and acceptance criteria written explicitly as Given/When/Then. Keep wallet top-up, ledger recording, payment idempotency, payment-state transitions, timeout handling, callbacks, fee calculation, limits, notifications, and audit logging as separate behaviours where appropriate. Return a structured Markdown document. Do not invent requirements that conflict with the brief.

**Improved AI answer:**

The revised answer separated the main system behaviours into individual user stories, assigned priorities, and added Given/When/Then acceptance criteria. The resulting stories could be checked against the functional requirements in the brief.

**Team verdict:** Fixed / accepted after review. The team must compare every story with the official brief and correct any missing or inaccurate criteria.

---

## Entry 2 – Handling Biller Timeout and Wallet Holds

**Date:** 2026-11-24  
**Author:** Ahmed Tamer Ahmed  
**Stage:** Requirements analysis / payment lifecycle  
**Tool and model:** ChatGPT – [enter the model actually used]

**Original prompt:**

> What should PayLink do if a biller does not respond to a payment request within the timeout?

**First AI answer (problem found):**

The first answer suggested treating the timeout as a failed payment and releasing the customer's held money immediately. This is unsafe because the biller may have received and processed the request even though its response was delayed or lost.

**Improved prompt:**

> Act as a payment-systems architect. In PayLink, a live biller has a 10-second timeout. A timeout does not prove that the biller rejected or failed to receive the payment. Follow these exact rules: after timeout, set the payment state to Unknown; keep the funds held; tell the customer that the payment is still being processed; retry/re-query after 1, 5, and 15 minutes, up to three retries; do not refund until reliable evidence confirms that the biller did not receive the payment. Explain the correct flow and list the allowed state transitions. Do not invent a direct Unknown-to-Refunded transition.

**Improved AI answer:**

The revised answer treated a timeout as an uncertain outcome. It set the payment to Unknown, retained the wallet hold, informed the customer that processing was pending, and described later confirmation through retry, callback, or reconciliation. It did not release funds merely because the timeout elapsed.

**Team verdict:** First answer rejected; improved answer fixed and accepted after checking it against Sections 2.5 and 2.6 of the brief.

---

## Entry 3 – Designing the Biller Integration Boundary

**Date:** 2026-11-25  
**Author:** Aly Ahmed Ibrahim  
**Stage:** Architecture design  
**Tool and model:** ChatGPT – [enter the model actually used]

**Original prompt:**

> Suggest an architecture for PayLink that supports ElectroCo, AquaCo, and TopUpNet.

**First AI answer (problem found):**

The initial suggestion described the integrations at a high level but did not clearly explain how the different protocols would be isolated from the payment-processing module. Without that boundary, protocol-specific code could spread into business logic.

**Improved prompt:**

> Act as a software architect. PayLink must integrate with ElectroCo using REST/JSON, AquaCo using SOAP-style XML over HTTP, and TopUpNet using asynchronous REST callbacks. Propose a Phase 1 layered or hexagonal modular monolith. Define the public interface between Payment Processing and Biller Integration. Place protocol conversion, biller-specific request/response fields, timeout handling, and callback validation inside the appropriate adapter. Explain how a future biller can be added by changing only the Biller Integration module and configuration. Return module responsibilities and a short rationale.

**Improved AI answer:**

The revised proposal introduced a Biller Integration boundary with a separate adapter for each biller. Payment Processing calls a common interface, while each adapter handles its own protocol and response format.

**Team verdict:** Accepted with refinement. The team selected a Layered Modular Monolith for Phase 1 and will verify that the diagrams and package structure preserve the adapter boundary.

---

## Entry 4 – Making Non-Functional Requirements Measurable

**Date:** 2026-11-25  
**Author:** Youssef Khaled Mohamed  
**Stage:** Requirements validation  
**Tool and model:** ChatGPT – [enter the model actually used]

**Original prompt:**

> Give me non-functional requirements for a wallet and bill-payment system.

**First AI answer (problem found):**

The first answer included broad statements such as “the system should be fast,” “the system should be secure,” and “the system should be reliable.” These statements were not measurable and did not explain how the team would prove that they were satisfied.

**Improved prompt:**

> Act as a software quality engineer. For PayLink, write at least six measurable non-functional requirements. Cover correctness, performance, resilience, modifiability, auditability, and testability. Use the exact targets from the project brief where provided: zero duplicate charges and zero negative balances in concurrency/duplicate tests; 100 payments per second for 60 seconds; one biller outage must not stop other billers; adding a biller changes only its integration and configuration; 100% of money movements have audit records; and at least 70% domain-logic line coverage measured in CI. For each requirement provide an ID, measurable target, and verification method.

**Improved AI answer:**

The revised answer converted the quality goals into six measurable requirements and connected each target to a suitable test, load test, failure simulation, code-change review, audit check, or CI coverage report.

**Team verdict:** First answer fixed. The measurable targets were retained after comparison with the official project brief.

---

## Entry 5 – Reviewing Payment State Transitions

**Date:** 2026-11-25  
**Author:** Ahmed Tamer Ahmed  
**Stage:** Domain modelling / state diagram  
**Tool and model:** ChatGPT – [enter the model actually used]

**Original prompt:**

> Create a payment state machine for PayLink with Initiated, FundsHeld, SentToBiller, Completed, Failed, Rejected, Unknown, and Refunded.

**First AI answer (problem found):**

The first draft did not fully enforce the lifecycle rules. In particular, it allowed an invalid direct transition from Unknown to Refunded and did not clearly identify which states are final.

**Improved prompt:**

> Act as a domain-driven design reviewer. Use only these PayLink lifecycle transitions from the project brief:
> - Initiated → FundsHeld when fraud checks pass and funds are sufficient.
> - Initiated → Rejected when checks fail or funds are insufficient.
> - FundsHeld → SentToBiller when the request is sent.
> - SentToBiller → Completed on biller confirmation.
> - SentToBiller → Failed on definitive biller refusal.
> - SentToBiller → Unknown on timeout.
> - Unknown → Completed on later biller confirmation.
> - Unknown → Failed on later refusal or reconciliation confirming no payment.
> - Failed → Refunded when the hold is released.
> Completed, Rejected, and Refunded are final. Unknown must never be refunded automatically. Return a transition table and identify invalid transitions.

**Improved AI answer:**

The revised answer returned the permitted transitions, marked Completed, Rejected, and Refunded as final, and kept Unknown unresolved until a later confirmation or reconciliation result. A confirmed failure is followed by releasing the hold and moving to Refunded.

**Team verdict:** First answer rejected; improved answer accepted after checking every transition against Section 2.5 of the brief.

---

## Summary of AI Review

| Entry | Stage | Main issue found in first answer | What the team changed |
|---|---|---|---|
| 1 | User stories | Stories were broad and acceptance criteria were incomplete. | Added separate behaviours, priorities, and Given/When/Then criteria. |
| 2 | Timeout handling | Timeout was incorrectly treated as confirmed failure. | Specified Unknown state and retained the wallet hold. |
| 3 | Architecture | Biller-specific protocol logic was not isolated clearly. | Defined a common integration interface and separate adapters. |
| 4 | Non-functional requirements | Quality statements were not measurable. | Added numerical targets and verification methods. |
| 5 | State diagram | Invalid transition and unclear final-state rules. | Supplied the exact allowed transitions and final states. |

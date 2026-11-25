# PayLink – Phase 1 Requirements

**Project:** PayLink – Bill-Payment and Digital Wallet Backend  
**Phase:** 1 – Requirements, Design, and DevOps Foundation  
**Team:**
- Youssef Khaled Mohamed — 20246133
- Ahmed Tamer Ahmed — 20246162
- Aly Ahmed Ibrahim — 20246069

**Technology decision:** Python 3.12, FastAPI, PostgreSQL  
**Architecture decision:** Modular Monolith using a layered structure

---

## 1. Problem Summary

PayLink is an Egyptian digital payment platform that allows customers to pay electricity, water, mobile, and internet bills using money stored in a digital wallet. Customers may also make payments through agents. PayLink communicates with external billers, calculates service fees, and may pay commissions to agents.

The backend must process payments reliably and protect customers' money. A payment must not be charged twice because of a repeated request, and a wallet must never become negative. The system must reserve funds before contacting a biller, confirm the payment only after a successful response, and release the reserved funds when a failure is confirmed. If the biller's response times out, the payment becomes **Unknown** and its funds remain held until the result is known.

The system is designed to support different biller protocols through separate integrations. This makes it possible to add or change a biller without rewriting the payment-processing logic.

## 2. Project Objectives

1. Provide a reliable backend for wallet-based utility bill payments.
2. Keep a complete ledger of wallet movements instead of directly overwriting balances.
3. Prevent duplicate charges through idempotency.
4. Enforce account verification limits, payment limits, and fraud rules.
5. Integrate with billers that use different communication protocols.
6. Calculate service fees and agent commissions according to configurable business rules.
7. Notify customers about payment outcomes.
8. Keep auditable records and support later reconciliation with biller settlement files.

## 3. Stakeholders

| Stakeholder | Interest / Responsibility |
|---|---|
| Customer | Registers, manages a wallet, checks bills, pays bills, and receives notifications. |
| Agent | Accepts cash or makes bill payments on behalf of customers and receives commission for completed eligible payments. |
| Administrator | Manages billers, services, fees, limits, and configuration. |
| Support employee | Searches payment references, reviews payment history, and handles account/payment issues. |
| Biller / Utility company | Provides bill inquiries, receives payments, and reports payment results. |
| PayLink management | Defines business rules and expects reliable, scalable, auditable operations. |
| Engineering / DevOps team | Builds, tests, deploys, monitors, and maintains the backend. |

## 4. Scope and Main Modules

The Phase 1 design defines the following modules and their responsibilities:

| Module | Main responsibility |
|---|---|
| Accounts and Wallet | Customer/agent accounts, verification level, wallet, ledger, holds, top-ups, and refunds. |
| Biller Catalog | Biller and service information, required inquiry fields, amount limits, and activation status. |
| Payment Processing | Payment orchestration, idempotency, payment state transitions, and payment history. |
| Biller Integration | A separate adapter for each biller protocol, including timeout and callback handling. |
| Fees and Commissions | Fixed, percentage, tiered, promotional fees, and agent commissions. |
| Notifications | SMS, email, and push notifications with retry handling. |
| Fraud Checks | Daily-limit, velocity, and blocked-account checks. |
| Reconciliation | Comparison of PayLink payment records with biller settlement files and reporting differences. |

## 5. Functional Requirements – User Stories

The following 25 user stories are prioritized as Must, Should, or Could. Acceptance criteria use Given/When/Then format.

### US-01 – Customer registration
**Priority:** Must

- **Given** a visitor provides valid registration information,
- **When** the visitor submits the registration request,
- **Then** the system creates a customer account with Basic verification level and an associated wallet.

### US-02 – Upgrade verification level
**Priority:** Should

- **Given** a customer has a Basic account and satisfies the verification requirements,
- **When** an authorized administrator approves the upgrade,
- **Then** the customer's verification level becomes Verified and the applicable daily limit becomes 30,000 EGP.

### US-03 – View wallet balance and history
**Priority:** Must

- **Given** a customer is authenticated,
- **When** the customer requests wallet information,
- **Then** the system returns available balance, held balance, and a paginated transaction history.

### US-04 – Top up wallet
**Priority:** Must

- **Given** a customer has a valid simulated card or an agent cash top-up request,
- **When** the top-up is accepted,
- **Then** the wallet ledger records the credit and the available balance is increased by the exact credited amount.

### US-05 – Record every wallet movement
**Priority:** Must

- **Given** a wallet movement is performed,
- **When** the movement is committed,
- **Then** the system creates an immutable ledger entry containing the amount, movement type, timestamp, reference, and actor, and derives the balance from ledger entries.

### US-06 – Manage billers and services
**Priority:** Must

- **Given** an administrator is authorized,
- **When** the administrator adds, edits, activates, or disables a biller or service,
- **Then** the catalog stores the change and the action is recorded in the audit log.

### US-07 – View available billers
**Priority:** Must

- **Given** a customer requests the biller catalog,
- **When** the catalog is retrieved,
- **Then** the system returns active billers, their services, and the required input fields for each service.

### US-08 – Run bill inquiry
**Priority:** Must

- **Given** a customer selects a biller and supplies valid inquiry fields,
- **When** the customer requests an inquiry,
- **Then** the system calls the appropriate biller integration and returns the bill amount or a clear inquiry error.

### US-09 – Preview fee and total
**Priority:** Must

- **Given** a bill inquiry succeeds,
- **When** the system calculates the payment preview,
- **Then** it displays the bill amount, service fee, and total payable amount before payment is submitted.

### US-10 – Pay a bill from wallet
**Priority:** Must

- **Given** a customer has sufficient available funds and passes the required checks,
- **When** the customer confirms a bill payment,
- **Then** the system creates a payment, holds the total amount, and starts the biller-payment process.

### US-11 – Idempotent payment request
**Priority:** Must

- **Given** a payment request has already been processed with an idempotency key,
- **When** the same request is submitted again with the same key,
- **Then** the system returns the original payment result and does not create another charge or biller payment.

### US-12 – Enforce payment state transitions
**Priority:** Must

- **Given** a payment is in a defined lifecycle state,
- **When** an event attempts to change its state,
- **Then** the system permits only transitions defined in the payment state model and rejects all other transitions.

### US-13 – Hold funds before biller call
**Priority:** Must

- **Given** a payment passes fraud checks and the wallet has sufficient available funds,
- **When** payment processing begins,
- **Then** the total amount is moved from available funds to held funds before the biller is contacted.

### US-14 – Release funds after confirmed failure
**Priority:** Must

- **Given** a payment has held funds and the biller definitively refuses the payment,
- **When** the payment is marked Failed,
- **Then** the system releases the hold, records the corresponding ledger movement, and marks the payment Refunded according to the lifecycle rules.

### US-15 – Handle biller timeout and Unknown state
**Priority:** Must

- **Given** a live biller does not respond within the configured 10-second timeout,
- **When** the timeout is reached,
- **Then** the payment becomes Unknown, the held funds remain held, and the customer is informed that processing is still pending.

### US-16 – Retry an Unknown payment
**Priority:** Must

- **Given** a payment is Unknown,
- **When** its scheduled retry time is reached,
- **Then** the system re-queries the biller according to the configured retry schedule of 1, 5, and 15 minutes, up to three retries, without creating a second payment.

### US-17 – Process asynchronous biller callback
**Priority:** Must

- **Given** a TopUpNet payment is awaiting an asynchronous result,
- **When** TopUpNet sends a valid success or failure callback,
- **Then** the system validates the callback and updates the payment through an allowed state transition.

### US-18 – Ignore duplicate callback
**Priority:** Must

- **Given** a callback for a payment has already been processed,
- **When** the same callback is received again,
- **Then** the system does not repeat the wallet or payment operation and records the duplicate for investigation.

### US-19 – Support the required billers
**Priority:** Must

- **Given** a customer uses the supported biller catalog,
- **When** the customer makes an electricity, water, or mobile top-up payment,
- **Then** the system communicates with ElectroCo, AquaCo, or TopUpNet through the corresponding integration without exposing protocol-specific details to Payment Processing.

### US-20 – Calculate configurable service fees
**Priority:** Must

- **Given** a payment is being priced,
- **When** the fee is calculated,
- **Then** electricity and water use a fixed 2.50 EGP fee, mobile top-up uses 1.5% with a 1 EGP minimum, internet uses 2 EGP up to 200 EGP and 4 EGP above 200 EGP, and a valid promotion makes the selected biller's fee zero.

### US-21 – Agent payment and commission
**Priority:** Should

- **Given** an authorized agent makes a payment for a customer,
- **When** that payment reaches Completed,
- **Then** the system credits the agent's wallet with 40% of the service fee and records the commission in the ledger.

### US-22 – Enforce amount and daily limits
**Priority:** Must

- **Given** a customer submits a payment below 5 EGP, above 10,000 EGP, or above the applicable daily limit,
- **When** the payment is validated,
- **Then** the system rejects it with a clear reason and does not contact the biller or hold funds.

### US-23 – Search payment by reference
**Priority:** Must

- **Given** a support employee is authorized,
- **When** the employee searches using a payment reference,
- **Then** the system returns the payment details, current state, timestamps, and recorded history.

### US-24 – Notify customer about payment result
**Priority:** Must

- **Given** a payment reaches Completed or Failed,
- **When** the result is committed,
- **Then** the system requests the configured SMS and push notifications with a clear payment result and reference.

### US-25 – Audit money movements and administrative actions
**Priority:** Must

- **Given** a wallet movement or administrative action occurs,
- **When** the operation is committed,
- **Then** the system stores an audit record identifying who performed it, when it happened, and why or what action was performed.

## 6. Non-Functional Requirements

The project will measure the following quality attributes. Measurements are targets for the completed system; Phase 1 establishes how they will be tested.

| ID | Quality attribute | Measurable requirement / acceptance measure |
|---|---|---|
| NFR-01 | Correctness and concurrency | In duplicate-request and concurrent-wallet tests, there must be zero duplicate charges and zero negative wallet balances. |
| NFR-02 | Performance | The system should sustain at least 100 payment requests per second for 60 seconds against mock billers under the defined test environment. |
| NFR-03 | Resilience | Disabling one mock biller must not prevent successful inquiries or payments through the other configured billers. |
| NFR-04 | Modifiability | Adding a new biller must require changes only in the Biller Integration module and its configuration; Payment Processing and other business modules must remain unchanged. |
| NFR-05 | Auditability | 100% of committed money movements must have an associated audit record containing actor, timestamp, and reason/reference. |
| NFR-06 | Testability | Domain-logic line coverage must be at least 70%, measured and reported by the CI pipeline. |

## 7. Fixed Business Rules and Constraints

All monetary calculations use exact decimal types (for example, Python `Decimal`) and must not use binary floating-point values.

| Rule | Value |
|---|---|
| Basic daily payment limit | 5,000 EGP |
| Verified daily payment limit | 30,000 EGP |
| Minimum single payment | 5 EGP |
| Maximum single payment | 10,000 EGP |
| Electricity and water fee | Fixed 2.50 EGP |
| Mobile top-up fee | 1.5% of amount, minimum 1 EGP |
| Internet fee | 2 EGP for amounts up to and including 200 EGP; 4 EGP above 200 EGP |
| Promotion | Zero fee for one configured biller during configured start and end dates |
| Agent commission | 40% of service fee, credited only when payment completes |
| Velocity rule | More than 5 payments in 60 seconds from one account blocks it for 10 minutes |
| Live biller timeout | 10 seconds |
| Unknown payment retries | After 1, 5, and 15 minutes; maximum 3 retries before reconciliation |
| Notification retries | 3 retries, then mark as undelivered |
| Money precision | Exact decimal arithmetic; no floating-point money calculations |

### Biller integration constraints

| Biller | Service | Protocol / behaviour |
|---|---|---|
| ElectroCo | Electricity | REST/JSON; inquiry by meter number; immediate confirmation; normal response under 1 second. |
| AquaCo | Water | SOAP-style XML over HTTP; slower response (2–4 seconds); rejects payments above the bill amount. |
| TopUpNet | Mobile top-up | REST/JSON asynchronous flow; initially accepts the request and later sends a success/failure callback. |
| NetCo | Internet | Daily CSV batch integration; optional for the minimum Phase 1 biller scope. |

## 8. Payment Lifecycle

A payment must be in exactly one state. Only the transitions below are allowed.

| Current state | Event / condition | Next state |
|---|---|---|
| Initiated | Fraud checks pass and wallet has sufficient funds | FundsHeld |
| Initiated | Fraud check fails or funds are insufficient | Rejected |
| FundsHeld | Payment request is sent to the biller | SentToBiller |
| SentToBiller | Biller confirms payment | Completed |
| SentToBiller | Biller definitively refuses payment | Failed |
| SentToBiller | No answer before timeout | Unknown |
| Unknown | Biller later confirms through callback, retry, or settlement | Completed |
| Unknown | Biller later refuses, or reconciliation confirms no payment | Failed |
| Failed | Held funds are released | Refunded |

**Final-state rules:** Completed, Rejected, and Refunded are final. Unknown is not a confirmed failure and must never trigger an automatic refund. Funds remain held until the system has reliable evidence that the biller did not receive the payment.

## 9. Technical Decisions for Phase 1

| Area | Decision |
|---|---|
| Programming language | Python 3.12 |
| Backend framework | FastAPI |
| Database | PostgreSQL (relational database) |
| Architecture | Layered Modular Monolith |
| API style | REST with OpenAPI documentation |
| Asynchronous flow | Begin with an in-process event/callback handling design; the final system can evolve this flow as required by Phase 2. |
| Diagrams | Mermaid source files stored under `/docs/design/` |
| Containers | Docker and Docker Compose |
| CI | GitHub Actions |
| Testing | Pytest |

The architecture separates business modules behind clear interfaces. Biller-specific protocols are isolated in Biller Integration adapters. This is intended to protect the payment domain from protocol changes, including the later ElectroCo API version change.

The final database design must be relational and contain at least 10 tables. Schema migrations must be version-controlled. The final API must document at least 20 REST endpoints in OpenAPI. These are implementation targets for Phase 2; Phase 1 records them as design constraints.

## 10. Ambiguities, Questions, and Decisions

| Question / ambiguity | Decision |
|---|---|
| Does a timeout mean that the biller definitely rejected the payment? | No. A timeout produces Unknown because the biller may have received the request. |
| Should the wallet hold be released immediately after a timeout? | No. Funds remain held while the result is uncertain. |
| Can an Unknown payment be refunded automatically? | No. Refund only after reliable confirmation that the biller did not receive the payment. |
| What happens when the same payment request is sent more than once? | The idempotency key identifies the original request; repeated requests return the original result and must not create another charge. |
| What happens if two payments arrive simultaneously and the balance covers only one? | Wallet reservation must be atomic/transactional so only one payment can reserve the available funds. The other is rejected. |
| What if a success callback is delivered more than once? | Process the first valid callback once; ignore and log duplicates. |
| When is agent commission credited? | Only after the payment reaches Completed; commission is 40% of the service fee. |
| Are wallet balances manually overwritten? | No. Every movement is represented by ledger entries; balances are derived from ledger data. |
| What monetary representation is allowed? | Exact decimal arithmetic, never floating-point arithmetic. |
| What happens when an SMS provider is unavailable? | Payment completion is not rolled back; notification delivery is retried three times and then marked undelivered. |
| Is NetCo required for the initial biller implementation? | No. NetCo batch support is optional; ElectroCo, AquaCo, and TopUpNet are the required minimum. |
| Where should biller-specific protocol transformations live? | Inside the corresponding Biller Integration adapter, not in Payment Processing or wallet modules. |
| Which daily limit applies? | Basic customers: 5,000 EGP; Verified customers: 30,000 EGP. |
| How should promotion dates be interpreted? | A promotion applies only to its configured biller and only within its configured start/end period. The exact timezone and inclusive/exclusive boundary convention must be consistent in implementation configuration. |

## 11. Phase 1 Completion Boundary

Phase 1 delivers the requirements and design baseline, diagram source files, Docker/Compose foundation, a basic application/database startup, a first GitHub Actions workflow, and the prompt log.

The complete payment implementation, all biller integrations, full test suite, production-like event-driven evolution, ElectroCo API v2 change, and final deployment comparison belong to Phase 2. They are intentionally not claimed as completed in this Phase 1 requirements document.

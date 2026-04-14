---
marp: true
theme: default
paginate: true
style: |
  section {
    font-family: system-ui, sans-serif;
    font-size: 1.6rem;
  }
  section.title {
    text-align: center;
    justify-content: center;
  }
  h1 { color: #1836b2; }
  h2 { color: #1836b2; border-bottom: 2px solid #ff914d; padding-bottom: 0.2em; }
  strong { color: #ff914d; }
  img[alt~="diagram"] {
    display: block;
    margin: auto;
  }
---

<!-- _class: title -->

# Amazon Bedrock AgentCore
## A Field Guide for AWS Builders

Rowan Udell · AWS Security Hero & Consultant
AWS Brisbane Usergroup · April 2026

---

## The Problem with AI Agents Today

Prototypes are easy. **Production is hard.**

Every team re-invents the same things:
- Hosting and scaling agent code
- Memory and session management
- Authentication and authorization
- Tool integration
- Observability and evaluation

AgentCore is the **missing platform layer** between your agent code and production.

---

## What is Amazon Bedrock AgentCore?

A suite of **10 composable services** for building, running, and governing AI agents.

- **Framework-agnostic** — LangGraph, CrewAI, Strands, custom code
- **Model-agnostic** — Bedrock, Claude, OpenAI, Gemini, whatever
- Use what you need, skip what you don't
- Not a new framework — it's **infrastructure for agents**

---

![bg contain](images/agentcore_all_components_final.png)

---

<!-- _class: title -->

# Run Your Agent
Runtime · Code Interpreter · Browser

---

## Runtime

Serverless hosting for AI agents — no infrastructure to manage.

- **Framework-agnostic**: bring any agent framework or custom Python
- **MicroVM isolation** (Firecracker) — each invocation is sandboxed
- Executions up to **8 hours** for long-running agents
- Native **MCP server** and **A2A protocol** support
- **WebSocket streaming** for real-time interactions
- Scales to zero, scales up automatically
- Pay only for what you use

---

## Code Interpreter & Browser

Two sandboxed capabilities agents can use at runtime.

**Code Interpreter**
- Sandboxed Python execution — agents can write and run code dynamically
- Data analysis, calculations, file I/O within the sandbox
- Direct invocation or framework integration

**Browser**
- Isolated Chromium instance per session
- Navigate, fill forms, click buttons, parse dynamic content
- **Session recording** for audit and debugging
- Built-in CAPTCHA reduction

---

<!-- _class: title -->

# Connect to the World
Gateway · Memory

---

## Gateway

Turn any API into an **MCP-compatible tool** — without writing glue code.

- Import from **Lambda functions, OpenAPI specs, or existing APIs**
- **1-click integrations**: Slack, Jira, GitHub, Salesforce, Zendesk
- **Semantic tool discovery** — agents find the right tool by description
- Centralized tool management across all your agents
- VPC Lattice support for private resources
- Built-in authentication and credential exchange

---

## Memory

Give agents the ability to **remember**.

- **Short-term memory**: session context — conversation history, scratchpad
- **Long-term memory**: persists across sessions — user preferences, facts, summaries
- Asynchronous memory generation and consolidation
- Managed storage — no DynamoDB tables to maintain
- **Encryption at rest** (KMS)
- Useful for personalization, continuity, and multi-step workflows

---

<!-- _class: title -->

# Secure & Govern
Identity · Policy · Registry

---

## Identity

First-class identity for agents — not just IAM roles bolted on.

- Each agent gets a **unique ARN**
- **OAuth 2.0** credential management
- **Credential vault** for third-party tokens — no secrets in env vars
- **User-delegated access**: agent acts *as* the user, not *instead of*
- Identity propagation through the full tool chain

![bg right:40% 90%](images/AgentCore%20Identity.jpg)

---

## Policy

Fine-grained access control using **Cedar** — enforced *outside* agent code.

- Policies are **declarative**, not embedded in prompts or agent logic
- Intercept tool calls at **gateway, tool, operation, or parameter** level
- Two modes: **LOG_ONLY** (shadow) or **ENFORCE** (block)
- Start in LOG_ONLY, review, then enforce

```
forbid(
  principal,
  action == AgentCore::Action::"HRTools__export_salary_report",
  resource
);
```

The agent doesn't decide its own permissions. **You do.**

---

## Registry

Centralized discovery and governance for your agent estate.

- **Register** agents, tools, and MCP servers in one catalog
- **Discover** what exists across teams and accounts
- Governance metadata: ownership, version, lifecycle status
- Approval workflows for curation
- MCP-native access via registry endpoints
- Foundation for **multi-agent architectures**

---

<!-- _class: title -->

# Observe & Evaluate
Observability · Evaluations

---

## Observability

See what your agents are **actually doing**.

- **OpenTelemetry-compatible** tracing
- Integrates with **Amazon CloudWatch** natively
- Agent-specific trace views: tool calls, LLM invocations, decisions
- Correlate agent behavior with downstream service metrics
- Key metrics: session count, latency, duration, token usage, error rates
- Essential for debugging **non-deterministic behavior**

---

## Evaluations

Measure agent quality **systematically**.

- **LLM-as-a-Judge**: use a model to evaluate agent outputs
- **13+ built-in evaluators**: correctness, faithfulness, relevance, toxicity
- Two modes:
  - **On-demand**: run evaluations in CI/CD or ad hoc
  - **Online**: continuous evaluation of live production traffic
- Build confidence before promoting agents to production
- Works with Runtime-hosted and external agents

---

## How the Services Fit Together

![diagram w:900](images/agentcore-architecture.svg)

---

## Prototype to Production

![diagram w:900](images/proto-to-prod.svg)

---

## Getting Started: Day 1

Start small. You don't need all 10 services on day one.

**Minimum viable agent stack:**
1. **Runtime** — deploy your existing agent code
2. **Gateway** — connect it to one or two tools
3. **Observability** — see what it's doing

**Then layer on:**
4. **Memory** — when you need cross-session context
5. **Policy** — when you need tool access control (start with LOG_ONLY)
6. **Identity** — when users need delegated access
7. **Evaluations** — before you promote to production

---

## Quick Start (CLI)

```bash
# Create a gateway with tools
aws bedrock-agentcore create-gateway \
  --gateway-name my-tools \
  --tool-configs file://tools.json

# Create a runtime endpoint
aws bedrock-agentcore create-runtime-endpoint \
  --runtime-name my-agent \
  --framework-config '{"type": "CUSTOM"}'

# Deploy your agent
aws bedrock-agentcore deploy-agent \
  --runtime-id $RUNTIME_ID \
  --agent-config file://agent.json
```

---

## What AgentCore Is Not

- Not a replacement for **Bedrock Agents** (managed orchestration)
  - AgentCore = infrastructure; Bedrock Agents = opinionated orchestration
- Not a new agent **framework** — bring your own
- Not **limited to Bedrock models** — works with any LLM
- Not a monolith — each service is **independently useful**

---

## Key Takeaways

1. AgentCore is **infrastructure for agents**, not another framework
2. **10 services** that are individually useful and composable
3. Start with **Runtime + Gateway + Observability**
4. Use **Policy in LOG_ONLY** mode before enforcing
5. **Identity propagation** solves the "agent uses a shared service account" anti-pattern
6. Treat agent security like application security — because it is

---

## Resources

- **AgentCore docs**: AWS Bedrock AgentCore User Guide
- **Cedar playground**: cedarpolicy.com
- **Strands SDK**: github.com/strands-agents/sdk-python
- **AWS re:Post**: search "AgentCore"

---

<!-- _class: title -->

# Thanks!

Rowan Udell
AWS Security Hero & Consultant

auditready.cloud

![bg right:40% 80%](images/rowanu-linkedin-qr.svg)

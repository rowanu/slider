---
marp: true
theme: aws-summit-sydney
paginate: false
footer: ""
---

<!-- _class: title-dark -->
<!-- _paginate: skip -->

# Securing Amazon Bedrock AgentCore
A Practical Framework
<span class="date">Rowan Udell • AWS Summit Sydney • April 2026</span>

---

<!-- _class: divider -->
<!-- _paginate: skip -->

# Agents Are Software.
Treat them like software.

---

# What Makes Agents Different?

<div class="columns">
<div>

**Traditional App**

Deterministic execution

* Fixed control flow
* Clearly scoped permissions
* Predictable I/O

</div>
<div>

**AI Agent**

Probabilistic outcomes are a feature, not a bug

* Broad access patterns
* Dynamic tool selection
* Untrusted content in the loop

</div>
</div>

---

<!-- _class: divider-teal -->
<!-- _paginate: skip -->

# The Lethal Trifecta
Simon Willison, 2025

---

# A Dangerous Combination

![bg left:50% 100%](images/venn-trifecta.svg)

* One or two? Manageable.
* All three?

---

# A Dangerous Combination

![bg left 100%](images/venn-trifecta.svg)
![w:450](images/maverick.jpg)

---

# Meet the Tax Assistant

![w:900](images/tax-assistant.svg)

An AI agent that helps Australians with tax returns, deductions, and financial planning

It has access to **financial records**, processes **documents** from users, and **takes actions** with the ATO and banks

Any concerns?

---

# Sensitive Data

The agent can see what users can't see about each other

- Tax file numbers (TFNs) and income summaries
- Bank accounts, investment portfolios, super balances
- PAYG payment summaries and group certificates
- Prior year returns and ATO correspondence

---

# Untrusted Content

LLMs follow instructions in content, regardless of source

- Uploaded receipts and invoices
- Forwarded bank statements and payslips
- MyGov / ATO portal messages
- RAG results from the financial knowledge base

---

# External Actions

Data exfiltration as a feature

- Lodge tax returns with the ATO
- Submit BAS statements
- Initiate bank transfers and BPAY
- Call third-party financial APIs

---

<!-- _class: divider -->
<!-- _paginate: skip -->

# Guardrails that are 95% effective
are not reliable enough.

---

<!-- _class: divider-teal -->
<!-- _paginate: skip -->

# "Old school" security
is still your best friend.

---

# The Fundamentals Haven't Changed

* **Least privilege** - don't give agents permissions they don't need
* **Defense in depth** - IAM, VPC, Guardrails, Cedar policies: independent layers that assume the others can fail
* **Separation of concerns** - multi-agent architectures scope capabilities and contain blast radius
* **Audit everything** - you can't secure what you can't see
* **Get identity right** - agents should act as users, not as omnipotent service accounts

---

<!-- _class: divider -->
<!-- _paginate: skip -->

# AgentCore's Security Toolkit
Mapped to the Trifecta

---

# The Map

![diagram w:1150](images/trifecta-map.svg)

---

# Sensitive Data

What your agent knows.

![bg right:40% 85%](images/sensitive-data.svg)

```json
{
  "Action": ["bedrock-agentcore:RetrieveMemoryRecords"],
  "Resource": "arn:aws:bedrock-agentcore:us-east-1:123456789012:memory/mem-12345abcdef",
  "Condition": { "StringEquals": {
    "bedrock-agentcore:namespace": "/actor/${aws:PrincipalTag/userId}/preferences/"
  }}
}
```

Namespace condition locks memory records to the calling user's identity. AgentCore Memory encrypts at rest (KMS-backed).

---

# Untrusted Content

What your agent sees.

![diagram w:800](images/content-pipeline.svg)

**Bedrock Guardrails**: Content filtering + injection detection.
**Input Validation**: Schema check, reject malformed or oversized payloads.
**Prompt Engineering**: Separate data from instructions. Never echo untrusted content.

```python
bedrock.apply_guardrail(
    guardrailIdentifier="grd-xxxxx", guardrailVersion="1",
    source="INPUT", content=[{"text": {"text": user_input}}]
)
```

Call `ApplyGuardrail` explicitly on all untrusted input. Don't rely on in-model filtering.

---

# Gateway + Identity

<div class="columns">
<div>

**AgentCore Gateway**
- Centralized tool access
- **Request interceptors**: validate the ATO reference in the request belongs to the calling user
- **Response interceptors**: strip TFNs and bank account numbers before returning to the agent

</div>
<div>

**AgentCore Identity**
- OAuth 2.0 credential management
- Token vault
- The agent's OAuth token carries the user's identity tag. Cedar sees it, policies enforce it.
- Agent acts *as* the user, not *instead of*

</div>
</div>

![diagram w:1150](images/identity-flow.svg)

---

# External Tool Access

What your agent does.

**AgentCore Policy** - Cedar policies, enforced *outside* agent code and context

```cedar
// Tax agents can approve claims under $1,000
permit(
  principal is AgentCore::OAuthUser,
  action == AgentCore::Action::"TaxTool__approve_claim",
  resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:ap-southeast-2:123456789012:gateway/tax-tool"
) when {
  principal.hasTag("role") &&
  principal.getTag("role") == "tax-agent" &&
  context.request.claim_amount < 1000
};
// forbid() works the same way - use it to block actions regardless of any permits
```

The agent doesn't decide its own permissions. You do.

---

# Separation of Concerns

How your agent is *structured*.

![diagram w:750](images/multi-agent.svg)

**AgentCore Runtime**: each agent runs isolated - scoped memory, credentials, and tool access
- Orchestrator delegates tasks to single-responsibility sub-agents
- A compromised sub-agent cannot escalate to orchestrator permissions
- Smaller blast radius per agent

---

# Observability & Evaluations

What your agent *did*.

![diagram w:900](images/observability-evaluations.svg)

**AgentCore Observability**: OTel spans to CloudWatch - tool calls, inputs/outputs, latency, errors. Full session replay.
**AgentCore Evaluations**: pre-deployment testing against datasets, plus always-on scoring of live traffic. Thirteen built-in evaluators - catch safety regressions before users do.

---

<!-- _class: divider-teal -->
<!-- _paginate: skip -->

# What To Do Tomorrow

---

# Audit Your Agents

1. Does your agent *really* need all three trifecta legs?
1. Least privilege IAM roles `#runtime` `#gateway`
1. Validate and sanitise all inputs before the model sees them `#runtime`
1. Add Guardrails - not perfect, but not bad `#runtime`
1. Tool boundaries in Cedar policies, not agent code `#policy`
1. Delegate credentials - agents act as users, not themselves `#identity`
1. Decompose agents - single-responsibility sub-agents limit blast radius `#runtime`
1. Observability no longer a "nice to have" `#observability`

---

<!-- _class: divider -->
<!-- _paginate: skip -->

# Agents Are Software.
**Secure** them like software.

---

<!-- _class: title-dark centered -->
<!-- _paginate: skip -->

# Thank You!

~~Questions?~~ No time for questions! Happy to chat after 🤙

<span class="subtitle">I help teams move agents from prototype to production</span>

![bg right:40% 80%](images/real-linkedin-qr.png)

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
<span class="date">AWS Summit Sydney • April 2026</span>

---

<!-- _class: divider -->
<!-- _paginate: skip -->

# Agents Are Software.
Secure them like software.

---

# What Makes Agents Different?

<div class="columns">
<div>

**Traditional App**

- Deterministic execution
- Fixed control flow
- Scoped permissions
- Predictable I/O

</div>
<div>

**AI Agent**

- Probabilistic decisions
- Dynamic tool selection
- Broad access patterns
- Untrusted content in the loop

</div>
</div>

---

<!-- _class: divider-teal -->
<!-- _paginate: skip -->

# The Lethal Trifecta
Simon Willison, 2025

---

# Three Capabilities. Dangerous When Combined.

<div class="columns">
<div>

![w:500](images/venn-trifecta.svg)

</div>
<div>

* Any two? Manageable.
* All three?
  1. **Data exfiltration.**
  1. **Prompt injection exploitation.**
  1. **Unauthorized actions.**

</div>
</div>

---

# Meet the HR Assistant

![w:900](images/hr-agent.svg)

An AI agent that helps employees with leave, payroll, onboarding

It has access to **employee records**, processes **messages** from users, and **takes actions** on other systems

Any concerns?

---

# Sensitive Data Access

The agent can see what employees can't see about each other

* Employee records - names, salaries, performance reviews
* Payroll data - bank accounts, tax file numbers
* Leave balances and medical certificates
* Onboarding documents - ID copies, contracts

---

# Untrusted Content

LLMs follow instructions in content, regardless of source

* Employee chat messages
* Uploaded resumes and CVs
* Forwarded emails
* RAG results from the knowledge base

---

# External Actions

Data exfiltration as a feature

* Update payroll
* Send offer letters
* Book onboarding meetings
* Call external APIs

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
* **Defense in depth** - multiple layers, not one guardrail
* **Separation of concerns** - isolate agent capabilities
* **Audit everything** - you can't secure what you can't see
* **Encrypt by default** - data at rest and in transit

---

<!-- _class: divider -->
<!-- _paginate: skip -->

# AgentCore's Security Toolkit
Mapped to the Trifecta

---

# The Map

<!--
  GRAPHIC: A three-column layout that mirrors the Venn diagram.

  Each column represents one trifecta leg, with the AgentCore
  services that mitigate it stacked below. Use the same colours
  as the Venn diagram circles for visual continuity.

  Column 1 (teal): "Sensitive Data"
    → AgentCore Memory (KMS encryption icon)
    → IAM Policies (shield icon)
    → Resource-based policies

  Column 2 (orange): "Untrusted Content"
    → Bedrock Guardrails (filter icon)
    → Memory best practices (validation icon)
    → Secure prompt engineering

  Column 3 (navy): "External Actions"
    → AgentCore Policy / Cedar (policy document icon)
    → AgentCore Gateway (gateway icon)
    → AgentCore Identity (OAuth/key icon)

  Connect each column to the corresponding Venn circle with a
  dotted line or matching colour border to link back to the framework.
-->

<div class="columns three">
<div>

**Sensitive Data**

Unauthorized access

*Memory* + *IAM*

</div>
<div>

**Untrusted Content**

Prompt injection, poisoning

*Guardrails* + *Memory best practices*

</div>
<div>

**External Actions**

Uncontrolled tool use

*Policy* + *Gateway* + *Identity*

</div>
</div>

---

# Leg 1: Controlling Data Access

<div class="columns">
<div>

**AgentCore Memory**
- Encryption at rest (KMS / CMK)
- Memory poisoning prevention
- Input validation

**IAM Policies**
- Least privilege per agent
- Resource-based policies on Runtime, Gateway, Memory

</div>
<div>

```json
{
  "Effect": "Allow",
  "Action": [
    "bedrock-agentcore:GetMemory",
    "bedrock-agentcore:RetrieveMemoryRecords"
  ],
  "Resource":
    "arn:aws:bedrock-agentcore:
     ap-southeast-2:123456789012:
     memory/hr-assistant/*"
}
```

Not `bedrock-agentcore:*`. Never `*`.

</div>
</div>

---

# Leg 2: Defending Against Untrusted Content

<div class="columns">
<div>

**Bedrock Guardrails**
- Content filtering
- Prompt injection detection

**Memory Hygiene**
- Validate before storing
- Test for injection regularly

**Prompt Engineering**
- System prompts that resist manipulation

</div>
<div>

<!--
  GRAPHIC: A simplified "pipeline" diagram showing content flowing
  through security layers before reaching the agent.

  Flow (top to bottom or left to right):

  [Employee message / Resume / Email]
       ↓
  [Bedrock Guardrails] - label: "content filter + injection detection"
       ↓
  [Input validation] - label: "schema check, sanitise"
       ↓
  [HR Agent] - label: "hardened system prompt"

  Each layer should look like a gate or filter.
  Use red "X" on one path to show blocked malicious content.
  Use green checkmark on clean path passing through.

  This reinforces "defense in depth" - multiple layers, not one.
-->

</div>
</div>

---

# Leg 3: Controlling Tool Access

**AgentCore Policy** - Cedar policies, enforced *outside* agent code

```cedar
// HR assistant can read employee records
permit(
  principal is AgentCore::OAuthUser,
  action == AgentCore::Action::"HRTools__get_employee_record",
  resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:ap-southeast-2:123456789012:gateway/hr-assistant"
) when {
  principal.hasTag("role") &&
  (principal.getTag("role") == "hr-manager" || principal.getTag("role") == "hr-admin")
};

// Nobody can bulk-export salary data
forbid(
  principal is AgentCore::OAuthUser,
  action == AgentCore::Action::"HRTools__export_salary_report",
  resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:ap-southeast-2:123456789012:gateway/hr-assistant"
);
```

The agent doesn't decide its own permissions. You do.

---

# Leg 3: Gateway + Identity

<div class="columns">
<div>

**AgentCore Gateway**
- Centralized tool access
- Interceptors at 4 levels:
  - Gateway
  - Tool
  - Operation
  - Parameter

</div>
<div>

**AgentCore Identity**
- OAuth 2.0 credential management
- Token vault
- Identity-aware authorization
- Agent acts *as* the user, not *instead of*

<!--
  GRAPHIC: A flow diagram showing identity propagation.

  [Employee "Sarah"] - logs in via SSO
       ↓ (OAuth token)
  [HR Agent] - receives Sarah's identity context
       ↓ (agent acts AS Sarah)
  [AgentCore Gateway] - checks Cedar policy against Sarah's role
       ↓ (permitted actions only)
  [Payroll API] - Sarah can see her own record, not others

  Key visual: Sarah's identity "flows through" the whole chain.
  Contrast with a crossed-out alternative: "Agent uses service account
  with full access" - show this as the WRONG way with a red X.
-->

</div>
</div>

---

<!-- _class: divider-teal -->
<!-- _paginate: skip -->

# What To Do Monday

---

# Audit Your Agents

![w:150](images/venn-trifecta-small.svg)

1. Apply least privilege to agent IAM roles
2. Use AgentCore Policy (Cedar) for tool boundaries - not agent code
3. Encrypt memory, validate inputs, test for injection
4. Enable CloudTrail + CloudWatch for agent activity
5. Ask: does your agent *really* need all three legs?

---

<!-- _class: quote -->
<!-- _paginate: skip -->

# Agents are software.
Secure them like software.

---

<!-- _class: title-dark -->
<!-- _paginate: skip -->

# Thank You
rowanudell.com
<span class="date">I help teams move agents from prototype to production. Come say hi.</span>

![w:200](images/linkedin-qr.png)

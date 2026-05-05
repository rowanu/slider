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

# All Three Legs

<div class="columns three">
<div>

**Sensitive Data**

* TFNs and income
* Bank and super balances
* Prior returns 

</div>
<div>

**Untrusted Content**

* Uploaded receipts
* Forwarded bank statements

</div>
<div>

**External Actions**

* Lodge tax returns
* Submit BAS statements
* Initiate bank transfers

</div>
</div>

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

# Guardrails that are 95% effective
are not reliable enough.

---

<!-- _class: divider -->
<!-- _paginate: skip -->

# Break a Leg
The trifecta is only lethal with **all three**.

---

# Three Patterns

Pick a leg to remove.

<div class="columns three">
<div>


**Scoped Data**

* Removes Sensitive Data
* Caller's own slice
* Like multi-tenant SaaS

</div>
<div>

**Curated Input**

* Removes Untrusted Content
* You limit what the agent sees
* Anything that writes

</div>
<div>

**Read-Only**

* Removes External Actions
* Agent thinks, doesn't act
* Think assistants, advisors

</div>
</div>


---

# Back to the Tax Assistant

<div class="columns three">
<div>

**Sensitive Data**

* Memory namespace `/actor/{actorId}/` — one slice per user
* IAM condition `bedrock-agentcore:namespace` blocks cross-user retrieval
* AgentCore Identity OBO token carries `actorId` on every call

</div>
<div>

**Untrusted Content**

* Gateway `SchemaDefinition` types every field: amounts, dates, ABNs
* No free-text or file-upload fields in the tool schema
* Documents pre-parsed into structured records before reaching agent context

</div>
<div>

**External Actions**

* Policy enforced at the Gateway, outside agent code
* Cedar `forbid` and `when` condition

</div>
</div>

---

# A Multi-Agent Approach

![diagram w:900](images/multi-agent.svg)

---

<!-- _class: divider-teal -->
<!-- _paginate: skip -->

# What To Do Tomorrow

---

# Make Things Better

* **Catalogue every agent** you run: you can't secure what you can't see.
* **Map the legs** each agent carries, erring on the side of caution.
* **Name the leg you removed** for each agent: if you can't name it, you haven't removed it.
* **Enforce removal outside agent code** using policies, gateways, and identity.
* **Decompose** multi-leg agents into focused, single-purpose sub-agents.

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

---
marp: true
theme: slider-light
paginate: true
---

<!-- _class: title -->

# What is an agent?

Rowan Udell
Independent Security Consultant | AWS Security Hero

---

## Is it an agent?

**Chatbot**
* Responds to input
* Takes no external actions
* Observes no results
* **Not** an agent: no loop - question in, answer out

---

## Is it an agent?

**Thermostat**
* Has a goal (maintain temperature)
* Takes action: heat on or off - one rule, always the same
* Observes results (reads the temperature back)
* **Not** an agent: one rule, not reasoning - it can't decide, it just triggers

---

## Is it an agent?

**OpenClaw** _(open-source agent that controls your computer)_
* Has a goal (whatever you give it)
* Takes actions: browser, calendar, files
* Observes results
* Decides what to do next
* **Agent**: goal, action, observe, decide - all four

---

## An agent...

* Has a **goal**
* Takes **actions**
* Observes **results**
* Decides **what to do next**: repeat or stop

---

## It's software.

_...just not like other software_

**Traditional software** _(deterministic)_: Same input, same output, every time

**An agent** _(non-deterministic)_: Same input, different path, different result

* Not a bug: it's how reasoning works
* The model decides the path, not the code

---

## Not an agent: it's a chatbot

Input in. One LLM call. Output out.

![diagram w:700](images/loop-prompt.svg)

*e.g. ChatGPT: you ask, it answers.*

---

## Not an agent: it's a workflow

Orchestrate multiple LLM calls: route, branch, combine results.

![diagram w:700](images/loop-workflow.svg)

*e.g. Support email: classify, draft, check tone. Code controls the flow.*

---

## It's an agent

Act on the environment. Observe feedback. Decide what to do next. Repeat until done.

![diagram w:700](images/loop-agent-fixed.svg)

---

## The reasoning step

A thermostat picks from a fixed list. A reasoning model **reasons from evidence**.

* Reads the goal, every prior action, every result, and the available tools
* Thinks: what worked? what failed? what tool fits next?
* Decides: act (with which tool, which inputs), or stop

**Reasoning models** (Claude, o1, Gemini Thinking) make this step visible: you can watch the model plan before it acts. Same loop: better reasoning means better decisions at every step.

---

## Stopping condition

Every loop needs a way to **stop**

<div class="columns">
<div>

**Vague**
- "Plan my trip"
- "Write a better email"
- "Research the topic"

</div>
<div>

**Concrete**
* "Book cheapest return flight, under $600"
* "Rewrite to be direct, under 100 words"
* "Summarise in 3 bullet points"

</div>
</div>

---

## The harness is the real engineering

![diagram w:800](images/harness.svg)

* Runs the loop (the plumbing that calls the model, handles tool calls, feeds results back)
* Manages errors, context, memory, retries
* Tells the model what tools exist (the model only knows what the harness exposes)
* A demo agent is just the loop: an afternoon's work. A production agent is mostly harness.

---

## Tools are the hands

The model names the tool and inputs. The harness runs it and returns the result.

```json
// Model outputs a structured tool call:
{ "tool": "book_restaurant", "name": "Gino's", "date": "Saturday", "time": "7pm", "party": 2 }

// Harness runs it. Model receives:
{ "result": "Confirmed. Table for 2 at 7pm Saturday. Ref #4821." }
```

* Common tools: search the web, book a table, edit a file, write code, send an email

---

<!-- _class: title -->

# Demo

---

<!-- _class: title -->

# Security is an issue

---

## The Lethal Trifecta

_Simon Willison, 2025_

![bg right:45% 90%](images/venn-trifecta.svg)

Dangerous when all three combine:

* **Inputs**: reads emails, pages, documents - content attackers can influence
* **Data access**: sees your files, calendar, credentials
* **Tools**: books, sends, edits, deletes - real actions with real consequences

Any one alone is manageable. All three together: an attacker who hijacks the agent gets everything.

---

## A shared mental model

Now you agree on what an agent is...

- How do you trust it?
- How do you hold it accountable?

Questions? Or connect on LinkedIn

![bg right:35% 80%](images/real-linkedin-qr.png)

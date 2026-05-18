---
marp: true
theme: slider-light
paginate: true
---

<!-- _class: title -->

# What is an agent?

Rowan Udell

---

<!-- reveal: on -->

## Is it an agent?

**Thermostat**
* Has a goal. Takes fixed actions. Checks results.
* **Not** an agent -- actions are fixed, no adaptive decision

**Chatbot**
* Responds to input. Takes no actions. Doesn't observe results.
* **Not** an agent -- no loop, no feedback, just in and out

**Claude Code**
* Has a goal. Takes actions. Observes results. Makes a decision.
* It's an agent -- full loop: goal, act, observe, decide

**OpenClaw**
* Has a goal. Takes actions (shell, browser, calendar). Observes results. Decides what to do next.
* It's an agent -- same loop, your whole computer as the environment

---

## An agent...

* Has a **goal**
* Takes **actions**
* Observes **results**
* Decides **what to do next**: repeat or stop

---

## Not an Agent: It's a Chatbot

Input in. One LLM call. Output out.

![diagram w:700](images/loop-prompt.svg)

---

## Not an Agent: It's a Workflow

Orchestrate multiple LLM calls: route, branch, combine results.

![diagram w:700](images/loop-workflow.svg)

**Example:** A support email arrives. LLM 1 classifies it. LLM 2 drafts a reply using the right template. LLM 3 checks tone. The code controls the flow -- the model never decides what happens next.

---

## It's an Agent

Act on the environment. Observe feedback. Decide what to do next. Repeat until done.

![diagram w:700](images/loop-agent.svg)

Also known as **ReAct** (Reason + Act).

---

## The reasoning step

A thermostat picks from a fixed list. A reasoning model **reasons from evidence**.

* Reads the goal, every prior action, every result so far
* Thinks: what worked? what failed? what tool fits next?
* Decides -- then acts

**Reasoning models** (Claude, o1, Gemini Thinking) make this step visible: you can watch the model plan before it acts. Same loop -- better reasoning means better decisions at every step.

---

## Stopping condition

Every loop needs a way to **stop**

<div class="columns">
<div>

**Vague**
- "Make the code better"
- "Research the topic"

</div>
<div>

**Concrete**
- "All tests pass, no lint errors"
- "Summarise in 3 bullet points"

</div>
</div>

---

## The model is the decider

* Reads the goal, the results so far, and the available tools
* Decides: **which tool**, with **which inputs**, or **stop**

---

## Tools are the hands

The model names the tool and inputs. The harness runs it and returns the result.

```json
// Model outputs a structured tool call:
{ "tool": "book_restaurant", "name": "Gino's", "date": "Saturday", "time": "7pm", "party": 2 }

// Harness runs it. Model receives:
{ "result": "Confirmed. Table for 2 at 7pm Saturday. Ref #4821." }
```

<!-- reveal: on -->

* A tool is any function the model can call: search the web, book a table, edit a file, call an API
* The model chooses; the harness executes and returns the result
* **MCP** (Model Context Protocol) is a standard for describing and connecting tools -- it's why any app can now offer itself as a tool for any agent
* No tools: chatbot. Right tools: real work.

---

<!-- _class: title -->

# Demo

Take a suggestion from the floor.

---

## The harness is the real engineering

![diagram w:800](images/harness.svg)

* Runs the loop -- the plumbing that calls the model, routes tool calls, feeds results back
* Manages errors, context length, memory, retries
* Tells the model what tools exist -- the model only knows what the harness exposes
* A demo agent is just the loop -- an afternoon's work. A production agent is mostly harness.

---

## The Lethal Trifecta

![bg right:45% 90%](images/venn-trifecta.svg)

- **Untrusted content** -- prompt injection: an attacker hides instructions inside content the agent reads, hijacking what it does next
- **Sensitive data** (exfiltration risk)
- **External actions** (real-world impact)

The model can't be trusted 🫤

---

## A Shared Mental Model

Now that you agree on what an agent is...

- How do you trust it?
- How do you hold it accountable?
- How do you know when NOT to let an agent do it?

Questions? Happy to chat. I help teams move agents from prototype to production.

![bg right:35% 80%](images/real-linkedin-qr.png)

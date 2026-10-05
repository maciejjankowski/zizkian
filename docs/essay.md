
# The Zizkian
## An operator for the question behind the question

**Historical conceptual appendix.** This essay preserves the requested matrix
and Hamiltonian analogy. Its numerical profiles and formal notation have no
operational role in the prompts or checker. Start with the [method](method.md)
for use, and the [evaluation protocol](evaluation.md) for claims that could fail.

**The Zizkian** names the framework. **WWZS?** (What would Žižek say?) names its provocation mode. “Žižekian” describes the inspiration. The falsification question, “What would prove that reading wrong?”, carries forward from an earlier conversation; it is not a newly invented safeguard.

We began with a name in a prompt. We ended with a question about what a prompt permits us to see.

“What would Žižek say?” offers an attractive shortcut: introduce a dissenter into an agreeable conversation. But a name is an unstable instruction. It can summon a method, an accent, a performance, or simply the confidence to be wrong in a more interesting way. We wanted to retain the operation after removing the costume.

The operation begins before the answer. It asks what must already be accepted for the question to appear reasonable.

“How do we improve onboarding?” contains several possible worlds. In one, newcomers lack useful instruction. In another, the product is difficult to use. In a third, the organization has made its own complexity the newcomer's responsibility. The sentence does not tell us which world we inhabit. It can, however, quietly appoint a tutorial as the solution before the investigation begins.

The Zizkian is our name for the instrument that makes this appointment visible.

## A matrix of attention

The Hamiltonian provides the analogy: an operator whose relationship to a system's state is formally specified, including its role in time evolution. Here the resemblance is architectural, not physical. Our states are briefs, evidence, constraints and interpretations. Our transformations are questions. We claim no equation of motion for human beings. [3 MODERATE \| MIT's lecture notes on time evolution](https://ocw.mit.edu/courses/22-02-introduction-to-applied-nuclear-physics-spring-2012/b5106a499ae03e36b5a2e002355668f9_MIT22_02S12_lec_ch6.pdf)

What we have built is a library of reasoning instructions. The matrix proposed here makes their allocation of attention explicit. Its dimensions are premise, incentive, agency, identity, value, time, alternative and decision. A lens assigns emphasis across these dimensions. The weights describe where to look, not how much truth has been found.

The Incentive Detective gives priority to rewards and value flows. The Constraint Hunter attends to what prevents the desired result. The Mirror attends to the distance between a person's stated priority and their own account of their choices. The Operator asks what can actually happen next. The Veil Piercer puts pressure on the premise that organized the inquiry.

These are distinct directions of interrogation. Six consulting lenses and six coaching lenses need not become twelve actors delivering monologues. A few selected rows can direct one investigation. The client receives the resulting decision, not the theatre of its production.

A fragment of the proposed matrix makes the distinction concrete. Here, 2 means
primary attention, 1 secondary and 0 background. The assignments are editorial
choices, not estimates of truth or measured effects.

| Lens | Premise | Incentive | Agency | Identity | Value | Time | Alternative | Decision |
|---|---|---|---|---|---|---|---|---|
| Veil Piercer | 2 | 1 | 1 | 2 | 1 | 0 | 2 | 1 |
| Incentive Detective | 1 | 2 | 2 | 1 | 2 | 1 | 1 | 1 |
| Identity Explorer | 1 | 1 | 1 | 2 | 1 | 1 | 2 | 0 |
| Operator | 0 | 1 | 2 | 0 | 1 | 2 | 1 | 2 |

Consulting and coaching remain different spaces. A business system can be examined through costs, permissions and observed behavior. A person's identity cannot be inferred from a polished question. There, an interpretation must remain something the person can reject. The same operator therefore changes its manner of application without acquiring the right to know another person's mind.

## The return operation

An ordinary critique offers a satisfying endpoint: we have discovered what the institution was hiding. The Zizkian introduces a further operation. What does the critic receive from this discovery?

The consultant may receive a mandate. The audience may receive the pleasure of being difficult to deceive. The model may receive approval for producing the unexpected answer. A critique can participate in the economy it describes without becoming false. Its participation is another fact to inspect, not a universal reason to dismiss it.

This is the return cut. It includes the observer in the arrangement without reducing every observation to self-interest.

The operator must also permit the less dramatic result. Sometimes onboarding is useful instruction. Sometimes a boundary is a genuine constraint. Sometimes the most intelligent recommendation is to keep the existing process. A method incapable of reaching those conclusions would merely exchange one compulsory story for another.

We stop the recursion when it stops changing what could be tested or decided. Otherwise the final boss becomes a meeting that cannot end.

## The function of the instrument

In schematic notation, let a lens produce an interpretation from a brief under an explicit attention profile. Apply the return cut to that interpretation. Then require an evidence check and a decision about what to do or learn next:

**Zizkian = directed inquiry → interpretation → return cut → evidence check → choice.**

This is a composition of reasoning operations, not a multiplication that turns language into a truth score. The matrix configures the inquiry; the evidence constrains its conclusions. A weighted average of opinions does not substitute for either.

The useful output is a newly visible choice: a premise to test, a cost to acknowledge, an authority to name, or an alternative to try. Its value is a design hypothesis, not an established gain in accuracy. If it is wrong, the earliest sign will be more compelling explanations with no better evidence and no changed decision.

There is a particular trap in describing all this with a matrix. We might begin to enjoy the authority of the notation. What was a choice about where to look could return as a number that appears to have chosen for us.

The Zizkian must therefore be applied to the Zizkian. Who chose the axes? Who set the weights? Which client benefits from this framing? What evidence would make us abandon it?

We have built an instrument for making hidden choices inspectable. Its first obligation is to show its own.

---

The term Zizkian names this project-specific construction, not an attributed theory of Slavoj Žižek. See the [attention matrix](attention-matrix.yaml) and [method](method.md).

### A compact formal definition

Let `x` be the brief, observations and constraints, `E` the evidence record, `W`
the attention matrix, and `s` a selection mask over lenses. Each row `W_l` directs
an evidence-aware inquiry `T_l`. Let `S` synthesize the active inquiries while retaining
disagreements, `R` apply the return cut, and `D_E` check the interpretation against
the evidence and produce a choice or a request for missing evidence.

```text
Z(W, s, E; x) = D_E(R(S({T_l(x; W_l, E) | s_l = 1}), x, E), x)
```

This defines an interface, not a numerical implementation. The functions act on
structured language, not measured quantum states. No linearity, commutation,
Hermiticity or calibrated probabilities are asserted. Altering `W` changes the
questions considered; it cannot alter `E`. `D_E` can return “retain the original
brief” or “insufficient evidence,” which prevents compulsory contrarianism.

Both `T_l` and `R` may return “no warranted finding.” Evidence gates an inversion
before it enters the synthesis. If the selected inquiries find no supported
reason to reframe the question, the composition retains the original brief;
an empty finding does not trigger a search for a more dramatic one.

### The return cut, applied

Our subsequent cross-model discussion challenged the construction itself.
The numerical weights have no operational role in the working prompts. Replacing
them with primary, secondary and background would preserve their entire current
meaning. We retain the matrix here as an illustration of an authored choice;
it is excluded from professional recommendations. It has earned no authority
over the client.

Removing its numbers would not remove the bias in selecting the lenses. A client
must be able to reject the interpretation without the operator treating that
rejection as a new symptom. Otherwise a device for exposing assumptions becomes
a device that cannot hear “no.”

The practical core is smaller than the notation: state the decision, check the
ordinary explanation, name what could disprove the interpretation, and record
whether any action changes. No finding allows closure. Whether this core adds
anything beyond a plain decision checklist remains an open empirical question.

Explain a topic to Jeremy in plain English so he walks away with a real grasp of it.

The topic is: **$ARGUMENTS**

If `$ARGUMENTS` is empty, ask him what he wants explained — one line, no filler.

## How to explain

Pitch it like you're talking to a smart 10-year-old who already gets computers. Not condescending, not dumbed down — just *clear*. Strip the jargon. Keep the rigor.

Follow this recipe:

1. **One-sentence definition.** No new jargon inside the sentence. If you have to use a term he might not know, define it inline in three words or fewer.
2. **The problem it solves.** What was the world like *without* this thing? Why did someone bother inventing it? This is the part that makes it stick.
3. **A concrete example.** Real, not hand-wavy. If it's code, show 3-8 lines max. If it's a concept, use a physical analogy (lockers, mailboxes, restaurant kitchens, sticky notes — whatever maps cleanly). One example is better than three.
4. **Where it bites you.** The one or two gotchas, footguns, or "wait, but what about…" moments that someone learning this hits. Naming the trap is what separates "heard of it" from "actually understands it."
5. **When you'd reach for it.** A one-line "you'd use this when…" so he knows where it lives in the toolbox.

## Hard rules

- **Length cap: ~250 words.** If you're going long, you're explaining badly. Cut.
- **One example, not three.** If you're tempted to add a second, the first one isn't good enough — replace it instead.
- **No headers like "Definition" / "Example" / "Gotchas."** Let the structure flow as prose. The recipe is for *you*, not the output.
- **No "Great question!", no "Let's dive in!", no recap of what he asked.** Just start with the answer.
- **No bullet-list dump of every fact you know.** Pick the load-bearing ideas. Leave the rest.
- **Assume he can ask a follow-up.** You don't need to preempt every edge case.

## After the explanation

End with exactly one line offering a next step, picked from:

- "Want me to save this as a note?" — when the topic is something he'll want to come back to (foundational concept, gotcha-heavy, hard-won knowledge). On yes, hand off to `/note` with the full explanation as the content.
- "Want to go one layer deeper on [the specific subtopic that's worth more depth]?" — when there's an obvious next rabbit hole the explanation skipped.
- "Want a worked example in your own codebase?" — when the concept is something he'd actually wire up in `~/workspace/`.

Pick the one that actually fits. Don't list all three. If none fit cleanly, omit the offer entirely — a clean ending beats a forced upsell.

## Worked example: `/explain terraform keepers`

> A `keeper` is a map you attach to a `random_*` resource that tells Terraform "regenerate this random value whenever any of these inputs change."
>
> Without keepers, `random_id` and friends generate a value once and then *cling* to it forever — even if the thing that value was tied to (a DB name, an instance, a bucket) gets replaced. So you end up with a stale random suffix on a brand-new resource, and your "unique" name silently isn't unique anymore.
>
> ```hcl
> resource "random_id" "bucket_suffix" {
>   keepers = {
>     bucket_name = var.bucket_name
>   }
>   byte_length = 4
> }
> ```
>
> Change `var.bucket_name` → Terraform sees the keeper changed → it rolls a new random ID → the bucket gets a fresh suffix. Don't change it → the suffix stays put across `apply`s.
>
> The trap: keepers cause *replacement*, not just a value refresh. If a downstream resource depends on that random value, it'll get destroyed and recreated too. So keep the keeper inputs narrow — only the things that *should* trigger a rebuild.
>
> You'd reach for keepers any time a random value needs to stay coupled to the lifecycle of something else, instead of drifting independently.
>
> Want me to save this as a note?

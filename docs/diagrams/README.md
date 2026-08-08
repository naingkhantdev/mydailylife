# Standalone diagram sources

Each `.mmd` file holds **one** diagram and nothing else — no headings, no prose, no code fences.

Use these when your tool renders *Mermaid source* rather than *markdown containing Mermaid*. Pasting
a whole `.md` file into such a tool fails with:

```
No diagram type detected matching given configuration for text: # RoutineSync — ...
```

…because the renderer is trying to read the markdown heading as a diagram.

| Want to read the diagrams with commentary | Want to open one diagram in a viewer |
| --- | --- |
| [`../sequence-diagrams.md`](../sequence-diagrams.md), [`../flowcharts.md`](../flowcharts.md) — renders on GitHub | the `.mmd` files here — paste into [mermaid.live](https://mermaid.live) or open in a Mermaid plugin |

The `.mmd` files are extracted from the two markdown documents, so those remain the source of truth:
if you change a diagram, change it there and re-extract.

## Files

| File | Same as |
| --- | --- |
| `seq-01-one-session-end-to-end.mmd` | sequence-diagrams.md, overview |
| `seq-02-cold-start-and-the-splash-gate.mmd` | stage 01 |
| `seq-03-signing-in-two-ways.mmd` | stage 02 |
| `seq-04-provider-hydration-uid-in-data-out.mmd` | stage 03 |
| `seq-05-marking-a-routine-done-or-missed.mmd` | stage 04 |
| `seq-06-meals-notes-and-the-save-queue.mmd` | stage 05 |
| `seq-07-gym-plan-technique-library-live-session.mmd` | stage 06 |
| `seq-08-reading-it-back-history-and-dashboard.mmd` | stage 07 |
| `seq-09-sign-out-and-account-teardown.mmd` | stage 08 |
| `flow-01-screen-and-navigation-map.mmd` | flowcharts.md, chart 01 |
| `flow-02-launch-and-routing-decision.mmd` | chart 02 |
| `flow-03-sign-in-decision-tree.mmd` | chart 03 |
| `flow-04-layers-widget-to-firestore.mmd` | chart 04 |
| `flow-05-provider-dependency-graph.mmd` | chart 05 |
| `flow-06-controller-hydration-decision.mmd` | chart 06 |
| `flow-07-the-daily-log-save-queue.mmd` | chart 07 |
| `flow-08-gym-technique-migration-and-plan-derivation.mmd` | chart 08 |
| `flow-09-marking-a-routine.mmd` | chart 09 |

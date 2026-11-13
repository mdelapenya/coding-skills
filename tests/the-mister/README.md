# the-mister evaluation fixtures

Synthetic cases for comparing the current and revised `the-mister` skill on behaviour, not on how its text reads. Each case is a small Go module and a request; each one exercises a way a squad can miss something a whole-change review should catch. Nothing here comes from a real project.

| Case | Request in short |
|---|---|
| `c01-retry` | Raise a client timeout so transient failures stop surfacing |
| `c02-email` | Store email addresses normalised |
| `c03-timeout` | Add a configurable request timeout, config and client |
| `c04-rounding` | Fix price rounding; the existing test must cover it |
| `c05-list` | Add a sorted `List(prefix)` to every key-value store |
| `c06-checks` | Strip punctuation from slugs; account for everything CI checks |
| `c08-stale` | Add `Reverse` and commit it |

How to run them is in `PROTOCOL.md`. The expected outcomes are deliberately not in this repository: whoever runs the cases must not see them first.

# HEDGE legacy scheduler: evidence, oracle, and target engine contract

Assessment date: 2026-10-05 (Asia/Jakarta). Branch: `devmode`. Source commit: `d8edf44c45625bc93d2716e0e8e1c6c6265b3afe`.

This file is an analysis artifact. Production source is unchanged and no Flutter implementation has been created. **F** means an observed source fact or reproduced output; **I** means inference; **R** means a proposed target design. Reproducing a known defect does not approve it as a HEDGE v2 business rule.

## Evidence and reproducibility

- [app.js](../../app.js): source of rules and state transitions.
- [legacy-scheduler-reference.json](legacy-scheduler-reference.json): 53 cases with complete inputs and exact expected outputs, including errors, metadata and side-effect traces where relevant.
- [verify-legacy-oracle.mjs](verify-legacy-oracle.mjs): extracts named original function bodies into `node:vm`; no copied scheduler implementation, network request, actual DOM, production mutation, real audio, or timer execution.

Run from the repository root using Git Bash/zsh:

```bash
git branch --show-current
pnpm exec node docs/migration/verify-legacy-oracle.mjs
```

The harness checks `devmode` and the normalized-LF SHA-256 of the complete original `app.js` before comparing all fixtures. It also records raw-byte SHA-256, function spans and capture commit. Normalized hashing allows equivalent CRLF/LF checkouts; other source changes require review, not automatic fixture replacement. `--record` is available only for explicitly reviewed baseline regeneration.

The captured run passed **53/53** cases. Raw source SHA-256: `b2e7547a7ebdb817a55fdc0bde95b146866060a1db9ef4a0a5a4bd1085084bba`.

On this Windows sandbox the bundled pnpm initially failed while resolving the host TEMP short path. Pointing temporary-directory variables to an existing workspace directory let the same command run without escalation:

```bash
TMPDIR=D:/MINE/HEDGE/docs/migration \
TEMP=D:/MINE/HEDGE/docs/migration \
TMP=D:/MINE/HEDGE/docs/migration \
pnpm exec node docs/migration/verify-legacy-oracle.mjs
```

Scope limitation: these are function-level characterization tests, with presentation/audio side effects stubbed. They do not prove browser rendering, acoustic delivery, background execution, service-worker behavior, platform notification delivery, or an approved target policy. IDs are deterministic in constructor/migration tests because `Math.random` is fixed to `0.125`. Dates use an injected local wall clock rather than real current time. Simple ASCII route names avoid environment-dependent locale ordering in the fixtures.

## End-to-end data path

**F:** `loadState` (117–192) creates/normalizes each route using `createRouteObject` (11–86). A route owns `masterUnits`, `departureOrder`, operation parameters, alarm settings and a committed snapshot. Parameter and roster edits persist the mutable route and call `markDirtyIfCommitted` (250–257), but do not regenerate departures. `buildScheduleForRoute` (1672–1726) derives an ordered roster, computes a timeline, and assigns departures round-robin. `generateScheduleForRoute` (1728–1748) replaces the committed snapshot, clears dirty and saves. `reconstructDisplaySchedule` (1750–1765) reads the committed snapshot rather than draft inputs. Rendering (1767–1847), exports, combined board and alarm consume committed departures. Recalculation (1914–2015) mutates that same snapshot in place, preserving planned history.

**I:** The current committed snapshot is the operational source of truth for planned departures, whereas editable route configuration is a draft. There is no actual dispatch-event ledger in this path. The implementation calls elapsed planned rows “history” and “completed”; those terms do not demonstrate that a vehicle physically departed.

## Exact inputs and validation boundaries

| Input | Actual rule / source |
| --- | --- |
| `masterUnits` | Route-local `{id, number, active}`. Constructor converts numbers to strings and repairs missing/duplicate IDs; does not reject duplicate displayed numbers (11–38). |
| `departureOrder` | Ordered IDs. Builder uses strict `x.id === id`; inactive/missing matches disappear. Constructor can map number or ID and appends missing active units (44–55). Rendering order also repairs missing active members and saves (1438–1445). Neither deduplicates repeated order IDs. |
| `ritase` | Builder `parseInt(value) || 1` (1679). UI constrains to 1–30 (901–910), but imported state bypasses this clamp. Zero becomes one; negative values survive. |
| operation window | `toMinutes` splits `HH:mm` without validation (1530). Builder rejects `end <= start` (1683–1684), thus overnight operation is unsupported. Invalid/noncanonical time may throw downstream or wrap when displayed. |
| peak configuration | Exactly two configured windows if enabled; intervals `parseInt(value) || 1` (1687–1690). UI constrains each to 1–60 (931–940). Timeline clamps interval at least one, not at most sixty. |
| `groupOrder` | `slow-first` groups larger gaps first; every other value uses smaller gaps first. It affects interval order, not unit departure order (1547–1549, 1624–1626). |
| route visibility | `activeInSchedule !== false` includes a route in generate-all, merge, and alarm; it is not a scheduler input. Direct builder can compute a hidden route (1881, 2086, 2634). |
| route identity/appearance | Rows duplicate route ID, name, color. They retain displayed unit number, not stable unit ID (1701–1711). |

**F:** Empty active ordered roster returns a user-visible error. Same/reversed operation times return a user-visible error. `buildTimeline` always returns `error:null`; there is no feasibility, resource, or malformed-import validation. `N` is number of matching order entries, including repeated IDs, not guaranteed distinct active vehicles.

## Non-peak interval distribution

Let `N = ordered active entry count`, `R = parsed ritase`, `D = N*R`, `T = end-start` minutes and `G = D-1` gaps (1539–1557).

For `G > 0`:

```text
low = floor(T / G)
high = low + 1
highCount = T - low*G
lowCount = G - highCount
gaps = low repeated lowCount, then high repeated highCount  // fast-first
// slow-first reverses those two groups
offsets = [0] followed by cumulative sums of gaps
last offset = T
```

**F:** First departure is operation start and final departure is operation end when `D > 1`. With `D == 1`, timeline returns only `[0]`, so the single departure occurs at start. When `G > T`, `low == 0` and zero-minute/simultaneous departures are valid legacy output. Gaps are grouped, not alternated or balanced through the day.

**F:** For the shipped JAK.115 default, 39 ordered units × 8 rounds = 312 departures over 1020 minutes: 224 three-minute gaps followed by 87 four-minute gaps. This is fixture `default-jak115-nonpeak`, not a workload benchmark.

## Peak algorithm and assumptions

**F:** Peak processing (1560–1647) performs these steps:

1. Clamp every peak start/end to operation boundaries; discard zero/reversed windows; sort by start.
2. Merge overlapping **and touching** windows (`next.start <= last.end`). Use union of the windows and the minimum interval for the entire union. A short overlapping fast segment makes the full merged period fast.
3. Split operation time into alternating absolute off-peak and peak segments.
4. Peak gap count is `max(1, round(segment.duration / requestedInterval))`.
5. `remainingGaps = D-1 - sum(peakGapCounts)`.
6. If remaining gaps and off-peak duration are positive, allocate off-peak gap counts by duration using floor plus largest remainder. Ties follow segment order in the current stable JS sort.
7. Otherwise assign zero gaps to all off-peak segments. If positive gaps remain and no usable off-peak area exists, add all of them to the last peak segment.
8. Peak intervals repeat the requested interval exactly. Off-peak intervals use the same floor/ceiling grouping as non-peak computation.
9. Concatenate interval arrays using a cumulative cursor beginning at **zero**, ignoring absolute segment positions after allocation. Zero-gap segments consume **no time**.
10. Pad offsets with operation end if too short; truncate if too long; overwrite final offset with operation end.
11. Tag peak by first render segment satisfying `segment.start <= offset <= segment.end` (1650–1653).

**F:** Render segments are formed before padding/truncation/end overwrite. Thus their labels/interval arrays need not match final rows. Rounding peak gap count means actual peak segment duration becomes `gapCount*interval`, not its configured duration. End overwrite hides total-duration mismatch in the last departure; it can create very large or negative final gaps.

**I:** The algorithm tries to meet all three of fixed ritase/departure count, fixed peak spacing, and fixed last departure time, but these constraints can conflict. It has no rule for explicitly reporting or resolving that conflict. There is no input for travel time, vehicle turnback duration, minimum turnaround, driver break, terminal occupancy, capacity, or shared vehicle assignment. A valid generated row therefore does not establish operational fleet feasibility.

## Ritase and vehicle order

**F:** For departure index `i`, displayed vehicle is `units[i % N]` and `ritase = floor(i / N)+1` (1695–1704). Every ordered roster entry receives R rows. There is no per-unit custom target or per-unit readiness constraint. `interval` means the gap to the **next departure on that route**, not time until that vehicle returns, and remains route-local even when rows are merged on a terminal board.

**I:** The displayed concept of one ritase here is one ordinal departure for each roster member in a round. Whether business users mean a complete physical round trip must be confirmed; the implementation does not model a physical return or paired outbound/inbound trips.

## Commit, dirty state and multi-route behavior

**F:** The snapshot contains rows, N, R, operation labels, peak flag and render segments, plus optional recalc boundary/label. It has no service date, revision ID, author, config hash, actual-dispatch status, or durable alert delivery identity (1734–1744). Dirty is a separately persisted Boolean; equality with snapshot configuration is not recomputed. Editing back to the original value still marks dirty. Dirty snapshot remains available to export, board and alarms.

**F:** Generate-current asks before replacing nonempty committed rows (1854–1857). Generate-all asks once, computes each visible route independently, saves after each success and leaves failed routes' old snapshots untouched (1877–1908). This is a partial-success operation, not an atomic terminal-wide commit. There is no collision prevention across routes.

**F:** `buildCombinedSchedule` (2082–2116) concatenates nonempty visible committed rows, overlays current route name/color/id, sorts by displayed time then route-name `localeCompare`, and sets `combinedNo`. Original per-route `no`, `ritase` and outgoing interval remain. Same-minute departures from different routes are permitted. Equal-time/equal-name order relies on stable array sort; locale comparison is environment dependent for non-ASCII names.

**F:** Hiding a route keeps its snapshot but excludes it from board/alarm/generate-all. The UI prevents removing the last visible route (378–398); `getActiveRoute` forcibly makes the first route visible if none are visible (202–218). Switching a hidden route may fall back to a different visible route because selection and visibility are coupled (561–597).

## Remaining schedule recalculation

**F:** Recalculation (1914–2015):

```text
require committed rows
nowMinute = local clock hour*60 + minute    // seconds discarded
require committedStart < nowMinute < committedEnd
history = committed rows with row.time <= nowMinute
completedCount[unit NUMBER] = count(history rows for that number)
R = committed.R                           // draft ritase is ignored
orderedActive = CURRENT roster and departure order
remaining[unit] = max(0, R-completedCount[unit.number])
queue = repeated passes through orderedActive with remaining>0
        assigning ritase completedCount+1, then +1 on each pass
timeline = buildTimeline(nowMinute, committedEnd, queue.length,
                         CURRENT peak policy and groupOrder)
future starts at nowMinute; numbering starts after history length
committed.rows = history + future
set recalc boundary and label; update N to active entry count
clear dirty, save, reset alarms, redraw
```

**F:** No remaining entries truncates rows to history but does not update N or segment metadata. Normal path also keeps original `segmentsInfo`, start/end labels, R and snapshot peak flag even when current peaks differ. History rows are reused unchanged, including their outgoing interval, although the next row has moved. New units receive full committed R from now; inactive/deleted units retain past rows but lose future rows. Duplicate displayed numbers share completed counts.

**F:** `completedCount` is a plain `{}` indexed by arbitrary displayed unit numbers (1928–1929). A unit called `__proto__` is accepted by the UI/constructor but collides with an inherited property; remaining count becomes `NaN`, so its future row silently disappears. Fixture `remaining-prototype-unit-number` reproduces this. Target counts must use stable IDs and a typed map, not user labels as object property keys.

**F:** At exact row boundary `05:08`, a row at `05:08` enters history and first future row also occurs `05:08`. At `05:10:30`, new first row is `05:10:00`, in the past relative to actual seconds. Changing draft R from 2 to 4 and end from `05:20` to `05:30` still yields remaining rows targeted at committed R=2/end=`05:20`; dirty is cleared despite those unapplied changes.

**R:** Make recalculation an explicit command carrying clock, original revision, accepted policy and immutable actual/preserved history. A proposed revision should explain removed, retained, moved and added rows. The user commits that revision transactionally. Pending alarms for changed rows reconcile by stable departure ID. Do not equate acknowledgement of an alarm with vehicle departure.

## Alarm and board characterization

**F:** Alarm (2629–2669) checks every second but matches exact `HH:mm`, at any second in that minute. Only visible alarm-enabled routes with committed rows participate. A key `routeId|row.no|row.time|unit.number` prevents repeated firing until runtime reset. It has neither service date nor revision identity and is not persisted. Missed minutes have no catchup. Regeneration/recalc resets all routes' fired keys, so another check in the same minute can refire.

**F:** Preparation countdown uses the current date plus row clock time, rounds seconds, and starts sound when `0 < seconds <= activeRoute.alarmPrepSeconds` (2247–2292). On the combined board it still uses the **selected route's** setting rather than the next departure's route. It does not check `alarmEnabled`, so disabled departure alarm does not disable preparation sound.

**F:** Due alarm rows carry per-route `_idx` (2647). `updatePapanHighlight` uses that index directly against the current board, including combined board (2304–2312). The global `lastDismissedIdx` has the same mismatch. Fixture `combined-alarm-index-local-vs-global` selects A at `05:00` when B's `05:02` alarm has local index zero. After dismissal, fixture `combined-dismiss-index-local-vs-global` selects B's same `05:02` row again.

**R:** Derive board selection/countdown from absolute departure instant and stable departure ID; keep visual selection separate from alert delivery and actual dispatch status. Persist notification reconciliation identity `(serviceDate, revisionId, departureId, alertKind)`. Native notification/background integration needs separate capability tests; a deterministic scheduler oracle does not validate OS delivery.

## Concrete reference outputs

Each compact sequence below omits route metadata; complete arrays are in the JSON fixture.

| Fixture / input | Reproduced output |
| --- | --- |
| `single-route-nonpeak`; A,B,C; R=2; 05:00–05:20 | A1 05:00, B1 05:04, C1 05:08, A2 05:12, B2 05:16, C2 05:20. |
| `fractional-fast-first`; same, end 05:23 | 05:00, 05:04, 05:08, 05:13, 05:18, 05:23. Gaps 4,4,5,5,5. |
| `fractional-slow-first`; same, end 05:23 | 05:00, 05:05, 05:10, 05:15, 05:19, 05:23. Gaps 5,5,5,4,4. |
| `custom-departure-order`; C,A,B | C1 05:00, A1 05:04, B1 05:08, C2 05:12, A2 05:16, B2 05:20. |
| `inactive-unit-filter`; ordered C,B,A; B inactive | C1 05:00, A1 05:06, C2 05:13, A2 05:20. |
| `peak-balanced`; A,B,C; R=3; peak 05:04–05:08/2m | 05:00,02,04,06,08,11,14,17,20. `05:04` is tagged offpeak; `05:08` peak. |
| `peak-only-negative-headway`; R=2; whole-window peak /10m | 05:00,10,20,30,40,20; outgoing gap at 05:40 is **−20m**. |
| `default-jak88-peak-shift`; shipped defaults | First peak renders 05:30–08:02, instead of configured 06:00–08:30. Next peak renders 16:02–18:32, instead of 16:30–19:00. Rows at 08:02 and 12:02 have 240m outgoing gaps; final outgoing gap is 178m. |
| `remaining-between-departures`; now 05:10:30 | History A1 05:00, B1 05:04, C1 05:08; future A2 05:10, B2 05:15, C2 05:20. C1 retains recorded gap4m although next row is two minutes later. |
| `remaining-new-unit-old-target`; current C,A,D; draft R4/end05:30 | History A1,B1,C1; future C2 05:10, A2 05:13, D1 05:16, D2 05:20. |
| `midnight-window-invalid`; 23:00–01:00 | Explicit end-after-start error; overnight operation is not supported. |
| `malformed-time-throws`; start `bad` | `RangeError: Invalid array length`, rather than typed validation error. |
| `alarm-skipped-minute-no-catchup`; ticks04:59:59 then05:01 | No 05:00 alarm event. |

## Defect and ambiguity register

| Finding | Evidence | Impact / disposition |
| --- | --- | --- |
| Negative/nonmonotonic peak timeline | 1608–1611, 1643–1645; fixture `peak-only-negative-headway` | High; retain oracle, propose explicit feasibility rejection/approved policy before production engine release. |
| Absolute peak windows shift / zero-gap segments disappear | 1590, 1621, 1635–1639; shipped JAK.88 fixture | High; semantics must be specified in absolute service time. |
| Peak start/end tags use previous segment | 1650–1652; `peak-boundary-label` | Medium; choose documented half-open boundary semantics for target, do not silently overwrite baseline. |
| Planned elapsed rows are treated as completed trips | 1927–1939 | High product ambiguity; decide whether actual dispatch recording is required before naming an event completed. |
| Recalc ignores dirty R/end yet clears dirty | 1931, 1978, 2004 | High; command must identify accepted config revision and unapplied changes. |
| Historical gap and segment metadata become stale | 1943–1946, 2000–2004 | Medium; derive display gaps from immutable rows; revise metadata alongside proposal. |
| Duplicate order and duplicate displayed number | 44–55, 1673–1676, 1929 | High; require unique membership by stable unit ID and quarantine ambiguous migration records. |
| Alarm/combined board indexes do not share identity | 2304–2312, 2647 | High; move to stable departure IDs. |
| Alarm missed on suspended/throttled runtime | 2638, 2668 | High; native capability and reconciliation design, with bounded late-alert policy. |
| Service date absent, alarm dedup volatile | 1734–1744, 2639–2641 | High; explicit service date/revision and persistent alert state. |
| Negative/imported values and malformed time not validated | 1530, 1679, 1684 | High; parser validation and typed domain failures. |
| Dense zero gaps, single departure start, overnight rejection | 1542, 1545–1549, 1684 | Business ambiguity; document policy decisions, not blanket “bug fixes”. |
| Route clone resets order and inconsistent alarm copying | 710–712 versus 817–819 | Medium; target duplicate command must explicitly copy configuration/order policy, never historical revision. |
| Corrupt v5 suppresses valid v4 fallback | 117–191; migration oracle | High recovery risk; backup originals, independent version parser and explicit fallback diagnostics. |
| Generate-all partially commits routes | 1887–1891 and 1746 | Medium; preserve partial-success behavior only with clear per-route results, or approve atomic terminal revision. |

## Target pure domain engine contract (recommendation)

Do not port the DOM-IIFE to Dart. Use a bounded scheduling module with these input/output contracts:

```text
GenerateSchedule(
  revisionId, engineVersion, serviceDate, operatingWindow,
  orderedUnitIds, perUnitTargets or validated commonTarget,
  peakPeriods, intervalGrouping, feasibilityPolicy
) -> ScheduleProposal OR typed SchedulingFailure

ReplanRemaining(
  acceptedRevision, preservedHistory, actualDispatchEvents if adopted,
  explicitNowInstant, acceptedConfig, activeOrderedUnitIds,
  historyBoundaryPolicy
) -> RevisionProposal OR typed SchedulingFailure
```

**R:** Value objects validate canonical times and ranges. Store dates and IANA zone (`Asia/Jakarta` as deployment default) separately from local service-minute offsets. A service-minute type can represent next-day values only if overnight service is approved; accepting `25:00` accidentally is not overnight support. Clock, IDs, zone resolution and platform adapters belong outside the engine. Explicit values make results deterministic.

**R:** For ordinary valid non-peak input, keep the observed floor/ceiling grouped allocation and round-robin order. Implement an integer allocation function reused by domain strategies and keep unit IDs in departures. Derive display labels and outgoing gaps from resulting immutable instants. A schedule revision owns accepted configuration/hash/version and immutable departures; a route configuration edit creates draft data, not a mutation of the committed revision.

**R:** Before choosing a peak strategy, determine precedence among exact target count, requested peak spacing and fixed operation endpoints. Recommended default is exact per-unit target plus monotonic feasible departure times; peak spacing should be an explicit configurable constraint/preference. Reject contradictory hard constraints with diagnostics identifying required/available gaps. Never truncate a timeline or force an end timestamp backwards. This recommendation requires an ADR and business approval before behavior-equivalence requirements change.

**R:** Target invariants should include unique unit membership, valid unit IDs, nonnegative durations, strictly nondecreasing departure instants (or strictly increasing if same-route simultaneity is disallowed), no departure beyond approved window, exact target count for feasible inputs, unambiguous peak membership, no outgoing gap inconsistent with adjacent rows, preserved committed history, and revision identity. A future real dispatch ledger adds separate invariants for transitions and idempotent actual-departure records. These are proposed correctness rules; the legacy does not satisfy all of them.

**R:** Layer allocation:

| Layer | Legacy responsibilities to extract |
| --- | --- |
| Domain | Validated window/peak/roster objects, interval allocation, order/ritase assignment, pure generation and replanning, feasibility/invariants. Candidates: `buildTimeline`, `isPeakAtOffset`, calculation part of `buildScheduleForRoute`, queue construction in `recalcRemaining`, time/value parsing. |
| Application | Generate/commit/replan commands, accepted revision lifecycle, draft dirty comparison, roster changes, alert reconciliation, combining query results. Candidates: `generateScheduleForRoute`, orchestration of `recalcRemaining`, mutation policies currently in event handlers. |
| Infrastructure | Versioned legacy import/export, local transaction/repository, clock/timezone adapter, notification/audio adapters. Candidates: `loadState`, `saveState`, constructor recovery, alarm platform side effects. |
| Presentation | Rendering, route selection, forms, drag order interaction, active/combined board highlighting, clock text and countdown view. Candidates: `render`, `renderOrderList`, `updatePapanCountdown`, `updatePapanHighlight`. Pure countdown time arithmetic may be shared with application/domain values; DOM stays here. |

## Migration test gate

1. Keep the checked-in legacy oracle immutable. Run it against unchanged source; detect source drift before regeneration.
2. Classify each reference as preserved behavior, bug reproduction, or business ambiguity. JSON includes `approvedBehaviorChanges: []` deliberately.
3. Implement pure Dart engine in the later implementation phase, then import the same language-neutral inputs/expected output. Compare canonical unit identity, local minute offsets, row order, ritase, intervals and peak labels. Route metadata/presentation maps can be tested separately.
4. Ordinary baseline cases must remain equivalent. Known defects become explicit negative tests asserting a typed error or approved correction; the approved rule, ADR, old output and new output must be retained together. Do not “update goldens until green”.
5. Add property tests beyond characterization: deterministic repeat, exact count, unit membership, monotonic time, endpoint behavior, no out-of-window departures, interval consistency, preserved history, import idempotency and bounded allocation.
6. Run repository/application tests for atomic commit and dirty lifecycle; platform tests for lifecycle/background/catchup/dedup; widget tests for active/combined row identity and touch operation. VM tests do not replace these.
7. Roll out after dispatcher-reviewed samples and side-by-side exports agree for approved baseline rules. Keep a versioned legacy importer and rollback-readable revisions during initial production rollout.

Genuine product decisions that cannot be inferred from source: hard versus advisory peak headway; whether an elapsed planned row is sufficient to count a completed ritase; allowed same-route simultaneous departures; whether service can cross midnight; whether terminal-wide collision spacing or vehicle turnaround constraints apply. The code provides current behavior but no evidence resolving those intended business policies.

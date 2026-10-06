// Analysis harness only. Executes named functions extracted from unchanged app.js.
// Verify: pnpm exec node docs/migration/verify-legacy-oracle.mjs
// Intentionally re-record after reviewing source changes: add --record.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const root = fileURLToPath(new URL('../../', import.meta.url));
const sourcePath = new URL('../legacy/app.js', import.meta.url);
const fixturePath = new URL('./legacy-scheduler-reference.json', import.meta.url);
const bytes = readFileSync(sourcePath);
const source = bytes.toString('utf8').replace(/\r\n/g, '\n');
const lines = source.split('\n');
const spans = [
  ['createRouteObject', 11, 86], ['defaultState', 88, 115],
  ['loadState', 117, 192], ['saveState', 194, 198],
  ['getActiveRoute', 202, 218], ['markDirtyIfCommitted', 250, 257],
  ['toMinutes', 1530, 1530], ['toHHMM', 1531, 1535],
  ['buildTimeline', 1539, 1648], ['isPeakAtOffset', 1650, 1653],
  ['buildScheduleForRoute', 1672, 1726],
  ['generateScheduleForRoute', 1728, 1748],
  ['reconstructDisplaySchedule', 1750, 1765],
  ['recalcRemaining', 1914, 2015], ['buildCombinedSchedule', 2082, 2116],
  ['updatePapanCountdown', 2247, 2292], ['updatePapanHighlight', 2296, 2329],
  ['resetAlarmTracking', 2406, 2413], ['checkAlarmTriggers', 2629, 2653],
];
for (const [name, first, last] of spans) {
  assert.match(lines[first - 1], new RegExp(`function ${name}\\(`), `Source span drift: ${name}`);
  assert.ok(last >= first);
}
const extracted = spans.map(([, first, last]) => lines.slice(first - 1, last).join('\n')).join('\n');
const sourceHash = createHash('sha256').update(bytes).digest('hex');
const normalizedSourceHash = createHash('sha256').update(source).digest('hex');
const git = (...args) => execFileSync('git', args, { cwd: root, encoding: 'utf8' }).trim();
assert.equal(git('branch', '--show-current'), 'devmode', 'Run this repository task only on devmode');

const clone = value => JSON.parse(JSON.stringify(value));
const unit = (number, active = true, id = `u${number}`) => ({ id, number: String(number), active });
const route = (overrides = {}) => ({
  id: 'rA', name: 'A', color: '#FFB020',
  masterUnits: [unit('A'), unit('B'), unit('C')],
  departureOrder: ['uA', 'uB', 'uC'],
  jamMulai: '05:00', jamSelesai: '05:20', ritase: 2, groupOrder: 'fast-first',
  peakEnabled: false, peak1Start: '05:04', peak1End: '05:08', peak1Interval: 2,
  peak2Start: '08:00', peak2End: '09:00', peak2Interval: 3,
  alarmEnabled: true, alarmPrepSeconds: 10, alarmDuration: 8,
  activeInSchedule: true, committedSchedule: null, scheduleDirty: false,
  ...overrides,
});
function at(hhmmss = '05:10:00') {
  const [h, m, s = 0] = hhmmss.split(':').map(Number);
  return new Date(2026, 9, 5, h, m, s, 0).getTime();
}
function makeContext(time) {
  let clock = at(time);
  const storage = new Map();
  const events = [];
  const calls = [];
  const classSet = () => {
    const values = new Set();
    return { values, add: (...v) => v.forEach(x => values.add(x)),
      remove: (...v) => v.forEach(x => values.delete(x)),
      contains: v => values.has(v),
      toggle: (v, on) => (on ? values.add(v) : values.delete(v)) };
  };
  const element = () => ({ classList: classSet(), textContent: '', innerHTML: '' });
  class ControlledDate extends Date {
    constructor(...args) { super(...(args.length ? args : [clock])); }
    static now() { return clock; }
  }
  const deterministicMath = Object.create(Math);
  deterministicMath.random = () => 0.125;
  const context = vm.createContext({
    Date: ControlledDate, Math: deterministicMath,
    console: { warn: (...args) => calls.push(['warn', String(args[0])]) },
    STORAGE_KEY: 'jadwalApp_multi_v5', LEGACY_STORAGE_KEY: 'jadwalApp_v4',
    ROUTE_PALETTE: ['#FFB020', '#6FB4FF', '#50E3C2', '#E066FF', '#FF7A45', '#FFE066', '#FF5370', '#82AAFF'],
    DEFAULT_UNITS_JAK115: [1000, 1001, 5, 6, 7, 8, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 756, 88, 92, 23, 24, 25, 26, 27, 28, 29, 30, 31, 33, 34, 35, 36, 2, 4, 79, 97, 3],
    DEFAULT_UNITS_JAK88: [101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 112, 114],
    localStorage: { getItem: key => storage.get(key) ?? null,
      setItem: (key, value) => { storage.set(key, value); calls.push(['save', key]); } },
    state: { activeRouteId: 'rA', routes: [], papanMode: 'active' },
    lastSchedule: null, firedRowKeys: new Set(), activeAlarmRows: [],
    lastDismissedIdx: -1, alarmAutoStopTimer: null,
    countdownWarningActive: false, lastPapanNextIdx: null, papanMode: 'active',
    papanCountdownBar: element(), papanCountdownLabel: element(),
    papanCountdownUnit: element(), papanCountdownTime: element(),
    alarmOverlay: element(), papanOverlay: element(),
    papanBoardBody: { querySelectorAll: () => [] },
    resultSection: { scrollIntoView: () => calls.push(['scrollIntoView']) },
    showToast: (msg, type) => calls.push(['toast', msg, type ?? null]),
    showError: msg => calls.push(['error', msg]),
    render: () => calls.push(['render']),
    renderDirtyBanner: () => calls.push(['dirtyBanner']),
    renderRouteBar: () => calls.push(['routeBar']),
    refreshPapanIfOpen: () => calls.push(['refreshPapan']),
    stopAlarmSound: () => calls.push(['stopAlarmSound']),
    clearTimeout: () => {},
    addRowsToAlarm: rows => events.push(clone(rows)),
    startCountdownWarningSound: () => calls.push(['prepSoundStart']),
    stopCountdownWarningSound: () => calls.push(['prepSoundStop']),
    navigator: { vibrate: pattern => calls.push(['vibrate', clone(pattern)]) },
    escapeHtml: value => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;'),
    centerPapanHighlight: () => {},
  });
  vm.runInContext(extracted, context, { filename: 'app.js-extracted-legacy', timeout: 1000 });
  return { context, storage, events, calls,
    setTime: timeValue => { clock = at(timeValue); },
    now: () => new ControlledDate(),
  };
}
function execute(input) {
  const harness = makeContext(input.now);
  const { context: c, storage, events, calls } = harness;
  try {
    if (input.kind === 'migration') {
      for (const [key, value] of Object.entries(input.storage)) storage.set(key, typeof value === 'string' ? value : JSON.stringify(value));
      const state = c.loadState();
      return clone({ state, calls });
    }
    if (input.kind === 'normalize') return clone(c.createRouteObject(input.route.id, input.route.name, input.route));
    if (input.kind === 'default-schedule') {
      const selected = c.defaultState().routes.find(r => r.name === input.routeName);
      return clone(c.buildScheduleForRoute(selected));
    }
    const routes = clone(input.routes ?? [input.route]);
    c.state = { activeRouteId: input.activeRouteId ?? routes[0].id, routes, papanMode: 'active' };
    if (input.kind === 'schedule') return clone(c.buildScheduleForRoute(routes[0]));
    if (input.kind === 'combined') {
      routes.forEach(r => c.generateScheduleForRoute(r, true));
      return clone(c.buildCombinedSchedule());
    }
    if (input.kind === 'commit') {
      const r = routes[0];
      c.generateScheduleForRoute(r, true);
      const committedBefore = clone(r.committedSchedule);
      Object.assign(r, clone(input.changes));
      c.markDirtyIfCommitted(r);
      const result = { committedBefore, routeAfterEdit: clone(r), displayAfterEdit: clone(c.reconstructDisplaySchedule(r)) };
      if (input.regenerate) {
        c.generateScheduleForRoute(r, true);
        result.routeAfterRegenerate = clone(r);
      }
      return clone(result);
    }
    if (input.kind === 'recalc') {
      const r = routes[0];
      c.generateScheduleForRoute(r, true);
      Object.assign(r, clone(input.changes ?? {}));
      const before = clone(r);
      c.recalcRemaining();
      return clone({ before, after: r, display: c.reconstructDisplaySchedule(r), calls });
    }
    if (input.kind === 'alarm') {
      routes.forEach(r => c.generateScheduleForRoute(r, true));
      for (const step of input.steps) {
        if (step.reset) c.resetAlarmTracking();
        harness.setTime(step.time);
        c.checkAlarmTriggers(harness.now());
      }
      return clone({ events, firedKeys: Array.from(c.firedRowKeys) });
    }
    if (input.kind === 'countdown') {
      const sched = { rows: [clone(input.row)] };
      c.papanMode = input.mode ?? 'active';
      c.updatePapanCountdown(0, harness.now(), sched);
      return clone({ label: c.papanCountdownLabel.textContent,
        time: c.papanCountdownTime.textContent,
        unit: c.papanCountdownUnit.textContent || c.papanCountdownUnit.innerHTML,
        classes: Array.from(c.papanCountdownBar.classList.values), calls });
    }
    if (input.kind === 'combined-highlight') {
      routes.forEach(r => c.generateScheduleForRoute(r, true));
      const sched = c.buildCombinedSchedule();
      c.papanOverlay.classList.add('show');
      c.getActivePapanSchedule = () => sched;
      c.activeAlarmRows = clone(input.activeAlarmRows ?? []);
      c.lastDismissedIdx = input.lastDismissedIdx ?? -1;
      let selected;
      c.updatePapanCountdown = idx => { selected = { index: idx, row: sched.rows[idx] ?? null }; };
      c.updatePapanHighlight();
      return clone({ combinedRows: sched.rows, selected });
    }
    throw new Error(`Unknown fixture kind: ${input.kind}`);
  } catch (error) {
    return { exception: { name: error.name, message: error.message } };
  }
}

const cases = [];
const add = (id, classification, explanation, input) => cases.push({ id, classification, explanation, input });
const sched = (id, overrides = {}, classification = 'baseline', explanation = '') => add(id, classification, explanation, { kind: 'schedule', route: route(overrides) });
sched('single-route-nonpeak');
sched('fractional-fast-first', { jamSelesai: '05:23' });
sched('fractional-slow-first', { jamSelesai: '05:23', groupOrder: 'slow-first' });
sched('custom-departure-order', { departureOrder: ['uC', 'uA', 'uB'] });
sched('inactive-unit-filter', { masterUnits: [unit('A'), unit('B', false), unit('C')], departureOrder: ['uC', 'uB', 'uA'] });
sched('ritase-one', { ritase: 1 });
sched('single-departure', { masterUnits: [unit('A')], departureOrder: ['uA'], ritase: 1 }, 'business-ambiguity', 'One departure is at operating start, not operating end.');
sched('dense-zero-minute-gaps', { jamSelesai: '05:03' }, 'business-ambiguity', 'Integer minute distribution can schedule simultaneous departures within one route.');
sched('empty-units', { masterUnits: [], departureOrder: [] });
sched('all-units-inactive', { masterUnits: [unit('A', false)], departureOrder: ['uA'] });
sched('same-start-end-invalid', { jamSelesai: '05:00' });
sched('midnight-window-invalid', { jamMulai: '23:00', jamSelesai: '01:00' }, 'business-ambiguity', 'Legacy only accepts same-day ascending operating windows.');
sched('malformed-time-throws', { jamMulai: 'bad' }, 'known-defect', 'No validation; malformed times reach invalid array length.');
sched('negative-ritase-invalid', { ritase: -2 }, 'known-defect', 'UI clamps values but imported state bypasses limits; builder accepts negative totalDep.');
sched('zero-ritase-falls-back', { ritase: 0 }, 'business-ambiguity', 'parseInt(ritase) || 1 turns zero into one.');
sched('active-unit-missing-order', { departureOrder: ['uA', 'uC'] }, 'known-defect', 'Pure builder omits active units absent from departureOrder; load/render normalization normally appends them.');
sched('duplicate-departure-order', { departureOrder: ['uA', 'uA', 'uB'] }, 'known-defect', 'Repeated order IDs inflate unit count and schedule same unit twice per round.');
sched('duplicate-unit-number', { masterUnits: [unit('A'), unit('A', true, 'uA2')], departureOrder: ['uA', 'uA2'] }, 'known-defect', 'Rows retain unit number only, losing distinct unit identity.');
sched('peak-balanced', { ritase: 3, peakEnabled: true });
sched('peak-boundary-label', { ritase: 3, peakEnabled: true, peak1End: '05:10' }, 'known-defect', 'Inclusive segment lookup labels the shared beginning boundary by the previous segment.');
sched('peak-rounding-shift', { ritase: 3, peakEnabled: true, peak1End: '05:09' }, 'known-defect', 'round(duration / interval) changes segment duration; later absolute peak windows drift.');
sched('peak-overlap-fastest', { ritase: 4, peakEnabled: true, peak1End: '05:10', peak1Interval: 3, peak2Start: '05:08', peak2End: '05:14', peak2Interval: 2 });
sched('peak-outside-window-clamped', { peakEnabled: true, peak1Start: '04:00', peak1End: '04:30', peak2Start: '06:00', peak2End: '07:00' });
sched('peak-overallocated-truncated', { peakEnabled: true, peak1Start: '05:00', peak1End: '05:20', peak1Interval: 1 }, 'known-defect', 'Peak count exceeds available gaps; truncation then forced end creates 16-minute final interval.');
sched('peak-only-negative-headway', { peakEnabled: true, peak1Start: '05:00', peak1End: '05:20', peak1Interval: 10 }, 'known-defect', 'Remaining gaps added to peak without changing interval; rows reach 05:40 then final row forced back to 05:20.');
add('default-jak88-peak-shift', 'known-defect', 'Shipped default loses the initial 30-minute offpeak segment and shifts both peak windows.', { kind: 'default-schedule', routeName: 'JAK.88' });
add('default-jak115-nonpeak', 'baseline', '39 active units, eight rounds, 312 departures over 1020 minutes.', { kind: 'default-schedule', routeName: 'JAK.115' });
add('multi-route-stable-merge', 'baseline', 'Schedules remain independent; merge sort uses time then route name, with no cross-route collision constraint.', { kind: 'combined', routes: [route({ id: 'rB', name: 'B' }), route()] });
add('route-inactive-excluded-merge', 'baseline', 'Hidden route retains its snapshot but does not enter combined schedule.', { kind: 'combined', routes: [route(), route({ id: 'rB', name: 'B', activeInSchedule: false })] });
add('commit-dirty-snapshot', 'baseline', 'Parameter edits mark dirty and preserve last committed rows; regeneration replaces snapshot.', { kind: 'commit', route: route(), changes: { ritase: 3, jamSelesai: '05:30' }, regenerate: true });
add('remaining-between-departures', 'known-defect', 'Past planned times count as completed and historical gap metadata is stale across the splice.', { kind: 'recalc', route: route(), now: '05:10:30' });
add('remaining-exact-boundary', 'known-defect', 'History includes departure at now; first future departure also starts at now minute.', { kind: 'recalc', route: route(), now: '05:08:00' });
add('remaining-new-unit-old-target', 'business-ambiguity', 'Recalc preserves snapshot R and endLabel while using current unit roster/order/peak policy.', { kind: 'recalc', route: route(), now: '05:10:00', changes: { masterUnits: [unit('A'), unit('C'), unit('D')], departureOrder: ['uC', 'uA', 'uD'], ritase: 4, jamSelesai: '05:30', scheduleDirty: true } });
add('remaining-none-active', 'known-defect', 'No remaining unit truncates to history but keeps old N/segments/interval metadata.', { kind: 'recalc', route: route(), now: '05:10:00', changes: { masterUnits: [unit('A', false), unit('B', false), unit('C', false)] } });
add('remaining-single-future-at-now', 'business-ambiguity', 'One remaining departure goes to now, not end of window.', { kind: 'recalc', route: route(), now: '05:17:00' });
add('remaining-prototype-unit-number', 'known-defect', 'Plain-object completedCount collides with unit number __proto__; NaN remaining silently removes a future departure.', { kind: 'recalc', route: route({ masterUnits: [unit('__proto__')], departureOrder: ['u__proto__'] }), now: '05:10:00' });
add('remaining-before-operating-start', 'baseline', '', { kind: 'recalc', route: route(), now: '05:00:00' });
add('remaining-at-operating-end', 'baseline', '', { kind: 'recalc', route: route(), now: '05:20:00' });
add('normalization-duplicate-id-and-order', 'known-defect', 'Constructor repairs duplicate unit IDs but preserves duplicate order references; ID-or-number lookup can map ambiguous inputs.', { kind: 'normalize', route: route({ masterUnits: [unit('A', true, 'same'), unit('B', true, 'same'), unit('C', false)], departureOrder: ['same', 'same', 'B'] }) });
add('migration-v4-single-route', 'baseline', 'Single-route snapshot and dirty flag preserved; additional presets receive fresh default scheduling configuration.', { kind: 'migration', storage: { jadwalApp_v4: { activeRouteName: 'LEGACY', jamMulai: '05:00', jamSelesai: '05:20', ritase: 2, masterUnits: [{ number: 'A', active: true }, { number: 'B', active: false }], departureOrder: ['A'], committedSchedule: { rows: [{ no: 1, unit: 'A', jam: '05:00', ritase: 1, interval: null, isPeak: false }], N: 1, R: 2, startLabel: '05:00', endLabel: '05:20' }, scheduleDirty: true, routes: [{ name: 'OTHER', units: [{ number: 'X', active: true }] }] } } });
add('migration-corrupt-v5-skips-valid-v4', 'known-defect', 'Single try/catch returns defaults when v5 JSON is corrupt, without trying valid v4.', { kind: 'migration', storage: { jadwalApp_multi_v5: '{bad', jadwalApp_v4: { activeRouteName: 'VALID-V4', masterUnits: [{ number: 'A', active: true }] } } });
add('alarm-exact-minute-and-dedup', 'baseline', 'Trigger matches HH:mm at any second; process-local fired key suppresses repeat checks.', { kind: 'alarm', route: route(), steps: [{ time: '04:59:59' }, { time: '05:00:30' }, { time: '05:00:59' }, { time: '05:04:00' }] });
add('alarm-reset-refires-same-minute', 'known-defect', 'Regeneration/recalc resets all fired keys; same-minute trigger can fire again.', { kind: 'alarm', route: route(), steps: [{ time: '05:00:00' }, { reset: true, time: '05:00:30' }] });
add('alarm-hidden-and-disabled-excluded', 'baseline', 'Alarm considers only visible routes with alarmEnabled=true.', { kind: 'alarm', routes: [route(), route({ id: 'rB', name: 'B', activeInSchedule: false }), route({ id: 'rC', name: 'C', alarmEnabled: false })], steps: [{ time: '05:00:00' }] });
add('alarm-skipped-minute-no-catchup', 'known-defect', 'No catchup if background throttling or suspended app skips exact scheduled minute.', { kind: 'alarm', route: route(), steps: [{ time: '04:59:59' }, { time: '05:01:00' }] });
add('alarm-all-routes-simultaneous', 'baseline', 'Due rows from independent routes are batched in state route order.', { kind: 'alarm', routes: [route(), route({ id: 'rB', name: 'B' })], steps: [{ time: '05:00:00' }] });
add('alarm-prep-at-threshold', 'baseline', 'Prep countdown sound starts when 0 < rounded seconds <= active route threshold.', { kind: 'countdown', route: route(), now: '04:59:50', row: { unit: 'A', jam: '05:00' } });
add('alarm-prep-before-threshold', 'baseline', '', { kind: 'countdown', route: route(), now: '04:59:49', row: { unit: 'A', jam: '05:00' } });
add('alarm-prep-ignores-disabled-setting', 'known-defect', 'Prep sound is independent of alarmEnabled.', { kind: 'countdown', route: route({ alarmEnabled: false }), now: '04:59:50', row: { unit: 'A', jam: '05:00' } });
add('alarm-prep-combined-uses-selected-route', 'known-defect', 'Combined row belongs to B with 30-second prep, but selected A has ten seconds.', { kind: 'countdown', routes: [route(), route({ id: 'rB', name: 'B', alarmPrepSeconds: 30 })], activeRouteId: 'rA', mode: 'combined', now: '04:59:40', row: { unit: 'B', jam: '05:00', routeId: 'rB', routeName: 'B', routeColor: '#6FB4FF' } });
add('alarm-prep-at-departure', 'baseline', 'Zero countdown displays departing and does not start preparation sound.', { kind: 'countdown', route: route(), now: '05:00:00', row: { unit: 'A', jam: '05:00' } });
const smallA = route({ masterUnits: [unit('A')], departureOrder: ['uA'] });
const smallB = route({ id: 'rB', name: 'B', masterUnits: [unit('B')], departureOrder: ['uB'], jamMulai: '05:02', jamSelesai: '05:22' });
add('combined-alarm-index-local-vs-global', 'known-defect', 'Alarm local index zero for B maps to combined row zero for A.', { kind: 'combined-highlight', routes: [smallA, smallB], now: '05:02:00', activeAlarmRows: [{ routeId: 'rB', unit: 'B', jam: '05:02', _idx: 0 }] });
add('combined-dismiss-index-local-vs-global', 'known-defect', 'Dismissed B local index zero advances to combined index one (same B row) instead of next departure.', { kind: 'combined-highlight', routes: [smallA, smallB], now: '05:02:10', lastDismissedIdx: 0 });

if (process.argv.includes('--record')) {
  const fixtures = {
    schemaVersion: 1,
    purpose: 'Legacy behavioral oracle; known defects are documented baselines, not approved target rules.',
    source: { path: 'app.js', sha256: sourceHash, normalizedLfSha256: normalizedSourceHash, gitCommit: git('rev-parse', 'HEAD'),
      branch: 'devmode', capturedLocalDate: '2026-10-05', functions: spans.map(([name, firstLine, lastLine]) => ({ name, firstLine, lastLine })) },
    execution: { runtime: 'Node.js node:vm', hostNodeVersion: process.version,
      clock: 'Controlled local wall clock 2026-10-05; fixtures choose HH:mm:ss; no internet, DOM, real audio or timers.',
      scope: 'Original selected function bodies; application side effects stubbed. Not an end-to-end browser test.',
      idRandomness: 'Math.random fixed to 0.125 for normalization/default/migration cases.',
      ordering: 'localeCompare uses runtime default locale; fixtures use simple ASCII names.' },
    approvedBehaviorChanges: [],
    cases: cases.map(test => ({ ...test, expected: execute(test.input) })),
  };
  writeFileSync(fixturePath, `${JSON.stringify(fixtures, null, 2)}\n`, 'utf8');
  console.log(`Recorded ${fixtures.cases.length} cases; source sha256=${sourceHash}`);
} else {
  const fixtures = JSON.parse(readFileSync(fixturePath, 'utf8'));
  assert.equal(normalizedSourceHash, fixtures.source.normalizedLfSha256, 'app.js changed beyond line endings; review source before explicitly re-recording baseline');
  let failures = 0;
  for (const test of fixtures.cases) {
    try { assert.deepEqual(execute(test.input), test.expected); }
    catch (error) { failures++; console.error(`FAIL ${test.id}\n${error.message}`); }
  }
  if (failures) process.exitCode = 1;
  else console.log(`PASS ${fixtures.cases.length}/${fixtures.cases.length} legacy cases; app.js unchanged; branch=devmode`);
}

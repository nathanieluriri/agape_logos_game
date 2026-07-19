# Measure navigation jank (single-tab, honest)

The four render fixes are proven. The open question is whether the shared **pond
shell** (one Flame engine under the Navigator, transparent pages) is a net win or
a slight regression on transition smoothness. Verify it like this.

## Procedure (single tab, nothing else competing)

1. Build the profile web bundle (release-like, keeps timeline info):

   ```
   C:\flutter\bin\flutter clean
   C:\flutter\bin\flutter build web --profile
   cd build/web && python -m http.server 8000
   ```

2. Open EXACTLY ONE Chrome tab at http://localhost:8000/ . Close every other
   Flutter/CanvasKit tab first: multiple CanvasKit tabs share the GPU/CPU and
   contaminate the numbers (this is what invalidated the in-session readings).

3. Open DevTools console on that tab, paste the snippet below, run it. It taps the
   settings gear (top-left, ~575,60 on a wide window) to push a route, then pops
   back, four times, and reports frame intervals DURING each transition.

```js
(async () => {
  const fire = (x, y) => {
    const el = document.elementFromPoint(x, y) || document.body;
    const b = { bubbles:true, cancelable:true, composed:true, clientX:x, clientY:y,
                pointerId:1, pointerType:'mouse', isPrimary:true, button:0, buttons:1 };
    el.dispatchEvent(new PointerEvent('pointerdown', b));
    el.dispatchEvent(new PointerEvent('pointerup', { ...b, buttons:0 }));
  };
  const record = async (action) => {
    const f = []; let last = performance.now(); let go = true;
    const tick = (t) => { f.push(t - last); last = t; if (go) requestAnimationFrame(tick); };
    requestAnimationFrame(tick);
    await new Promise(r => setTimeout(r, 400));
    const mark = f.length; action();
    await new Promise(r => setTimeout(r, 1600));
    go = false;
    const d = f.slice(mark).filter(x => x > 0);
    const s = [...d].sort((a,b) => a-b);
    return { median:+s[s.length>>1].toFixed(1), worst:+Math.max(...d).toFixed(1),
             jankMs:+d.filter(x=>x>20).reduce((a,b)=>a+b,0).toFixed(1),
             dropped:d.filter(x=>x>20).length };
  };
  await new Promise(r => setTimeout(r, 5000)); // let it fully boot
  const push = [], pop = [];
  for (let i = 0; i < 4; i++) { push.push(await record(() => fire(575, 60)));
                                pop.push(await record(() => history.back())); }
  const avg = (a,k) => +(a.reduce((s,x)=>s+x[k],0)/a.length).toFixed(1);
  console.table({
    push: { median:avg(push,'median'), worst:avg(push,'worst'), jankMs:avg(push,'jankMs'), dropped:avg(push,'dropped') },
    pop:  { median:avg(pop,'median'),  worst:avg(pop,'worst'),  jankMs:avg(pop,'jankMs'),  dropped:avg(pop,'dropped') },
  });
})();
```

## Reading the result

- **median ~16.7ms** during the transition means a clean 60fps: the pond shell is
  good, keep it.
- **median 30ms+** means transparency-everywhere is costing compositing: the shell
  is a net regression on the animation. Revert just the shell (keep the four render
  fixes) by reverting the `pond_shell.dart` addition, restoring `PondBackground` to
  own its game, and removing the `scaffoldBackgroundColor: transparent` changes.

## Reference numbers captured in-session (all CONTAMINATED by 3 competing tabs;
use them only for rough shape, not as truth)

- Original code:        worst ~990ms, ~1230ms jank per nav (huge per-nav hitch).
- Four render fixes:     worst ~200ms.
- Pond shell:            worst ~200ms but median crept up (possible compositing
                         cost). This is the number that needs a clean re-measure.

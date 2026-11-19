// Checks for the Mac app's own JavaScript. tests/smoke.sh runs this file after
// the app's code (taken from the doppeldock script), so the app's functions are
// in scope. The definitions below replace the app's call to the doppeldock
// script and its run handler, so no profile is touched and no window is shown.
// (The app's own start-up code still runs, e.g. `uname -m`.)
// Prints one line per check: "ok NAME" or "FAIL NAME (why)".

var TEST_APPS = ["/System/Applications/Calculator.app", "/System/Applications/Chess.app",
                 "/Applications/Calculator.app"];

function dd(args) { return args[0] === "sources" ? TEST_APPS.join("\n") + "\n" : ""; }

function greyedOut() { // -> titles of app items macOS would show greyed out
  np.app.menu.update;
  var off = [];
  for (var i = 0; i < np.sources.length; i++) {
    if (!np.app.itemAtIndex(i).isEnabled) off.push(np.app.itemAtIndex(i).title.js);
  }
  return off;
}

function inkColumns(view) { // -> [first, last] pixel column with any drawing, and the width
  var rep = view.bitmapImageRepForCachingDisplayInRect(view.bounds);
  view.cacheDisplayInRectToBitmapImageRep(view.bounds, rep);
  var w = Number(rep.pixelsWide), h = Number(rep.pixelsHigh), first = -1, last = -1;
  for (var x = 0; x < w; x++) {
    for (var y = 0; y < h; y++) {
      if (Number(rep.colorAtXY(x, y).alphaComponent) > 0.3) {
        if (first < 0) first = x;
        last = x;
        break;
      }
    }
  }
  return [first, last, w];
}

function run() {
  var out = [];
  function check(name, fn) {
    var r;
    try { r = fn(); } catch (e) { r = "error: " + e; }
    out.push(r === true ? "ok " + name : "FAIL " + name + " (" + r + ")");
  }
  controller = $.DDController.alloc.init;
  buildForm(null);

  // 1.1.1: apps with their own icon were added without the pop-up's action,
  // so macOS greyed them out and only "Other…" could be chosen.
  check("Mac app: every app in the App list can be chosen", function () {
    var off = greyedOut();
    return off.length === 0 || "greyed out: " + off.join(", ");
  });
  check("Mac app: App list names each app once, in order", function () {
    var got = [];
    for (var i = 0; i < np.sources.length; i++) got.push(np.app.itemAtIndex(i).title.js);
    var want = ["Calculator (/System/Applications)", "Chess", "Calculator (/Applications)"];
    return got.join("|") === want.join("|") || "got " + got.join(", ");
  });
  check("Mac app: an app added with Other… can be chosen", function () {
    var p = "/System/Applications/TextEdit.app";
    selectOtherApp(p);
    selectOtherApp(p);  // picking it again doesn't add it twice
    var n = Number(np.app.numberOfItems);
    if (np.sources.length !== 4 || n !== 6) return "list has " + n + " items for " + np.sources.length + " apps";
    if (np.app.itemAtIndex(n - 1).title.js !== "Other…") return "Other… is not last";
    if (Number(np.app.indexOfSelectedItem) !== 3 || np.app.titleOfSelectedItem.js !== "TextEdit") return "TextEdit is not selected";
    var off = greyedOut();
    return off.length === 0 || "greyed out: " + off.join(", ");
  });
  check("Mac app: Other… offers only apps", function () {
    var t = appTypes();
    return (Number(t.count) === 1 && t.objectAtIndex(0).identifier.js === "com.apple.application-bundle") || "wrong types";
  });

  // 1.1.1: on Apple silicon the labels were centred (alignment numbers differ by processor).
  check("Mac app: form labels are right-aligned", function () {
    var c = inkColumns(fieldLabel("App:", 0));
    return (c[0] > c[2] / 2 && c[1] >= c[2] * 0.85) || "text spans columns " + c[0] + "–" + c[1] + " of " + c[2];
  });
  check("Mac app: colour swatches are drawn", function () {
    var rep = swatch("#E03131").representations.objectAtIndex(0);
    var mid = rep.colorAtXY(Number(rep.pixelsWide) / 2, Number(rep.pixelsHigh) / 2);
    return (Number(mid.alphaComponent) > 0.9 && Number(mid.redComponent) > 0.8) || "the centre is not red";
  });
  return out.join("\n");
}

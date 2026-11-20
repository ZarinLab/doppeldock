// Checks of the website's machine-readable parts, run by tests/smoke.sh:
//   osascript -l JavaScript tests/site_checks.js ROOT
// Prints "ok NAME" or "FAIL NAME (why)" for each check.
ObjC.import("Foundation");

function read(path) {
  var s = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null);
  if (!s || s.isNil()) throw new Error("cannot read " + path);
  return s.js;
}

// Visible text of an HTML fragment: tags removed, the entities the page uses decoded,
// white space collapsed.
function text(html) {
  return html.replace(/<[^>]*>/g, "")
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&quot;/g, "\"").replace(/&#39;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/\s+/g, " ").trim();
}

function run(argv) {
  var root = argv[0];
  var out = [];
  function check(name, fn) {
    try {
      var why = fn();
      out.push(why ? "FAIL " + name + " (" + why + ")" : "ok " + name);
    } catch (e) {
      out.push("FAIL " + name + " (" + e.message + ")");
    }
  }

  var page = read(root + "/site/index.html");
  var version = (read(root + "/doppeldock").match(/^VERSION="([^"]+)"/m) || [])[1];
  var blocks = [], m, re = /<script type="application\/ld\+json">([\s\S]*?)<\/script>/g;
  while ((m = re.exec(page))) blocks.push(m[1]);
  var data = [];

  check("website: structured data is valid JSON", function () {
    if (!blocks.length) return "no structured data found";
    data = blocks.map(function (b) { return JSON.parse(b); });
  });

  var nodes = [];
  data.forEach(function (d) { nodes = nodes.concat(d["@graph"] || [d]); });
  function node(type) { return nodes.filter(function (n) { return n["@type"] === type; })[0]; }

  check("website: structured data has the current version", function () {
    if (!version) return "VERSION not found in the script";
    var app = node("SoftwareApplication");
    if (!app) return "no SoftwareApplication";
    if (app.softwareVersion !== version) return "has " + app.softwareVersion + ", script is " + version;
  });

  check("website: structured FAQ matches the Questions section", function () {
    var faq = node("FAQPage");
    if (!faq) return "no FAQPage";
    var shown = [], d, dre = /<details><summary>([\s\S]*?)<\/summary>\s*<p>([\s\S]*?)<\/p><\/details>/g;
    while ((d = dre.exec(page))) shown.push({ q: text(d[1]), a: text(d[2]) });
    var all = (page.match(/<details[\s>]/g) || []).length;
    if (all !== shown.length) return (all - shown.length) + " question(s) could not be read; keep each as <details><summary>…</summary> <p>…</p></details>";
    var listed = faq.mainEntity.map(function (e) { return { q: e.name, a: e.acceptedAnswer.text }; });
    if (shown.length !== listed.length) return shown.length + " shown, " + listed.length + " listed";
    for (var i = 0; i < shown.length; i++) {
      if (shown[i].q !== listed[i].q) return "question " + (i + 1) + " differs: " + listed[i].q;
      if (shown[i].a !== listed[i].a) return "answer " + (i + 1) + " differs: " + listed[i].q;
    }
  });

  check("website: llms.txt has the current version", function () {
    if (!version) return "VERSION not found in the script";
    var v = (read(root + "/site/llms.txt").match(/Current version: (\S+?)\.?$/m) || [])[1];
    if (v !== version) return "has " + v + ", script is " + version;
  });

  return out.join("\n");
}

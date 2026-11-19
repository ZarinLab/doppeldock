// Copy buttons and install tabs for the DoppelDock website.
  (function () {
    // Copy buttons
    Array.prototype.forEach.call(document.querySelectorAll("button.copy"), function (btn) {
      var code = btn.parentNode.querySelector("code");
      btn.addEventListener("click", function () {
        var done = function () { btn.textContent = "Copied"; setTimeout(function () { btn.textContent = "Copy"; }, 1600); };
        var fallback = function () {
          var r = document.createRange(); r.selectNodeContents(code);
          var s = window.getSelection(); s.removeAllRanges(); s.addRange(r);
          try { document.execCommand("copy"); done(); } catch (e) { btn.textContent = "Press ⌘C"; }
        };
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(code.textContent).then(done, fallback);
        } else { fallback(); }
      });
    });

    // Install tabs (arrow keys move between them)
    var tabs = Array.prototype.slice.call(document.querySelectorAll('[role="tab"]'));
    function select(tab) {
      tabs.forEach(function (t) {
        var on = t === tab;
        t.setAttribute("aria-selected", on ? "true" : "false");
        t.tabIndex = on ? 0 : -1;
        document.getElementById(t.getAttribute("aria-controls")).hidden = !on;
      });
    }
    tabs.forEach(function (tab, i) {
      tab.tabIndex = i === 0 ? 0 : -1;
      tab.addEventListener("click", function () { select(tab); });
      tab.addEventListener("keydown", function (e) {
        var d = e.key === "ArrowRight" ? 1 : e.key === "ArrowLeft" ? -1 : 0;
        if (d) { var t = tabs[(i + d + tabs.length) % tabs.length]; select(t); t.focus(); e.preventDefault(); }
      });
    });
  })();

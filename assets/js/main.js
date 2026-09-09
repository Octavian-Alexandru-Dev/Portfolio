(function () {
  "use strict";

  var LANG_KEY = "portfolio:lang";
  var htmlEl = document.documentElement;
  var originalText = new WeakMap();
  var i18nNodes = Array.prototype.slice.call(document.querySelectorAll("[data-i18n]"));

  i18nNodes.forEach(function (node) {
    originalText.set(node, node.textContent);
  });

  function applyLanguage(lang) {
    var dict = (window.translations && window.translations[lang]) || null;

    i18nNodes.forEach(function (node) {
      var key = node.getAttribute("data-i18n");
      if (lang === "it" || !dict || !dict[key]) {
        node.textContent = originalText.get(node);
      } else {
        node.textContent = dict[key];
      }
    });

    htmlEl.setAttribute("lang", lang);
    document.querySelectorAll("[data-lang]").forEach(function (btn) {
      var isActive = btn.getAttribute("data-lang") === lang;
      btn.classList.toggle("is-active", isActive);
    });

    try {
      localStorage.setItem(LANG_KEY, lang);
    } catch (err) {
      /* localStorage unavailable (private mode, disabled storage) — language just won't persist */
    }
  }

  function initLanguage() {
    var stored = null;
    try {
      stored = localStorage.getItem(LANG_KEY);
    } catch (err) {
      /* ignore */
    }

    var lang = stored === "en" ? "en" : "it";
    applyLanguage(lang);

    document.querySelectorAll("[data-lang]").forEach(function (btn) {
      btn.addEventListener("click", function () {
        applyLanguage(btn.getAttribute("data-lang"));
      });
    });
  }

  function initNav() {
    var nav = document.getElementById("nav");
    var toggle = document.getElementById("nav-toggle");
    var links = document.getElementById("nav-links");

    if (!nav) return;

    var onScroll = function () {
      nav.classList.toggle("is-scrolled", window.scrollY > 12);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });

    if (toggle && links) {
      var closeMenu = function () {
        nav.classList.remove("is-open");
        toggle.setAttribute("aria-expanded", "false");
      };

      toggle.addEventListener("click", function () {
        var isOpen = nav.classList.toggle("is-open");
        toggle.setAttribute("aria-expanded", String(isOpen));
      });

      links.querySelectorAll("a").forEach(function (link) {
        link.addEventListener("click", closeMenu);
      });

      document.addEventListener("keydown", function (event) {
        if (event.key === "Escape") closeMenu();
      });
    }

    var sections = Array.prototype.slice
      .call(document.querySelectorAll("main section[id]"))
      .filter(function (section) {
        return links && links.querySelector('a[href="#' + section.id + '"]');
      });

    if (sections.length && "IntersectionObserver" in window) {
      var navLinkFor = function (id) {
        return links.querySelector('a[href="#' + id + '"]');
      };

      var observer = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            var link = navLinkFor(entry.target.id);
            if (!link) return;
            if (entry.isIntersecting) {
              links.querySelectorAll(".nav__link").forEach(function (l) {
                l.classList.remove("is-active");
              });
              link.classList.add("is-active");
            }
          });
        },
        { rootMargin: "-45% 0px -45% 0px" }
      );

      sections.forEach(function (section) {
        observer.observe(section);
      });
    }
  }

  function initReveal() {
    var items = document.querySelectorAll("[data-reveal]");
    if (!items.length) return;

    if (!("IntersectionObserver" in window)) {
      items.forEach(function (el) {
        el.classList.add("is-visible");
      });
      return;
    }

    var observer = new IntersectionObserver(
      function (entries, obs) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            obs.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15, rootMargin: "0px 0px -60px 0px" }
    );

    items.forEach(function (el) {
      observer.observe(el);
    });
  }

  function initFooterYear() {
    var yearEl = document.getElementById("year");
    if (yearEl) yearEl.textContent = String(new Date().getFullYear());
  }

  document.addEventListener("DOMContentLoaded", function () {
    initLanguage();
    initNav();
    initReveal();
    initFooterYear();
  });
})();

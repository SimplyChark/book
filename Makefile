# By default, build all the various output formats.
.PHONY: all
all: book.pdf book.html book.epub

# For development, ask Typst to rebuild the PDF output when anything changes.
.PHONY: watch
watch:
	typst watch main.typ book.pdf --features html --font-path ./fonts

book.pdf: $(wildcard *.typ chapters/*.typ images/* bib.yml)
	# The HTML feature is required for the "target()" function to exist.
	typst compile main.typ book.pdf --features html --font-path ./fonts

book.html: $(wildcard *.typ chapters/*.typ images/* bib.yml)
	typst compile main.typ book.html --features html --font-path ./fonts
	# Python insertor thing
	python - <<'PY'
from pathlib import Path
p = Path("book.html")
s = p.read_text(encoding="utf8")

style = """\
  <style>
      body {
        unicode-bidi: isolate;
        padding-left: 10%;

        @media (min-width: 768px) {
          display: block;
          margin-block-start: 1em;
          margin-block-end: 1em;
          margin-inline-start: 10%;
          margin-inline-end: 10%;
          padding-right: 20%;
        }
      }

      p {
        font-family: "EB Garamond";
        font-size: 0.95em;
        line-height: calc(0.95em * 1.5);

        margin: 0 0 4pt 0;
        padding-right: 10%;
        @media (min-width: 768px) {
          padding-right: 20%;
        }
        margin-bottom: calc(0.95em * 1);
      }

      .pre-header p {
        text-align: right;
        line-height: 10px;
        font-size: 0.3em;
      }

      .title-gratitude {
        border-width: calc(0.95em * 0.1);
        border-style: solid;
        margin-right: 20%;
        padding: 0% 1% 3% 1%;
      }

      .title-gratitude p,
      .title-gratitude h2 {
        text-align: center;
        padding-right: 0%;
        margin-block-end: 0;
        padding: 0 0 0 0;
      }

      nav {
        position: relative;
        @media (min-width: 768px) {
          position: fixed;
          top: 5%;
          left: 70%;
          right: 5%;
          bottom: 5;
          height: fit-content;
          border-width: calc(0.95em * 0.1);
          border-style: solid;
          padding: 0% 1% 2% 1%;
        }
      }

      nav ol {
        padding-left: 5%;
        font-size: 0.7rem;

        @media (min-width: 768px) {
          font-size: 1vw;
        }
      }

      a {
        color: black;
        text-decoration: none; /* no underline */
      }

      section ul {
        padding-right: 20%;
        padding-left: 0;
      }

      blockquote {
        font-style: italic;
      }

      h1,
      h2,
      h3,
      h4,
      h5 {
        text-align: center;
        padding-right: 10%;
        @media (min-width: 768px) {
          text-align: left;
          padding-right: 20%;
        }
      }
    </style>
"""

script = """\
  <script>
      function wrapBetweenHeaders(options = {}) {
        const {
          container = document.body,
          idPrefix = "section-",
          startIndex = 1,
        } = options;

        const headerSelector = "h1,h2,h3,h4,h5,h6";
        const headers = Array.from(container.querySelectorAll(headerSelector));

        // slugify header text >>> can become a class name
        const slugify = (str) =>
          String(str || "")
            .trim()
            .toLowerCase()
            .normalize("NFKD") // remove accents
            .replace(/[^\w\s-]/g, "") // remove non-word chars
            .replace(/\s+/g, "-")
            .replace(/-+/g, "-")
            .replace(/^-|-$/g, "");

        const isHeaderNode = (node) =>
          node &&
          node.nodeType === Node.ELEMENT_NODE &&
          /^H[1-6]$/.test(node.tagName);

        /*// If no headers, wrap all content as one
        if (headers.length === 0) {
          // create a single wrapper for all content
          const wrapper = document.createElement("div");
          wrapper.id = `${idPrefix}${startIndex}`;
          wrapper.classList.add("section", "no-headers");
          // move all child nodes of container into wrapper
          while (container.firstChild)
            wrapper.appendChild(container.firstChild);
          container.appendChild(wrapper);
          return;
        }*/

        // Helper: detect if node is already inside an assistant-created wrapper
        const isAlreadyWrapped = (node) => {
          let el = node.parentElement;
          while (el && el !== container) {
            if (el.dataset && el.dataset.generated === "true") return true;
            el = el.parentElement;
          }
          return false;
        };

        let idCount = startIndex;

        // Handle content before the first header
        const firstHeader = headers[0];
        if (firstHeader.previousSibling) {
          // if there's any node before the first header and it's not already wrapped
          let hasContentBefore = false;
          for (
            let n = container.firstChild;
            n && n !== firstHeader;
            n = n.nextSibling
          ) {
            // treat text nodes and elements (non-empty text)
            if (n.nodeType === Node.TEXT_NODE && n.textContent.trim() === "")
              continue;
            hasContentBefore = true;
            break;
          }
          if (hasContentBefore) {
            const wrapper = document.createElement("div");
            wrapper.id = `${idPrefix}${idCount++}`;
            wrapper.dataset.generated = "true";
            wrapper.classList.add("section", "pre-header");
            // move nodes before firstHeader into wrapper
            while (
              container.firstChild &&
              container.firstChild !== firstHeader
            ) {
              wrapper.appendChild(container.firstChild);
            }
            container.insertBefore(wrapper, firstHeader);
          }
        }

        // For each header: create wrapper and move header + siblings until next header
        headers.forEach((header) => {
          if (isAlreadyWrapped(header)) return; // skip if already processed

          const wrapper = document.createElement("div");
          wrapper.id = `${idPrefix}${idCount++}`;
          wrapper.dataset.generated = "true";

          // add classes: general 'section', header tag (h1,h2...), and slug of header text (if any)
          wrapper.classList.add("section", header.tagName.toLowerCase());
          const text = header.textContent.trim();
          if (text) {
            const slug = slugify(text);
            if (slug) wrapper.classList.add(`title-${slug}`);
          }

          // insert wrapper before header, then move header + following nodes into wrapper
          header.parentNode.insertBefore(wrapper, header);

          let node = header;
          while (node) {
            const next = node.nextSibling;
            // move the node into the wrapper
            wrapper.appendChild(node);
            // stop if the next node is a header element (we don't include it here)
            if (next && isHeaderNode(next)) break;
            node = next;
          }
        });
      }
      wrapBetweenHeaders(); // default: container=document.body
    </script>
"""

# insert once if possible
s = s.replace("</head>", style + "\n</head>", 1)
s = s.replace("</body>", script + "\n</body>", 1)

p.write_text(s, encoding="utf8")
PY

book.epub: book.html
	pandoc --from html --to epub --output book.epub book.html

# Runs a spellchecker over source files, using "dictionary.txt" for project-specific vocabulary.
# Adding terms in aspell will automatically add to dictionary.txt.
.PHONY: spell
spell:
	LANG=en_US.utf8 aspell --home-dir=. --personal=dictionary.txt check chapters/acknowledgements.typ
	LANG=en_US.utf8 aspell --home-dir=. --personal=dictionary.txt check chapters/foreword.typ
	LANG=en_US.utf8 aspell --home-dir=. --personal=dictionary.txt check chapters/1.typ
	LANG=en_US.utf8 aspell --home-dir=. --personal=dictionary.txt check chapters/pointing-out.typ
	LANG=en_US.utf8 aspell --home-dir=. --personal=dictionary.txt check chapters/2.typ
	LANG=en_US.utf8 aspell --home-dir=. --personal=dictionary.txt check chapters/3.typ
	LANG=en_US.utf8 aspell --home-dir=. --personal=dictionary.txt check chapters/4.typ

.PHONY: clean
clean:
	rm -f book.pdf book.html book.epub  # Target output files.
	rm -f .aspell.en.prepl  # aspell nonsense.
	rm -f chapters/*.bak  # aspell nonsense.
	rm -f chapters/*.new  # aspell nonsense.

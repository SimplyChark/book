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

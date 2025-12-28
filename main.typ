#import "template.typ": *
#show: template

/////////////////////////////////////////////////////////////////////////////////
// Cover Page
/////////////////////////////////////////////////////////////////////////////////

#context {
  if target() == "paged" { // Paged output, like PDF, SVG, etc.
    page(
      background: rect(
        fill: gradient.linear(rgb("#87cfe9"), white, angle: 90deg),
        width: 100%,
        height: 100%
      ),
      numbering: none,
      margin: auto,
      [
        #set par(spacing: 0em)
        #set par(justify: false)
        #place(top + center, [
          #text(40pt, weight: "bold", "Beyond Recognition")\
          #v(4pt)\
          #text(28pt, weight: "bold", "Four Phases of Freedom")
        ])
        #place(horizon + center, [
          #v(40pt)
          #image("images/thigle.png", width: 90%)
        ])
        #place(bottom + center, text(30pt, book_author))
      ]
    )
    pagebreak()
  } else if target() == "html" {
    book_author
  }
}

#counter(page).update(1) // Don't count the cover page.

/////////////////////////////////////////////////////////////////////////////////
// Copyright and publication information
/////////////////////////////////////////////////////////////////////////////////

#context {
  let copyright_text = [
    Published #datetime.today().display("[year]-[month]-[day]").\
    This text is self-secret and self-protected.

    Copyright © #datetime.today().display("[year]"), Lama Dawai Gocha.\
    #link("https://www.meditationonline.org")[#underline[www.meditationonline.org]]

    Licensed under #link("https://creativecommons.org/licenses/by-nc-sa/4.0/")[CC BY-NC-SA 4.0].\
    No AI was used in the making of this text.
  ]

  if target() == "paged" {
    set page(numbering: none) // Copyright page does not get a page number.
    copyright_text
    pagebreak()
  } else if target() == "html" {
    copyright_text
  }
}


/////////////////////////////////////////////////////////////////////////////////
// Acknowledgements, Foreword, etc.
/////////////////////////////////////////////////////////////////////////////////

#counter(page).update(1)

#context {
  if target() == "paged" {
    set page(numbering: "i")

    include("chapters/acknowledgements.typ")
    pagebreak(weak: true)

    include("chapters/foreword.typ")
    pagebreak(weak: true)
  } else if target() == "html" {
    include("chapters/acknowledgements.typ")
    include("chapters/foreword.typ")
  }
}


/////////////////////////////////////////////////////////////////////////////////
// Table of Contents
/////////////////////////////////////////////////////////////////////////////////

// Add a little more vertical spacing after the text "Table of Contents".
// #show outline.entry.where(
//   level: 1
// ): set block(above: 1.2em)

#context {
  let toc = outline(title: [Table of Contents], target: heading)

  if target() == "paged" {
    set page(numbering: "i")
    toc
  } else if target() == "html" {
    toc
  }
}

/////////////////////////////////////////////////////////////////////////////////
// The Four Phases
/////////////////////////////////////////////////////////////////////////////////

#pagebreak(weak: true)
#counter(page).update(1) // For the rest of the book, switch back to "1, 2, 3" page numbering.

#include("chapters/1.typ")
#pagebreak(weak: true)
#include("chapters/2.typ")
#pagebreak(weak: true)
#include("chapters/3.typ")
#pagebreak(weak: true)
#include("chapters/4.typ")

/////////////////////////////////////////////////////////////////////////////////
// Bibliography
/////////////////////////////////////////////////////////////////////////////////

#pagebreak(weak: true)
#bibliography(
  "bib.yml",
  style: "ieee",
)

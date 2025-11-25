#set text(font: "Noto Serif JP", size: 24pt)
#show raw: set text(font: ("DejaVu Sans Mono", "Noto Sans JP"))
#set page(width: auto, height: auto, margin: 1cm)

#let dbg(body) = {
  raw(repr(body), lang: "typc")
}

#let c = [途中で
  改行]

#dbg(c) \
#dbg(c.children.at(1).func()) \
#dbg(c == [途中で] + [ ] + [改行])

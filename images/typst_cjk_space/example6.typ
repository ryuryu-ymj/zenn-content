#set text(font: "Noto Serif JP", size: 24pt)
#show raw: set text(font: ("DejaVu Sans Mono", "Noto Sans JP"))
#set page(width: auto, height: auto, margin: 1cm)


#show " ": it => highlight(it, fill: red.transparentize(40%))

#{ [途中で] + [ ] + [改行] } \
#{ [途中で] + [ ] + h(0em, weak: true) + [改行] } \
#{ [途中で] + h(0em, weak: true) + [ ] + [改行] }

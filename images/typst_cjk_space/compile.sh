for f in ./*.typ; \
do \
    echo "Compile $f."; \
    typst compile "$f" -f png --root ./; \
done

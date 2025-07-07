PDFS=$(wildcard *.pdf)
NOCOPY_PDFS=$(addprefix nocopy/, $(PDFS))

all: $(NOCOPY_PDFS)

nocopy:
	mkdir nocopy

nocopy/%.pdf: %.pdf nocopy
	gs -o "$@" -sDEVICE=pdfwrite -c "<< /AlwaysOutline [/Menlo-Regular /Menlo-Bold /DejaVuSansMono /DejaVuSansMono-Bold] >> setdistillerparams" -f "$<"

clean:
	rm -rf nocopy

.PHONY: all clean

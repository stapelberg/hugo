INKSCAPE=/home/michael/Downloads/Inkscape-9dee831-x86_64.AppImage

all: ondisk.svgo.svg bitpacking256v32.svgo.svg bitpacking.svgo.svg block-bitpackex.svgo.svg block-bitpack.svgo.svg block-bitpackvb.svgo.svg block-constant.svgo.svg

%.export.svg: %.svg
	$(INKSCAPE) $^ --export-text-to-path --export-type=svg -o $@

%.svgo.svg: %.export.svg
	svgo -i $^ -o $@

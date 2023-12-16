curl -OL https://github.com/roc-lang/roc/releases/download/nightly/roc_nightly-linux_x86_64-latest.tar.gz
mkdir rocextract
tar -xf roc_nightly-linux_x86_64-latest.tar.gz -C rocextract
rocdir=$(ls rocextract)
mv ./rocextract/$rocdir/roc ~/.local/bin/roc

rm -rf roc_nightly-linux_x86_64-latest.tar.gz rocextract

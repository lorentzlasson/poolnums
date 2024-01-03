wget -q -O roc.tar.gz https://github.com/roc-lang/roc/releases/download/nightly/roc_nightly-linux_x86_64-latest.tar.gz
tar -xvz -f roc.tar.gz --directory ~/.local/bin --strip-components=1
rm roc.tar.gz

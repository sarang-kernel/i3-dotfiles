"""Regenerate the whole docs site into S/site (hand-written pages + generated reference pages), then validate it."""
import shutil, subprocess, sys
from common import *
import gen_i3, gen_scripts, gen_tune, gen_nvim, gen_hp, gen_reference
import pages_core, pages_i3, pages_spotlight, pages_tune, pages_nvim, pages_hp


def main():
    if SITE.exists():
        shutil.rmtree(SITE)
    SITE.mkdir(parents=True)
    pages_core.build()
    gen_i3.build()
    pages_i3.build()
    gen_scripts.build()
    gen_tune.build()
    pages_spotlight.build()
    pages_tune.build()
    gen_nvim.build()
    pages_nvim.build()
    pages_hp.build()
    gen_reference.deps()
    r = gen_reference.file_index()
    print("file index:", r[:4], "undescribed:", r[4])
    shutil.copytree(S / "imgs", SITE / "img")
    n = len(list(SITE.rglob("*.md")))
    print(n, "pages written")


if __name__ == "__main__":
    main()

# MikTeX Docker Image

This repository is based on [Debian 12.x Bookworm (slim) with Python 3.13](https://hub.docker.com/_/python).

## Usage

```bash
docker image run --rm -v $(pwd):/data pytooling/miktex:latest
```

## Installed Tools

Installed additional tools are:

* curl
* GhostScript
* make
* MikTeX
  * Preinstalled packages: [Common.list](Common.list) 
* Perl
* Python 3.13

## Why another MikTeX Docker Image?

* [MikTeX original containers](https://hub.docker.com/r/miktex/miktex) do not provide installations based on Ubuntu LTS.
* MikTeX original containers are infrequently updated (>1 year).
* MikTeX original containers aren't smaller (less download time).
* pyTooling has control over preinstalled commonly used LaTeX packages (`amsfonts`/`amsmath`, `babel`, `hyperref`, `longtables`, ...)
* pyTooling can derive specific images for e.g. [Sphinx](Sphinx.list).

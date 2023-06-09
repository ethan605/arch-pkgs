# System fonts

## Pre-built fonts

- `Operator Mono` (`otf-operator-mono`)
- `OperatorMono Nerd Font` (`otf-operator-mono-nerd`)
- `Operator Mono SSm` (`otf-operator-mono-ssm`)
- `OperatorMonoSSm Nerd Font` (`otf-operator-mono-ssm-nerd`)

## Patch with ligatures

Follow [`operator-mono-lig`'s instruction](https://github.com/kiliman/operator-mono-lig#docker).

## Patch with Nerd fonts

From `fonts/` directory, run:

```shell
$ docker run --rm -v ./<original-fonts-folder>:/in -v ./<original-fonts-folder>-nerd:/out nerdfonts/patcher --complete
```

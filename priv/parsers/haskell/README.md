# Haskell Parser for Metastatic

This directory contains the Haskell parser infrastructure for the Metastatic project.

## Setup

### Install Stack (Haskell build tool)

```bash
curl -sSL https://get.haskellstack.org/ | sh
```

Or on Ubuntu/Debian:
```bash
wget -qO- https://get.haskellstack.org/ | sh
```

### Build the Parser

```bash
cd priv/parsers/haskell
stack setup  # Downloads GHC if needed (first time only)
stack build
```

### Test the Parser

```bash
echo "1 + 2" | stack exec parser
```

Expected output:
```json
{"status":"ok","ast":{"type":"infix","left":{"type":"literal","value":{"literalType":"int","value":1}},"operator":"+","right":{"type":"literal","value":{"literalType":"int","value":2}}},"errorMessage":null}
```

## Development

The parser uses:
- `haskell-src-exts` for parsing Haskell syntax
- `aeson` for JSON serialization
- Stack for dependency management

To add new AST node support, edit `Parser.hs` and add cases to `exprToJson`.

## CI Setup

For GitHub Actions, add the following step before running tests:

```yaml
- name: Set up Haskell
  uses: haskell-actions/setup@v2
  with:
    ghc-version: '9.6'
    enable-stack: true
    stack-version: 'latest'

- name: Build Haskell parser
  run: |
    cd priv/parsers/haskell
    stack setup
    stack build
```

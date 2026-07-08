# consult-spotlight

Consult-powered macOS Spotlight (mdfind) search.

## Requirements

- Emacs 28.1+
- consult 2.0+
- macOS with `mdfind` available

## Installation

MELPA (once published):

```elisp
(use-package consult-spotlight
  :after consult
  :custom
  (consult-spotlight-silence-stderr t))
```

Manual:

```elisp
(add-to-list 'load-path "/path/to/consult-spotlight")
(require 'consult-spotlight)
```

## Usage

```elisp
M-x consult-spotlight
```

With a prefix argument (`C-u`), you will be prompted for a base directory.
You can also call it programmatically with a directory:

```elisp
(consult-spotlight "/path/to/dir")
```

### Open in browser

Candidates use Consult's `file` category, so they work with Embark.
With the default Compleseus/Embark binding (`M-o`), choose:

- `b` — open in the default browser (`consult-spotlight-open-in-browser`)
- `RET` / `f` — open in Emacs (`find-file`)
- `x` — open with the system default application (`embark-open-externally`)

Set `consult-spotlight-register-embark-actions` to nil if you prefer to
bind `consult-spotlight-open-in-browser` yourself.

## Customization

- `consult-spotlight-default-directory`: Default base directory (default: `~`).
- `consult-spotlight-min-input`: Minimum input length before starting search.
- `consult-spotlight-args`: Base command and arguments for `mdfind`.
- `consult-spotlight-silence-stderr`: Whether to discard stderr from Spotlight.
- `consult-spotlight-register-embark-actions`: Bind `b` on `embark-file-map`.

## License

GPL-3.0-or-later

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

## Customization

- `consult-spotlight-default-directory`: Default base directory (default: `~`).
- `consult-spotlight-min-input`: Minimum input length before starting search.
- `consult-spotlight-args`: Base command and arguments for `mdfind`.
- `consult-spotlight-silence-stderr`: Whether to discard stderr from Spotlight.

## License

GPL-3.0-or-later

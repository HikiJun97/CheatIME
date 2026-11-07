# CLAUDE.md

Read `CONTRIBUTING.md` before changing anything. Its build commands, code guidelines, localization rules, and release steps apply to every change.

- Prefer plain, explicit code over magic. Don't use runtime reflection (`Mirror`), implicit registration, or other tricks that hide where something comes from.
- Keep `K.portable` in `Prefs.swift` a hand-written list, and add each new setting that settings export should carry to it.

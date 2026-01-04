# Hemlock Syntax Tokens Reference

This document lists all reserved words and tokens from the Hemlock lexer for syntax highlighting purposes.

> Generated from `/home/user/hemlock-review/include/lexer.h` and `/home/user/hemlock-review/src/frontend/lexer.c`

## Keywords

### Control Flow & Declarations
```
let       const     if        else      while     loop
for       in        break     continue  fn        return
ref       define    enum      object    self      try
catch     finally   throw     switch    case      default
async     await     import    export    from      as
extern    defer     type
```

### Type Keywords
```
i8        i16       i32       i64       u8        u16
u32       u64       f32       f64       integer   number
byte      bool      string    rune      ptr       buffer
array     void
```

### Constants/Literals
```
true      false     null
```

## Operators

### Arithmetic
| Token | Symbol |
|-------|--------|
| TOK_PLUS | `+` |
| TOK_MINUS | `-` |
| TOK_STAR | `*` |
| TOK_SLASH | `/` |
| TOK_PERCENT | `%` |
| TOK_PLUS_PLUS | `++` |
| TOK_MINUS_MINUS | `--` |

### Assignment
| Token | Symbol |
|-------|--------|
| TOK_EQUAL | `=` |
| TOK_PLUS_EQUAL | `+=` |
| TOK_MINUS_EQUAL | `-=` |
| TOK_STAR_EQUAL | `*=` |
| TOK_SLASH_EQUAL | `/=` |
| TOK_PERCENT_EQUAL | `%=` |
| TOK_AMP_EQUAL | `&=` |
| TOK_PIPE_EQUAL | `\|=` |
| TOK_CARET_EQUAL | `^=` |
| TOK_LESS_LESS_EQUAL | `<<=` |
| TOK_GREATER_GREATER_EQUAL | `>>=` |
| TOK_QUESTION_QUESTION_EQUAL | `??=` |

### Comparison
| Token | Symbol |
|-------|--------|
| TOK_EQUAL_EQUAL | `==` |
| TOK_BANG_EQUAL | `!=` |
| TOK_LESS | `<` |
| TOK_LESS_EQUAL | `<=` |
| TOK_GREATER | `>` |
| TOK_GREATER_EQUAL | `>=` |

### Logical
| Token | Symbol |
|-------|--------|
| TOK_AMP_AMP | `&&` |
| TOK_PIPE_PIPE | `\|\|` |
| TOK_BANG | `!` |

### Bitwise
| Token | Symbol |
|-------|--------|
| TOK_AMP | `&` |
| TOK_PIPE | `\|` |
| TOK_CARET | `^` |
| TOK_TILDE | `~` |
| TOK_LESS_LESS | `<<` |
| TOK_GREATER_GREATER | `>>` |

### Special Operators
| Token | Symbol | Description |
|-------|--------|-------------|
| TOK_QUESTION_DOT | `?.` | Optional chaining |
| TOK_QUESTION_QUESTION | `??` | Null coalescing |

## Punctuation

| Token | Symbol |
|-------|--------|
| TOK_SEMICOLON | `;` |
| TOK_COLON | `:` |
| TOK_COMMA | `,` |
| TOK_LPAREN | `(` |
| TOK_RPAREN | `)` |
| TOK_LBRACE | `{` |
| TOK_RBRACE | `}` |
| TOK_LBRACKET | `[` |
| TOK_RBRACKET | `]` |
| TOK_DOT | `.` |
| TOK_DOT_DOT_DOT | `...` |
| TOK_QUESTION | `?` |

## Literals

| Token | Description | Example |
|-------|-------------|---------|
| TOK_NUMBER | Integer or float | `42`, `3.14`, `0xFF`, `0b1010` |
| TOK_STRING | Double-quoted string | `"hello"` |
| TOK_TEMPLATE_STRING | Backtick template | `` `Hello ${name}` `` |
| TOK_RUNE | Single character | `'a'`, `'\n'` |
| TOK_IDENT | Identifier | `myVar`, `_count` |

## Special Tokens

| Token | Description |
|-------|-------------|
| TOK_EOF | End of file |
| TOK_ERROR | Lexer error |

## Contextual Keywords

Some keywords can be used as identifiers in certain contexts:
- `as` - Used in imports (`import { x as y }`)
- `from` - Used in imports (`import { x } from "module"`)
- Type keywords when not in type annotation position

## JavaScript Arrays for Syntax Highlighting

```javascript
const Highlighter = {
    // Control flow and declaration keywords
    keywords: new Set([
        'let', 'const', 'if', 'else', 'while', 'loop', 'for', 'in',
        'break', 'continue', 'fn', 'return', 'ref', 'define', 'enum',
        'object', 'self', 'try', 'catch', 'finally', 'throw', 'switch',
        'case', 'default', 'async', 'await', 'import', 'export', 'from',
        'as', 'extern', 'defer', 'type'
    ]),

    // Type keywords (highlight differently from control keywords)
    types: new Set([
        'i8', 'i16', 'i32', 'i64', 'u8', 'u16', 'u32', 'u64',
        'f32', 'f64', 'integer', 'number', 'byte', 'bool', 'string',
        'rune', 'ptr', 'buffer', 'array', 'void'
    ]),

    // Literal constants
    constants: new Set(['true', 'false', 'null']),

    // Built-in functions (not keywords, but commonly highlighted)
    builtins: new Set([
        'print', 'eprint', 'read_line', 'length', 'push', 'pop',
        'shift', 'join', 'split', 'substr', 'char_at', 'find',
        'contains', 'keys', 'values', 'parse', 'stringify', 'spawn'
    ])
};
```

## Color Recommendations (Tokyo Night Theme)

| Category | CSS Class | Color | Example |
|----------|-----------|-------|---------|
| Keywords | `.tok-keyword` | `#bb9af7` (purple) | `if`, `fn`, `return` |
| Types | `.tok-type` | `#7dcfff` (cyan) | `i32`, `string` |
| Constants | `.tok-constant` | `#e0af68` (yellow) | `true`, `null` |
| Strings | `.tok-string` | `#9ece6a` (green) | `"hello"` |
| Numbers | `.tok-number` | `#e0af68` (yellow) | `42`, `3.14` |
| Comments | `.tok-comment` | `#565f89` (dim) | `// comment` |
| Functions | `.tok-function` | `#7aa2f7` (blue) | `myFunc()` |
| Builtins | `.tok-builtin` | `#7dcfff` (cyan) | `print()` |
| Operators | `.tok-operator` | `#89ddff` (cyan) | `+`, `??` |
| Punctuation | `.tok-punctuation` | `#565f89` (dim) | `;`, `{}` |

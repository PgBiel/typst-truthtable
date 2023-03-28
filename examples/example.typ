#import "../truthtable.typ": truth-table, l-and, l-imp, l-iff, l-not, l-or, l-var, l-expr-tree

#set text(font: "Linux Libertine")

#align(center, text(17pt)[*Some truth table examples*])

Importing some names with:

```typ
#import "../truthtable.typ": truth-table, l-and, l-or, l-imp, l-iff, l-not, l-var, l-expr-tree
```

Import more as needed (do note, however, that there are several "private" functions,
so importing everything at once might be excessive).

#let expression = l-or("A", l-imp("B", "C"))

1. For #expression.repr:

```typ
#let expression = l-or("A", l-imp("B", "C"))

For #expression.repr:

#truth-table(expression)
```

#truth-table(expression)

It has the following tree:

```typ
#l-expr-tree(expression).flatten().map(c => c.repr).join([; ])
```

#l-expr-tree(expression).flatten().map(c => c.repr).join([; ])


2. *Customize T/F:*

```typ
#let expression = l-iff("A", l-not(l-and("A", "A")))

#truth-table(expression, repr_true: 1, repr_false: 0)
```

#let expression = l-iff("A", l-not(l-and("A", "A")))

#truth-table(expression, repr_true: 1, repr_false: 0)

3. *Skip a column:*

```typ
#let expression = l-iff("A", l-not(l-and("A", "A"), skip: true))

#truth-table(expression, repr_true: 1, repr_false: 0)
```

#let expression = l-iff("A", l-not(l-and("A", "A"), skip: true))

#truth-table(expression, repr_true: 1, repr_false: 0)

4. *Specify a custom text representation for your variables:* Use `l-var`:

```typ
#let expression = l-iff(l-var("P+Q", repr: $P(x) + Q(x)$), l-not(l-var("R", repr: $R(x)$)))

#truth-table(expression, repr_true: 1, repr_false: 0)
```

#let expression = l-iff(l-var("P+Q", repr: $P(x) + Q(x)$), l-not(l-var("R", repr: $R(x)$)))

#truth-table(expression, repr_true: 1, repr_false: 0)

5. *Customize the table:* Pass table parameters directly:

```typ
#let expression = l-iff("A", l-not(l-and("A", "A"), skip: true))

#truth-table(expression, repr_true: 1, repr_false: 0, fill: yellow, stroke: 5pt + blue)
```

#let expression = l-iff("A", l-not(l-and("A", "A"), skip: true))

#truth-table(expression, repr_true: 1, repr_false: 0, fill: yellow, stroke: 5pt + blue)

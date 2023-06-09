# typst-truthtable
A library for generating truth tables

## Usage

Compose logic expressions with the logic operators: `l-and(a, b)`, `l-or(a, b)`,
`l-imp(a, b)`, `l-iff(a, b)`, `l-not(a)`, where `a` and `b` can be either
other expressions created with operators, atomic variables/propositions
(which can be created with `"name"` or
`l-var("name", repr: $custom_representation$)`), and boolean values
(`true` or `false`).

Then, for any expression, you may write `#truth-table(expr)` to generate its
truth table.

Note that it gets ugly if there are too many columns, so make sure to mark any
excessive columns with `skip: true` (e.g. `l-and(a, b, skip: true))` will not show
the possible values for "a and b" in the table).

You may also create your own _n_-ary operator by invoking `l-operator("ITS_NAME", a, b, ..other_children, value: variable_mapping => {/* calculate truth value based on a dict (VARIABLE_NAME: true_or_false) */}, repr: $my_operators_appearance$)`. Regarding `value`, note that you may get your children's
truth value based on the given variable map with `(child.value)(variable_mapping)`.

See `examples/` for some examples.

![image](https://user-images.githubusercontent.com/9021226/228386381-96bcfdb2-76a5-4966-8d21-31a06887345d.png)


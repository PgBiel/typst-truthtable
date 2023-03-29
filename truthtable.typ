// Logic "true" object
#let l-true(repr: $top$) = (
    logic_dict: true,
    logic_type: "true",
    repr: [#repr],
    value: m => true,
    name: "TRUE",
    skip: true,
    children: ()
)

// Logic "false" object
#let l-false(repr: $bot$) = (
    logic_dict: true,
    logic_type: "false",
    repr: [#repr],
    name: "FALSE",
    value: m => false,
    skip: true,
    children: ()
)

// Converts bools to their equivalent logic objects
#let l-bool(bool) = if bool { l-true() } else { l-false() }

// Logic atomic variable / proposition / ...
#let l-var(name, repr: none) = (
    logic_dict: true,
    logic_type: "var",
    repr: if repr == none { $#name$ } else { [#repr] },
    name: name,
    value: mapping => if name in mapping { mapping.at(name) } else { false },
    skip: false,
    children: ()
)

// Convert a value to their equivalent logical object
// Boolean becomes a true or false object;
// A string becomes a logical variable;
// All else must be a dictionary created by this library.
#let l-logic-convert(val) = if type(val) == "boolean" {
    l-bool(val)
} else if type(val) == "string" {
    l-var(val)
} else if type(val) != "dictionary" {
    panic("Failed to convert value (of type '" + type(val) + "') to a logic object: Not a boolean, string or dictionary.")
} else if "logic_dict" not in val or val.logic_dict != true {
    panic("Invalid dictionary given as logic object (must be a valid logic dictionary).")
} else {
    val
}

// Represents an arbitrary logic operator or functor
// Customize its representation with the 'repr' parameter
#let l-operator(
    name,
    ..children,
    value: mapping => false,
    repr: none,
    skip: false,
) = (
    logic_dict: true,
    logic_type: "operator",
    name: str(name),
    repr: if repr == none { [#name] } else { repr },
    value: value,
    skip: skip,
    children: children.pos().map(l-logic-convert)
)

// Return an expression's representation,
// around parentheses if it has multiple children
#let l-parens-repr-if-composite(expr) = {
    if expr.children.len() > 1 {
        $(#expr.repr)$
    } else {
        $#expr.repr$
    }
}

// Generate binary operator representation
#let l-gen-binary-operator-repr(op, a, b, parens: auto) = {
    let a_repr = a.repr
    let b_repr = b.repr

    if parens == auto {
        a_repr = l-parens-repr-if-composite(a)
        b_repr = l-parens-repr-if-composite(b)
    } else if parens {  // force parens
        a_repr = $(#a_repr)$
        b_repr = $(#b_repr)$
    }

    $#a_repr #op #b_repr$
}

// Generate unry operator representation
#let l-gen-unary-operator-repr(op, a, parens: auto) = {
    let a_repr = a.repr

    if parens == auto {
        a_repr = l-parens-repr-if-composite(a)
    } else if parens {  // force parens
        a_repr = $(#a_repr)$
    }

    $#op #a_repr$
}

// Logic object for the AND operator
#let l-and(a, b, parens: auto, skip: false) = {
    let a = l-logic-convert(a)
    let b = l-logic-convert(b)

    l-operator(
        "AND",
        a, b,
        value: mapping => (a.value)(mapping) and (b.value)(mapping),
        repr: l-gen-binary-operator-repr($and$, a, b, parens: parens),
        skip: skip,
    )
}

// Logic object for the OR operator
#let l-or(a, b, parens: auto, skip: false) = {
    let a = l-logic-convert(a)
    let b = l-logic-convert(b)

    l-operator(
        "OR",
        a, b,
        value: mapping => (a.value)(mapping) or (b.value)(mapping),
        repr: l-gen-binary-operator-repr($or$, a, b, parens: parens),
        skip: skip,
    )
}

// Logic object for the NOT operator
#let l-not(a, parens: auto, skip: false) = {
    let a = l-logic-convert(a)
    
    l-operator(
        "NOT",
        a,
        value: mapping => not (a.value)(mapping),
        repr: l-gen-unary-operator-repr($not$, a, parens: parens),
        skip: skip,
    )
}

// Logic object for the IMPLIES operator
#let l-imp(a, b, parens: auto, skip: false) = {
    let a = l-logic-convert(a)
    let b = l-logic-convert(b)
    
    l-operator(
        "IMP",
        a, b,
        value: mapping => (not (a.value)(mapping)) or (b.value)(mapping),
        repr: l-gen-binary-operator-repr($->$, a, b, parens: parens),
        skip: skip,
    )
}

// Logic object for the IF AND ONLY IF operator
#let l-iff(a, b, parens: auto, skip: false) = {
    let a = l-logic-convert(a)
    let b = l-logic-convert(b)
    
    l-operator(
        "IFF",
        a, b,
        value: mapping => (a.value)(mapping) == (b.value)(mapping),
        repr: l-gen-binary-operator-repr($<->$, a, b, parens: parens),
        skip: skip,
    )
}

// Returns all atomic variables in the expression
#let l-search-variables(expr) = {
    let children = expr.children

    if (children.len() == 0) {
        if (expr.logic_type not in ("true", "false")) {
            (expr,)
        } else {
            ()
        }
    } else {
        children.map(c => l-search-variables(c)).flatten()
    }
}

// Returns 'true' if two logic objects
// are likely to represent the same thing
#let l-compare-logic-objects(a, b) = (
    (type(a) == "dictionary")
        and (type(b) == "dictionary")
        and "logic_dict" in a
        and "logic_dict" in b
        and a.logic_dict
        and b.logic_dict
        and a.logic_type == b.logic_type
        and a.repr == b.repr
        and a.name == b.name
        and a.skip == b.skip
)

// Returns all sub-expressions of an expression until the given
// depth (-1 = unlimited)
// 'unique: true' is used to ensure elements do not repeat
// and 'initial_vars: true' ensures all variables are at the beginning
// of the tree
#let l-expr-tree(
    expr,
    max_depth: -1, unique: true, initial_vars: true
) = {
    if max_depth == 0 {  // reached the max
        return ()
    }

    if expr.logic_type in ("true", "false") {
        ()
    } else {
        let subexprs = expr.children.map(
            c => l-expr-tree(
                c,
                max_depth: calc.max(-1, max_depth - 1),
                unique: false,  // deal with it only on the first-level
                initial_vars: initial_vars))
        // don't allow going below -1 ^

        let res = subexprs.flatten()

        if initial_vars and expr.logic_type == "var" {
            res.insert(0, expr)  // variable at the beginning
        } else {
            res.push(expr)
        }

        if unique {
            res.fold(
                (),
                (acc, expr) => {
                    if acc.filter(l-compare-logic-objects.with(expr)).len() == 0 {
                        acc + (expr,)
                    } else {
                        acc
                    }
                }
            )
        } else {
            res
        }
    }
}

// Generate all possible true/false combinations
// of certain variables
#let l-gen-true-false-maps(vars) = {
    if vars.len() == 0 {
        return ()
    }

    let head = vars.first()

    // convert to string
    if (
        type(head) == "dictionary"
        and "logic_dict" in head
        and head.logic_dict
    ) {
        head = head.name
    } else {
        head = str(head)
    }

    // Recursively generate T/F map for the rest of the
    // variable array
    let tail_res = l-gen-true-false-maps(vars.slice(1))

    // this variable's single true/false combinations
    let true_d = (:)
    let false_d = (:)

    true_d.insert(head, true)
    false_d.insert(head, false)

    let res = ()

    // join with the true/false combinations from the
    // other variables
    for d in tail_res {
        if head in d {  // don't override this variable's existing values
            res.push(d)
        } else {
            res.push((: ..true_d, ..d))
            res.push((: ..false_d, ..d))
        }
    }

    if res.len() == 0 {  // base case: only one variable => T/F
        (true_d, false_d)
    } else {
        res
    }
}

// Builds a truth table automatically from a logic
// expression. Use 'repr_true' and 'repr_false' to
// control the output of True and False values.
// Any additional args are passed to the 'table' call
// (such as 'fill').
#let truth-table(
    expr,
    repr_true: "T",
    repr_false: "F",
    ..table_args
) = {
    let vars = l-search-variables(expr)
    let varnames = vars.map(c => c.name)
    let mappings = l-gen-true-false-maps(varnames)

    let expr_tree = l-expr-tree(expr)
        .flatten()
        .filter(e => "skip" not in e or not e.skip)

    // initialize with the table headers
    let table_children = expr_tree.map(c => c.repr)

    for map in mappings {
        for expr in expr_tree {
            let bool_value = (expr.value)(map)

            table_children.push(if bool_value {
                [#repr_true]
            } else {
                [#repr_false]
            })
        }
    }

    table(
        columns: (auto,) * expr_tree.len(),
        rows: (auto,) * mappings.len(),
        ..table_children,
        ..table_args.named())
}

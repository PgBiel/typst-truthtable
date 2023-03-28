// Logic "true" object
#let l-true(repr: $ top $) = (
    logic_dict: true,
    logic_type: "true",
    repr: [#repr],
    value: m => true,
    name: "TRUE",
    children: ()
)

// Logic "false" object
#let l-false(repr: $ bot $) = (
    logic_dict: true,
    logic_type: "false",
    repr: [#repr],
    name: "FALSE",
    value: m => false,
    children: ()
)

// Converts bools to their equivalent logic objects
#let l-bool(bool) = if bool { l-true() } else { l-false() }

// Logic atomic variable / proposition / ...
#let l-var(name, repr: none) = (
    logic_dict: true,
    logic_type: "var",
    repr: if repr == none { $ #name $ } else { [#repr] },
    name: name,
    value: mapping => if name in mapping { mapping.at(name) } else { false },
    children: ()
)

// Convert a value to their equivalent logical object
// Boolean becomes a true or false object;
// A string becomes a logical variable;
// All else 
#let l-conv(val) = if type(val) == "boolean" {
    l-bool(val)
} else if type(val) in ("string", "content") {
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
    repr: none
) = (
    logic_dict: true,
    logic_type: "operator",
    name: str(name),
    repr: if repr == none { [#name] } else { repr },
    value: value,
    children: children.pos().map(l-conv)
)

// Logic object for the AND operator
#let l-and(a, b) = {
    let a = l-conv(a)
    let b = l-conv(b)

    l-operator(
        "AND",
        a, b,
        value: mapping => (a.value)(mapping) and (b.value)(mapping),
        repr: $ (#a.repr and #b.repr) $,
    )
}

// Logic object for the OR operator
#let l-or(a, b) = {
    let a = l-conv(a)
    let b = l-conv(b)
    
    l-operator(
        "OR",
        a, b,
        value: mapping => (a.value)(mapping) or (b.value)(mapping),
        repr: $ (#a.repr or #b.repr) $,
    )
}

// Logic object for the NOT operator
#let l-not(a) = {
    let a = l-conv(a)
    
    l-operator(
        "NOT",
        a,
        value: mapping => not (a.value)(mapping),
        repr: $ (not #a.repr) $,
    )
}

// Logic object for the IMPLIES operator
#let l-imp(a, b) = {
    let a = l-conv(a)
    let b = l-conv(b)
    
    l-operator(
        "IMP",
        a, b,
        value: mapping => (not (a.value)(mapping)) or (b.value)(mapping),
        repr: $ (#a.repr -> #b.repr) $,
    )
}

// Logic object for the IF AND ONLY IF operator
#let l-iff(a, b) = {
    let a = l-conv(a)
    let b = l-conv(b)
    
    l-operator(
        "IFF",
        a, b,
        value: mapping => (a.value)(mapping) == (b.value)(mapping),
        repr: $ (#a.repr <-> #b.repr) $,
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

// Returns all sub-expressions of an expression until the given
// depth (-1 = unlimited)
#let l-expr-tree(expr, max_depth: -1) = {
    if max_depth == 0 {  // reached the max
        return ()
    }

    if expr.children.len() == 0 {
        if (expr.name not in ("TRUE", "FALSE")) {
            (expr,)
        } else {
            ()
        }
    } else {
        let subexprs = expr.children.map(
            c => l-expr-tree(
                c,
                max_depth: calc.max(-1, max_depth - 1)))
        // don't allow going below -1 ^

        (expr, ..subexprs)
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
        res.push((: ..true_d, ..d))
        res.push((: ..false_d, ..d))
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
        .rev()
    
    let unique_tree = ()

    for expr in expr_tree {  // filter out repeated cols
        if expr not in unique_tree {
            if "logic_type" in expr and expr.logic_type == "var" {
                unique_tree.insert(0, expr)
            } else {
                unique_tree.push(expr)
            }
        }
    }

    let table_children = unique_tree.map(c => c.repr)
    // initialize with the table headers

    for map in mappings {
        let seen_expr = ()
        for expr in unique_tree {
            let bool_value = (expr.value)(map)

            table_children.push(if bool_value {
                [#repr_true]
            } else {
                [#repr_false]
            })
        }
    }

    table(
        columns: (auto,) * unique_tree.len(),
        rows: (auto,) * mappings.len(),
        ..table_children,
        ..table_args.named())
}

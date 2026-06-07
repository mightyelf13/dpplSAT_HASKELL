# DPLL SAT Solver in Haskell

This is a small Haskell project that implements a SAT solver using the DPLL algorithm.

A SAT solver checks whether a propositional logic formula can be made true by assigning truth values to its variables. In this project, the input formula is written in CNF, which means Conjunctive Normal Form.

A CNF formula is made from clauses connected with `AND`. Each clause is made from literals connected with `OR`.

Example:

```text
(p OR q) AND (NOT p OR r) AND (NOT q)
```

The program decides whether the formula is satisfiable. If it is satisfiable, it prints one possible assignment. If it is not satisfiable, it reports that the formula is unsatisfiable.

## Files in This Project

```text
Main.hs
README.md
cnf.txt
```

`Main.hs` contains the whole implementation of the project. I kept it in one file because the project is not too large, and it is easier to run in GHCi this way.

`README.md` explains the project and the algorithm.

`cnf.txt` is just a trial run file where I can keep example inputs and outputs.

## Running the Project


Open the project folder in the terminal and start GHCi with:

```bash
ghci Main.hs
```

Then run the program by typing:

```haskell
main
```

The program will ask for a CNF formula. For example, enter:

```text
(p OR q) AND (NOT p OR r) AND (NOT q)
```

Expected output:

```text
Parsed formula:
(p OR q) AND (NOT p OR r) AND (NOT q)

Satisfiable.

One possible assignment:
p = True
q = False
r = True
```

The exact order of the variables may be different, but the assignment should still satisfy the formula.



## Trying Functions Directly in GHCi

the functions can also be tested directly.

For example:

```haskell
parseCNF "(p OR q) AND (NOT p OR r)"
```

This parses the formula into the internal CNF representation.

Another example:

```haskell
case parseCNF "(p OR q) AND (NOT p OR r) AND (NOT q)" of
  Right cnf -> solve cnf
  Left err -> error err
```

This parses and solves the formula directly.

## Input Format

The parser accepts formulas like this:

```text
(p OR q) AND (NOT p OR r) AND (NOT q OR NOT r)
```

Rules for the input:

- each clause must be inside parentheses
- clauses are joined with `AND`
- literals inside a clause are joined with `OR`
- negation is written as `NOT`
- `AND`, `OR`, and `NOT` must be uppercase
- variable names can contain letters, digits, and underscores

Valid examples:

```text
(p)
(p OR q)
(p OR q) AND (NOT p OR r)
(p OR q) AND (p OR NOT q) AND (NOT p OR q)
```

An unsatisfiable example is:

```text
(p) AND (NOT p)
```

This is unsatisfiable because `p` cannot be both true and false.

## How the Formula Is Represented

In the Haskell code, variables are strings:

```haskell
type Variable = String
```

A literal is either positive or negative:

```haskell
data Literal
  = Pos Variable
  | Neg Variable
```

A clause is a list of literals:

```haskell
type Clause = [Literal]
```

A CNF formula is a list of clauses:

```haskell
type CNF = [Clause]
```

An assignment is a list of variables with Boolean values:

```haskell
type Assignment = [(Variable, Bool)]
```

For example, this formula:

```text
(p OR q) AND (NOT p OR r)
```

is represented as:

```haskell
[
  [Pos "p", Pos "q"],
  [Neg "p", Pos "r"]
]
```

## Algorithm

The algorithm is DPLL obviously. Which stands for Davis-Putnam-Logemann-Loveland.

The program follows these main steps:

1. If the formula has no clauses left, it is satisfiable.
2. If the formula contains an empty clause, it is unsatisfiable.
3. If there is a unit clause, assign that literal immediately.
4. If there is a pure literal, assign it immediately.
5. Otherwise, choose a literal and try both possible truth values using recursion.

## Unit Propagation

A unit clause is a clause with only one literal, for example:

```text
(p)
```

or:

```text
(NOT q)
```

A unit clause has to be true if the whole formula is going to be true.

For example, if the formula contains:

```text
(NOT q)
```

then the solver assigns:

```text
q = False
```

After that, it simplifies the formula. Any clause containing `NOT q` is already satisfied and can be removed. Any occurrence of `q` in the remaining clauses can also be removed.

This is the same idea as unit propagation from the course notes.

## Pure Literal Elimination

A pure literal is a literal that appears only in one form in the whole formula.

For example, if  `p` appears only as:

```text
p
```

and never as:

```text
NOT p
```

then `p` can safely be assigned:

```text
p = True
```

If a variable appears only negated, then it can be assigned false.

This reduces the formula before the solver has to guess.

## Backtracking

If there are no unit clauses and no pure literals, the solver chooses a literal and branches.

For example, it may choose `p` and first try:

```text
p = True
```

If that causes a contradiction later, it backtracks and tries:

```text
p = False
```


## Example

The formula:

```text
(a OR b) AND (NOT a OR c) AND (NOT b)
```

The solver finds the unit clause:

```text
(NOT b)
```

So it assigns:

```text
b = False
```

Then the clause:

```text
(a OR b)
```

becomes:

```text
(a)
```

Now the solver assigns:

```text
a = True
```

Then:

```text
(NOT a OR c)
```

becomes:

```text
(c)
```

So the solver assigns:

```text
c = True
```

Now all clauses are satisfied, so the formula is satisfiable.

One possible assignment is:

```text
a = True
b = False
c = True
```

## Possible Improvements

Some possible future improvements are:

- support DIMACS CNF format
- print each solving step
- count recursive calls
- add a better branching heuristic
- compare the solver with brute force search
- split the code into modules if the project becomes larger


## Sources

This project is based on the course material of propositional logic and Predicate logic taught by: Petr Gregor and Introduction to Artificial Intelligence taught by Roman Barták.


From the propositional logic lecture I used the definition of SAT for CNF formulas and the DPLL algorithm. That lecture describes unit propagation, pure literal elimination, empty clauses, empty formulas, and branching.

From the artificial intelligence lecture I used the idea that DPLL combines search and inference. The AI lecture also connects SAT solving to knowledge representation, where possible models are satisfying assignments of logical formulas.

So the project is basically a small implementation of the algorithm from logic, written in Haskell.

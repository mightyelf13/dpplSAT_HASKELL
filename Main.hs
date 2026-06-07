module Main where

import Data.Char (isAlphaNum, isSpace)
import Data.List (find, nub, sort)

type Variable = String

data Literal
  = Pos Variable
  | Neg Variable
  deriving (Eq, Ord)

instance Show Literal where
  show (Pos v) = v
  show (Neg v) = "NOT " ++ v

type Clause = [Literal]

type CNF = [Clause]

type Assignment = [(Variable, Bool)]

-- literal helper functions
variableOf :: Literal -> Variable
variableOf (Pos v) = v
variableOf (Neg v) = v

valueOfLiteral :: Literal -> Bool
valueOfLiteral (Pos _) = True
valueOfLiteral (Neg _) = False

negateLiteral :: Literal -> Literal
negateLiteral (Pos v) = Neg v
negateLiteral (Neg v) = Pos v

-- formula simplification
simplify :: Literal -> CNF -> CNF
simplify lit = map removeOpposite . filter (notElem lit)
  where
    removeOpposite = filter (/= negateLiteral lit)

-- Unit propagation
findUnitLiteral :: CNF -> Maybe Literal
findUnitLiteral cnf =
  case find ((== 1) . length) cnf of
    Just [lit] -> Just lit
    _          -> Nothing

-- Pure literal elimination
findPureLiteral :: CNF -> Maybe Literal
findPureLiteral cnf = find isPure allLiterals
  where
    allLiterals = nub (concat cnf)

    isPure lit =
      negateLiteral lit `notElem` allLiterals

-- Assignment helper
insertAssignment :: Literal -> Assignment -> Assignment
insertAssignment lit assignment =
  case lookup var assignment of
    Just _  -> assignment
    Nothing -> (var, valueOfLiteral lit) : assignment
  where
    var = variableOf lit

-- Branching choice
chooseLiteral :: CNF -> Literal
chooseLiteral cnf = head (head cnf)


solve :: CNF -> Maybe Assignment
solve cnf = dpll cnf []

-- DPLL algorithm
dpll :: CNF -> Assignment -> Maybe Assignment
dpll cnf assignment
  | null cnf =
      Just (completeAssignment assignment)

  | any null cnf =
      Nothing

  | otherwise =
      case findUnitLiteral cnf of
        Just lit ->
          dpll
            (simplify lit cnf)
            (insertAssignment lit assignment)

        Nothing ->
          case findPureLiteral cnf of
            Just lit ->
              dpll
                (simplify lit cnf)
                (insertAssignment lit assignment)

            Nothing ->
              let lit = chooseLiteral cnf

                  tryTrue =
                    dpll
                      (simplify lit cnf)
                      (insertAssignment lit assignment)

                  tryFalse =
                    dpll
                      (simplify (negateLiteral lit) cnf)
                      (insertAssignment (negateLiteral lit) assignment)

              in case tryTrue of
                   Just result -> Just result
                   Nothing-> tryFalse

-- Sort the final assignment for nicer output
completeAssignment :: Assignment -> Assignment
completeAssignment assignment = sort assignment

-- Parser token representation
data Token
  = TLParen
  | TRParen
  | TAnd
  | TOr
  | TNot
  | TVar String
  deriving (Eq, Show)

-- Parse a full CNF formula
parseCNF :: String -> Either String CNF
parseCNF input = do
  tokens <- tokenize input
  (cnf, rest) <- parseFormula tokens

  case rest of
    [] -> Right cnf
    _  -> Left ("Unexpected tokens at end: " ++ show rest)

-- Convert the input string into tokens
tokenize :: String -> Either String [Token]
tokenize [] = Right []

tokenize (c:cs)
  | isSpace c =
      tokenize cs

  | c == '(' =
      (TLParen :) <$> tokenize cs

  | c == ')' =
      (TRParen :) <$> tokenize cs

  | isVarChar c =
      let (word, rest) = span isVarChar (c:cs)

          token =
            case word of
              "AND" -> TAnd
              "OR"  -> TOr
              "NOT" -> TNot
              _     -> TVar word

      in (token :) <$> tokenize rest

  | otherwise =
      Left ("Unexpected character: " ++ [c])

isVarChar :: Char -> Bool
isVarChar ch = isAlphaNum ch || ch == '_'

-- Parse clauses
parseFormula :: [Token] -> Either String (CNF, [Token])
parseFormula tokens = do
  (clause, rest) <- parseClause tokens
  parseMoreClauses [clause] rest

parseMoreClauses :: CNF -> [Token] -> Either String (CNF, [Token])
parseMoreClauses clauses (TAnd:rest) = do
  (clause, rest') <- parseClause rest
  parseMoreClauses (clauses ++ [clause]) rest'

parseMoreClauses clauses rest =
  Right (clauses, rest)

-- Parse one clause inside parentheses
parseClause :: [Token] -> Either String (Clause, [Token])
parseClause (TLParen:rest) = do
  (clause, rest') <- parseLiterals rest

  case rest' of
    TRParen:afterParen ->
      Right (clause, afterParen)
    _->
      Left "Expected ')' after clause"

parseClause [] =
  Left "Expected '(' to start a clause, but reached the end of input"

parseClause bad =
  Left ("Expected '(' to start a clause near: " ++ show (take 5 bad))

-- Parse literals
parseLiterals :: [Token] -> Either String (Clause, [Token])
parseLiterals tokens = do
  (lit, rest) <- parseLiteral tokens
  parseMoreLiterals [lit] rest

parseMoreLiterals :: Clause -> [Token] -> Either String (Clause, [Token])
parseMoreLiterals lits (TOr:rest) = do
  (lit, rest') <- parseLiteral rest
  parseMoreLiterals (lits ++ [lit]) rest'

parseMoreLiterals lits rest =
  Right (lits, rest)

-- Parse one literal
parseLiteral :: [Token] -> Either String (Literal, [Token])
parseLiteral (TVar v:rest) =
  Right (Pos v, rest)

parseLiteral (TNot:TVar v:rest) =
  Right (Neg v, rest)

parseLiteral [] =
  Left "Expected a literal, but reached the end of input"

parseLiteral bad =
  Left ("Expected a literal such as p or NOT p near: " ++ show (take 5 bad))

-- Pretty printing
prettyCNF :: CNF -> String
prettyCNF cnf =
  joinWith " AND " (map prettyClause cnf)

prettyClause :: Clause -> String
prettyClause clause =
  "(" ++ joinWith " OR " (map show clause) ++ ")"

prettyAssignment :: Assignment -> String
prettyAssignment assignment =
  unlines [v ++ " = " ++ show b | (v, b) <- sort assignment]

joinWith :: String -> [String] -> String
joinWith _[] =
  ""

joinWith _[x] =
  x

joinWith sep (x:xs) =
  x ++ sep ++ joinWith sep xs


main :: IO ()
main = interactiveMode

-- Interactive input
interactiveMode :: IO ()
interactiveMode = do
  putStrLn "Enter a CNF formula. Example:"
  putStrLn "(p OR q) AND (NOT p OR r) AND (NOT q)"
  input <- getLine
  solveAndPrint input

-- Parse, solve, and print the result
solveAndPrint :: String -> IO ()
solveAndPrint input =
  case parseCNF input of
    Left err -> do
      putStrLn "Parse error."
      putStrLn err

    Right cnf -> do
      putStrLn "Parsed formula:"
      putStrLn (prettyCNF cnf)
      putStrLn ""

      case solve cnf of
        Nothing ->
          putStrLn "Unsatisfiable."

        Just assignment -> do
          putStrLn "Satisfiable."
          putStrLn ""
          putStrLn "One possible assignment:"
          putStr (prettyAssignment assignment)

-- Step 21: Example formula for quick use in GHCi
exampleFormula :: String
exampleFormula = "(p OR q) AND (NOT p OR r) AND (NOT q)"
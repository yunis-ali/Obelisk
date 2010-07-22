{ 
-- | Parser for obelisk.  Generated by happy.  See happy/obelisk.y
module Language.Obelisk.Parser where

import Prelude hiding (lex)

import Language.Obelisk.Parser.Monad hiding (eparse, run_parser)
import qualified Language.Obelisk.Parser.Monad as M

import Language.Obelisk.Lexer
import Language.Obelisk.Lexer.Token

import Language.Obelisk.AST.Simple

parse :: Parse

terror :: Token -> OParser a
terror = fail . ("Caused by token: " ++) . show 

-- Convienence parsers
run_parser :: FilePath -> String -> SimpleObelisk
run_parser = M.run_parser parse

eparse :: FilePath -> String -> ParseResult SimpleObelisk
eparse = M.eparse parse

}

{- Parse is the name of the main parsing function -}
%name parse Obelisk

{- We're parsing tokens as defined in Language.Obelisk.Lexer.Token -}
%tokentype { Token }

{- parse_error is our error function -}
%error { terror }

{- We're using a monadic lexer provided by Language.Obelisk.Lexer -}
%lexer { lex } { TEOF } 

{- We're using a monad -}
%monad { OParser }

{- Declare tokens -}
%token
   def       { TDef }
   if        { TIf }
   int       { TInt $$ }
   var       { TVar $$ }
   op        { TOp $$ }
   true      { TTrue }
   false     { TFalse }
   where     { TWhere }
   let       { TConstant }
   classname { TClassName $$ }
   '->'      { TArrow }
   '#'       { TTypeTerm }
   '('       { TParOpen }
   ')'       { TParClose }
   char      { TChar $$ }

%%

{- Get the source position -}
Pos :: { CodeFragment }
Pos : {- empty -} {% get_pos}

{- Parse a type -}
QType :: { QType }
QType : FQType   { $1 }
      | SQType   { $1 }

{- Parse a function's type -}
FQType :: { QType }
FQType : Pos FType '#' { QType $1 [] $2 }

{- Parse a simple quantified type -}
SQType :: { QType }
SQType : Pos SType '#' { QType $1 [] $2 }

{- Parse a function's quantified type -}
FType :: { Type }
FType : '(' ArgTypes ')'  { $2 }

{- Parse a simple type -}
SType :: { Type }
SType : TypeName { Type $1 }

{- Parse a function's type -}
ArgTypes :: { Type }
ArgTypes : TypeNames   { Function $ reverse $1 }

{- Parse a list of type names seperated by arrows -}
TypeNames :: { [TypeName] }
TypeNames : TypeNames '->' TypeName   { $3 : $1 }
          | TypeName                  { [$1] }

{- A type name -}
TypeName :: { TypeName }
TypeName : classname   { TypeClassName $1 }

{- Parse the AST -}
Obelisk :: { SimpleObelisk }
Obelisk : FDefs   { Obelisk $ reverse $1 }

{- A list of function definitions -}
FDefs :: { [SimpleFDef] }
FDefs : FDefs '(' FDef ')'    { $3 : $1 }
     | {- empty -} { [] }


{- A list of definitions -}
Defs :: { [SimpleDef] }
Defs : Defs '(' Def ')'    { $3 : $1 }
     | {- empty -} { [] }

{- A function definition -}
FDef :: { SimpleFDef }
FDef : Pos FQType def var Vars Block WhereClause  { Def $1 $2 $4 $5 $6 $7 }


{- Define a function or a constant -}
Def :: { SimpleDef }
Def : FDef                     { FDef $1 } 
    | Pos QType let var Exp   { Constant $1 $2 $4 $5 }

{- A where clause -}
WhereClause :: { [SimpleDef]}
WhereClause : where '(' Defs ')'  { $3 }
            | {- empty -}   { [] }

{- A list of variables -}
Vars :: { [String] }
Vars : {- empty -}        { [] }
     | Vars var   { $2 : $1 }

{- If statement -}
If :: { SimpleExp }
If : Pos if Exp Block Block   { If $1 $3 $4 $5 }

{- An terminal expression -}
TExp :: { SimpleExp }
TExp : Var   { $1 }
    | Int    { $1 }
    | Bool   { $1 }
    | Char   { $1 }

{- An expression -}
Exp :: { SimpleExp }
Exp : TExp           { $1 }
    | '(' PExp ')'   { $2 }

{- An expression found within parenthesis -}
PExp :: { SimpleExp }
PExp : Apply { $1 }
     | Infix { $1 }
     | If    { $1 }

{- Function application. -}
Apply :: { SimpleExp }
Apply : Pos Exp Exps  { Apply $1 $2 (reverse $3) }

{- A list of expressions -}
Exps :: { [SimpleExp] }
Exps : {- empty -}   { [] }
     | Exps Exp      { $2 : $1 }

{- Infix application. -}
Infix :: { SimpleExp }
Infix : Pos Exp op Exp   { Infix $1 $2 $3 $4}

{- Variable used in expressions -}
Var :: { SimpleExp }
Var : Pos var   { OVar $1 $2 }

{- Integers -}
Int :: { SimpleExp }
Int : Pos int   { OInt $1 $2 }

{- Booleans -}
Bool :: { SimpleExp }
Bool : Pos true   { OBool $1 True }
     | Pos false  { OBool $1 False }

{- Literal characters -}
Char :: { SimpleExp }
Char : Pos char { OChar $1 $2 }

{- Block of code -}
Block :: { SimpleBlock }
Block : Pos '(' Exps ')'  { Block $1 (reverse $3) }

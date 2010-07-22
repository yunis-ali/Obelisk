{-

Copyright 2010 John Morrice

This source file is part of The Obelisk Programming Language and is distributed under the terms of the GNU General Public License

This file is part of The Obelisk Programming Language.

    The Obelisk Programming Language is free software: you can 
    redistribute it and/or modify it under the terms of the GNU 
    General Public License as published by the Free Software Foundation, 
    either version 3 of the License, or any later version.

    The Obelisk Programming Language is distributed in the hope that it 
    will be useful, but WITHOUT ANY WARRANTY; without even the implied 
    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
    See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with The Obelisk Programming Language.  
    If not, see <http://www.gnu.org/licenses/>

-}

-- Ensure parser output is correct
import Language.Obelisk.Parser

import qualified Language.Obelisk.Parser.Monad as M

import Control.Monad

main = 
   run_tests "success" success >> run_tests "failure" failure

run_tests name =
   mapM (\ t -> do
      putStrLn $ "\n\nThe parser must report " ++ name ++ ":"
      putStrLn $ "\n\nTest:\n" ++ t ++ "\n\n"
      putTest $ eparse name t)

putTest r = putStrLn $
   case r of
   M.ParseOK ob -> show ob
   M.ParseFail s -> s

success =
   ["((A) # def howdy x y z ((x 'a' z)))"
   ,"((A) # def a (b) where ((A # let b a)))"
   ,"((Int -> Double -> TripleVodka) # def a ())"
   ,"((A) # def x () where (((Int -> Double) # let z a)))"
   ]

failure =
   ["(A # let a (6 + 3))"
   ,"((("
   ,")))"
   ,"'x'"
   ,"(A # let a (def x ())"
   ,"(A # let def 3)"
   ,"(A # if let (3) (4))"
   ]

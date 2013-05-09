module Main where
import Data.Array.Repa.Series           as R
import Data.Array.Repa.Series.Series    as S
import Data.Array.Repa.Series.Vector    as V
import qualified Data.Vector.Unboxed    as U

---------------------------------------------------------------------
-- | Set the primitives used by the lowering transform.
repa_primitives :: R.Primitives
repa_primitives =  R.primitives


---------------------------------------------------------------------
main
 = do   v1      <- V.fromUnboxed $ U.enumFromN (1 :: Int) 10
        print $ R.runSeries v1 lower_single
        print $ R.runSeries v1 lower_ffold
        print $ R.runSeries v1 lower_fffold
        print $ R.runSeries v1 lower_foldMap
        print $ R.runSeries v1 lower_map
        print $ R.runSeries v1 lower_map_map


-- Single fold.
lower_single :: R.Series k Int -> Int
lower_single s
 = R.fold (+) 0 s


-- Double fold fusion.
--  Computation of both reductions is interleaved.
lower_ffold :: R.Series k Int -> Int
lower_ffold s
 = R.fold (+) 0 s + R.fold (*) 1 s


-- Triple fold fusion.
--  We end up with an extra let-binding for the second baseband 
--  addition that needs to be handled properly.
lower_fffold :: R.Series k Int -> Int
lower_fffold s
 = R.fold (+) 0 s + R.fold (*) 1 s + R.fold (*) 1 s


-- Fold/map fusion.
lower_foldMap :: R.Series k Int -> Int
lower_foldMap s
 = R.fold (+) 0 (R.map (\x -> x * 2) s)


-- Single maps
--  The resulting code produces a vector rather than a plain Int.
lower_map :: R.Series k Int -> Vector Int
lower_map s
 = S.toVector (R.map (\x -> x * 2 + 1) s)


-- Map/map fusion,
--  Producing a vector.
lower_map_map :: R.Series k Int -> Vector Int
lower_map_map s
 = S.toVector (R.map (\x -> x * 2) (R.map (\x -> x + 1) s))



{-}
-- Fold a series while mapping across it.
--  The source elements are only read from memory once.
lower_fold_map :: R.Series k Int -> (Int, Vector Int)
lower_fold_map s
 = ( R.fold (+) 0 s
   , R.map  (\x -> x * 2) s)

-}



{-# LANGUAGE MagicHash #-}
module Data.Array.Repa.Repr.Cursored
        ( C, Array (..)
        , makeCursored)
where
import Data.Array.Repa.Base
import Data.Array.Repa.Shape
import Data.Array.Repa.Index
import Data.Array.Repa.Repr.Delayed
import Data.Array.Repa.Repr.Undefined
import Data.Array.Repa.Eval.Fill
import Data.Array.Repa.Eval.Elt
import Data.Array.Repa.Eval.Cursored
import GHC.Exts
import Debug.Trace

-- | Cursored Arrays.
--   These are produced by Repa's stencil functions, and help the fusion
--   framework to share index compuations between array elements.
--
--   The basic idea is described in ``Efficient Parallel Stencil Convolution'',
--   Ben Lippmeier and Gabriele Keller, Haskell 2011 -- though the underlying
--   array representation has changed since this paper was published.
data C

data instance Array C sh e
        = forall cursor. ACursored
        { cursoredExtent :: sh 
                
          -- | Make a cursor to a particular element.
	, makeCursor    :: sh -> cursor

	  -- | Shift the cursor by an offset, to get to another element.
	, shiftCursor   :: sh -> cursor -> cursor

	  -- | Load\/compute the element at the given cursor.
	, loadCursor	:: cursor -> e }


-- Repr -----------------------------------------------------------------------
-- | Compute elements of a cursored array.
instance Repr C a where
 index (ACursored _ makec _ loadc)
        = loadc . makec
 {-# INLINE index #-}

 unsafeIndex    = index
 {-# INLINE unsafeIndex #-}
 
 linearIndex (ACursored sh makec _ loadc)
        = loadc . makec . fromIndex sh
 {-# INLINE linearIndex #-}

 extent (ACursored sh _ _ _)
        = sh
 {-# INLINE extent #-}
        
 deepSeqArray (ACursored sh makec shiftc loadc) y
  = sh `deepSeq` makec  `seq` shiftc `seq` loadc `seq` y
 {-# INLINE deepSeqArray #-}


-- Fill -----------------------------------------------------------------------
-- | Compute all elements in an rank-2 array. 
instance (Fillable r2 e, Elt e) => Fill C r2 DIM2 e where
 fillP (ACursored (Z :. (I# h) :. (I# w)) makec shiftc loadc) marr
  = do  traceEventIO "Repa.fillP[Cursored]: start"
        fillCursoredBlock2P 
                (unsafeWriteMArr marr) 
                makec shiftc loadc
                w 0# 0# w h
        touchMArr marr
        traceEventIO "Repa.fillP[Cursored]: end"
 {-# INLINE fillP #-}
        
 fillS (ACursored (Z :. (I# h) :. (I# w)) makec shiftc loadc) marr
  = do  traceEventIO "Repa.fillS[Cursored]: start"
        fillCursoredBlock2S 
                (unsafeWriteMArr marr) 
                makec shiftc loadc
                w 0# 0# w h
        touchMArr marr
        traceEventIO "Repa.fillS[Cursored]: end"
 {-# INLINE fillS #-}
        

-- | Compute a range of elements in a rank-2 array.
instance (Fillable r2 e, Elt e) => FillRange C r2 DIM2 e where
 fillRangeP  (ACursored (Z :. _h :. (I# w)) makec shiftc loadc) marr
             (Z :. (I# y0) :. (I# x0)) (Z :. (I# h0) :. (I# w0))
  = do  traceEventIO "Repa.fillRangeP[Cursored]: start"
        fillCursoredBlock2P 
                (unsafeWriteMArr marr) 
                makec shiftc loadc
                w x0 y0 w0 h0
        touchMArr marr
        traceEventIO "Repa.fillRangeP[Cursored]: end"
 {-# INLINE fillRangeP #-}
        
 fillRangeS  (ACursored (Z :. _h :. (I# w)) makec shiftc loadc) marr
             (Z :. (I# y0) :. (I# x0)) 
             (Z :. (I# h0) :. (I# w0))
  = do  traceEventIO "Repa.fillRangeS[Cursored]: start"
        fillCursoredBlock2S
                (unsafeWriteMArr marr) 
                makec shiftc loadc
                w x0 y0 w0 h0
        touchMArr marr
        traceEventIO "Repa.fillRangeS[Cursored]: end"
 {-# INLINE fillRangeS #-}
        

-- Conversions ----------------------------------------------------------------
-- | Define a new cursored array.
makeCursored 
        :: sh
        -> (sh -> cursor)               -- ^ Create a cursor for an index.
        -> (sh -> cursor -> cursor)     -- ^ Shift a cursor by an offset.
        -> (cursor -> e)                -- ^ Compute the element at the cursor.
        -> Array C sh e

makeCursored = ACursored
{-# INLINE makeCursored #-}


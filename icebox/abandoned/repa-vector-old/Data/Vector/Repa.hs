
module Data.Vector.Repa
        ( -- * Representations
          N
        , Vector

          -- * Conversion
        , chain
        , unchainP
        , unchainS

          -- * Projections
        , vlength

          -- * Constructors
        , vreplicate
        , vreplicates

          -- * Maps and Zips
        , Map(..)
        , Zip(..)
        , vzip3
        , vzip4
        , vzip5
        , vzip6
        , vzipWith
        , vzipWith3
        , vzipWith4
        , vzipWith5
        , vzipWith6)
where
import Data.Vector.Repa.Operators.Zip
import Data.Vector.Repa.Operators.Replicate
import Data.Vector.Repa.Repr.Chain
import Data.Vector.Repa.Base

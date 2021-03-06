
module Data.Array.Repa.Plugin.FatName
        ( GhcName (..)
        , FatName (..))
where
import Data.Array.Repa.Plugin.GHC.Pretty        ()

import DDC.Base.Pretty
import qualified DDC.Core.Flow.Prim     as D

import qualified Var                    as G
import qualified Literal                as G
import qualified TyCon                  as G
import qualified TypeRep                as G


data GhcName
        = GhcNameVar     G.Var
        | GhcNameTyCon   G.TyCon
        | GhcNameTyLit   G.TyLit
        | GhcNameLiteral G.Literal
        | GhcNameIntU   
        | GhcNameWordU
        | GhcNameFloatU
        | GhcNameDoubleU
        deriving (Eq, Ord)

instance Pretty GhcName where
 ppr nn
  = case nn of
        GhcNameVar     v        -> text "VAR   " <> ppr v
        GhcNameTyCon   tc       -> text "TYCON " <> ppr tc
        GhcNameTyLit   tylit    -> text "TYLIT " <> ppr tylit
        GhcNameLiteral lit      -> text "LIT   " <> ppr lit
        GhcNameIntU             -> text "Int#"
        GhcNameWordU            -> text "Word#"
        GhcNameFloatU           -> text "Float#"
        GhcNameDoubleU          -> text "Double#"


data FatName
        = FatName
        { fatNameGHC    :: GhcName
        , fatNameDDC    :: D.Name }
        deriving (Eq, Ord)

instance Pretty FatName where
 ppr (FatName _ name)   = ppr name


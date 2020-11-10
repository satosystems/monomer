-- {-# OPTIONS_GHC -F -pgmF hspec-discover #-}

import Test.Hspec

import qualified Monomer.Widgets.ButtonSpec as ButtonSpec
import qualified Monomer.Widgets.GridSpec as GridSpec
import qualified Monomer.Widgets.LabelSpec as LabelSpec
import qualified Monomer.Widgets.StackSpec as StackSpec

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  ButtonSpec.spec
  GridSpec.spec
  LabelSpec.spec
  StackSpec.spec

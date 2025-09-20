module Tintin.Errors
  ( Errors
  , showAndDie
  , textDie
  )
where

import qualified Data.Text as T
import Tintin.Core
import Tintin.Capabilities.Logging (Logging)
import qualified Tintin.Capabilities.Logging as Logging

data Errors

showAndDie :: ( Has Logging.Capability eff
              , Show error
              )
           => [error]
           -> Effectful eff ()
showAndDie errors = do
    errors
     & mapM_ (Logging.err . show)
    die "Errors found. Exiting."

textDie :: ( Has Logging.Capability eff
           )
        => [T.Text]
        -> Effectful eff ()
textDie errors = do
    errors
     & mapM_ Logging.err
    die "Errors found. Exiting."


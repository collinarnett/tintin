module Tintin.Parse
  ( Parse
  , docs
  )
where

import  Tintin.Core
import Tintin.Capabilities.Logging (Logging)
import qualified Tintin.Capabilities.Logging as Logging
import Tintin.Capabilities.Filesystem (Filesystem)
import qualified Tintin.Capabilities.Filesystem as Filesystem
import Tintin.Domain.DocumentationFile (DocumentationFile)
import qualified Tintin.Domain.DocumentationFile as DocumentationFile
import Tintin.Errors (Errors)
import qualified Tintin.Errors as Errors


data Parse

docs :: ( Has Logging.Capability eff
        , Has Filesystem.Capability eff
        )
     => DocumentationDirectory
     -> [Filesystem.Path]
     -> Effectful eff [DocumentationFile]
docs docDir filenames = do
  Logging.debug "Parsing documentation"
  (errors, docFiles) <- filenames
                        & traverse (readAndParse docDir)
                        & fmap partitionEithers
  unless (null errors) (Errors.showAndDie errors)
  return docFiles


readAndParse :: ( Has Logging.Capability eff
                , Has Filesystem.Capability eff
                )
             => DocumentationDirectory
             -> Filesystem.Path
             -> Effectful eff (Either DocumentationFile.ParseError DocumentationFile)
readAndParse ( DocumentationDirectory d ) ( Filesystem.Path f ) = do
  contents <- Filesystem.readFile ( Filesystem.Path $ d <> "/" <> f)
  return $ DocumentationFile.new (DocumentationFile.Filename f) contents





module Tintin
  ( runApp
  , publish
  )
where

import Tintin.Core

import Tintin.Capabilities.Logging (Logging)
import qualified Tintin.Capabilities.Logging as Logging
import Tintin.Capabilities.Filesystem (Filesystem)
import qualified Tintin.Capabilities.Filesystem as Filesystem
import Tintin.Capabilities.Process (Process)
import qualified Tintin.Capabilities.Process as Process
import Tintin.Parse (Parse)
import qualified Tintin.Parse as Parse
import Tintin.Render (Render)
import qualified Tintin.Render as Render
import Tintin.Errors (Errors)
import qualified Tintin.Errors as Errors
import Tintin.ConfigurationLoading (ConfigurationLoading)
import qualified Tintin.ConfigurationLoading as ConfigurationLoading
import Tintin.Domain.HtmlFile (HtmlFile)
import qualified Tintin.Domain.HtmlFile as HtmlFile

import Data.Text (Text)
import qualified Data.Text as Text



publish :: ( Has Logging.Capability eff
           , Has Filesystem.Capability eff
           , Has Process.Capability eff
           )
        => OutputDirectory
        -> Effectful eff ()
publish (OutputDirectory p)= do
  gitContents <- Filesystem.readFile ( Filesystem.Path ".git/config" )
  let r = lines gitContents
          &  dropWhile (not . Text.isInfixOf "origin")
          &  nonEmpty
          & fmap tail
          & flatMap safeHead
          & fmap (Text.dropWhile (/= '='))
          & fmap (Text.dropWhile (/= 'g'))
  case r of
    Nothing ->
      Errors.textDie ["Could not read origin remote. Are you in a Git repository?"]

    Just remote -> do
      Logging.debug "Initializing repo"
      Process.call ( Process.CommandName $ "cd " <> p
                     <> " && git init"
                   )
      Logging.debug "Adding origin remote"
      Process.call ( Process.CommandName $ "cd " <> p
                     <> " && git remote add origin " <> remote
                   )
      Logging.debug "Cheking out gh-pages"
      Process.call ( Process.CommandName $ "cd " <> p
                     <> " && git checkout -b gh-pages"
                   )
      Logging.debug "Adding new docs"
      Process.call ( Process.CommandName $ "cd " <> p
                     <> " && git add *"
                   )
      Logging.debug "Commiting"
      Process.call ( Process.CommandName $ "cd " <> p
                     <> " && git commit -m 'Update docs'"
                   )
      Logging.debug "Pushing"
      Process.call ( Process.CommandName $ "cd " <> p
                     <> " && git push -f origin gh-pages"
                   )


runApp :: ( Has Logging.Capability eff
          , Has Filesystem.Capability eff
          , Has Process.Capability eff
          )
       => Bool
       -> OutputDirectory
       -> Effectful eff ()
runApp shouldUseCabal outputDirectory = do
  cleanUp outputDirectory
  docDir    <- getDocumentationDirectory
  filenames <- getDocumentationFilenames docDir
  let buildTool = if shouldUseCabal then HtmlFile.Cabal else HtmlFile.Stack

  Parse.docs docDir filenames
   & flatMap (Render.perform buildTool)
   & flatMap (ConfigurationLoading.loadInfo)
   & flatMap (Render.writeOutput outputDirectory)


cleanUp :: ( Has Logging.Capability eff
           , Has Filesystem.Capability eff
           )
        => OutputDirectory
        -> Effectful eff ()
cleanUp (OutputDirectory p) = do
  Logging.debug "Cleaning output directory"
  Filesystem.deleteIfExists (Filesystem.Path p)



getDocumentationFilenames :: ( Has Logging.Capability eff
                             , Has Filesystem.Capability eff
                             )
                          => DocumentationDirectory
                          -> Effectful eff [Filesystem.Path]
getDocumentationFilenames (DocumentationDirectory docDir) = do
  Logging.debug ( "Reading documentation files at " <> docDir )
  Filesystem.Path docDir
   & Filesystem.list
   & fmap (Filesystem.getPathsWith $ Filesystem.Extension ".md")



getDocumentationDirectory :: Has Filesystem.Capability eff
                          => Effectful eff DocumentationDirectory
getDocumentationDirectory = do
  Filesystem.Path currentDir <- Filesystem.currentDirectory
  return ( DocumentationDirectory $ currentDir <> "/doc/" )




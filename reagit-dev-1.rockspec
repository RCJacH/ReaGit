package = "ReaGit"
version = "dev-1"
source = {
   url = "git+https://github.com/RCJacH/ReaGit.git"
}
description = {
   homepage = "https://github.com/RCJacH/ReaGit",
   license = "*** please specify a license ***"
}
build = {
   type = "builtin",
   modules = {
      chunkparser = "src/chunkparser.lua",
      git = "src/git.lua",
      interface = "src/interface.lua",
      ["parser.chunk"] = "src/parser/chunk.lua",
      ["parser.node"] = "src/parser/node.lua",
      ["parser.token"] = "src/parser/token.lua",
      pathlib = "src/pathlib.lua",
      project = "src/project.lua",
      settings = "src/settings.lua",
      sh = "src/sh.lua",
      ["std+"] = "src/std+.lua"
   }
}

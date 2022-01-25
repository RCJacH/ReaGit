LU = require('luaunit')
local workspace_folder = debug.getinfo(1).source:match("@(.*[/\\]).+[/\\]")

package.path = package.path .. ';' .. workspace_folder ..'?.lua'

require('src.std+')
Pathlib = require('src.pathlib')
ChunkParser = require('src.chunkparser')

local project_path = workspace_folder .. 'test/project/'

dofile('test/chunks.lua')

function testEmptyTrack()
    local parser = ChunkParser(EMPTY_TRACK)
    LU.assertEquals(parser.id, '2296AB9A-3C5D-4928-85F1-E1D1FE12BC95')
    LU.assertEquals(parser.name, 'Track is empty')
    LU.assertEquals(#parser.children, 0)
end

function testParseChildren()
    local parser = ChunkParser(ITEM_SOURCED)
    LU.assertEquals(#parser.children, 1)
    local take = parser.children[1]
    LU.assertEquals(take.type, 'TAKE')
    LU.assertEquals(#take, 2)
    LU.assertEquals(take.children[1].type, 'SOURCE')
end

function testMultipleTakes()
    local parser = ChunkParser(ITEM_WITH_MULTIPLE_TAKES)
    LU.assertEquals(#parser.children, 3)
end

function testGroup()
    local parser = ChunkParser(GROUP_WITH_MULTIPLE_TRACKS)
    LU.assertEquals(parser.type, 'GROUP')
    LU.assertEquals(parser.subtype, 'TEST')
    LU.assertEquals(#parser.children, 2)
    LU.assertEquals(parser.children[1].id, '320653B5-869B-49C8-9435-0D974C7A845C')
    LU.assertEquals(parser.children[2].id, '33374A97-357A-460B-BF17-2DE20F29CF97')
    LU.assertEquals(#parser.children[2].children, 2)
end

function testFileStructure()
    local parser = ChunkParser(GROUP_WITH_MULTIPLE_TRACKS)
    local path = Pathlib(project_path)
    parser:create_file_structure(path)
    local project_folder = path / 'TEST/'
    LU.assertIsTrue(project_folder:exists())
    project_folder:rm_no_regret()
end

function testRetrieveFromFolderStructure()
    local parser = ChunkParser(GROUP_WITH_MULTIPLE_TRACKS)
    local path = Pathlib(project_path)
    parser:create_file_structure(path)
    local project_folder = path / 'TEST/'
    local parser2 = ChunkParser(project_folder)
    local s1 = tostring(parser)
    local s2 = tostring(parser2)
    LU.assertEquals(s1, s2)
    project_folder:rm_no_regret()
end

os.exit(LU.LuaUnit.run())

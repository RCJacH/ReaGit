LU = require('luaunit')
local workspace_folder = debug.getinfo(1).source:match("@(.*[/\\]).+[/\\]")

package.path = package.path .. ';' .. workspace_folder ..'?.lua'

require('src.std+')
PATHLIB = require('src.pathlib')
CHUNKPARSER = require('src.chunkparser')

local project_path = workspace_folder .. 'test/project/'

EMPTY_TRACK = [[<TRACK {2296AB9A-3C5D-4928-85F1-E1D1FE12BC95}
NAME "Track is empty"
TRACKID {2296AB9A-3C5D-4928-85F1-E1D1FE12BC95}
>]]

ITEM_SOURCED = [[    <ITEM
SEL 0
IGUID {5142DB17-C86E-4264-903F-B09FC9BBEE8E}
IID 2
NAME "Referenced MIDI"
GUID {C19BF76F-CEC1-4F26-AE79-DEF746C1B741}
<SOURCE MIDIPOOL
  POOLEDEVTS {7325073C-1D7F-468B-BAB3-429ECC1CAAD9}
  GUID {08F64A65-197F-4D30-85AB-380388D6D973}
>
>]]

ITEM_WITH_MULTIPLE_TAKES = [[    <ITEM
SEL 0
IGUID {4C881EF6-B8BB-4B08-892B-AF3691AD5B25}
IID 9
NAME "Take 1/3"
GUID {F0E0C31F-E612-4747-8D1A-86A919F05A65}
<SOURCE MIDI
  POOLEDEVTS {1CD43D32-A4BC-4B3B-A3DB-360C0FD7E0A4}
  GUID {F0AFF325-4F85-491A-81EA-8EDD70390B21}
>
TAKE SEL
NAME "Take 2/3"
GUID {811E6C8B-519E-45FF-97D3-A3D65BFD5D49}
<SOURCE MIDI
  POOLEDEVTS {014DDD1D-039A-438C-8B52-894E2E551858}
  GUID {D7A3205B-93DF-47A3-9217-15E6013F49D4}
>
<VOLENV
  EGUID {0212225E-590C-4A4F-88C8-ABB7050C20D5}
>
TAKE NULL
>

]]

GROUP_WITH_MULTIPLE_TRACKS = [[<GROUP TEST
<TRACK {320653B5-869B-49C8-9435-0D974C7A845C}
NAME "Track with child tracks"
ISBUS 1 1
TRACKID {320653B5-869B-49C8-9435-0D974C7A845C}
>
<TRACK {33374A97-357A-460B-BF17-2DE20F29CF97}
NAME "Child Track"
ISBUS 2 -1
TRACKID {33374A97-357A-460B-BF17-2DE20F29CF97}
<VOLENV2
  EGUID {40D5874C-B631-4D2E-AC94-F502D93E9EBD}
>
<ITEM
  IGUID {4B5282A0-620F-40EF-888F-8CD5B9CC3FBB}
  IID 15
  NAME "Referenced MIDI"
  GUID {D02EE17F-E79D-43FF-90E7-BDCC9036F685}
  <SOURCE MIDI
    POOLEDEVTS {60EB2A66-9BAF-42F0-BBE8-A564EBFE4F7D}
    GUID {304D889D-8B83-4B6A-93B6-D7DE4D2D1ECB}
  >
>
>
>]]

function testEmptyTrack()
    local parser = CHUNKPARSER(EMPTY_TRACK)
    LU.assertEquals(parser.id, '2296AB9A-3C5D-4928-85F1-E1D1FE12BC95')
    LU.assertEquals(parser.name, 'Track is empty')
    LU.assertEquals(#parser.children, 0)
end

function testParseChildren()
    local parser = CHUNKPARSER(ITEM_SOURCED)
    LU.assertEquals(#parser.children, 1)
    local take = parser.children[1]
    LU.assertEquals(take.type, 'TAKE')
    LU.assertEquals(#take, 2)
    LU.assertEquals(take.children[1].type, 'SOURCE')
end

function testMultipleTakes()
    local parser = CHUNKPARSER(ITEM_WITH_MULTIPLE_TAKES)
    LU.assertEquals(#parser.children, 3)
end

function testGroup()
    local parser = CHUNKPARSER(GROUP_WITH_MULTIPLE_TRACKS)
    LU.assertEquals(parser.type, 'GROUP')
    LU.assertEquals(parser.subtype, 'TEST')
    LU.assertEquals(#parser.children, 2)
    LU.assertEquals(parser.children[1].id, '320653B5-869B-49C8-9435-0D974C7A845C')
    LU.assertEquals(parser.children[2].id, '33374A97-357A-460B-BF17-2DE20F29CF97')
    LU.assertEquals(#parser.children[2].children, 2)
end

function testFileStructure()
    local parser = CHUNKPARSER(GROUP_WITH_MULTIPLE_TRACKS)
    local path = PATHLIB(project_path)
    parser:create_file_structure(path)
    local project_folder = path / 'TEST'
    LU.assertIsTrue(project_folder:exists())
end

os.exit(LU.LuaUnit.run())

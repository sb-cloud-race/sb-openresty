--- @module Module providing a non-validating XML stream parser in Lua. 
--  
--  Features:
--  =========
--  
--      * Tokenises well-formed XML (relatively robustly)
--      * Flexible handler based event API (see below)
--      * Parses all XML Infoset elements - ie.
--          - Tags
--          - Text
--          - Comments
--          - CDATA
--          - XML Decl
--          - Processing Instructions
--          - DOCTYPE declarations
--      * Provides limited well-formedness checking 
--        (checks for basic syntax & balanced tags only)
--      * Flexible whitespace handling (selectable)
--      * Entity Handling (selectable)
--  
--  Limitations:
--  ============
--  
--      * Non-validating
--      * No charset handling 
--      * No namespace support 
--      * Shallow well-formedness checking only (fails
--        to detect most semantic errors)
--  
--  API:
--  ====
--
--  The parser provides a partially object-oriented API with 
--  functionality split into tokeniser and handler components.
--  
--  The handler instance is passed to the tokeniser and receives
--  callbacks for each XML element processed (if a suitable handler
--  function is defined). The API is conceptually similar to the 
--  SAX API but implemented differently.
--
--  XML data is passed to the parser instance through the 'parse'
--  method (Note: must be passed a single string currently)
--
--  License:
--  ========
--
--      This code is freely distributable under the terms of the [MIT license](LICENSE).
--
--
--@author Paul Chakravarti (paulc@passtheaardvark.com)
--@author Manoel Campos da Silva Filho
local xml2lua = { _VERSION = "1.5-2-ordered" }
local XmlParser = require("XmlParser")

---Recursivelly prints a table in an easy-to-ready format
--@param tb The table to be printed
--@param level the indentation level to start with
local function printableInternal(tb, level)
    if tb == nil then
        return
    end

    level = level or 1
    local spaces = string.rep(' ', level * 2)
    for k, v in pairs(tb) do
        if type(v) == "table" then
            print(spaces .. k)
            printableInternal(v, level + 1)
        else
            print(spaces .. k .. '=' .. v)
        end
    end
end

---Instantiates a XmlParser object to parse a XML string
--@param handler Handler module to be used to convert the XML string
--to another formats. See the available handlers at the handler directory.
-- Usually you get an instance to a handler module using, for instance:
-- local handler = require("xmlhandler/tree").
--@return a XmlParser object used to parse the XML
--@see XmlParser
function xml2lua.parser(handler)
    if handler == xml2lua then
        error("You must call xml2lua.parse(handler) instead of xml2lua:parse(handler)")
    end

    local options = {
        --Indicates if whitespaces should be striped or not
        stripWS = 1,
        expandEntities = 1,
        errorHandler = function(errMsg, pos)
            error(string.format("%s [char=%d]\n", errMsg or "Parse Error", pos))
        end
    }

    return XmlParser.new(handler, options)
end

---Recursivelly prints a table in an easy-to-ready format
--@param tb The table to be printed
function xml2lua.printable(tb)
    printableInternal(tb)
end

---Handler to generate a string prepresentation of a table
--Convenience function for printHandler (Does not support recursive tables).
--@param t Table to be parsed
--@return a string representation of the table
function xml2lua.toString(t)
    local sep = ''
    local res = ''
    if type(t) ~= 'table' then
        return t
    end

    for k, v in pairs(t) do
        if type(v) == 'table' then
            v = xml2lua.toString(v)
        end
        res = res .. sep .. string.format("%s=%s", k, v)
        sep = ','
    end
    res = '{' .. res .. '}'

    return res
end

--- Loads an XML file from a specified path
-- @param xmlFilePath the path for the XML file to load
-- @return the XML loaded file content
function xml2lua.loadFile(xmlFilePath)
    local f, e = io.open(xmlFilePath, "r")
    if f then
        --Gets the entire file content and stores into a string
        local content = f:read("*a")
        f:close()
        return content
    end

    error(e)
end

---Gets an _attr element from a table that represents the attributes of an XML tag,
--and generates a XML String representing the attibutes to be inserted
--into the openning tag of the XML
--
--@param attrTable table from where the _attr field will be got
--@return a XML String representation of the tag attributes
local function attrToXml(attrTable)
    local s = ""
    attrTable = attrTable or {}

    for k, v in pairs(attrTable) do
        s = s .. " " .. k .. "=" .. '"' .. v .. '"'
    end
    return s
end

---Gets the first key of a given table
local function getFirstKey(tb)
    if type(tb) == "table" then
        for k, _ in pairs(tb) do
            return k
        end
        return nil
    end

    return tb
end

---Gets the first value of a given table
local function getFirstValue(tb)
    if type(tb) == "table" then
        for _, v in pairs(tb) do
            return v
        end
        return nil
    end

    return tb
end

xml2lua.level = 0
xml2lua.pretty = false

function xml2lua.getSpaces(level)
    local spaces = ''
    if (xml2lua.pretty) then
        spaces = string.rep(' ', level * 2)
    end
    return spaces
end

function xml2lua.addTagValueAttr(xmltb, tagName, tagValue, attrTable, level)
    local attrStr = attrToXml(attrTable)
    local spaces = xml2lua.getSpaces(level)
    table.insert(xmltb, spaces .. '<' .. tagName .. attrStr .. '>' .. tostring(tagValue) .. '</' .. tagName .. '>')
end

function xml2lua.startTag(xmltb, tagName, attrTable, level)
    if(type(tagName) ~= "number") then
        local attrStr = attrToXml(attrTable)
        local spaces = xml2lua.getSpaces(level)
        table.insert(xmltb, spaces .. '<' .. tagName .. attrStr .. '>')
    end
end

function xml2lua.endTag(xmltb, tagName, level)
    if(type(tagName) ~= "number") then
        local spaces = xml2lua.getSpaces(level)
        table.insert(xmltb, spaces .. '</' .. tagName .. '>')
    end
end

function xml2lua.parseObjectToXml(xmltb, obj, tagName, level)
    if (type(obj) == 'table') then
        xml2lua.startTag(xmltb, tagName, obj._attr, level)
        obj._attr = nil
        xml2lua.routeSequence(xmltb, obj, tagName, level + 1)
        xml2lua.endTag(xmltb, tagName, level)
    else
        if (tagName) then
            xml2lua.addTagValueAttr(xmltb, tagName, obj, nil, level)
        end
    end
end

function xml2lua.routeSequence(xmltb, obj, tagName, level)
    level = level or 1
    if (type(obj) == 'table') then
        if (obj._sequence) then
            for tag, value in xml2lua.getSorted(obj) do
                xml2lua.parseObjectToXml(xmltb, value, tag, level)
            end
        else
            for tag, value in pairs(obj) do
                xml2lua.parseObjectToXml(xmltb, value, tag, level)
            end
        end
    else
        xml2lua.parseObjectToXml(xmltb, value, tagName, level)
    end
end

function xml2lua.getContentByKeyName(table, keyname)
    for k, v in pairs(table) do
        if (k == keyname) then
            return v
        end
    end
end

function xml2lua.getSorted(tb_obj)
    local sequence = tb_obj._sequence
    local values = {}
    local tags = {}

    for _, v in pairs(sequence) do
        table.insert(values, 1, xml2lua.getContentByKeyName(tb_obj, v))
        table.insert(tags, 1, v)
    end
    table.insert(values, 1, tb_obj._attr)
    table.insert(tags, 1, '_attr')
    tb_obj._sequence = nil
    return function()
        local value = table.remove(values)
        local tag = table.remove(tags)
        if value ~= nil then
            return tag, value
        end
    end
end

---Converts a Lua table to a XML String representation.
--@param tb Table to be converted to XML
--@pretty output pretty xml
--
--@return a String representing the table content in XML
function xml2lua.toXml(tb, pretty, xmlRoot)
    xml2lua.pretty = pretty or false
    local xmltb = {}
    xmlRoot = xmlRoot or getFirstKey(tb)

    --tbl_debug.print_table(tb[xmlRoot]._attr)

    local xmlRootObj = tb[xmlRoot]
    if (type(xmlRootObj) == 'table') then
        xml2lua.startTag(xmltb, xmlRoot, xmlRootObj._attr, 0)
        xmlRootObj._attr = nil
        xml2lua.routeSequence(xmltb, getFirstValue(tb), xmlRoot)
    else
        xml2lua.startTag(xmltb, xmlRoot, nil, 0)
        table.insert(xmltb, tostring(getFirstValue(tb)))
    end
    xml2lua.endTag(xmltb, xmlRoot, 0)

    if (xml2lua.pretty) then
        return table.concat(xmltb, '\n')
    end
    return table.concat(xmltb)
end

return xml2lua

local xml2lua = require("xml2lua")
local cjson = require "cjson"
ngx.arg[1] = xml2lua.toXml(cjson.decode(ngx.arg[1]), "")
ngx.arg[2] = true

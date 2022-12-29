ngx.req.read_body()
data = ngx.req.get_body_data()
os.getenv("")
if data then
    local xml2lua = require("xml2lua")
    local handler = require("xmlhandler.tree")
    local parser = xml2lua.parser(handler)
    parser:parse(data)
    local cjson = require "cjson"
    ngx.req.set_body_data(cjson.encode(handler.root))
end

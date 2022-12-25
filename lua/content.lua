local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")
local cjson = require "cjson"

local method_name = ngx.req.get_method()
local method_id_tmp = ngx.GET
if (method_name == "POST") then
    method_id_tmp = ngx.HTTP_POST
else
    if (method_name == "PUT") then
        method_id_tmp = ngx.HTTP_PUT
    end
end

local capture_conf = { method = method_id_tmp }
local post_data = ngx.req.get_body_data()

if (post_data) then
    local parser = xml2lua.parser(handler)
    parser:parse(post_data)
    local json_data
    ngx.req.set_body_data(cjson.encode(handler.root))
    capture_conf.body = json_data
end

local args = ngx.req.get_uri_args()

if (args) then
    capture_conf.args = args
end

local res = ngx.location.capture(
        ngx.var.app_path .. ngx.var.path .. '.json',
        capture_conf)

local data = res.body
if (res.status == ngx.HTTP_OK and data) then
    local xmldata = xml2lua.toXml(cjson.decode(data))
    ngx.ctx.content_length = #xmldata
    ngx.print(xmldata)
else
    ngx.ctx.content_length = 0
end

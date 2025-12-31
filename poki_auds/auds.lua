--- Poki AUDS client module.
-- Provides helper functions to interact with Poki AUDS (Arbitrary User Data Store)
-- over HTTPS using Defold's `http.request` API.
--
-- This API is currently in development on Poki's side and subject to change.
-- See Poki docs: https://sdk.poki.com/auds.html
--
-- @module poki_auds

local M = {}

-- Check if running in editor scripts environment
local is_editor = type(editor) ~= "nil"

---@class PokiAudsResponse
---@field status integer HTTP status code
---@field headers table<string,string> Response headers
---@field raw string|nil Raw response body (string)
---@field json any|nil Decoded JSON value if available

---@alias PokiAudsCallback fun(self:table, success:boolean, result_or_error:any|nil, resp:PokiAudsResponse)

-- Mutable configuration
local current_game_id = nil
if not is_editor and sys and sys.get_config_string then
    current_game_id = sys.get_config_string("poki_auds.game_id")
end
local current_admin_token = nil
local http_fn = http.request
local current_base_url = "https://auds.poki.io/v0"

--- Set Poki game id used in all requests.
-- @param string game_id Your Poki game id
function M.set_game_id(game_id)
    current_game_id = game_id
end

--- Get currently configured Poki game id.
-- @return string|nil game id or nil if not set
function M.get_game_id()
    return current_game_id
end

--- Set Admin token to authorize update/delete requests via header.
-- If set, the module will send header `Authorization: AdminToken <token>`.
--
-- ⚠️ SECURITY WARNING ⚠️
-- This function grants FULL ADMINISTRATIVE ACCESS to ALL data in your AUDS store.
-- Anyone with this token can modify or delete ANY data for your game.
--
-- NEVER use this function in production game code that is distributed to players.
-- ONLY use it in:
--   - Secure server-side code
--   - Editor scripts (that never ship with your game)
--   - Development/testing environments
--
-- For production code, use per-item `secret` values instead (returned by `create()`).
-- If you must use admin token, ensure it is stored securely and never exposed in client code.
--
-- @param string|nil token Admin token (nil to clear)
function M.set_admin_token(token)
    current_admin_token = token
end

--- Get currently configured Admin token.
-- @return string|nil admin token or nil if not set
function M.get_admin_token()
    return current_admin_token
end

--- Set custom HTTP request function to replace default http.request.
-- Custom function should have the same signature as http.request:
--   Editor: fn(url, opts) -> response (synchronous)
--   Runtime: fn(url, method, callback, headers, post_data, options) (asynchronous)
-- Pass nil to use default http.request.
-- @param function|nil fn Custom HTTP request function (nil to use default)
function M.set_http_request_fn(fn)
    if fn ~= nil and type(fn) ~= "function" then
        error("http_request_fn must be a function or nil")
    end
    http_fn = fn
end

--- Set base URL for Poki AUDS API.
-- @param string base_url Base URL
function M.set_base_url(base_url)
    assert(type(base_url) == "string" and base_url ~= "", "base_url must be a non-empty string")
    current_base_url = base_url
end

--- Get currently configured base URL.
-- @return string base URL
function M.get_base_url()
    return current_base_url
end

-- Internal helpers

local function url_encode(str)
    if str == nil then return "" end
    str = tostring(str)
    -- RFC 3986 unreserved: ALPHA / DIGIT / '-' / '.' / '_' / '~'
    return (str:gsub("[^%w%-%._~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function build_query(params)
    if not params then return "" end
    local parts = {}
    for k, v in pairs(params) do
        if v ~= nil then
            table.insert(parts, url_encode(k) .. "=" .. url_encode(v))
        end
    end
    if #parts == 0 then return "" end
    return "?" .. table.concat(parts, "&")
end

local function build_url(path, params)
    if not current_game_id or current_game_id == "" then
        return nil, "Poki AUDS: game id is not set. Call set_game_id()."
    end
    local url = string.format("%s/%s%s", current_base_url, current_game_id, path)
    local query = build_query(params)
    return url .. query
end

local function make_headers(has_body)
    local headers = {
        Accept = "application/json",
    }
    if has_body then
        headers["Content-Type"] = "application/json"
    end
    if current_admin_token and current_admin_token ~= "" then
        headers["Authorization"] = "AdminToken " .. current_admin_token
    end
    return headers
end

local function decode_json_if_any(response, is_editor_response)
    local body = nil
    if is_editor_response then
        -- Editor response: body is already available
        body = response and response.body or nil
    else
        -- Runtime response: body is in response.response
        body = response and response.response or nil
    end

    if not body or body == "" then return nil end

    -- If body is already decoded (from editor with as="json"), return it
    if type(body) == "table" then
        return body
    end

    -- Otherwise, try to decode JSON string
    local content_type = nil
    if response.headers then
        for k, v in pairs(response.headers) do
            local k_lower = string.lower(k)
            if k_lower == "content-type" then
                content_type = type(v) == "table" and v[1] or v
                break
            end
        end
    end
    if content_type and not string.find(string.lower(content_type), "application/json", 1, true) then
        return nil
    end
    local ok, decoded = pcall(json.decode, body)
    if ok then
        return decoded
    end
    return nil
end

local function invoke_callback(self, user_cb, success, decoded_or_error, http_response, is_editor_response)
    if not user_cb then return end

    if is_editor_response then
        -- Editor: synchronous, call directly
        local resp = {
            status = http_response and http_response.status or 0,
            headers = http_response and http_response.headers or {},
            raw = http_response and http_response.body or nil,
            json = nil,
        }
        if success then
            resp.json = decoded_or_error
            user_cb(self or {}, true, decoded_or_error, resp)
        else
            user_cb(self or {}, false, decoded_or_error, resp)
        end
    else
        -- Runtime: asynchronous, use timer if no self
        if not self then
            timer.delay(0, function(new_self)
                invoke_callback(new_self, user_cb, success, decoded_or_error, http_response, false)
            end)
            return
        end
        local resp = {
            status = http_response and http_response.status or 0,
            headers = http_response and http_response.headers or {},
            raw = http_response and http_response.response or nil,
            json = nil,
        }
        if success then
            resp.json = decoded_or_error
            user_cb(self, true, decoded_or_error, resp)
        else
            user_cb(self, false, decoded_or_error, resp)
        end
    end
end

local function perform_request(method, path, query_params, body_tbl, callback)
    local url_or_nil, err = build_url(path, query_params)
    if not url_or_nil then
        invoke_callback(nil, callback, false, err, nil, is_editor)
        return
    end

    local post_data = nil
    if body_tbl ~= nil then
        local ok, encoded = pcall(json.encode, body_tbl)
        if not ok then
            invoke_callback(nil, callback, false, "Failed to encode body to JSON", nil, is_editor)
            return
        end
        post_data = encoded
    end

    local headers = make_headers(post_data ~= nil)

    if is_editor then
        -- Editor scripts: synchronous http.request
        local opts = {
            method = method,
            headers = headers,
            body = post_data,
            as = "json" -- Request JSON parsing
        }

        local ok_req, response = pcall(http_fn, url_or_nil, opts)
        if not ok_req then
            invoke_callback(nil, callback, false, "HTTP request failed: " .. tostring(response), nil, true)
            return
        end

        local status = response and response.status or 0
        local ok_http = status >= 200 and status < 300

        if ok_http then
            -- body is already decoded if as="json" was used
            local decoded = response.body
            if type(decoded) ~= "table" then
                decoded = decode_json_if_any(response, true)
            end
            invoke_callback(nil, callback, true, decoded, response, true)
        else
            local decoded = decode_json_if_any(response, true)
            local err_msg = decoded and (decoded.error or decoded.message) or (response and response.body) or ("HTTP " .. tostring(status))
            invoke_callback(nil, callback, false, err_msg, response, true)
        end
    else
        -- Runtime: asynchronous http.request
        http_fn(url_or_nil, method, function(self, _, response)
            local decoded = decode_json_if_any(response, false)
            local status = response and response.status or 0
            local ok_http = status >= 200 and status < 300
            if ok_http then
                invoke_callback(self, callback, true, decoded, response, false)
            else
                local err_msg = decoded and (decoded.error or decoded.message or decoded.key) or (response and response.response) or ("HTTP " .. tostring(status))
                invoke_callback(self, callback, false, err_msg, response, false)
            end
        end, headers, post_data, nil)
    end
end

-- Public API (CRUD)

--- Create userdata.
-- POST /userdata/<freeform-key>
-- Body example:
-- {
--   data = { ... },
--   values = { levelname = "Test", type = "arena-1v1" }
-- }
-- @param string freeform_key Resource group name (e.g. "tests", "levels")
-- @param table body Table matching Poki AUDS schema
-- @param PokiAudsCallback callback Callback receiving (success, result, response)
function M.create(freeform_key, body, callback)
    assert(type(freeform_key) == "string" and freeform_key ~= "", "freeform_key must be a non-empty string")
    assert(type(body) == "table", "body must be a table")
    perform_request("POST", string.format("/userdata/%s", url_encode(freeform_key)), nil, body, callback)
end

--- Fetch userdata by id.
-- GET /userdata/<freeform-key>/<id>
-- @param string freeform_key Resource group name
-- @param string id Item id returned by create
-- @param PokiAudsCallback callback Callback receiving (success, result, response)
function M.fetch(freeform_key, id, callback)
    assert(type(freeform_key) == "string" and freeform_key ~= "", "freeform_key must be a non-empty string")
    assert(type(id) == "string" and id ~= "", "id must be a non-empty string")
    perform_request("GET", string.format("/userdata/%s/%s", url_encode(freeform_key), url_encode(id)), nil, nil, callback)
end

--- List userdata.
-- GET /userdata/<freeform-key>?q=...&sort=...&includedata
-- Pass query params as table, e.g. { q = "type:arena-1v1", sort = "-created_at", includedata = true }
-- @param string freeform_key Resource group name
-- @param table|nil params Optional query params
-- @param PokiAudsCallback callback Callback receiving (success, result, response)
function M.list(freeform_key, params, callback)
    assert(type(freeform_key) == "string" and freeform_key ~= "", "freeform_key must be a non-empty string")
    local qp = nil
    if params then
        qp = {}
        for k, v in pairs(params) do
            if type(v) == "boolean" then
                if v then qp[k] = "" end -- boolean true becomes presence-only flag
            else
                qp[k] = v
            end
        end
    end
    perform_request("GET", string.format("/userdata/%s", url_encode(freeform_key)), qp, nil, callback)
end

--- Update userdata by id.
-- POST /userdata/<freeform-key>/<id>
-- Provide either a `secret` field in body or set Admin token via `set_admin_token`.
-- Only provided keys are updated.
-- @param string freeform_key Resource group name
-- @param string id Item id
-- @param table body Body table; may include fields: secret, data, values
-- @param PokiAudsCallback callback Callback receiving (success, result, response)
function M.update(freeform_key, id, body, callback)
    assert(type(freeform_key) == "string" and freeform_key ~= "", "freeform_key must be a non-empty string")
    assert(type(id) == "string" and id ~= "", "id must be a non-empty string")
    assert(type(body) == "table", "body must be a table")
    perform_request("POST", string.format("/userdata/%s/%s", url_encode(freeform_key), url_encode(id)), nil, body, callback)
end

--- Delete userdata by id.
-- DELETE /userdata/<freeform-key>/<id>
-- Provide `secret` in body or set Admin token via `set_admin_token`.
-- @param string freeform_key Resource group name
-- @param string id Item id
-- @param string|nil secret Optional secret string; ignored if Admin token is set
-- @param PokiAudsCallback callback Callback receiving (success, result, response)
function M.delete(freeform_key, id, secret, callback)
    assert(type(freeform_key) == "string" and freeform_key ~= "", "freeform_key must be a non-empty string")
    assert(type(id) == "string" and id ~= "", "id must be a non-empty string")
    local body = nil
    if (not current_admin_token or current_admin_token == "") and secret and secret ~= "" then
        body = { secret = secret }
    end
    perform_request("DELETE", string.format("/userdata/%s/%s", url_encode(freeform_key), url_encode(id)), nil, body, callback)
end

return M
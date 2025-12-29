# Poki AUDS (Defold Lua module)

Lua module for Poki AUDS (Arbitrary User Data Store) using Defold's `http.request`.

Reference API: [Poki AUDS docs](https://sdk.poki.com/auds.html)

## Installation

To use Poki AUDS module in your Defold project, add a version of the library to your `game.project` dependencies from the list of available [Releases](https://github.com/indiesoftby/defold-poki-auds/releases). Find the version you want, copy the URL to ZIP archive of the release and add it to the project dependencies.

Click `Project->Fetch Libraries` once you have added the version to `game.project` to download the library and make it available in your project.

## Configuration

```lua
local auds = require("poki_auds.auds")

auds.set_game_id("your-poki-game-id")

-- Optional: use admin token instead of per-item secrets
auds.set_admin_token("YOUR_ADMIN_TOKEN")
```

## Usage

```lua
local auds = require("poki_auds.auds")

auds.set_game_id("your-poki-game-id")
-- auds.set_admin_token("YOUR_ADMIN_TOKEN") -- optional

-- Create
auds.create("tests", {
    data = { tiles = {1, 0, 0}, note = "freeform" },
    values = { levelname = "Test level", type = "arena-1v1" }
}, function(self, ok, res, resp)
    pprint(ok and res or resp.status)
end)

-- Fetch
auds.fetch("tests", "<id>", function(self, ok, res)
    pprint(res)
end)

-- List (with filters/sort)
auds.list("tests", { q = "type:arena-1v1", sort = "levelname" }, function(self, ok, res)
    pprint(res)
end)

-- Update (with secret in body OR via admin token header)
auds.update("tests", "<id>", {
    -- secret = "<SECRET_FROM_CREATE>", -- not needed if admin token set
    data = { tiles = {1, 1, 0} },
    values = { levelname = "Edited", type = "arena-1v1" }
}, function(self, ok, res, resp)
    pprint(ok and res or resp.status)
end)

-- Delete (with secret in body OR via admin token header)
auds.delete("tests", "<id>", nil, function(self, ok, _, resp)
    print(ok, resp.status)
end)
```

## API

- `set_game_id(game_id)` / `get_game_id()`
- `set_admin_token(token)` / `get_admin_token()`
- `create(freeform_key, body, callback)`
- `fetch(freeform_key, id, callback)`
- `list(freeform_key, params, callback)`
  - `params` example: `{ q = "type:arena-1v1", sort = "-created_at", includedata = true }`
- `update(freeform_key, id, body, callback)`
  - `body` may include: `secret`, `data`, `values`
- `delete(freeform_key, id, secret, callback)`

## Callback signature

```lua
---@param self table -- script instance reference
---@param success boolean
---@param result any|nil -- decoded JSON on success, or error text on failure
---@param resp table -- { status:number, headers:table, raw:string|nil, json:any|nil }
function callback(self, success, result, resp) end
```

## Notes

- If `set_admin_token` is set, the module sends `Authorization: AdminToken <token>` on requests.
- For update/delete: if no admin token is set, provide `secret` in the request body.
- Per Poki docs, AUDS is in development and subject to change.

## License

This repository is distributed under the CC0 license; see the [LICENSE.md](LICENSE.md) file for details.

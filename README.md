# Poki AUDS for Defold

Lua module for Poki AUDS (Arbitrary User Data Store) using Defold's `http.request`.

Reference API: [Poki AUDS docs](https://sdk.poki.com/auds.html)

## What is AUDS?

AUDS (Arbitrary User Data Store) is a service that allows you to store and retrieve arbitrary data for your Poki games. Common use cases include:

- **Player levels**: Store user-generated levels and content that can be shared and played by other players
- **Leaderboards**: Create custom leaderboards
- **Remote config**: Store game configuration that can be updated without rebuilding the game (this module includes example code and convenient editor scripts for working with remote config)

## Installation

To use Poki AUDS module in your Defold project, add a version of the library to your `game.project` dependencies from the list of available [Releases](https://github.com/indiesoftby/defold-poki-auds/releases). Find the version you want, copy the URL to ZIP archive of the release and add it to the project dependencies.

Click `Project->Fetch Libraries` once you have added the version to `game.project` to download the library and make it available in your project.

## Configuration

```lua
local auds = require("poki_auds.auds")

-- By default, the module will use the game id from `game.project` but you can set it manually if needed
auds.set_game_id("your-poki-game-id")

-- Optional: use admin token instead of per-item secrets (ONLY for trusted environments - see notes below)
-- auds.set_admin_token("YOUR_ADMIN_TOKEN")
```

## Usage

```lua
local auds = require("poki_auds.auds")

-- auds.set_game_id("your-poki-game-id")

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
    secret = "<SECRET_FROM_CREATE>", -- not needed if admin token set
    data = { tiles = {1, 1, 0} },
    values = { levelname = "Edited", type = "arena-1v1" }
}, function(self, ok, res, resp)
    pprint(ok and res or resp.status)
end)

-- Delete (with secret in body OR via admin token header)
auds.delete("tests", "<id>", "<SECRET_FROM_CREATE>", function(self, ok, _, resp)
    print(ok, resp.status)
end)
```

## API

- `set_game_id(game_id)` / `get_game_id()`
- `set_admin_token(token)` / `get_admin_token()` - **⚠️ SECURITY WARNING**: Never use in production game code! See Notes section.
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

- By default, the module will use the game id from `game.project` but you can set it manually if needed.
- **⚠️ SECURITY WARNING**: `set_admin_token()` grants full administrative access to ALL data in your AUDS store. **NEVER** use it in production game code that ships to players. Only use it in secure server-side code or editor scripts. If the admin token is exposed, anyone can modify or delete any data for your game. Use per-item `secret` values instead for production code.
- If `set_admin_token` is set, the module sends `Authorization: AdminToken <token>` on requests.
- For update/delete: if no admin token is set, provide `secret` in the request body.
- Per Poki docs, AUDS is in development and subject to change.

## Remote Config

The module provides a helper for working with remote config stored in AUDS.

### Setup

1. In Poki for Developers, go to **Settings / Integrations** for your game and copy the AUDS admin token. Save it to a secure location.
2. Copy your Poki game ID from the same location.
3. Set the game ID in `game.project`:
   ```ini
   [poki_auds]
   game_id = your-poki-game-id
   ```
4. Create a `remote_config.json` file in the root of your project (or use a different name/path and update `game.project` accordingly):
   ```json
   {
     "test_string": "A",
     "test_boolean": true,
     "test_number": 1
   }
   ```
5. In the IDE, select **Project / Poki AUDS: Save Config** - the script will save the JSON to AUDS, store the configuration ID in `game.project` as `poki_auds.remote_config_id`, and save the secret to `remote_config.secret` file in the root of your project.
6. You can now use the remote config in your game!

Note: keep the secret - otherwise you will need to use the admin token to update or delete the config.

### Usage in Game

You can load the config in your game. See example in `example/example.script`:

```lua
local auds = require("poki_auds.auds")

function init(self)
    local config_id = sys.get_config_string("poki_auds.remote_config_id")
    local config_key = sys.get_config_string("poki_auds.remote_config_key", "config")

    auds.fetch(config_key, config_id, function(self, ok, result, resp)
        if ok then
            pprint(result.data)
        else
            print("ERROR: Failed to fetch remote config")
            print("Error: " .. tostring(result))
            if resp and resp.status then
                print("HTTP Status: " .. tostring(resp.status))
            end
        end
    end)
end
```

### Pro Tip

For faster startup times, you can load the remote config directly in JavaScript before the Defold engine finishes loading. This eliminates the need for an HTTP request from Lua and makes the config available immediately when your game starts.

Add this code to your `engine_template.html` (located in `builtins/manifests/` or your custom template):

```html
<script>
(function() {
    // Load remote config before Defold engine starts
    // {{#poki_auds.game_id}}
    // {{#poki_auds.remote_config_id}}
    const gameId = '{{poki_auds.game_id}}';
    const configKey = '{{poki_auds.remote_config_key}}';
    const configId = '{{poki_auds.remote_config_id}}';
    
    fetch(`https://auds.poki.io/v0/${gameId}/userdata/${configKey}/${configId}`)
        .then(response => response.text())
        .then(result => {
            // Store config in window for Defold to access
            window.pokiRemoteConfig = result;
        })
        .catch(error => {
            console.warn('Failed to load remote config:', error);
        });
    // {{/poki_auds.remote_config_id}}
    // {{/poki_auds.game_id}}
})();
</script>
```

Then in your Lua code, you can access the config:

```lua
function init(self)
    local config = nil

    -- Check if config was loaded via JavaScript
    if html5 then
        local config_json = html5.run("window.pokiRemoteConfig || ''")
        if config_json ~= "" then
            local config_obj = json.decode(config_json)

            -- Use your config here - config_obj.data is the JSON object
            config = config_obj.data
            -- pprint(config)
        end
    end

    if not config then
        -- No config loaded via JavaScript, so fetch from AUDS in Lua
        -- (see the example above)
    end
end
```

**Note**: The mustache tags `{{poki_auds.game_id}}`, `{{poki_auds.remote_config_key}}`, and `{{poki_auds.remote_config_id}}` will be automatically replaced with values from your `game.project` file when Defold builds your game.

## License

This repository is distributed under the CC0 license; see the [LICENSE.md](LICENSE.md) file for details.

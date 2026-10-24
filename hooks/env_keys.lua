--- Return environment variables for the tool
--- @param ctx {path: string}  Context information (SDK installation directory)
--- @return table Environment variables

local file = require("file")
local python = require("python")

function PLUGIN:EnvKeys(ctx)
    local version_path = ctx.path

    -- The SDK extracts directly to the version path
    local bin_path = file.join_path(version_path, "bin")

    local keys = {
        {
            key = "PATH",
            value = bin_path,
        },
        {
            key = "CLOUDSDK_ROOT_DIR",
            value = version_path,
        },
    }

    -- gcloud's macOS Python setup only recognizes interpreters from Homebrew,
    -- python.org or CLOUDSDK_PYTHON, and when it finds none it downloads and
    -- runs an installer with sudo. Point gcloud at an interpreter the user's
    -- shell would resolve, verified to be the exact version gcloud requires.
    -- Never override the interpreter the user chose themselves.
    local is_macos = RUNTIME.osType == "darwin" or RUNTIME.osType == "Darwin"
    local configured = os.getenv("CLOUDSDK_PYTHON")
    if is_macos and (not configured or configured == "") then
        local required = python.required_version(version_path)
        local found = required and python.find(required)
        if found then
            table.insert(keys, {
                key = "CLOUDSDK_PYTHON",
                value = found,
            })
        end
    end

    return keys
end

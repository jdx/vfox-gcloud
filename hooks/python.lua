--- Shared Python discovery for gcloud.
--- gcloud only accepts an interpreter whose minor version exactly matches the
--- one its macOS installer wants (read from the SDK itself), so every
--- candidate is executed and checked before it is used.

local file = require("file")
local cmd = require("cmd")
local strings = require("strings")

local M = {}

local function get_home_dir()
    return os.getenv("HOME") or os.getenv("USERPROFILE") or ""
end

--- Read the exact Python minor version gcloud's macOS installer wants, which is
--- recorded in the extracted SDK. Returns e.g. "3.14", or nil if it cannot be read.
function M.required_version(sdk_path)
    local manager = file.join_path(sdk_path, "lib", "googlecloudsdk", "core", "updater", "python_manager.py")
    if not file.exists(manager) then
        return nil
    end
    local contents = file.read(manager)
    if not contents then
        return nil
    end
    return string.match(contents, "PYTHON_VERSION%s*=%s*['\"](%d+%.%d+)['\"]")
end

--- Return the interpreter behind `candidate` if it runs and reports exactly
--- `version` (e.g. "3.14"), otherwise nil. gcloud accepts only an exact match.
function M.resolve(candidate, version)
    local command = string.format(
        '"%s" -c "import sys; print(sys.executable); print(\'.\'.join(str(n) for n in sys.version_info[:2]))"',
        candidate
    )
    local ok, output = pcall(cmd.exec, command)
    if not ok or type(output) ~= "string" then
        return nil
    end
    local lines = strings.split(strings.trim_space(output), "\n")
    if #lines < 2 or strings.trim_space(lines[2]) ~= version then
        return nil
    end
    local executable = strings.trim_space(lines[1])
    if executable == "" then
        return candidate
    end
    return executable
end

--- Find an interpreter that is exactly `version`, preferring locations the
--- user's shell would resolve before the ones gcloud itself checks.
function M.find(version)
    local candidates = {}

    local configured = os.getenv("CLOUDSDK_PYTHON")
    if configured and configured ~= "" then
        table.insert(candidates, configured)
    end

    -- mise strips its shim directories from PATH while hooks run, so the
    -- shim must be probed explicitly. It is what the user's shell PATH would
    -- otherwise resolve `python` to, and it keeps pointing at the interpreter
    -- mise currently uses when versions change.
    local data_dir = os.getenv("XDG_DATA_HOME") or file.join_path(get_home_dir(), ".local", "share")
    if data_dir ~= "" then
        table.insert(candidates, file.join_path(data_dir, "mise", "shims", "python"))
    end

    table.insert(candidates, "/opt/homebrew/bin/python" .. version)
    table.insert(candidates, "/usr/local/bin/python" .. version)
    table.insert(candidates, "/Library/Frameworks/Python.framework/Versions/" .. version .. "/bin/python3")
    table.insert(candidates, "python" .. version)
    table.insert(candidates, "python3")
    table.insert(candidates, "python")

    for _, candidate in ipairs(candidates) do
        local executable = M.resolve(candidate, version)
        if executable then
            if file.exists(candidate) then
                -- Keep the candidate itself: it is an absolute path, and for
                -- mise's shim that is the address that stays valid when the
                -- version it points at changes.
                return candidate
            end
            -- A bare command name from PATH: use the interpreter it resolved to.
            return executable
        end
    end
    return nil
end

return M

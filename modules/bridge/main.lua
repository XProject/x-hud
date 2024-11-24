if not Config then
    lib.load("shared.config")
end

return lib.load(("modules/bridge/%s/%s"):format(Config.Framework, IsDuplicityVersion() and "server" or "client"))

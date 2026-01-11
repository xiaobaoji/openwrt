module("luci.controller.argon-config", package.seeall)

function index()
	if not nixio.fs.access('/www/luci-static/argon/css/cascade.css') then
		return
	end

	local page = entry({"admin", "system", "argon-config"}, form("argon-config"), _("主题设置"), 89)
	page.acl_depends = { "luci-app-argon-config" }
end

module("luci.controller.timecontrol",package.seeall)
function index()
if not nixio.fs.access("/etc/config/timecontrol")then return end
entry({"admin","services","timecontrol"},cbi("timecontrol"),translate("Internet Time Control"),60).acl_depends={ "luci-app-timecontrol" }
entry({"admin","services","timecontrol","status"},call("status")).leaf=true
end
function status()
local e={}
e.status=luci.sys.call("iptables -L FORWARD | grep TIMECONTROL >/dev/null")==0
luci.http.prepare_content("application/json")
luci.http.write_json(e)
end

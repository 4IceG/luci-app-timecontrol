local o = require "luci.sys"
local a, t, e
a = Map("timecontrol", translate("Internet Time Control"))
a.template = "timecontrol/index"

t = a:section(TypedSection, "basic")
t.anonymous = true

e = t:option(DummyValue, "timecontrol_status", translate("Status"))
e.template = "timecontrol/timecontrol"
e.value = translate("Collecting data...")

e = t:option(Flag, "enable", translate("Enabled"))
e.rmempty = false

t = a:section(TypedSection, "macbind", translate("Client Settings"), translate("Internet disabling settings for clients."))
t.template = "cbi/tblsection"
t.anonymous = true
t.addremove = true

e = t:option(Flag, "enable", translate("Enabled"))
e.rmempty = false

e = t:option(Value, "macaddr", "MAC")
e.rmempty = true
o.net.mac_hints(function(t, a) e:value(t, "%s (%s)" % {t, a}) end)

e = t:option(Value, "timeon", translate("No Internet start time"))
e.default = "00:00"
e.optional = false

e = t:option(Value, "timeoff", translate("No Internet end time"))
e.default = "23:59"
e.optional = false

e = t:option(Flag, "z1", translate("Mo"))
e.rmempty = true

e = t:option(Flag, "z2", translate("Tu"))
e.rmempty = true

e = t:option(Flag, "z3", translate("We"))
e.rmempty = true

e = t:option(Flag, "z4", translate("Th"))
e.rmempty = true

e = t:option(Flag, "z5", translate("Fr"))
e.rmempty = true

e = t:option(Flag, "z6", translate("Sa"))
e.rmempty = true

e = t:option(Flag, "z7", translate("Su"))
e.rmempty = true

return a

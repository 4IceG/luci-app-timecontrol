module("luci.controller.timecontrol", package.seeall)

function index()
    -- 主配置页面
    entry({"admin", "services", "timecontrol"}, cbi("timecontrol"), _("Internet Time Control"), 60).dependent = true
    -- Turbo ACC任务处理接口（供按钮调用）
    entry({"admin", "services", "timecontrol", "turbo_process"}, call("action_turbo_process")).leaf = true
    -- 保持原有扫描接口（如果存在）
    entry({"admin", "services", "timecontrol", "scan"}, call("action_scan")).leaf = true
end

-- Turbo ACC任务处理逻辑（与主文件逻辑一致，避免重复引用）
function action_turbo_process()
    local sys = require "luci.sys"
    local uci = require "luci.model.uci".cursor()
    
    local function time_to_minutes(time_str)
        local h, m = time_str:match("^(%d+):(%d+)$")
        return tonumber(h) * 60 + tonumber(m)
    end
    
    local function minutes_to_time(minutes)
        local h = math.floor(minutes / 60)
        local m = minutes % 60
        return string.format("%02d:%02d", h, m)
    end
    
    local function get_time_window()
        local min_timeon = nil
        local max_timeoff = nil
        uci:foreach("timecontrol", "macbind", function(section)
            if section.enable == "1" then
                local timeon = section.timeon or "22:30"
                local timeoff = section.timeoff or "07:00"
                local ton = time_to_minutes(timeon)
                local toff = time_to_minutes(timeoff)
                if not min_timeon or ton < min_timeon then min_timeon = ton end
                if not max_timeoff or toff > max_timeoff then max_timeoff = toff end
            end
        end)
        return min_timeon, max_timeoff
    end
    
    -- 执行任务并返回结果
    local timecontrol_enabled = uci:get("timecontrol", "config", "enabled") or "0"
    local task_comment = "# TimeControl Turbo ACC"
    sys.exec("sed -i '/" .. task_comment .. "/d' /etc/crontabs/root")
    
    local result = ""
    if timecontrol_enabled ~= "1" then
        sys.exec("/etc/init.d/cron restart")
        result = "Time control disabled, all Turbo ACC tasks removed"
    else
        local min_timeon, max_timeoff = get_time_window()
        if not min_timeon or not max_timeoff then
            result = "No enabled client rules found, no Turbo ACC tasks created"
        else
            local start_time = minutes_to_time(min_timeon)
            local end_time = minutes_to_time(max_timeoff)
            local start_h, start_m = start_time:match("^(%d+):(%d+)$")
            local end_h, end_m = end_time:match("^(%d+):(%d+)$")
            
            local disable_cmd = string.format(
                "/etc/init.d/qca-nss-ecm stop; %s",
                task_comment
            )
            local enable_cmd = string.format(
                "/etc/init.d/qca-nss-ecm start; %s",
                task_comment
            )
            
            sys.exec(string.format("echo '%s %s * * * %s' >> /etc/crontabs/root", start_m, start_h, disable_cmd))
            sys.exec(string.format("echo '%s %s * * * %s' >> /etc/crontabs/root", end_m, end_h, enable_cmd))
            sys.exec("/etc/init.d/cron restart")
            
            result = string.format("Turbo ACC tasks created:\n- Disable at %s (start of control)\n- Enable at %s (end of control)", start_time, end_time)
        end
    end
    
    -- 返回结果（纯文本，避免乱码）
    luci.http.prepare_content("text/plain; charset=utf-8")
    luci.http.write(result)
end

-- ★★★ 关键修复2：修复scan接口 ★★★
function action_scan()
    local sys = require "luci.sys"
    
    -- 执行扫描并获取输出
    local output = sys.exec("/etc/init.d/timecontrol scan showlogs 2>&1")
    
    local e = {}
    e.output = output
    e.success = (output:match("updated") ~= nil) or (output:match("No updates needed") ~= nil)
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function status()
	local e = {}
	e.status = (luci.sys.call("iptables -L FORWARD 2>/dev/null | grep -q TIMECONTROL") == 0)
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

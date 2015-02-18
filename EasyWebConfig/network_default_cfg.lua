ssid="ESP8266_".. node.chipid()
password="12345678"

function decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end


_G["para"] = {}

wifi.setmode(wifi.SOFTAP)
--set ap ssid and pwd
cfg={}
cfg.ssid=ssid
cfg.pwd=password
wifi.ap.config(cfg)
print(wifi.ap.getip())

--  http server
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
     conn:on("receive",function(conn,payload)
          --print(payload)
          print("received")
          --find last line in plyload(stupid function,improve later)
          local i = 0
          local j = 0
          while true do
               i = string.find(payload, "\n", i+1)
               -- find 'next' newline  
               if i == nil then break
               else 
               j=i
               end    
          end
          paraStr = string.sub(payload,j)
          
          if(_G["wifiStatue"] == nil) then _G["wifiStatue"]="..." end

          --there should be a "=" in Post data,such as ssid=id&password=ps
          if (string.find(paraStr,"=")~=nil) then
               file.open("network_user_cfg.lua","w+")
               for name, value in string.gfind(paraStr, "([^&=]+)=([^&=]+)") do
                 file.writeline(name.."=\""..decodeURI(value).."\"")
               end
               
               _G["wifiStatue"]="Saved"
               print("store ok")
               file.close()
          end

          -- html-output
          conn:send("HTTP/1.0 200 OK\r\nContent-type: text/html\r\nServer: ESP8266\r\n\n")
          conn:send("<html><head>")
          if(_G["wifiStatue"]=="Saved") then
          conn:send("<meta http-equiv=\"refresh\" content=\"30\">")
          end
          conn:send("</head><body>")
          conn:send("<div><h2>Configuration</h2>")
          conn:send("<font color=\"red\">[<i>".._G["wifiStatue"].."</i>]</color>")
          if(_G["wifiStatue"]=="Saved") then
          conn:send("<br>wait 30 sec<br>Server lost mean NO ERROR MET.")
          end
          conn:send("<FORM action=\"\" method=\"POST\">")
          conn:send("<table><tr><td>")
          
          for vK,vN in ipairs(_G["config"]) do
          conn:send("<tr><td>"..vN.name.."</td><td><input type=\"text\" name=\""..vN.name.."\" value=\"")
          if(_G[vN.name] ~= nil) then 
          conn:send(_G[vN.name])
          end
          conn:send("\"></td></tr>")
          end
          conn:send("<tr><td><input type=\"submit\" value=\"SAVE\"></td></tr>")
          conn:send("</table>")
          conn:send("</form></div>")
          conn:send("</body>")
          conn:send("</html>")
          conn:close()

          if(_G["wifiStatue"]=="Saved") then
               print("reboot")
               tmr.alarm(0,3000,0,function()node.restart() end )
          elseif(_G["wifiStatue"]=="..." or _G["wifiStatue"]=="Failed") then 
               --keep server open for 10 min to configure
               tmr.alarm(0,600000,0,function()node.restart() end )
          end
     end)
end)

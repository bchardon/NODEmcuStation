SSID = "WN-AERGFS"
PASSWORD = "qyo9vaesx6zf"
SCL = 4 -- GPIO2
SDA = 3 -- GPIO0
DHTPIN = 5

bmp085 = require("bmp085") 
dht = require("dht")


token = "5AORuSDZw2EO548Ozy7X9sNh7iqmv1VKcNPvczJ4YGDbEUJAEHc7DqzhRLDw"
dataselect = 1

function postUbidots(level)
    connout = nil
    connout = net.createConnection(net.TCP, 0)
 
    connout:on("receive", function(connout, payloadout)
        if (string.find(payloadout, "201 CREATED") ~= nil) then
            print("GOOD POST");
        end
    end)
 
    connout:on("connection", function(connout, payloadout)
    
        local tBMP,pBMP =readBMP();  
        local tDHT,hDHT =readDHT(); 
 
        if(dataselect == 1) then
        value = pBMP;
        idvariable = "569ecb917625424e73098158"
        dataselect = dataselect + 1
        elseif(dataselect == 2) then
        value = tDHT;
        idvariable = "569ecb6b7625424e1d0cc6bf"
        dataselect = dataselect + 1
        elseif(dataselect == 3) then
        value = hDHT;
        idvariable = "569ecbb77625424e1d0cc7cf"
        dataselect = dataselect + 1
        elseif(dataselect == 4) then
        value = tBMP;
        idvariable = "569ecb7a7625424d71dc01b6"
        dataselect = dataselect + 1
        elseif(dataselect == 5) then
        dataselect = 1
        else
        error("Mauvais choix de donnée")
        end
           
        local var = '{"value": '..value..'}';
        local num = string.len(var);  

        local postval = "POST /api/v1.6/variables/"..idvariable.."/values HTTP/1.1\n"       
          .."Content-Type: application/json\n"
          .."Content-Length: "..num.."\n"
          .."X-Auth-Token: "..token .."\n" 
          .."Host: things.ubidots.com\n\n"
          ..var.."\n\n"; 
        connout:send(postval)
    end)
 
    connout:on("disconnection", function(connout, payloadout)
        connout:close();
        collectgarbage();
    end)
 
    connout:connect(80,'things.ubidots.com')
end


function wait_for_wifi ( )
   tmr.alarm (1, 1000, 1, function ( )
      if wifi.sta.getip ( ) == nil then
         print ("Waiting for Wifi connection")
      else
         tmr.stop (1)
         print ("ESP8266 mode is: " .. wifi.getmode ( ))
         print ("The module MAC address is: " .. wifi.ap.getmac ( ))
         print ("Config done, IP is " .. wifi.sta.getip ( ))
      end
   end)
end

function connect()
    wifi.setmode(wifi.STATION);
    wifi.sta.config(SSID,PASSWORD,1)
    wait_for_wifi()
end 

function readBMP()
    bmp085.init(SDA, SCL)
    local t = bmp085.temperature()/10
    local p = bmp085.pressure()/100
    print("Temperature: " .. t .. " degrees C")
    print("Pressure: " .. p .. "Hpa")
    return t,p
end

function readBMP()
    bmp085.init(SDA, SCL)
    local t = bmp085.temperature()/10
    local p = bmp085.pressure()/100
    local p = p*((t+273.15)/((t+273.15)+0.0065*411))^-5.255 
    print("Temperature: " .. t .. " degrees C")
    print("Pressure: " .. p .. "Hpa")
    return t,p
end 

function readDHT()    
    local status,temp,humi,temp_decimal,humi_decimial = dht.read(DHTPIN) 
    if( status == dht.OK ) then
        print("DHT Temperature:"..temp..";".."Humidite"..humi)
    elseif( status == dht.ERROR_CHECKSUM ) then
        print( "DHT Checksum error." );
    elseif( status == dht.ERROR_TIMEOUT ) then
        print( "DHT Time out." );
    end
    return temp,humi
end

function http_conn(sock)
    sock:on("receive",function(sock,payload) 
    print(payload) -- for debugging only

    --ReadSensor 
        t,p =readBMP()
        temp,humi = readDHT() 
    --generates HTML web site     
    
    sock:send('HTTP/1.1 200 OK\r\nConnection: keep-alive\r\nCache-Control: private, no-store\r\n\r\n\
   <!DOCTYPE HTML>\
   <html><head>\
   <style>\
    body {background-color: #f8f8fa;\
    font-family: Helvetica, Sans-Serif;\
    border: 0px solid black;}\
    h1   {color:blue;}\
    h2   {text-align: center;}\
    iframe {  -moz-border-radius: 12px;\
  -webkit-border-radius: 12px;\
  border-radius: 12px;\
  -moz-box-shadow: 4px 4px 14px #000;\
  -webkit-box-shadow: 4px 4px 14px #000;\
  box-shadow: 4px 4px 14px #000;}\
    .header {height: 15%; text-align: center;}\
    .meteobox  { width: 80%;\
    border: 0px black solid;\
    padding-left: 5%;\
    margin: auto;\
    background-color: #f8f8fa;}\
   </style>\
   <meta content="text/html;charset=utf-8"><title>ESP8266</title></head>\
   <body>\
   <div class="header"><h3>MeteoColoc</h3><div>\
   <div class="meteobox">\
   <iframe width="430" height="280" frameborder="0" src="https://app.ubidots.com/ubi/getchart/dNNfdqij9cugFAyNJgY5oxAjG7I" style="background: transparent"></iframe>\
   <iframe width="430" height="280" frameborder="0" src="https://app.ubidots.com/ubi/getchart/gqVR3cOFX_NJVIMOu4Dv9_fGZ-w" style="background: transparent"></iframe><br><br>\
   <iframe width="430" height="280" frameborder="0" src="https://app.ubidots.com/ubi/getchart/BdAKfIguX3xplKnP_-zzUaFNV_w" style="background: transparent"></iframe>\
   </div></body></html>')
    sock:on("sent",function(sock) sock:close() end)
    end)
end  
 

connect()
svr = net.createServer (net.TCP, 30)
svr:listen (80, http_conn)
tmr.alarm(1, 120000, 1, function() postUbidots(0) end)  -- post to ubicode every 5 minutes

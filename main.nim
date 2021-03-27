import os, net, strutils, parsecfg, rdstdin, sequtils
# sry for crap ;D 
let client: Socket = newSocket()
client.connect("s9.mcskill.net", Port(25475))
stdout.writeLine("Client: connected")

var magic = "\xFE\xFD"
var challenge = "\x09"
var status = "\x00"                       #"\xFE\xFD\x09\x00\x00\x00\x01" - session generation "\xFE\xFD\x09\x00\x00\x00\x01\x00\x91\x29\x5B"
var session = "dev1lroot\x0F"

proc parseMinecraftServerStatus(data:string) =
  var status = data.split("\x00\x00\x00");
  echo "version: "&status[2].replace("\x00","")&" online: "&status[4].replace("\x00","")&" of "&status[5].replace("\x00","")

proc sr(client: Socket, message: string) =
  var result: string
  client.send(message)  # \xFE - ping
  try:
    discard client.recv(result,1024,1000);
    try:
      #writeFile("output.txt",result)
      parseMinecraftServerStatus(result)
      #echo "C ->[str]-> S :"&message
      #echo "C ->[hex]-> S :"& toHEX(message)
      #echo "C <-[str]<- S :" & $result & ";"
      #echo "C <-[hex]<- S :" & toHEX(result) & ";"
    except:
      echo "failed to display responce"
  except:
    echo "no responce"
client.sr("\xFE\x01")
client.sr("\x01\x00")
client.close()

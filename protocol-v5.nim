import os, net, strutils, parsecfg, rdstdin, sequtils, terminal

proc statusProtocolVersionFive(client: Socket, address: string):string =
  var buffer: string
  client.send("\x13\x00\x05\x0D"&address&"\x64\x4B\x01\x01\x00")
  try:
    discard client.recv(buffer,2048,2000);
    return buffer
  except:
    return "failure"

let client: Socket = newSocket()
client.connect("s6.mcskill.ru", Port(11111))
echo "> protocol version 5"
echo client.statusProtocolVersionFive("s6.mcskill.ru")
while client.hasDataBuffered():
  echo client.statusProtocolVersionFive("s6.mcskill.ru")

client.close()

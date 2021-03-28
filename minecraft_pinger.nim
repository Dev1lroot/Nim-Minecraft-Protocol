import os, net, json, nativesockets, strutils, parsecfg, rdstdin, sequtils, terminal, threadpool

var global_servers = 0
var finish_threads = 0
var failed_threads = 0
var sz = 512


stdout.writeLine("Client: connected")

type
  MinecraftServer* = ref object of RootObj
    address*: string
    port*: int
    thread*: int

proc toFixed(number,fixed: int):string =
  var result = $number
  while result.len < fixed:
    result = "0" & result
  return result

proc setStatus(server: MinecraftServer, status: int) =
  let prefix = "[Thread #" & server.thread.toFixed(5) & "] "
  if status == 0:
    echo prefix & "Failed to ping server: " & server.address & " on port " & $server.port
    failed_threads = failed_threads + 1
  if status == 1:
    echo prefix & "Failed to connect: " & server.address & " on port " & $server.port
    failed_threads = failed_threads + 1
  if status == 2:
    echo prefix & "Data integrity verified"
    finish_threads = finish_threads + 1

proc setStatus(server: MinecraftServer, status, package: int) =
  let prefix = "[Thread #" & server.thread.toFixed(5) & "] "
  if status == 3:
    echo prefix & "Getting data package #" & package.toFixed(5) & " size of " & $sz & " from " & server.address & " on port " & $server.port

proc receive(s: Socket, server: MinecraftServer):string=
  var i = 0
  while true:
    i = i + 1
    let data = s.recv(sz)
    #os.sleep(400)
    result &= data
    if data.len < sz:
      return result
    else:
      server.setStatus(3,i)

proc statusProtocolVersionFive(client: Socket, server: MinecraftServer):string =
  client.send("\x13\x00\x05\x0D"&server.address&"\x64\x4B\x01\x01\x00")
  return client.receive(server)

proc pingServer(server: MinecraftServer) {.thread, nimcall.} =
  echo "Pinging " & server.address & " at port " & $server.port
  let client: Socket = newSocket()
  try:
    client.connect(server.address, Port(server.port))
    try:
      var data = client.statusProtocolVersionFive(server)
      writeFile("servers/" & server.address & "_" & $server.port & ".json",data[7..data.len-1])
      server.setStatus(2)
    except:
      server.setStatus(0)
  except:
    server.setStatus(1)
  client.close()

if(fileExists("servers.json")):
  try:
    var i = 0
    var file = readFile("servers.json")
    var chan: Channel[int]
    var threads: array[10000, Thread[MinecraftServer]]
    var servers = parseJson(file)
    try:
      echo "Spawning threads to ping minecraft servers:"
      for server in servers:
        var mcserver = MinecraftServer(address: server["ip"].getStr(), port: server["port"].getInt(), thread: i)
        createThread[MinecraftServer](threads[i], pingServer, mcserver)
        i = i + 1
        global_servers = i
      joinThreads(threads)
      while global_servers > finish_threads + failed_threads:
        os.sleep(1000)
      echo "==========================================================================="
      echo "total:    " & $global_servers
      echo "finished: " & $finish_threads
      echo "failed:   " & $failed_threads
      echo "==========================================================================="
    except:
      echo "Iteration error of servers.json"
  except:
    echo "Corrupted or damaged servers.json"
else:
  echo "servers.json not found"

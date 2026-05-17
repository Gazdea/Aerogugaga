local network = {}

network._modem = nil
network._channel = 42
network._node_id = nil

function network.init(side, channel)
  if not side then return false end
  network._modem = peripheral.wrap(side)
  if not network._modem then return false end
  network._channel = channel or 42
  network._modem.open(network._channel)
  network._modem.open(network._channel + 1)
  return true
end

function network.announce(node_id, caps)
  network._node_id = node_id
  if not network._modem then return end
  network._modem.transmit(network._channel, network._channel + 1, {
    type = "announce",
    node_id = node_id,
    caps = caps,
  })
end

function network.broadcastState(data)
  if not network._modem then return end
  data.type = "state"
  data.node_id = network._node_id
  network._modem.transmit(network._channel, network._channel + 1, data)
end

function network.sendExec(target, action)
  if not network._modem then return end
  network._modem.transmit(network._channel, network._channel + 1, {
    type = "exec",
    target = target,
    source = network._node_id,
    action = action,
  })
end

function network.broadcastPeripherals(peripherals)
  if not network._modem then return end
  network._modem.transmit(network._channel, network._channel + 1, {
    type = "peripherals",
    node_id = network._node_id,
    list = peripherals,
  })
end

function network.pollAll()
  local messages = {}
  while true do
    local event, side, channel, reply, msg, distance = os.pullEvent("modem_message", 0)
    if not event then break end
    if channel == network._channel or channel == network._channel + 1 then
      table.insert(messages, msg)
    end
  end
  return messages
end

return network

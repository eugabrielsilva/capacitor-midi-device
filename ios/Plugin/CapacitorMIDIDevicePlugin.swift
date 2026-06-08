import Foundation
import Capacitor
import CoreMIDI

@objc(CapacitorMIDIDevicePlugin)
public class CapacitorMIDIDevicePlugin: CAPPlugin {
  private var midiClient: MIDIClientRef = 0
  private var inputPort: MIDIPortRef = 0
  private var outputPort: MIDIPortRef = 0
  private var connectedSource: MIDIEndpointRef = 0
  private var activeDeviceNumber: Int?
  private var connectionListenerInitialized = false

  public override func load() {
    super.load()
    _ = createClientIfNeeded()
    _ = createInputPortIfNeeded()
  }

  deinit {
    if connectedSource != 0, inputPort != 0 {
      MIDIPortDisconnectSource(inputPort, connectedSource)
    }
    if inputPort != 0 {
      MIDIPortDispose(inputPort)
    }
    if outputPort != 0 {
      MIDIPortDispose(outputPort)
    }
    if midiClient != 0 {
      MIDIClientDispose(midiClient)
    }
  }

    @objc func listMIDIDevices(_ call: CAPPluginCall) {
    call.resolve(["value": listAvailableSourceNames()])
    }

  @objc func openDevice(_ call: CAPPluginCall) {
    guard let deviceNumber = call.getInt("deviceNumber") else {
          call.reject("No deviceNumber given")
          return
      }

    guard createClientIfNeeded() else {
      call.reject("Could not initialize MIDI client")
      return
    }

    guard createInputPortIfNeeded() else {
      call.reject("Could not initialize MIDI input port")
      return
    }

    guard createOutputPortIfNeeded() else {
      call.reject("Could not initialize MIDI output port")
      return
    }

    let sources = listAvailableSources()
    guard sources.indices.contains(deviceNumber) else {
      call.reject("Invalid deviceNumber")
      return
    }

    if connectedSource != 0 {
      MIDIPortDisconnectSource(inputPort, connectedSource)
    }

    let sourceEndpoint = sources[deviceNumber]
    let status = MIDIPortConnectSource(inputPort, sourceEndpoint, nil)
    guard status == noErr else {
      call.reject("Error connecting MIDI source")
      return
    }

    connectedSource = sourceEndpoint
    activeDeviceNumber = deviceNumber
    call.resolve()
  }

  @objc func sendMIDIMessage(_ call: CAPPluginCall) {
    guard let rawData = call.getArray("data", NSNumber.self), !rawData.isEmpty else {
      call.reject("No valid MIDI message data given")
      return
    }

    guard createClientIfNeeded() else {
      call.reject("Could not initialize MIDI client")
      return
    }

    guard createOutputPortIfNeeded() else {
      call.reject("Could not initialize MIDI output port")
      return
    }

    if rawData.count > 256 {
      call.reject("MIDI message is too long. Maximum supported size is 256 bytes")
      return
    }

    var bytes: [UInt8] = []
    bytes.reserveCapacity(rawData.count)
    for (index, number) in rawData.enumerated() {
      let value = number.intValue
      if value < 0 || value > 255 {
        call.reject("MIDI byte out of range at index \(index): \(value)")
        return
      }
      bytes.append(UInt8(value))
    }

    let requestedDeviceNumber = call.getInt("deviceNumber")
    let targetDeviceNumber = requestedDeviceNumber ?? activeDeviceNumber
    guard let targetDeviceNumber = targetDeviceNumber else {
      call.reject("No MIDI output device selected")
      return
    }

    let destinations = listAvailableDestinations()
    guard destinations.indices.contains(targetDeviceNumber) else {
      call.reject("Invalid output deviceNumber")
      return
    }

    let destination = destinations[targetDeviceNumber]
    var packetList = MIDIPacketList()
    var sendStatus: OSStatus = -1

    bytes.withUnsafeBufferPointer { bufferPointer in
      guard let baseAddress = bufferPointer.baseAddress else {
        return
      }

      var packet = MIDIPacketListInit(&packetList)
      packet = MIDIPacketListAdd(&packetList, MemoryLayout<MIDIPacketList>.size, packet, 0, bufferPointer.count, baseAddress)
      guard packet != nil else {
        return
      }

      sendStatus = MIDISend(outputPort, destination, &packetList)
    }

    guard sendStatus == noErr else {
      call.reject("Could not send MIDI message")
      return
    }

    call.resolve()
  }

  @objc func initConnectionListener(_ call: CAPPluginCall) {
    connectionListenerInitialized = true
    emitConnectionEvent()
    call.resolve()
  }

  private func createClientIfNeeded() -> Bool {
    if midiClient != 0 {
      return true
    }

    let status = MIDIClientCreateWithBlock("CapacitorMIDIDeviceClient" as CFString, &midiClient) { [weak self] _ in
      guard let self = self, self.connectionListenerInitialized else {
        return
      }
      self.emitConnectionEvent()
    }

    return status == noErr
  }

  private func createInputPortIfNeeded() -> Bool {
    if inputPort != 0 {
      return true
    }

    let readProc: MIDIReadProc = { packetList, refCon, _ in
      guard
        let refCon = refCon
      else {
        return
      }

      let plugin = Unmanaged<CapacitorMIDIDevicePlugin>.fromOpaque(refCon).takeUnretainedValue()
      plugin.handleMidiPacketList(packetList)
    }

    let status = MIDIInputPortCreate(
      midiClient,
      "CapacitorMIDIDeviceInputPort" as CFString,
      readProc,
      Unmanaged.passUnretained(self).toOpaque(),
      &inputPort
    )

    return status == noErr
  }

  private func createOutputPortIfNeeded() -> Bool {
    if outputPort != 0 {
      return true
    }

    let status = MIDIOutputPortCreate(midiClient, "CapacitorMIDIDeviceOutputPort" as CFString, &outputPort)
    return status == noErr
  }

  private func listAvailableSources() -> [MIDIEndpointRef] {
    var sources: [MIDIEndpointRef] = []
    for index in 0..<MIDIGetNumberOfSources() {
      let source = MIDIGetSource(index)
      if source != 0 {
        sources.append(source)
      }
    }
    return sources
  }

  private func listAvailableSourceNames() -> [String] {
    return listAvailableSources().map(getSourceName)
  }

  private func listAvailableDestinations() -> [MIDIEndpointRef] {
    var destinations: [MIDIEndpointRef] = []
    for index in 0..<MIDIGetNumberOfDestinations() {
      let destination = MIDIGetDestination(index)
      if destination != 0 {
        destinations.append(destination)
      }
    }
    return destinations
  }

  private func getSourceName(_ source: MIDIEndpointRef) -> String {
    var displayName: Unmanaged<CFString>?
    let displayNameStatus = MIDIObjectGetStringProperty(source, kMIDIPropertyDisplayName, &displayName)
    if displayNameStatus == noErr, let cfString = displayName?.takeRetainedValue() {
      return cfString as String
    }

    var name: Unmanaged<CFString>?
    let nameStatus = MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name)
    if nameStatus == noErr, let cfString = name?.takeRetainedValue() {
      return cfString as String
    }

    return "Unknown MIDI Device"
  }

  private func handleMidiPacketList(_ packetListPointer: UnsafePointer<MIDIPacketList>) {
    let packetList = packetListPointer.pointee
    var packet = packetList.packet

    for _ in 0..<packetList.numPackets {
      let length = Int(packet.length)
      let bytes: [UInt8] = withUnsafeBytes(of: packet.data) { rawBuffer in
        Array(rawBuffer.prefix(length))
      }
      emitMessageEvent(bytes)
      packet = MIDIPacketNext(&packet).pointee
    }
  }

  private func emitMessageEvent(_ bytes: [UInt8]) {
    guard !bytes.isEmpty else {
      return
    }

    let statusByte = bytes[0]
    let status = bytes[0] & 0xF0
    let channel = Int(statusByte & 0x0F) + 1
    let note: Int? = bytes.count > 1 ? Int(bytes[1]) : nil
    let velocity: Int? = bytes.count > 2 ? Int(bytes[2]) : nil
    let velocityValue = velocity ?? 0
    let type: String

    if status == 0x90 && velocityValue != 0 {
      type = "NoteOn"
    } else if status == 0x80 || (status == 0x90 && velocityValue == 0) {
      type = "NoteOff"
    } else if status == 0xA0 {
      type = "PolyAftertouch"
    } else if status == 0xB0 {
      type = "ControlChange"
    } else if status == 0xC0 {
      type = "ProgramChange"
    } else if status == 0xD0 {
      type = "ChannelAftertouch"
    } else if status == 0xE0 {
      type = "PitchBend"
    } else {
      type = "SystemMessage"
    }

    var payload: [String: Any] = [
      "type": type,
      "data": bytes.map { Int($0) },
      "channel": channel,
    ]

    if status == 0xB0 {
      if let note = note {
        payload["controller"] = note
      }
      if let velocity = velocity {
        payload["value"] = velocity
      }
    } else if status == 0xC0 {
      if let note = note {
        payload["program"] = note
      }
    } else if status == 0xD0 {
      if let note = note {
        payload["pressure"] = note
      }
    } else if status == 0xE0 {
      if let note = note, let velocity = velocity {
        let pitchBend = ((velocity & 0x7F) << 7) | (note & 0x7F)
        payload["pitchBend"] = pitchBend - 8192
      }
    } else if status == 0xA0 {
      if let note = note {
        payload["note"] = note
      }
      if let velocity = velocity {
        payload["pressure"] = velocity
      }
    } else {
      if let note = note {
        payload["note"] = note
      }
      if let velocity = velocity {
        payload["velocity"] = velocity
      }
    }

    DispatchQueue.main.async {
      self.notifyListeners("MIDI_MSG_EVENT", data: payload)
    }
  }

  private func emitConnectionEvent() {
    let names = listAvailableSourceNames()
    DispatchQueue.main.async {
      self.notifyListeners("MIDI_CON_EVENT", data: ["value": names])
    }
  }
}

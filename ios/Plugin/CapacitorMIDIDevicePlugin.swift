import Foundation
import Capacitor
import CoreMIDI

@objc(CapacitorMIDIDevicePlugin)
public class CapacitorMIDIDevicePlugin: CAPPlugin {
  private var midiClient: MIDIClientRef = 0
  private var inputPort: MIDIPortRef = 0
  private var connectedSource: MIDIEndpointRef = 0
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
        let packetList = packetList,
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
    guard bytes.count >= 3 else {
      return
    }

    let status = bytes[0] & 0xF0
    let note = Int(bytes[1])
    let velocity = Int(bytes[2])
    let type: String

    if status == 0x90 && velocity != 0 {
      type = "NoteOn"
    } else if status == 0x80 || (status == 0x90 && velocity == 0) {
      type = "NoteOff"
    } else {
      type = "UNKNOWN - \(bytes[0])"
    }

    DispatchQueue.main.async {
      self.notifyListeners("MIDI_MSG_EVENT", data: [
        "type": type,
        "note": note,
        "velocity": velocity,
      ])
    }
  }

  private func emitConnectionEvent() {
    let names = listAvailableSourceNames()
    DispatchQueue.main.async {
      self.notifyListeners("MIDI_CON_EVENT", data: ["value": names])
    }
  }
}

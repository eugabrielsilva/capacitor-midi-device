import type {PluginListenerHandle} from "@capacitor/core";

/**
 * Parsed MIDI message emitted by the plugin.
 *
 * The raw MIDI bytes are always available in `data` and semantic fields are
 * populated according to the MIDI message type.
 */
export interface MidiMessage {
  /** Human-friendly message type like `NoteOn`, `ControlChange`, `PitchBend`, etc. */
  type: string;

  /** Raw MIDI bytes (0-255). */
  data: number[];

  /** MIDI channel in range 1..16. */
  channel?: number;

  // NoteOn, NoteOff and PolyAftertouch
  /** Note number (0-127) for note-based messages. */
  note?: number;

  // NoteOn and NoteOff
  /** Note velocity (0-127) for note on/off messages. */
  velocity?: number;

  // ControlChange
  /** Controller number (0-127) for Control Change messages. */
  controller?: number;

  /** Controller value (0-127) for Control Change messages. */
  value?: number;

  // ProgramChange
  /** Program number (0-127) for Program Change messages. */
  program?: number;

  // ChannelAftertouch and PolyAftertouch
  /** Pressure value (0-127) for aftertouch messages. */
  pressure?: number;

  // PitchBend normalized to -8192..8191
  /** Pitch bend value normalized to -8192..8191. */
  pitchBend?: number;
}

/** Options used to select and open a MIDI input device for listening. */
export interface DeviceOptions {
  deviceNumber: number
}

/** Options used to send raw MIDI data to a MIDI output device. */
export interface SendMIDIMessageOptions {
  /** Raw MIDI bytes to send (0-255). */
  data: number[];

  /**
   * Optional target output device index.
   * If omitted, the currently active/opened device is used.
   */
  deviceNumber?: number;
}

export interface CapacitorMIDIDevicePlugin {
  /** List available MIDI input devices. */
  listMIDIDevices(): Promise<{ value: string[] }>

  /** Open a MIDI input device to receive `MIDI_MSG_EVENT` events. */
  openDevice(options: DeviceOptions): Promise<void>

  /** Send a raw MIDI message to an output device. */
  sendMIDIMessage(options: SendMIDIMessageOptions): Promise<void>

  /** Start listening for device connection/disconnection updates. */
  initConnectionListener(): Promise<void>

  addListener(eventName: 'MIDI_MSG_EVENT', listenerFunc: (message: MidiMessage) => void): Promise<PluginListenerHandle>;

  addListener(eventName: 'MIDI_CON_EVENT', listenerFunc: (devices: { value: string[] }) => void): Promise<PluginListenerHandle>;
}

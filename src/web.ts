import { WebPlugin } from '@capacitor/core';

import {WebMIDIHandler} from "./WebMIDIHandler";
import {MidiMessageType} from './definitions';
import type {CapacitorMIDIDevicePlugin, DeviceOptions, MidiMessage, SendMIDIMessageOptions} from './definitions';

export class CapacitorMIDIDeviceWeb
  extends WebPlugin
  implements CapacitorMIDIDevicePlugin
{
  private wmh: WebMIDIHandler = WebMIDIHandler.instance

  async listMIDIDevices(): Promise<{ value: string[] }> {
    const wmh = WebMIDIHandler.instance;
    await wmh.initWebMidi()

    return wmh.getInputsAndOutputs();
  }

  async openDevice(options: DeviceOptions): Promise<void> {
    const wmh = WebMIDIHandler.instance;
    await wmh.initWebMidi()
    const callback = (ret: any) => {
      const data: number[] = Array.isArray(ret.data)
        ? ret.data
        : Array.from(ret.data ?? []);
      const statusByte = data.length > 0 ? data[0] : 0;
      const status = statusByte & 0xF0;
      const channel = (statusByte & 0x0F) + 1;
      const velocity = data.length > 2 ? data[2] : 0;

      let msgType = MidiMessageType.SystemMessage
      if (status === 0x80 || (status === 0x90 && velocity === 0)) {
        msgType = MidiMessageType.NoteOff
      } else if (status === 0x90) {
        msgType = MidiMessageType.NoteOn
      } else if (status === 0xA0) {
        msgType = MidiMessageType.PolyAftertouch
      } else if (status === 0xB0) {
        msgType = MidiMessageType.ControlChange
      } else if (status === 0xC0) {
        msgType = MidiMessageType.ProgramChange
      } else if (status === 0xD0) {
        msgType = MidiMessageType.ChannelAftertouch
      } else if (status === 0xE0) {
        msgType = MidiMessageType.PitchBend
      }

      const msg: MidiMessage = {
        type: msgType,
        data,
        channel,
      }

      if (data.length > 1) {
        const data1 = data[1]
        if (msgType === MidiMessageType.ControlChange) {
          msg.controller = data1
        } else if (msgType === MidiMessageType.ProgramChange) {
          msg.program = data1
        } else if (msgType === MidiMessageType.ChannelAftertouch) {
          msg.pressure = data1
        } else {
          msg.note = data1
        }
      }
      if (data.length > 2) {
        const data2 = data[2]
        if (msgType === MidiMessageType.ControlChange) {
          msg.value = data2
        } else if (msgType === MidiMessageType.PolyAftertouch) {
          msg.pressure = data2
        } else {
          msg.velocity = data2
        }
      }

      if (msgType === MidiMessageType.PitchBend && data.length > 2) {
        const lsb = data[1] & 0x7F
        const msb = data[2] & 0x7F
        msg.pitchBend = ((msb << 7) | lsb) - 8192
      }

      this.notifyListeners('MIDI_MSG_EVENT', msg)
    }
    this.wmh.addDeviceListener(options.deviceNumber, callback)
    console.log("MIDIPlugin", "Device opened: " + options.deviceNumber)
  }

  async sendMIDIMessage(options: SendMIDIMessageOptions): Promise<void> {
    const wmh = WebMIDIHandler.instance;
    await wmh.initWebMidi()
    wmh.sendMIDIMessage(options.data, options.deviceNumber)
  }

  async initConnectionListener(): Promise<void> {
    const wmh = WebMIDIHandler.instance;
    await wmh.initWebMidi()
    const callback = (devices: { value: string[] }) => {
      this.notifyListeners('MIDI_CON_EVENT', devices)
    }
    this.wmh.addConnectionListener(callback)
  }
}

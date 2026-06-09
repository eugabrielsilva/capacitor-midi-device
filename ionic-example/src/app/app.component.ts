import {ChangeDetectorRef, Component, OnInit} from '@angular/core';
import {DeviceOptions, CapacitorMIDIDevice, MidiMessage, MidiMessageType} from '@eugabrielsilva/capacitor-midi-device';
@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
})
export class AppComponent implements OnInit{
  readonly MidiMessageType = MidiMessageType;
  devices: string[] = [];
  messages: MidiMessage[] = [];
  opened = false;

  constructor(private cd: ChangeDetectorRef) {
  }

  async ngOnInit(): Promise<void> {
    this.devices = (await CapacitorMIDIDevice.listMIDIDevices()).value;

    CapacitorMIDIDevice.addListener('MIDI_MSG_EVENT', (message: MidiMessage) => {
      this.messages.push(message);
      this.cd.detectChanges();
    });

    await CapacitorMIDIDevice.initConnectionListener();

    CapacitorMIDIDevice.addListener('MIDI_CON_EVENT', (devices: { value: string[] }) => {
      this.devices = devices.value;
      this.cd.detectChanges();
    });
  }

  updateDevices(): void {
    CapacitorMIDIDevice.listMIDIDevices()
      .then((devices: { value: string[] }) => {
        this.devices = devices.value;
        this.cd.detectChanges();
      });
  }

  openDevice(deviceNumber: number): void {
    const deviceOptions: DeviceOptions = {
      deviceNumber
    };
    CapacitorMIDIDevice.openDevice(deviceOptions).then(() => {
      this.clearMessages();
    });
  }

  clearMessages(): void {
    this.messages = [];
  }

  msgToString(msg: MidiMessage): string {
    const summary = this.getSummary(msg);
    return `${msg.type} - ${summary} - raw: ${JSON.stringify(msg.data)}`;
  }

  private getSummary(msg: MidiMessage): string {
    switch (msg.type) {
      case MidiMessageType.NoteOn:
      case MidiMessageType.NoteOff:
        return `ch ${msg.channel}, note ${msg.note}, vel ${msg.velocity}`;
      case MidiMessageType.ControlChange:
        return `ch ${msg.channel}, cc ${msg.controller}, value ${msg.value}`;
      case MidiMessageType.ProgramChange:
        return `ch ${msg.channel}, program ${msg.program}`;
      case MidiMessageType.PolyAftertouch:
      case MidiMessageType.ChannelAftertouch:
        return `ch ${msg.channel}, pressure ${msg.pressure}`;
      case MidiMessageType.PitchBend:
        return `ch ${msg.channel}, bend ${msg.pitchBend}`;
      default:
        return `ch ${msg.channel}`;
    }
  }
}

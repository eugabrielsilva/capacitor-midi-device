# @eugabrielsilva/capacitor-midi-device

Connect midi devices to your Capacitor app.

✅ Working on web, Android and iOS.

⚠️ **Requires Capacitor 8**

## Install

```bash
npm install @eugabrielsilva/capacitor-midi-device
npx cap sync
```

## API

<docgen-index>

* [`listMIDIDevices()`](#listmididevices)
* [`openDevice(...)`](#opendevice)
* [`sendMIDIMessage(...)`](#sendmidimessage)
* [`initConnectionListener()`](#initconnectionlistener)
* [`addListener('MIDI_MSG_EVENT', ...)`](#addlistenermidi_msg_event-)
* [`addListener('MIDI_CON_EVENT', ...)`](#addlistenermidi_con_event-)
* [Interfaces](#interfaces)
* [Enums](#enums)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### listMIDIDevices()

```typescript
listMIDIDevices() => Promise<{ value: string[]; }>
```

List available MIDI input devices.

**Returns:** <code>Promise&lt;{ value: string[]; }&gt;</code>

--------------------


### openDevice(...)

```typescript
openDevice(options: DeviceOptions) => Promise<void>
```

Open a MIDI input device to receive `MIDI_MSG_EVENT` events.

| Param         | Type                                                    |
| ------------- | ------------------------------------------------------- |
| **`options`** | <code><a href="#deviceoptions">DeviceOptions</a></code> |

--------------------


### sendMIDIMessage(...)

```typescript
sendMIDIMessage(options: SendMIDIMessageOptions) => Promise<void>
```

Send a raw MIDI message to an output device.

| Param         | Type                                                                      |
| ------------- | ------------------------------------------------------------------------- |
| **`options`** | <code><a href="#sendmidimessageoptions">SendMIDIMessageOptions</a></code> |

--------------------


### initConnectionListener()

```typescript
initConnectionListener() => Promise<void>
```

Start listening for device connection/disconnection updates.

--------------------


### addListener('MIDI_MSG_EVENT', ...)

```typescript
addListener(eventName: 'MIDI_MSG_EVENT', listenerFunc: (message: MidiMessage) => void) => Promise<PluginListenerHandle>
```

| Param              | Type                                                                      |
| ------------------ | ------------------------------------------------------------------------- |
| **`eventName`**    | <code>'MIDI_MSG_EVENT'</code>                                             |
| **`listenerFunc`** | <code>(message: <a href="#midimessage">MidiMessage</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('MIDI_CON_EVENT', ...)

```typescript
addListener(eventName: 'MIDI_CON_EVENT', listenerFunc: (devices: { value: string[]; }) => void) => Promise<PluginListenerHandle>
```

| Param              | Type                                                    |
| ------------------ | ------------------------------------------------------- |
| **`eventName`**    | <code>'MIDI_CON_EVENT'</code>                           |
| **`listenerFunc`** | <code>(devices: { value: string[]; }) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### Interfaces


#### DeviceOptions

Options used to select and open a MIDI input device for listening.

| Prop               | Type                |
| ------------------ | ------------------- |
| **`deviceNumber`** | <code>number</code> |


#### SendMIDIMessageOptions

Options used to send raw MIDI data to a MIDI output device.

| Prop               | Type                  | Description                                                                                  |
| ------------------ | --------------------- | -------------------------------------------------------------------------------------------- |
| **`data`**         | <code>number[]</code> | Raw MIDI bytes to send (0-255).                                                              |
| **`deviceNumber`** | <code>number</code>   | Optional target output device index. If omitted, the currently active/opened device is used. |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### MidiMessage

Parsed MIDI message emitted by the plugin.

The raw MIDI bytes are always available in `data` and semantic fields are
populated according to the MIDI message type.

| Prop             | Type                                                        | Description                                                                   |
| ---------------- | ----------------------------------------------------------- | ----------------------------------------------------------------------------- |
| **`type`**       | <code><a href="#midimessagetype">MidiMessageType</a></code> | Human-friendly message type like `NoteOn`, `ControlChange`, `PitchBend`, etc. |
| **`data`**       | <code>number[]</code>                                       | Raw MIDI bytes (0-255).                                                       |
| **`channel`**    | <code>number</code>                                         | MIDI channel in range 1..16.                                                  |
| **`note`**       | <code>number</code>                                         | Note number (0-127) for note-based messages.                                  |
| **`velocity`**   | <code>number</code>                                         | Note velocity (0-127) for note on/off messages.                               |
| **`controller`** | <code>number</code>                                         | Controller number (0-127) for Control Change messages.                        |
| **`value`**      | <code>number</code>                                         | Controller value (0-127) for Control Change messages.                         |
| **`program`**    | <code>number</code>                                         | Program number (0-127) for Program Change messages.                           |
| **`pressure`**   | <code>number</code>                                         | Pressure value (0-127) for aftertouch messages.                               |
| **`pitchBend`**  | <code>number</code>                                         | Pitch bend value normalized to -8192..8191.                                   |


### Enums


#### MidiMessageType

| Members                 | Value                            |
| ----------------------- | -------------------------------- |
| **`SystemMessage`**     | <code>'SystemMessage'</code>     |
| **`NoteOff`**           | <code>'NoteOff'</code>           |
| **`NoteOn`**            | <code>'NoteOn'</code>            |
| **`PolyAftertouch`**    | <code>'PolyAftertouch'</code>    |
| **`ControlChange`**     | <code>'ControlChange'</code>     |
| **`ProgramChange`**     | <code>'ProgramChange'</code>     |
| **`ChannelAftertouch`** | <code>'ChannelAftertouch'</code> |
| **`PitchBend`**         | <code>'PitchBend'</code>         |

</docgen-api>

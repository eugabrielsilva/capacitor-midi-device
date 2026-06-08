import {WebMidi} from "webmidi";

export class WebMIDIHandler {
    private static _instance?: WebMIDIHandler;
    private midi: any = null;
    private activeDeviceNo?: number;

    private constructor() {
        if (WebMIDIHandler._instance)
            throw new Error("Use WebMIDIHandler.instance instead of new.");
        WebMIDIHandler._instance = this;
    }

    static get instance(): WebMIDIHandler {
        return WebMIDIHandler._instance ?? (WebMIDIHandler._instance = new WebMIDIHandler());
    }

    public async initWebMidi(): Promise<void> {
        if (!this.midi) {
            try {
                this.midi = await WebMidi.enable()
            } catch (e) {
                console.error("WebMidi initialization failed", e)
                throw e
            }
        }
    }

    public addDeviceListener(deviceNo: number, callback: (arg: any) => any): void {
        if (!this.midi) {
            console.error("WebMidi not initialized!")
            return
        }

        if (this.midi.inputs && this.midi.inputs.length > 0 && deviceNo < this.midi.inputs.length) {
            const device = this.midi.inputs[deviceNo]
            this.activeDeviceNo = deviceNo;

            // prevent multiple event listener subscriptions
            this.midi.inputs.forEach((d: any) => {
                d.removeListener("midimessage")
            })

            device.addListener("midimessage", (e: any) => {
                callback(e)
            });
        } else {
            console.error("Could not open device")
        }
    }

    public sendMIDIMessage(data: number[], deviceNo?: number): void {
        if (!this.midi) {
            console.error("WebMidi not initialized!")
            return
        }

        const targetDeviceNo = deviceNo ?? this.activeDeviceNo;
        if (targetDeviceNo === undefined || targetDeviceNo < 0 || targetDeviceNo >= this.midi.outputs.length) {
            console.error("No valid output device selected")
            return
        }

        if (!Array.isArray(data) || data.length === 0) {
            console.error("MIDI message data cannot be empty")
            return
        }

        const sanitizedData = data.map((byte) => Math.max(0, Math.min(255, Math.floor(byte))));
        this.midi.outputs[targetDeviceNo].send(sanitizedData)
    }

    public getInputsAndOutputs(): { value: string[] } {
        if (!this.midi) {
            console.error("WebMidi not initialized!")
            return {value: []}
        }

        const devices = []
        for (const entry of this.midi.inputs) {
            if (entry?.type && entry.type == "input") {
                devices.push((entry.name) ? entry.name : "Unknown Device")
            }
        }
        return {value: devices}
    }

    public addConnectionListener(callback: (devices: { value: string[] }) => any): void {
        if (!this.midi) {
            console.error("WebMidi not initialized!")
            return
        }
        this.midi.removeListener("connected")
        this.midi.removeListener("disconnected")
        this.midi.addListener("connected", () => {
            callback(this.getInputsAndOutputs())
        })
        this.midi.addListener("disconnected", () => {
            callback(this.getInputsAndOutputs())
        })
    }
}
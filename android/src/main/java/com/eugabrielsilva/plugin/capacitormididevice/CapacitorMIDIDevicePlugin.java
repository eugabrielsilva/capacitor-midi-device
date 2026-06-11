package com.eugabrielsilva.plugin.capacitormididevice;

import android.os.Build;

import androidx.annotation.RequiresApi;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import java.util.Arrays;

import org.json.JSONException;

@CapacitorPlugin(name = "CapacitorMIDIDevice")
public class CapacitorMIDIDevicePlugin extends Plugin {

    private AndroidMIDIHandler androidMidiHandler;

    @RequiresApi(api = Build.VERSION_CODES.M)
    @Override
    public void load() {
        this.androidMidiHandler = new AndroidMIDIHandler(this.getContext());
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @PluginMethod
    public void listMIDIDevices(PluginCall call) {
        JSObject ret = new JSObject();
        JSArray devices = new JSArray();
        Arrays.stream(androidMidiHandler.listMIDIDevices()).forEach(devices::put);
        ret.put("value", devices);
        call.resolve(ret);
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @PluginMethod
    public void openDevice(PluginCall call) {
        Integer deviceNumber = call.getInt("deviceNumber");
        if (deviceNumber == null || deviceNumber < 0) {
            call.reject("No valid deviceNumber given");
            return;
        }

        androidMidiHandler.openDevice(deviceNumber, (MIDIDeviceMessage message) -> {
            if (message == null || message.msg == null || message.count <= 0) {
                return;
            }

            int messageStart = message.offset;
            int messageEnd = Math.min(message.offset + message.count, message.msg.length);
            if (messageStart >= messageEnd) {
                return;
            }

            JSArray data = new JSArray();
            for (int i = messageStart; i < messageEnd; i++) {
                data.put(message.msg[i] & 0xFF);
            }

            JSObject midiMessage = new JSObject();

            int statusByte = message.msg[messageStart] & 0xFF;
            int rawStatus = statusByte & 0xF0;
            int channel = (statusByte & 0x0F) + 1;
            int note = messageStart + 1 < messageEnd ? (message.msg[messageStart + 1] & 0x7F) : -1;
            int velocity = messageStart + 2 < messageEnd ? (message.msg[messageStart + 2] & 0x7F) : -1;

            String type = "";
            if (rawStatus == 0x90 && velocity != 0) {
                type = "NoteOn";
            } else if (rawStatus == 0x80 || (rawStatus == 0x90 && velocity == 0)) {
                type = "NoteOff";
            } else if (rawStatus == 0xA0) {
                type = "PolyAftertouch";
            } else if (rawStatus == 0xB0) {
                type = "ControlChange";
            } else if (rawStatus == 0xC0) {
                type = "ProgramChange";
            } else if (rawStatus == 0xD0) {
                type = "ChannelAftertouch";
            } else if (rawStatus == 0xE0) {
                type = "PitchBend";
            } else {
                type = "SystemMessage";
            }

            midiMessage.put("type", type);
            midiMessage.put("data", data);
            midiMessage.put("channel", channel);

            if (rawStatus == 0xB0) {
                if (note >= 0) {
                    midiMessage.put("controller", note);
                }
                if (velocity >= 0) {
                    midiMessage.put("value", velocity);
                }
            } else if (rawStatus == 0xC0) {
                if (note >= 0) {
                    midiMessage.put("program", note);
                }
            } else if (rawStatus == 0xD0) {
                if (note >= 0) {
                    midiMessage.put("pressure", note);
                }
            } else if (rawStatus == 0xE0) {
                if (note >= 0 && velocity >= 0) {
                    int pitchBend = ((velocity & 0x7F) << 7) | (note & 0x7F);
                    midiMessage.put("pitchBend", pitchBend - 8192);
                }
            } else if (rawStatus == 0xA0) {
                if (note >= 0) {
                    midiMessage.put("note", note);
                }
                if (velocity >= 0) {
                    midiMessage.put("pressure", velocity);
                }
            } else {
                if (note >= 0) {
                    midiMessage.put("note", note);
                }
                if (velocity >= 0) {
                    midiMessage.put("velocity", velocity);
                }
            }

            notifyListeners("MIDI_MSG_EVENT", midiMessage);
        });
        call.resolve();
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @PluginMethod
    public void sendMIDIMessage(PluginCall call) {
        JSArray dataArray = call.getArray("data");
        if (dataArray == null || dataArray.length() == 0) {
            call.reject("No valid MIDI message data given");
            return;
        }

        byte[] data = new byte[dataArray.length()];
        for (int i = 0; i < dataArray.length(); i++) {
            int value;
            try {
                value = dataArray.getInt(i);
            } catch (JSONException e) {
                call.reject("Invalid MIDI data byte at index " + i);
                return;
            }

            if (value < 0 || value > 255) {
                call.reject("MIDI byte out of range at index " + i + ": " + value);
                return;
            }
            data[i] = (byte) (value & 0xFF);
        }

        Integer deviceNumber = call.getInt("deviceNumber");
        if (!androidMidiHandler.sendMIDIMessage(data, deviceNumber)) {
            call.reject("Could not send MIDI message");
            return;
        }

        call.resolve();
    }


    @RequiresApi(api = Build.VERSION_CODES.N)
    @PluginMethod
    public void initConnectionListener(PluginCall call) {
        androidMidiHandler.addDeviceConnectionListener((String[] devices) -> {
            JSObject conMsg = new JSObject();
            JSArray values = new JSArray();
            Arrays.stream(devices).forEach(values::put);
            conMsg.put("value", values);

            notifyListeners("MIDI_CON_EVENT", conMsg);
        });
        call.resolve();
    }
}

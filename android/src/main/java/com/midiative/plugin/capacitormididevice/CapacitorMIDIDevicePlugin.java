package com.midiative.plugin.capacitormididevice;

import android.os.Build;

import androidx.annotation.RequiresApi;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import java.util.Arrays;

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
            if (message == null || message.msg == null || message.count < 3) {
                return;
            }

            int statusIndex = message.offset;
            int noteIndex = message.offset + 1;
            int velocityIndex = message.offset + 2;

            if (statusIndex >= message.msg.length || noteIndex >= message.msg.length || velocityIndex >= message.msg.length) {
                return;
            }

            JSObject midiMessage = new JSObject();

            int rawStatus = message.msg[statusIndex] & 0xF0;
            int note = message.msg[noteIndex] & 0x7F;
            int velocity = message.msg[velocityIndex] & 0x7F;

            String type = "";
            if (rawStatus == 0x90 && velocity != 0) {
                type = "NoteOn";
            } else if (rawStatus == 0x80 || (rawStatus == 0x90 && velocity == 0)) {
                type = "NoteOff";
            } else {
                type = "UNKNOWN - " + rawStatus;
            }

            midiMessage.put("type", type);
            midiMessage.put("note", note);
            midiMessage.put("velocity", velocity);

            notifyListeners("MIDI_MSG_EVENT", midiMessage);
        });
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

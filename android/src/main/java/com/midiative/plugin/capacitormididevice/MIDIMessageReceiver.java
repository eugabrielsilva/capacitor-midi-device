package com.midiative.plugin.capacitormididevice;

import android.media.midi.MidiReceiver;
import android.os.Build;
import android.util.Log;

import androidx.annotation.RequiresApi;

import java.io.IOException;
import java.util.Arrays;
import java.util.function.Consumer;

@RequiresApi(api = Build.VERSION_CODES.M)
public class MIDIMessageReceiver extends MidiReceiver {
    Consumer<MIDIDeviceMessage> consumer;
    public MIDIMessageReceiver(Consumer<MIDIDeviceMessage> consumer) {
        this.consumer = consumer;
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public void onSend(byte[] msg, int offset, int count, long timestamp) throws IOException {
        int end = Math.min(msg.length, offset + count);
        String message = Arrays.toString(Arrays.copyOfRange(msg, offset, end));
        Log.i("MIDIMessageReceiver", "msg: " + message + ", offset: " + offset + ", count: " + count + ", timestamp: " + timestamp);
        consumer.accept(new MIDIDeviceMessage(msg, offset, count, timestamp));
    }
}
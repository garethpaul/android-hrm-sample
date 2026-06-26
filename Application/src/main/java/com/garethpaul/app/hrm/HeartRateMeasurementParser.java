package com.garethpaul.app.hrm;

final class HeartRateMeasurementParser {
    private static final int HEART_RATE_UINT16 = 0x01;
    private static final int SENSOR_CONTACT_DETECTED = 0x02;
    private static final int SENSOR_CONTACT_SUPPORTED = 0x04;
    private static final int ENERGY_EXPENDED_PRESENT = 0x08;
    private static final int RR_INTERVAL_PRESENT = 0x10;
    private static final int RESERVED_FLAGS = 0xe0;

    private HeartRateMeasurementParser() {
    }

    static HeartRateMeasurement parse(byte[] packet) {
        if (packet == null || packet.length < 2) {
            return null;
        }

        int flags = unsignedByte(packet[0]);
        if ((flags & RESERVED_FLAGS) != 0 ||
                ((flags & SENSOR_CONTACT_SUPPORTED) == 0 &&
                        (flags & SENSOR_CONTACT_DETECTED) != 0)) {
            return null;
        }

        int offset = 1;
        int heartRateBytes = (flags & HEART_RATE_UINT16) != 0 ? 2 : 1;
        if (!contains(packet, offset, heartRateBytes)) {
            return null;
        }
        int beatsPerMinute = heartRateBytes == 2 ?
                unsignedLittleEndian16(packet, offset) : unsignedByte(packet[offset]);
        offset += heartRateBytes;

        Boolean sensorContactDetected = null;
        if ((flags & SENSOR_CONTACT_SUPPORTED) != 0) {
            sensorContactDetected = Boolean.valueOf(
                    (flags & SENSOR_CONTACT_DETECTED) != 0);
        }

        Integer energyExpendedKilojoules = null;
        if ((flags & ENERGY_EXPENDED_PRESENT) != 0) {
            if (!contains(packet, offset, 2)) {
                return null;
            }
            energyExpendedKilojoules = Integer.valueOf(
                    unsignedLittleEndian16(packet, offset));
            offset += 2;
        }

        int[] rrIntervals = new int[0];
        if ((flags & RR_INTERVAL_PRESENT) != 0) {
            int remainingBytes = packet.length - offset;
            if (remainingBytes < 2 || remainingBytes % 2 != 0) {
                return null;
            }
            rrIntervals = new int[remainingBytes / 2];
            for (int index = 0; index < rrIntervals.length; index++) {
                rrIntervals[index] = unsignedLittleEndian16(packet, offset);
                offset += 2;
            }
        }

        if (offset != packet.length) {
            return null;
        }

        return new HeartRateMeasurement(
                beatsPerMinute,
                sensorContactDetected,
                energyExpendedKilojoules,
                rrIntervals);
    }

    private static boolean contains(byte[] packet, int offset, int byteCount) {
        return offset >= 0 && byteCount >= 0 && offset <= packet.length - byteCount;
    }

    private static int unsignedByte(byte value) {
        return value & 0xff;
    }

    private static int unsignedLittleEndian16(byte[] packet, int offset) {
        return unsignedByte(packet[offset]) | unsignedByte(packet[offset + 1]) << 8;
    }
}

package com.garethpaul.app.hrm;

import java.util.Arrays;

public final class HeartRateMeasurementParserTest {
    private static int assertions;

    public static void main(String[] args) {
        parsesUnsignedEightBitHeartRate();
        parsesUnsignedSixteenBitHeartRate();
        parsesSensorContactStates();
        parsesEnergyExpended();
        parsesMultipleRrIntervals();
        parsesCombinedOptionalFields();
        protectsRrIntervalOwnership();
        rejectsMalformedPackets();
        System.out.println("HeartRateMeasurementParser tests passed: " + assertions);
    }

    private static void parsesUnsignedEightBitHeartRate() {
        HeartRateMeasurement measurement = parse(0x00, 200);
        expectEquals(200, measurement.beatsPerMinute(), "UINT8 BPM");
        expectEquals(null, measurement.sensorContactDetected(), "unsupported contact");
        expectEquals(null, measurement.energyExpendedKilojoules(), "absent energy");
        expectArrayEquals(new int[0], measurement.rrIntervals(), "absent RR intervals");
    }

    private static void parsesUnsignedSixteenBitHeartRate() {
        HeartRateMeasurement measurement = parse(0x01, 0x2c, 0x01);
        expectEquals(300, measurement.beatsPerMinute(), "UINT16 BPM");
    }

    private static void parsesSensorContactStates() {
        expectEquals(Boolean.FALSE,
                parse(0x04, 72).sensorContactDetected(),
                "supported contact not detected");
        expectEquals(Boolean.TRUE,
                parse(0x06, 72).sensorContactDetected(),
                "supported contact detected");
    }

    private static void parsesEnergyExpended() {
        HeartRateMeasurement measurement = parse(0x08, 72, 0xd2, 0x04);
        expectEquals(Integer.valueOf(1234),
                measurement.energyExpendedKilojoules(),
                "energy expended");
    }

    private static void parsesMultipleRrIntervals() {
        HeartRateMeasurement measurement = parse(0x10, 72, 0x00, 0x04, 0x00, 0x02);
        expectArrayEquals(new int[] {1024, 512},
                measurement.rrIntervals(),
                "RR intervals");
    }

    private static void parsesCombinedOptionalFields() {
        HeartRateMeasurement measurement = parse(
                0x1f,
                0x2c, 0x01,
                0xff, 0xff,
                0x34, 0x12);
        expectEquals(300, measurement.beatsPerMinute(), "combined BPM");
        expectEquals(Boolean.TRUE, measurement.sensorContactDetected(), "combined contact");
        expectEquals(Integer.valueOf(65535),
                measurement.energyExpendedKilojoules(),
                "combined energy");
        expectArrayEquals(new int[] {0x1234},
                measurement.rrIntervals(),
                "combined RR interval");
    }

    private static void protectsRrIntervalOwnership() {
        HeartRateMeasurement measurement = parse(0x10, 72, 0x00, 0x04);
        int[] intervals = measurement.rrIntervals();
        intervals[0] = 1;
        expectArrayEquals(new int[] {1024},
                measurement.rrIntervals(),
                "RR interval defensive copy");
    }

    private static void rejectsMalformedPackets() {
        expectRejected(null, "null packet");
        expectRejected(bytes(), "empty packet");
        expectRejected(bytes(0x00), "missing UINT8 BPM");
        expectRejected(bytes(0x01, 0x2c), "truncated UINT16 BPM");
        expectRejected(bytes(0x20, 72), "reserved flag bit");
        expectRejected(bytes(0x02, 72), "contact status without support");
        expectRejected(bytes(0x08, 72, 0xd2), "truncated energy");
        expectRejected(bytes(0x10, 72), "RR flag without interval");
        expectRejected(bytes(0x10, 72, 0x00), "truncated RR interval");
        expectRejected(bytes(0x00, 72, 0x00), "trailing data without RR flag");
    }

    private static HeartRateMeasurement parse(int... values) {
        HeartRateMeasurement measurement = HeartRateMeasurementParser.parse(bytes(values));
        if (measurement == null) {
            throw new AssertionError("expected packet to parse: " + Arrays.toString(values));
        }
        assertions++;
        return measurement;
    }

    private static void expectRejected(byte[] packet, String message) {
        if (HeartRateMeasurementParser.parse(packet) != null) {
            throw new AssertionError(message + " should be rejected");
        }
        assertions++;
    }

    private static byte[] bytes(int... values) {
        byte[] bytes = new byte[values.length];
        for (int index = 0; index < values.length; index++) {
            bytes[index] = (byte) values[index];
        }
        return bytes;
    }

    private static void expectEquals(Object expected, Object actual, String message) {
        if (expected == null ? actual != null : !expected.equals(actual)) {
            throw new AssertionError(message + ": expected " + expected + ", got " + actual);
        }
        assertions++;
    }

    private static void expectEquals(int expected, int actual, String message) {
        if (expected != actual) {
            throw new AssertionError(message + ": expected " + expected + ", got " + actual);
        }
        assertions++;
    }

    private static void expectArrayEquals(int[] expected, int[] actual, String message) {
        if (!Arrays.equals(expected, actual)) {
            throw new AssertionError(message + ": expected " +
                    Arrays.toString(expected) + ", got " + Arrays.toString(actual));
        }
        assertions++;
    }
}

package com.garethpaul.app.hrm;

final class HeartRateMeasurement {
    private final int beatsPerMinute;
    private final Boolean sensorContactDetected;
    private final Integer energyExpendedKilojoules;
    private final int[] rrIntervals;

    HeartRateMeasurement(int beatsPerMinute,
                         Boolean sensorContactDetected,
                         Integer energyExpendedKilojoules,
                         int[] rrIntervals) {
        this.beatsPerMinute = beatsPerMinute;
        this.sensorContactDetected = sensorContactDetected;
        this.energyExpendedKilojoules = energyExpendedKilojoules;
        this.rrIntervals = rrIntervals.clone();
    }

    int beatsPerMinute() {
        return beatsPerMinute;
    }

    Boolean sensorContactDetected() {
        return sensorContactDetected;
    }

    Integer energyExpendedKilojoules() {
        return energyExpendedKilojoules;
    }

    int[] rrIntervals() {
        return rrIntervals.clone();
    }
}

package com.garethpaul.app.hrm;

final class CallbackGeneration {
    private long generation;

    synchronized long advance() {
        generation++;
        return generation;
    }

    synchronized void invalidate() {
        generation++;
    }

    synchronized boolean isCurrent(long candidate) {
        return candidate == generation;
    }
}

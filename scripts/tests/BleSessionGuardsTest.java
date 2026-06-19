package com.garethpaul.app.hrm;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public final class BleSessionGuardsTest {
    private static final class FakeGatt {
        private final String name;

        FakeGatt(String name) {
            this.name = name;
        }

        @Override
        public String toString() {
            return name;
        }
    }

    public static void main(String[] args) throws Exception {
        rejectsCallbacksFromStoppedAndReplacedScans();
        issuesUniqueScanGenerationsAcrossThreads();
        releasesOnlyTheCurrentlyOwnedGatt();
        releasesTheCurrentGattExactlyOnce();
        System.out.println("BLE session guard tests passed.");
    }

    private static void rejectsCallbacksFromStoppedAndReplacedScans() {
        CallbackGeneration generations = new CallbackGeneration();
        long first = generations.advance();
        assertTrue(generations.isCurrent(first), "first scan must be current");

        generations.invalidate();
        assertFalse(generations.isCurrent(first), "stopped scan callback must be stale");

        long second = generations.advance();
        assertFalse(generations.isCurrent(first), "replaced scan callback must remain stale");
        assertTrue(generations.isCurrent(second), "replacement scan must be current");
    }

    private static void issuesUniqueScanGenerationsAcrossThreads() throws Exception {
        final CallbackGeneration generations = new CallbackGeneration();
        final Set<Long> tokens = Collections.synchronizedSet(new HashSet<Long>());
        Thread[] threads = new Thread[8];
        for (int index = 0; index < threads.length; index++) {
            threads[index] = new Thread(new Runnable() {
                @Override
                public void run() {
                    for (int count = 0; count < 250; count++) {
                        tokens.add(Long.valueOf(generations.advance()));
                    }
                }
            });
            threads[index].start();
        }
        for (Thread thread : threads) {
            thread.join();
        }
        assertEquals(2000, tokens.size(), "every scan generation must be unique");
    }

    private static void releasesOnlyTheCurrentlyOwnedGatt() {
        GattConnectionOwner<FakeGatt> owner = new GattConnectionOwner<FakeGatt>();
        FakeGatt first = new FakeGatt("first");
        FakeGatt second = new FakeGatt("second");

        assertSame(null, owner.replace(first), "first publish must not replace a GATT");
        assertSame(first, owner.replace(second), "replacement must return prior GATT");
        assertSame(null, owner.releaseIfCurrent(first), "stale callback must not release current GATT");
        assertTrue(owner.isCurrent(second), "stale callback must preserve replacement GATT");
        assertSame(second, owner.releaseIfCurrent(second), "current callback must release owned GATT");
    }

    private static void releasesTheCurrentGattExactlyOnce() {
        GattConnectionOwner<FakeGatt> owner = new GattConnectionOwner<FakeGatt>();
        FakeGatt gatt = new FakeGatt("owned");
        owner.replace(gatt);

        assertSame(gatt, owner.releaseCurrent(), "first close must receive owned GATT");
        assertSame(null, owner.releaseCurrent(), "repeated close must be a no-op");
        assertSame(null, owner.releaseIfCurrent(gatt), "late callback must not re-release closed GATT");
    }

    private static void assertTrue(boolean condition, String message) {
        if (!condition) {
            throw new AssertionError(message);
        }
    }

    private static void assertFalse(boolean condition, String message) {
        assertTrue(!condition, message);
    }

    private static void assertEquals(int expected, int actual, String message) {
        if (expected != actual) {
            throw new AssertionError(message + ": expected " + expected + ", got " + actual);
        }
    }

    private static void assertSame(Object expected, Object actual, String message) {
        if (expected != actual) {
            throw new AssertionError(message + ": expected " + expected + ", got " + actual);
        }
    }
}

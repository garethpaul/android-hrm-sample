package com.garethpaul.app.hrm;

final class GattConnectionOwner<T> {
    private T current;

    synchronized T current() {
        return current;
    }

    synchronized boolean isCurrent(T candidate) {
        return candidate != null && candidate == current;
    }

    synchronized T replace(T replacement) {
        T previous = current;
        current = replacement;
        return previous;
    }

    synchronized T releaseIfCurrent(T candidate) {
        if (!isCurrent(candidate)) {
            return null;
        }
        current = null;
        return candidate;
    }

    synchronized T releaseCurrent() {
        T released = current;
        current = null;
        return released;
    }
}

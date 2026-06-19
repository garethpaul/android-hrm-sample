package com.garethpaul.app.hrm;

import android.app.ActionBar;
import android.app.Activity;
import android.app.ListActivity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;
import android.util.Log;

import java.util.ArrayList;

/**
 * Activity for scanning and displaying available Bluetooth LE devices.
 */
public class DeviceScanActivity extends ListActivity {
    private static final String TAG = DeviceScanActivity.class.getSimpleName();
    private LeDeviceListAdapter mLeDeviceListAdapter;
    private BluetoothAdapter mBluetoothAdapter;
    private boolean mScanning;
    private Handler mHandler;
    private final CallbackGeneration mScanGeneration = new CallbackGeneration();
    private BluetoothAdapter.LeScanCallback mLeScanCallback;

    private static final int REQUEST_ENABLE_BT = 1;
    // Stops scanning after 10 seconds.
    private static final long SCAN_PERIOD = 10000;
    private final Runnable mStopScanRunnable = new Runnable() {
        @Override
        public void run() {
            scanLeDevice(false);
        }
    };

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        configureActionBar();
        mHandler = new Handler();

        // Use this check to determine whether BLE is supported on the device.  Then you can
        // selectively disable BLE-related features.
        if (!getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            Toast.makeText(this, com.garethpaul.app.hrm.R.string.ble_not_supported, Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        // Initializes a Bluetooth adapter.  For API level 18 and above, get a reference to
        // BluetoothAdapter through BluetoothManager.
        final BluetoothManager bluetoothManager =
                (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        if (bluetoothManager == null) {
            Toast.makeText(this, com.garethpaul.app.hrm.R.string.error_bluetooth_not_supported, Toast.LENGTH_SHORT).show();
            finish();
            return;
        }
        mBluetoothAdapter = bluetoothManager.getAdapter();

        // Checks if Bluetooth is supported on the device.
        if (mBluetoothAdapter == null) {
            Toast.makeText(this, com.garethpaul.app.hrm.R.string.error_bluetooth_not_supported, Toast.LENGTH_SHORT).show();
            finish();
            return;
        }
    }

    private void configureActionBar() {
        ActionBar actionBar = getActionBar();
        if (actionBar == null) {
            return;
        }

        actionBar.setDisplayShowTitleEnabled(false);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(com.garethpaul.app.hrm.R.menu.main, menu);
        if (!mScanning) {
            menu.findItem(com.garethpaul.app.hrm.R.id.menu_stop).setVisible(false);
            menu.findItem(com.garethpaul.app.hrm.R.id.menu_scan).setVisible(true);
            menu.findItem(com.garethpaul.app.hrm.R.id.menu_refresh).setActionView(null);
        } else {
            menu.findItem(com.garethpaul.app.hrm.R.id.menu_stop).setVisible(true);
            menu.findItem(com.garethpaul.app.hrm.R.id.menu_scan).setVisible(false);
            menu.findItem(com.garethpaul.app.hrm.R.id.menu_refresh).setActionView(
                    com.garethpaul.app.hrm.R.layout.actionbar_indeterminate_progress);
        }
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case com.garethpaul.app.hrm.R.id.menu_scan:
                if (mLeDeviceListAdapter != null) {
                    mLeDeviceListAdapter.clear();
                }
                scanLeDevice(true);
                break;
            case com.garethpaul.app.hrm.R.id.menu_stop:
                scanLeDevice(false);
                break;
        }
        return true;
    }

    @Override
    protected void onResume() {
        super.onResume();

        if (mBluetoothAdapter == null) {
            finish();
            return;
        }

        // Ensures Bluetooth is enabled on the device.  If Bluetooth is not currently enabled,
        // fire an intent to display a dialog asking the user to grant permission to enable it.
        final boolean bluetoothEnabled;
        try {
            bluetoothEnabled = mBluetoothAdapter.isEnabled();
        } catch (SecurityException securityException) {
            Log.w(TAG, "Bluetooth state permission is unavailable.");
            Toast.makeText(this, com.garethpaul.app.hrm.R.string.scan_start_failed,
                    Toast.LENGTH_SHORT).show();
            finish();
            return;
        }
        if (!bluetoothEnabled) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
            return;
        }

        // Initializes list view adapter.
        mLeDeviceListAdapter = new LeDeviceListAdapter();
        setListAdapter(mLeDeviceListAdapter);
        scanLeDevice(true);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        // User chose not to enable Bluetooth.
        if (requestCode == REQUEST_ENABLE_BT && resultCode == Activity.RESULT_CANCELED) {
            finish();
            return;
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onPause() {
        super.onPause();
        scanLeDevice(false);
        if (mLeDeviceListAdapter != null) {
            mLeDeviceListAdapter.clear();
        }
    }

    @Override
    protected void onListItemClick(ListView l, View v, int position, long id) {
        if (mLeDeviceListAdapter == null) {
            return;
        }

        final BluetoothDevice device = mLeDeviceListAdapter.getDevice(position);
        if (device == null || !(v.getTag() instanceof ViewHolder)) return;
        final String deviceAddress = device.getAddress();
        final ViewHolder viewHolder = (ViewHolder) v.getTag();
        if (!BluetoothAdapter.checkBluetoothAddress(deviceAddress) ||
                !deviceAddress.equals(viewHolder.boundDeviceAddress)) {
            return;
        }
        final Intent intent = new Intent(this, DeviceControlActivity.class);
        intent.putExtra(DeviceControlActivity.EXTRAS_DEVICE_NAME, device.getName());
        intent.putExtra(DeviceControlActivity.EXTRAS_DEVICE_ADDRESS, deviceAddress);
        if (mScanning) {
            scanLeDevice(false);
        }
        startActivity(intent);
    }

    private void scanLeDevice(final boolean enable) {
        if (mBluetoothAdapter == null || mHandler == null) {
            return;
        }

        if (enable) {
            // Stops scanning after a pre-defined scan period.
            mHandler.removeCallbacks(mStopScanRunnable);
            final long generation = mScanGeneration.advance();
            final BluetoothAdapter.LeScanCallback scanCallback =
                    createLeScanCallback(generation);
            boolean scanStarted = false;
            try {
                scanStarted = mBluetoothAdapter.startLeScan(scanCallback);
            } catch (SecurityException securityException) {
                Log.w(TAG, "Bluetooth scan permission is unavailable.");
            }
            if (scanStarted) {
                mLeScanCallback = scanCallback;
                mScanning = true;
                mHandler.postDelayed(mStopScanRunnable, SCAN_PERIOD);
            } else {
                mScanGeneration.invalidate();
                mLeScanCallback = null;
                mScanning = false;
                Toast.makeText(this, com.garethpaul.app.hrm.R.string.scan_start_failed,
                        Toast.LENGTH_SHORT).show();
            }
        } else {
            mHandler.removeCallbacks(mStopScanRunnable);
            mScanning = false;
            mScanGeneration.invalidate();
            final BluetoothAdapter.LeScanCallback scanCallback = mLeScanCallback;
            mLeScanCallback = null;
            if (scanCallback != null) {
                try {
                    mBluetoothAdapter.stopLeScan(scanCallback);
                } catch (SecurityException securityException) {
                    Log.w(TAG, "Bluetooth scan stop permission is unavailable.");
                }
            }
        }
        invalidateOptionsMenu();
    }

    // Adapter for holding devices found through scanning.
    private class LeDeviceListAdapter extends BaseAdapter {
        private ArrayList<BluetoothDevice> mLeDevices;
        private LayoutInflater mInflator;

        public LeDeviceListAdapter() {
            super();
            mLeDevices = new ArrayList<BluetoothDevice>();
            mInflator = DeviceScanActivity.this.getLayoutInflater();
        }

        public void addDevice(BluetoothDevice device) {
            if (device == null) {
                return;
            }

            if(!mLeDevices.contains(device)) {
                mLeDevices.add(device);
            }
        }

        public BluetoothDevice getDevice(int position) {
            if (position < 0 || position >= mLeDevices.size()) {
                return null;
            }

            return mLeDevices.get(position);
        }

        public void clear() {
            mLeDevices.clear();
        }

        @Override
        public int getCount() {
            return mLeDevices.size();
        }

        @Override
        public Object getItem(int i) {
            return mLeDevices.get(i);
        }

        @Override
        public long getItemId(int i) {
            return i;
        }

        @Override
        public View getView(int i, View view, ViewGroup viewGroup) {
            ViewHolder viewHolder;
            // General ListView optimization code.
            if (view == null) {
                view = mInflator.inflate(
                        com.garethpaul.app.hrm.R.layout.listitem_device, viewGroup, false);
                viewHolder = new ViewHolder();
                viewHolder.deviceAddress = (TextView) view.findViewById(com.garethpaul.app.hrm.R.id.device_address);
                viewHolder.deviceName = (TextView) view.findViewById(com.garethpaul.app.hrm.R.id.device_name);
                view.setTag(viewHolder);
            } else {
                viewHolder = (ViewHolder) view.getTag();
            }

            BluetoothDevice device = mLeDevices.get(i);
            final String deviceName = device.getName();
            if (deviceName != null && deviceName.length() > 0)
                viewHolder.deviceName.setText(deviceName);
            else
                viewHolder.deviceName.setText(com.garethpaul.app.hrm.R.string.unknown_device);
            viewHolder.deviceAddress.setText(device.getAddress());
            viewHolder.boundDeviceAddress = device.getAddress();

            return view;
        }
    }

    // Device scan callback.
    private BluetoothAdapter.LeScanCallback createLeScanCallback(final long generation) {
        return new BluetoothAdapter.LeScanCallback() {

        @Override
        public void onLeScan(final BluetoothDevice device, int rssi, byte[] scanRecord) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (!mScanning || !mScanGeneration.isCurrent(generation) ||
                            mLeDeviceListAdapter == null || device == null) {
                        return;
                    }

                    mLeDeviceListAdapter.addDevice(device);
                    mLeDeviceListAdapter.notifyDataSetChanged();
                }
            });
        }
        };
    }

    static class ViewHolder {
        TextView deviceName;
        TextView deviceAddress;
        String boundDeviceAddress;
    }
}

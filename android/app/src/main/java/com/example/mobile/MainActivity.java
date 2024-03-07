package com.example.mobile;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.location.LocationManager;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;
import android.os.Handler;
import android.provider.Settings;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import com.espressif.provisioning.DeviceConnectionEvent;
import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.WiFiAccessPoint;
import com.espressif.provisioning.listeners.BleScanListener;
import com.espressif.provisioning.listeners.ProvisionListener;
import com.espressif.provisioning.listeners.ResponseListener;
import com.espressif.provisioning.listeners.WiFiScanListener;
import com.example.mobile.AppConstants;

import io.flutter.embedding.android.FlutterActivity;

import com.espressif.provisioning.ESPProvisionManager;

import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;
import org.jetbrains.annotations.NotNull;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "mings";
    private static final String CHANNEL = "est.co.kr/IoT_Hub";
    private static final int REQUEST_LOCATION = 1;
    private static final int REQUEST_ENABLE_BT = 2;

    private static final int REQUEST_FINE_LOCATION = 3;
    private static final long DEVICE_CONNECT_TIMEOUT = 20000;
    private ESPProvisionManager provisionManager;
    private SharedPreferences sharedPreferences;
    private String deviceType;
    private BluetoothAdapter bleAdapter;
    private String deviceNamePrefix;
    private boolean isDeviceConnected = false, isConnecting = false;
    private boolean isScanning = false;
    private Handler handler;
    private ArrayList<BleDevice> deviceList;
    private ArrayList<String> deviceNameList;
    private HashMap<BluetoothDevice, String> bluetoothDevices;

    private MethodChannel.Result mainActivityResult;

    private String hubName = "";
    private String hubID = "";
    private String accountID = "";
    private String serverIp = "";
    private String serverPort = "";
    private String userID = "";
    private String userPw = "";
    private String selectedWifiName = "";
    private String selectedWifiPassword = "";
    private ArrayList<WiFiAccessPoint> wifiAPList;

    private static String[] PERMISSIONS_LOCATION  = {
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_LOCATION_EXTRA_COMMANDS,
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_PRIVILEGED
    };
    private void checkPermissions() {
        // 권한 체크해서 권한이 있을 때
        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_LOCATION_EXTRA_COMMANDS) == PackageManager.PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_PRIVILEGED) == PackageManager.PERMISSION_GRANTED) {
        }

        // 권한이 없을 때 권한을 요구함
        else {
            ActivityCompat.requestPermissions(
                    this,
                    PERMISSIONS_LOCATION,
                    1
            );
        }
    }
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        EventBus.getDefault().register(this);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            // This method is invoked on the main thread.
                            if (call.method.equals("findEsp32")) {
                                checkPermissions();
                                hubName = "";
                                mainActivityResult = result;
                                scanEsp32Device();
                            } else if (call.method.equals("settingHub")) {
                                hubName = call.argument("hubName");
                                hubID = "";
                                accountID = call.argument("accountID");
                                serverIp = call.argument("serverIp");
                                serverPort = call.argument("serverPort");
                                userID = call.argument("userID");
                                userPw = call.argument("userPw");

                                mainActivityResult = result;

                                scanEsp32Device();
                            } else if (call.method.equals("_wifiProvision")) {
                                wifiAPList = new ArrayList<>();
                                mainActivityResult = result;

                                startWifiScan();
                            } else if (call.method.equals("setWifiConfig")) {
                                selectedWifiName = call.argument("wifiName");
                                selectedWifiPassword = call.argument("password");
                                Log.d(TAG, "-------------- " + selectedWifiName + "  " + selectedWifiPassword);

                                mainActivityResult = result;

                                startWifiProvision();
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private void startWifiProvision() {
        provisionManager.getEspDevice().provision(selectedWifiName, selectedWifiPassword, new ProvisionListener() {

            @Override
            public void createSessionFailed(Exception e) {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        Log.d(TAG,"Failed to create session");
                    }
                });
            }

            @Override
            public void wifiConfigSent() {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        Log.d(TAG,"Wi-Fi config sent.");
                    }
                });
            }

            @Override
            public void wifiConfigFailed(Exception e) {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        Log.d(TAG,"Failed to send Wi-Fi credentials");
                    }
                });
            }

            @Override
            public void wifiConfigApplied() {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        Log.d(TAG,"Wi-Fi config applied.");
                    }
                });
            }

            @Override
            public void wifiConfigApplyFailed(Exception e) {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        Log.d(TAG,"Failed to apply Wi-Fi credentials");
                    }
                });
            }

            @Override
            public void provisioningFailedFromDevice(final ESPConstants.ProvisionFailureReason failureReason) {

                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {

                        switch (failureReason) {
                            case AUTH_FAILED:
                                Log.d(TAG,"Wi-Fi Authentication failed.");
                                break;
                            case NETWORK_NOT_FOUND:
                                Log.d(TAG,"Network not found.");
                                break;
                            case DEVICE_DISCONNECTED:
                            case UNKNOWN:
                                Log.d(TAG, "Failed to provisioning device");
                                break;
                        }
                    }
                });
            }

            @Override
            public void deviceProvisioningSuccess() {
                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        Log.d(TAG, "Device provisioning success.");
                        mainActivityResult.success("Device provisioning success.");
                    }
                });
            }

            @Override
            public void onProvisioningFailed(Exception e) {

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        mainActivityResult.success("Failed to provisioning device");
                    }
                });
            }
        });
    }

    private void scanEsp32Device() {
        checkPermissions();

        sharedPreferences = getSharedPreferences(AppConstants.ESP_PREFERENCES, Context.MODE_PRIVATE);
        provisionManager = ESPProvisionManager.getInstance(getApplicationContext());

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {

            if (!isLocationEnabled()) {
                askForLocation();
                closeErrorActivity("Can't find device");
            }
        }

        final BluetoothManager bluetoothManager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothAdapter bleAdapter = bluetoothManager.getAdapter();

        if (!bleAdapter.isEnabled()) {
//            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
//            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
//                closeErrorActivity("Can't find device");
//            }
//            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        } else {
            startProvisioningFlow();
        }
    }

    private void startProvisioningFlow() {
        deviceType = AppConstants.DEVICE_TYPE_BLE;
        final boolean isSec1 = sharedPreferences.getBoolean(AppConstants.KEY_SECURITY_TYPE, true);
        Log.d(TAG, "Device Types : " + deviceType);
        Log.d(TAG, "isSec1 : " + isSec1);
        int securityType = 0;
        if (isSec1) {
            //여기
            securityType = 1;
        }

        Log.d(TAG, "=================");
        provisionManager.createESPDevice(ESPConstants.TransportType.TRANSPORT_BLE, ESPConstants.SecurityType.SECURITY_1);
        bleProvisionLanding(securityType);
    }

    private void bleProvisionLanding(int securityType) {
        Log.d(TAG, "bleProvisionLanding()");
        if (!getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            Log.d(TAG, "=====================");
            closeErrorActivity("Sorry! BLE is not supported - 1");
            return;
        }

        final BluetoothManager bluetoothManager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        bleAdapter = bluetoothManager.getAdapter();

        // Checks if Bluetooth is supported on the device.
        if (bleAdapter == null) {
            closeErrorActivity("Sorry! BLE is not supported - 2");
            return;
        }

        isConnecting = false;
        isDeviceConnected = false;
        handler = new Handler();
        bluetoothDevices = new HashMap<>();
        deviceList = new ArrayList<>();
        deviceNameList = new ArrayList<>();
        deviceNamePrefix = sharedPreferences.getString(AppConstants.KEY_BLE_DEVICE_NAME_PREFIX, "PROV_");

        if (!bleAdapter.isEnabled()) {
//            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
//            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
//                closeErrorActivity("Sorry! BLE is not supported - 3");
//                return;
//            }
//            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        } else {

            if (!isDeviceConnected && !isConnecting) {
                startScan();
            }
        }
    }



    private void startScan() {

//        if (!hasPermissions() || isScanning) {
//            Log.d(TAG, "hasPermissions()");
//            closeErrorActivity("hasPermissions() is failed.");
//            return;
//        }

        isScanning = true;
        deviceList.clear();
        bluetoothDevices.clear();

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            provisionManager.searchBleEspDevices(deviceNamePrefix, bleScanListener);
        } else {
            closeErrorActivity("Not able to start scan as Location permission is not granted.");
        }
    }

//    private boolean hasPermissions() {
//
//        if (bleAdapter == null || !bleAdapter.isEnabled()) {
//            Log.d(TAG, "hasPermissioin() - 1");
//            requestBluetoothEnable();
//            return false;
//
//        } else if (!hasLocationPermissions()) {
//            Log.d(TAG, "hasPermissioin() - 2");
//            requestLocationPermission();
//            return false;
//        }
//        return true;
//    }

    private void stopScan() {

        isScanning = false;

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            provisionManager.stopBleScan();
        } else {
            closeErrorActivity("Not able to stop scan as Location permission is not granted.");
        }

        if (deviceList.size() <= 0) {
            closeErrorActivity("No Bluetooth devices found!");
        }
    }

    private BleScanListener bleScanListener = new BleScanListener() {

        @Override
        public void scanStartFailed() {
            isScanning = false;
            closeErrorActivity("Please turn on Bluetooth to connect BLE device");
        }

        @Override
        public void onPeripheralFound(BluetoothDevice device, ScanResult scanResult) {
            Log.d(TAG, "====== onPeripheralFound ===== " + device.getName());
            boolean deviceExists = false;
            String serviceUuid = "";

            if (scanResult.getScanRecord().getServiceUuids() != null && scanResult.getScanRecord().getServiceUuids().size() > 0) {
                serviceUuid = scanResult.getScanRecord().getServiceUuids().get(0).toString();
            }
            Log.d(TAG, "Add service UUID : " + serviceUuid);

            if (bluetoothDevices.containsKey(device)) {
                deviceExists = true;
            }

            if (!deviceExists) {
                BleDevice bleDevice = new BleDevice();
                bleDevice.setName(scanResult.getScanRecord().getDeviceName());
                bleDevice.setBluetoothDevice(device);

                bluetoothDevices.put(device, serviceUuid);
                deviceList.add(bleDevice);

                deviceNameList.add(scanResult.getScanRecord().getDeviceName());

                if (hubName != "")
                {
                    stopScan();
                }
            }
        }

        @Override
        public void scanCompleted() {
            isScanning = false;

            Log.d(TAG, "scanCompleted() - " + deviceNameList.toString());

            if (hubName == "") {
                EventBus.getDefault().unregister(this);
                mainActivityResult.success(deviceNameList);
            } else {
                if (deviceList.size() > 0) {
                    settingHub();
                }

            }
        }

        @Override
        public void onFailure(Exception e) {
            Log.e(TAG, e.getMessage());
            e.printStackTrace();
        }
    };

    private void settingHub() {
        BleDevice bleDevice = deviceList.get(0);
        String uuid = bluetoothDevices.get(bleDevice.getBluetoothDevice());

        provisionManager.getEspDevice().connectBLEDevice(bleDevice.getBluetoothDevice(), uuid);
        handler.postDelayed(disconnectDeviceTask, DEVICE_CONNECT_TIMEOUT);
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(DeviceConnectionEvent event) {

        Log.d(TAG, "ON Device Prov Event RECEIVED : " + event.getEventType());
        handler.removeCallbacks(disconnectDeviceTask);

        switch (event.getEventType()) {

            case ESPConstants.EVENT_DEVICE_CONNECTED:
                Log.d(TAG, "Device Connected Event Received");
                isConnecting = false;
                isDeviceConnected = true;

                //isSecure: false && securityType != AppConstants.SEC_TYPE_0을 전제로 한다.
                //isSecure, securityType의 용도는 모르겠음.
                processDeviceCapabilities();

                break;

            case ESPConstants.EVENT_DEVICE_DISCONNECTED:

                isConnecting = false;
                isDeviceConnected = false;
                //Toast.makeText(BLEProvisionLanding.this, "Device disconnected", Toast.LENGTH_LONG).show();
                break;

            case ESPConstants.EVENT_DEVICE_CONNECTION_FAILED:
                isConnecting = false;
                isDeviceConnected = false;
                //Utils.displayDeviceConnectionError(this, getString(R.string.error_device_connect_failed));
                break;
        }
    }

    private void processDeviceCapabilities() {
        ArrayList<String> deviceCaps = provisionManager.getEspDevice().getDeviceCapabilities();

        //if (deviceCaps != null && !deviceCaps.contains("no_pop") && securityType != AppConstants.SEC_TYPE_0) {
        if (deviceCaps != null && !deviceCaps.contains("no_pop")) {
            Log.d(TAG, "11111111111");
//            goToPopActivity();

        } else if (deviceCaps.contains("wifi_scan")) {
            Log.d(TAG, "22222222222");
            getDeviceID();

        } else {
            Log.d(TAG, "33333333333");
//            goToWiFiConfigActivity();
        }
    }

    class CGetDeviceID {
        private String order;

        public CGetDeviceID(String order){
            this.order = order;
        }
    }

    class CSetID {
        private String order;
        private String accountID;

        public CSetID(String order, String accountID){
            this.order = order;
            this.accountID = accountID;
        }
    }

    class CSetMQTT {
        private String order;
        private String ip;
        private String port;
        private String id;
        private String pw;

        public CSetMQTT(String order, String ip, String port, String id, String pw){
            this.order = order;
            this.ip = ip;
            this.port = port;
            this.id = id;
            this.pw = pw;
        }
    }

    private void getDeviceID() {

        CGetDeviceID getDeviceIDConfig = new CGetDeviceID("getDeviceID");
        Gson gson = new GsonBuilder().setPrettyPrinting().create();

        byte[] result = gson.toJson(getDeviceIDConfig).getBytes(StandardCharsets.UTF_8);

        Log.i(TAG, Arrays.toString(result));
        Log.i(TAG, new String(result));
        provisionManager.getEspDevice().sendDataToCustomEndPoint("custom-data", result, new ResponseListener() {

            @Override
            public void onSuccess(final byte[] returnData) {
                Log.i(TAG, ">>> sendData response  : " + new String(returnData));
                Log.i(TAG, ">>> sendData response length : " + returnData.length);

                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        try {
                            hubID = new String(returnData, "US-ASCII");
                        }catch(UnsupportedEncodingException e){

                        }
                    }
                });

                setAccountID();
            }

            @Override
            public void onFailure(Exception e) {
                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        closeErrorActivity("Failed to doDeviceConfig_3");
                    }
                });
            }
        });
    }

    private void setAccountID() {

        CSetID idConfig = new CSetID("setID", accountID);
//        CSetID idConfig = new CSetID("setID", "dn9318dn@gmail.com");

        Gson gson = new GsonBuilder().setPrettyPrinting().create();

        byte[] result = gson.toJson(idConfig).getBytes(StandardCharsets.UTF_8);



        Log.i(TAG, "1 " + Arrays.toString(result));
        Log.i(TAG, "2 " + new String(result));

        provisionManager.getEspDevice().sendDataToCustomEndPoint("custom-data", result, new ResponseListener() {

            @Override
            public void onSuccess(final byte[] returnData) {
                Log.i(TAG, ">>> sendData response  : " + new String(returnData));
                Log.i(TAG, ">>> sendData response length : " + returnData.length);

                setMqtt();
                //getKeyValue();
            }

            @Override
            public void onFailure(Exception e) {
                closeErrorActivity("Failed to doDeviceConfig_2()");
            }
        });
    }

    private void setMqtt() {
        Log.d(TAG, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        CSetMQTT mqttConfig = new CSetMQTT("setMQTT", serverIp, serverPort, userID, userPw);

//        Log.d(TAG, "" + serverIp + " " + serverPort + " " + userID + " " + userPw);
//        CSetMQTT mqttConfig = new CSetMQTT("setMQTT", "14.42.209.174", "6002", "mings", "Sct91234!");
        Gson gson = new GsonBuilder().setPrettyPrinting().create();

        byte[] result = gson.toJson(mqttConfig).getBytes(StandardCharsets.UTF_8);

        Log.i(TAG, "1 " + Arrays.toString(result));
        Log.i(TAG, "2 " + new String(result));

        provisionManager.getEspDevice().sendDataToCustomEndPoint("custom-data", result, new ResponseListener() {

            @Override
            public void onSuccess(final byte[] returnData) {
                Log.i(TAG, ">>> sendData response  : " + new String(returnData));
                Log.i(TAG, ">>> sendData response length : " + returnData.length);

//                startWifiScan();

                mainActivityResult.success(hubID);
            }

            @Override
            public void onFailure(Exception e) {
                runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        closeErrorActivity("Failed to doDeviceConfig_3()");
                    }
                });
            }
        });
    }

    private void startWifiScan() {
        Log.d(TAG, "Start Wi-Fi Scan");
        wifiAPList.clear();

//        runOnUiThread(new Runnable() {
//
//            @Override
//            public void run() {
//                updateProgressAndScanBtn(true);
//            }
//        });

//        handler.postDelayed(stopScanningTask, 100000);

        provisionManager.getEspDevice().scanNetworks(new WiFiScanListener() {

            @Override
            public void onWifiListReceived(final ArrayList<WiFiAccessPoint> wifiList) {

                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        wifiAPList.addAll(wifiList);
                        completeWifiList();
                    }
                });
            }

            @Override
            public void onWiFiScanFailed(Exception e) {

                // TODO
                Log.e(TAG, "onWiFiScanFailed");
                e.printStackTrace();
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        closeErrorActivity("Failed to get Wi-Fi scan list");
                    }
                });
            }
        });
    }

    private void completeWifiList() {

        // Add "Join network" Option as a list item
        WiFiAccessPoint wifiAp = new WiFiAccessPoint();
        wifiAp.setWifiName("Join Other Network");
        wifiAPList.add(wifiAp);

//        updateProgressAndScanBtn(false);
//        handler.removeCallbacks(stopScanningTask);

        try {
            JSONArray jsonArr = new JSONArray();
            for (int i = 0; i < wifiAPList.size(); i++) {
                WiFiAccessPoint ap = wifiAPList.get(i);

                JSONObject jsonObj = new JSONObject();
                jsonObj.put("WifiName", ap.getWifiName());
                jsonObj.put("rssi", ap.getRssi());
                jsonObj.put("security", ap.getSecurity());
                jsonObj.put("password", ap.getPassword());

                jsonArr.put(jsonObj);
            }

            String data = jsonArr.toString();
            mainActivityResult.success(data);
        } catch (JSONException e) {
            e.printStackTrace();
            closeErrorActivity("Failed to Wifi Scan()");
        }
    }

    private Runnable disconnectDeviceTask = new Runnable() {

        @Override
        public void run() {
            Log.e(TAG, "Disconnect device");
            closeErrorActivity("Communication failed. Device may not be supported.");
        }
    };

    private void closeErrorActivity(String msg) {
        EventBus.getDefault().unregister(this);
        mainActivityResult.error("UNAVAILABLE", msg, null);
    }

    private void requestBluetoothEnable() {

        Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
        startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        Log.d(TAG, "Requested user enables Bluetooth.");
    }

    private boolean hasLocationPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        }
        return true;
    }

    private void requestLocationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, REQUEST_FINE_LOCATION);
        }
    }

    private void askForLocation() {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(true);
        builder.setMessage("Location services are disabled. Please enable them to continue");

        // Set up the buttons
        builder.setPositiveButton("Ok", new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                startActivityForResult(new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS), REQUEST_LOCATION);
            }
        });

        builder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        builder.show();
    }
    private boolean isLocationEnabled() {

        boolean gps_enabled = false;
        boolean network_enabled = false;
        LocationManager lm = (LocationManager) getApplicationContext().getSystemService(Activity.LOCATION_SERVICE);

        try {
            gps_enabled = lm.isProviderEnabled(LocationManager.GPS_PROVIDER);
        } catch (Exception ex) {
        }

        try {
            network_enabled = lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
        } catch (Exception ex) {
        }

        Log.d(TAG, "GPS Enabled : " + gps_enabled + " , Network Enabled : " + network_enabled);

        boolean result = gps_enabled || network_enabled;
        return result;
    }
}

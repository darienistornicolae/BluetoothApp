import SwiftUI

struct ContentView: View {
  @StateObject private var bluetoothManager = BluetoothManager()
  @State private var showingAlert: Bool = false
  @State private var alertMessage: String = ""
  
  var body: some View {
    NavigationView {
      List {
        if let connectedDevice = bluetoothManager.connectedDevice {
          Section(header: Text("Connected Device")) {
            Text(connectedDevice.name ?? "Unknown Device")
            Button("Disconnect") {
              bluetoothManager.disconnect()
            }
            if bluetoothManager.isAudioReady {
              Button(bluetoothManager.isPlaying ? "Stop Audio" : "Play Audio") {
                if bluetoothManager.isPlaying {
                  bluetoothManager.stopPlayback()
                } else {
                  bluetoothManager.playAudioOnConnectedDevice()
                }
              }
            }
          }
        }
        
        Section(header: Text("Available Devices")) {
          ForEach(bluetoothManager.availableDevices, id: \.identifier) { device in
            Button(action: {
              bluetoothManager.connect(to: device)
            }) {
              Text(device.name ?? "Unknown Device")
            }
          }
        }
      }
      .navigationTitle("Bluetooth Devices")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(bluetoothManager.isScanning ? "Stop Scanning" : "Start Scanning") {
            if bluetoothManager.isScanning {
              bluetoothManager.stopScanning()
            } else {
              bluetoothManager.startScanning()
            }
          }
        }
      }
      .onChange(of: bluetoothManager.connectedDevice) { newDevice in
        if newDevice != nil {
          alertMessage = "Successfully connected. Audio will play automatically."
          showingAlert = true
        }
      }
      .alert(isPresented: $showingAlert) {
        Alert(
          title: Text("Bluetooth Action"),
          message: Text(alertMessage),
          dismissButton: .default(Text("Ok"))
        )
      }
    }
  }
}

import Foundation
import CoreBluetooth
import AVFoundation

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  @Published var availableDevices: [CBPeripheral] = []
  @Published var connectedDevice: CBPeripheral?
  @Published var isScanning: Bool = false
  @Published var isPlaying: Bool = false
  @Published var isAudioReady: Bool = false
  
  private var centralManager: CBCentralManager!
  private var audioPlayer: AVAudioPlayer?
  
  override init() {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: .main)
    setupAudioSession()
    loadAudioFile()
  }
  
  private func setupAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Failed to set up audio session: \(error)")
    }
  }
  
  private func loadAudioFile() {
    guard let url = Bundle.main.url(forResource: "testConnection2", withExtension: "mp3") else {
      print("Audio file not found")
      return
    }
    
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: url)
      audioPlayer?.prepareToPlay()
      isAudioReady = true
    } catch {
      print("Error loading audio file: \(error.localizedDescription)")
    }
  }
  
  func startScanning() {
    guard centralManager.state == .poweredOn else { return }
    centralManager.scanForPeripherals(withServices: nil, options: nil)
    isScanning = true
  }
  
  func stopScanning() {
    centralManager.stopScan()
    isScanning = false
  }
  
  func connect(to peripheral: CBPeripheral) {
    centralManager.connect(peripheral, options: nil)
  }
  
  func disconnect() {
    if let connectedDevice = connectedDevice {
      centralManager.cancelPeripheralConnection(connectedDevice)
    }
  }
  
  func playAudioOnConnectedDevice() {
    guard let player = audioPlayer, !isPlaying, isAudioReady else { return }
    player.play()
    isPlaying = true
  }
  
  func stopPlayback() {
    guard let player = audioPlayer, isPlaying else { return }
    player.stop()
    player.currentTime = 0
    isPlaying = false
  }
  
  // MARK: - CBCentralManagerDelegate
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn {
      print("Bluetooth is powered on")
    } else {
      print("Bluetooth is not available: \(central.state.rawValue)")
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    if !availableDevices.contains(peripheral) {
      availableDevices.append(peripheral)
    }
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    DispatchQueue.main.async {
      self.connectedDevice = peripheral
      self.playAudioOnConnectedDevice()
    }
    peripheral.delegate = self
    stopScanning()
    print("Connected to \(peripheral.name ?? "unknown device")")
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    DispatchQueue.main.async {
      self.connectedDevice = nil
      self.stopPlayback()
    }
    print("Disconnected from \(peripheral.name ?? "unknown device")")
  }
  
  // MARK: - CBPeripheralDelegate
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard error == nil else {
      print("Error discovering services: \(error!.localizedDescription)")
      return
    }
    
    guard let services = peripheral.services else { return }
    
    for service in services {
      print("Discovered service: \(service.uuid)")
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard error == nil else {
      print("Error discovering characteristics: \(error!.localizedDescription)")
      return
    }
    
    guard let characteristics = service.characteristics else { return }
    
    for characteristic in characteristics {
      print("Discovered characteristic: \(characteristic.uuid)")
    }
  }
}

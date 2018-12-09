//
//  ViewController.swift
//  Music 216 Instrument
//
//  Created by Peter Kos on 10/25/18.
//  Copyright © 2018 UW. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation
import CoreBluetooth
import AudioKit


class ViewController: UIViewController, CLLocationManagerDelegate, CBCentralManagerDelegate {

	@IBOutlet var attitudeLabelX: UILabel!
	@IBOutlet var attitudeLabelY: UILabel!
	@IBOutlet var attitudeLabelZ: UILabel!

	@IBOutlet var gyroscopeLabelX: UILabel!
	@IBOutlet var gyroscopeLabelY: UILabel!
	@IBOutlet var gyroscopeLabelZ: UILabel!

	@IBOutlet weak var frequencyLabel: UILabel!

	@IBAction func accOscSwitch(_ sender: UISwitch) {

		if sender.isOn && !accOsc.isPlaying {
			accOsc.start()
			print("starting second...")
		} else {
			accOsc.stop()
			print("stopping second...")
		}

	}


	let motionManager = CMMotionManager()
	var currentPitch = 0.0
	var currentRoll = 0.0
	var currentYaw = 0.0

	let locationManager = CLLocationManager()
	var region: CLBeaconRegion? = nil

	let beaconOsc = AKOscillator()
	let accOsc = AKOscillator()

	var bluetoothManager: CBCentralManager? = nil

	override func viewDidLoad() {

		super.viewDidLoad()

		// Configure location things
		locationManager.delegate = self
		locationManager.requestAlwaysAuthorization()


		// Configure our beacon
		let proximityUUID = UUID(uuidString: "B0702880-A295-A8AB-F734-031A98A512DA")
		let beaconID = "test"

		// Create our region
		self.region = CLBeaconRegion(proximityUUID: proximityUUID!, identifier: beaconID)

		// Manually request state because reasons
		// https://stackoverflow.com/q/34934181/1431900
		locationManager.requestState(for: self.region!)

		monitorBeacons()
		monitorMotion()


		// Initialize CBPMDelegate
//		bluetoothManager.delegate = self as? CBPeripheralManagerDelegate
		bluetoothManager = CBCentralManager(delegate: self as CBCentralManagerDelegate, queue: DispatchQueue.main)









		// --- SOUND ---


		let mixer = AKMixer(beaconOsc, accOsc)
		AudioKit.output = mixer

		// Configure default amp and freq
		// (These are set later in didRangeBeacons())
		beaconOsc.amplitude = 0.5
		beaconOsc.frequency = 440

		// Default values for accosc
		// (These are set later in monitorMotion()
		accOsc.amplitude = 0.5
		accOsc.frequency = 220

		// Output sound
		do {
			try AudioKit.start()
		} catch {
			print("oh no")
		}

		beaconOsc.start()
		accOsc.start()


	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		switch central.state {
			case .poweredOn: self.startScanning()
			default: print("oh noes")
		}
	}

	func startScanning() {
		bluetoothManager?.scanForPeripherals(withServices: nil, options: nil)
	}


	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		print("DISCOVERED SOMETHING")
		print("Name: \(peripheral.name)")
		print("RSSI: \(RSSI)")
	}




	func monitorBeacons() {

		if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {

			guard let region = self.region else {
				print("ERROR: Unable to instantiate beacon region.")
				return
			}

			print("entry notif: \(region.notifyOnEntry)")
			locationManager.startMonitoring(for: region)
		}

	}

	// MARK -- CLLocationManagerDelegate
	func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {

		print("Entered region")
		if region is CLBeaconRegion {
			if CLLocationManager.isRangingAvailable() {
				print("RANGING IS AVAILABLE")
				manager.startRangingBeacons(in: region as! CLBeaconRegion)
			}
		}

	}

	func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {

		// Print our beacons
//		print(beacons)
//		print("found in \(region.identifier)")

		if beacons.count > 0 {
			let nearestBeacon = beacons.first!

			// Let's implement a second oscillator
			// This time, the frequency changes with RSSI of the main beacon
			// @TODO: Scale logarithmically for more granular detail?
			print(nearestBeacon.rssi)
			beaconOsc.frequency = abs(nearestBeacon.rssi) * 8
			print("\tfrequency: \(beaconOsc.frequency)")

			print("\tAccuracy: \(nearestBeacon.accuracy)")

			// -40 is base signal strength
			// Using a scale factor of 2 to make the notes
			// "closer together" in 3d space
			let current = (abs(nearestBeacon.rssi) - 40) * (2)
			print("CURRENT: \(current)")

			switch current {
			case 0..<10: beaconOsc.frequency = 440.00  // A
			case 10..<20: beaconOsc.frequency = 493.88 // B
			case 20..<30: beaconOsc.frequency = 554.37 // C#
			case 30..<40: beaconOsc.frequency = 587.33 // D
			case 40..<50: beaconOsc.frequency = 659.25 // E
			case 50..<60: beaconOsc.frequency = 739.99 // F#
			case 60..<70: beaconOsc.frequency = 830.61 // G#
			case 70..<80: beaconOsc.frequency = 880.00 // A
			default: beaconOsc.frequency = 440.0
			}

		}

	}

	func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
		print(region.identifier)
	}

	func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
		print("identif: \(region.identifier)")
	}

	func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {

		guard let localRegion = self.region else {
			print("Unable to create our beacon region")
			return
		}

		// Make sure we're inside *our* region
		guard region.identifier == localRegion.identifier else {
			print("Found different region")
			return
		}

		print("Determined state for our region: \(state)")

		switch state {
			case .inside: print("You're alreday inside the region!")
			case .outside: print("You're outside the region!")
			case .unknown: print("Hey buddy, are you in space?")
		}

		if state == .inside {
			// Thanks SO!
			// https://stackoverflow.com/q/29936882/1431900
			self.locationManager.startRangingBeacons(in: localRegion)
		}

	}



	func monitorMotion() {

		// Parameter control with Euler angles
		if motionManager.isDeviceMotionAvailable {

			motionManager.showsDeviceMovementDisplay = true
			motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

			motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue.main) { (data, error) in


				if let data = data {

					// Assign data for AudioKit to use
					self.currentPitch = data.attitude.pitch
					self.currentRoll = data.attitude.roll
					self.currentYaw = data.attitude.yaw

					// Show on screen for Debug reasons
					self.attitudeLabelX.text = "Pitch: " + self.currentPitch.description
					self.attitudeLabelY.text = "Roll: " + self.currentRoll.description
					self.attitudeLabelZ.text = "Yaw: " + self.currentYaw.description


					let rollFreq = Double(abs(100 * self.currentRoll) + 300)
					self.accOsc.amplitude = 0.5
					self.accOsc.frequency = rollFreq
//					print("cutoff freq: \(rollFreq)")
//					let filter = AKLowPassFilter(self.beaconOsc, cutoffFrequency: rollFreq, resonance: 0.5)
//					AudioKit.output = filter

//					self.osc.amplitude = 0.5
//					self.osc.frequency = abs(1000 * self.currentRoll)
					//					print(self.osc.frequency)

				}

			}

		}

	}



}


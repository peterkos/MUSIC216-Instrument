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
import AudioKit


class ViewController: UIViewController, CLLocationManagerDelegate {

	@IBOutlet var attitudeLabelX: UILabel!
	@IBOutlet var attitudeLabelY: UILabel!
	@IBOutlet var attitudeLabelZ: UILabel!

	@IBOutlet var gyroscopeLabelX: UILabel!
	@IBOutlet var gyroscopeLabelY: UILabel!
	@IBOutlet var gyroscopeLabelZ: UILabel!


	let motionManager = CMMotionManager()
	var currentPitch = 0.0
	var currentRoll = 0.0
	var currentYaw = 0.0

	let locationManager = CLLocationManager()

	let osc = AKOscillator()
	let beaconOsc = AKOscillator()


	override func viewDidLoad() {
		super.viewDidLoad()

		// Configure location things
		locationManager.delegate = self
		locationManager.requestAlwaysAuthorization()


		// Each generates their own sound
		// @TODO: Isolate sound generation to separate function
		monitorBeacons()
//		monitorMotion()


	}

	func monitorBeacons() {

		let bitcrusher = AKBitCrusher(osc, bitDepth: 16, sampleRate: 40000)
		AudioKit.output = bitcrusher
		beaconOsc.amplitude = 0.5
		beaconOsc.frequency = 300

		// Output sound
		do {
			try AudioKit.start()
		} catch {
			print("oh no")
		}

		beaconOsc.start()


		if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {

			let proximityUUID = UUID(uuidString: "B0702880-A295-A8AB-F734-031A98A512DA")
			let beaconID = "test"

			let region = CLBeaconRegion(proximityUUID: proximityUUID!, identifier: beaconID)

			print("entry notif: \(region.notifyOnEntry)")

			print("started")
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

		print(beacons)
		print("found in \(region.identifier)")

		if beacons.count > 0 {
			let nearestBeacon = beacons.first!


			// Let's implement a second oscillator
			// This time, the frequency changes with RSSI of the main beacon
			// @TODO: Scale logarithmically for more granular detail?
			print(nearestBeacon.rssi)
			beaconOsc.amplitude = 0.5
			beaconOsc.frequency = abs(nearestBeacon.rssi) * 10


		}

	}

	func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
		print(region.identifier)
	}

	func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
		print("identif: \(region.identifier)")
	}



	func monitorMotion() {
		let bitcrusher = AKBitCrusher(osc, bitDepth: 16, sampleRate: 40000)
		AudioKit.output = bitcrusher

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

					self.osc.amplitude = 0.5
					self.osc.frequency = abs(1000 * self.currentRoll)
					//					print(self.osc.frequency)

				}

			}

		}

		// Output sound
		do {
			try AudioKit.start()
		} catch {
			print("oh no")
		}

		osc.start()

	}



}


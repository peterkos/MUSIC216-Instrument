//
//  ViewController.swift
//  Music 216 Instrument
//
//  Created by Peter Kos on 10/25/18.
//  Copyright © 2018 UW. All rights reserved.
//

import UIKit
import CoreMotion
import CoreBluetooth
import AudioKit
import KalmanFilter
import os.log

class ViewController: UIViewController, CBCentralManagerDelegate {

	@IBOutlet weak var frequencyLabel: UILabel!
	@IBOutlet weak var noteLabel: UILabel!

	@IBAction func accOscSwitch(_ sender: UISwitch) {

		if sender.isOn && !accOsc.isPlaying {
			accOsc.start()
			os_log("starting second...")
		} else {
			accOsc.stop()
			os_log("stopping second...")
		}

	}


	// Managers
	let motionManager = CMMotionManager()
	var bluetoothManager: CBCentralManager? = nil

	// Oscillators
	let blueOsc = AKOscillator()
	let accOsc = AKOscillator()

	// Kalman filter stuff for relatively-consistent RSSI values
	var rssiMeasurements = [Double]()
	var filter = KalmanFilter<Double>(stateEstimatePrior: 0.0, errorCovariancePrior: 10.0)

	// Enum of note values for us (A Major)
	// s = sharp, AA = octave up
	// @TODO: Make dynamic for on-the-fly scale changing?
	enum Note: Double {
		case A  = 440.00
		case B  = 493.88
		case Cs = 554.37
		case D  = 587.33
		case E  = 659.25
		case Fs = 739.99
		case Gs = 830.61
		case AA = 880.00

		// Rounds input to corresponding scale value
		init(rssi: Int) {
			switch rssi {
			case 00..<10: self = .A  // A
			case 10..<20: self = .B // B
			case 20..<30: self = .Cs // C#
			case 30..<40: self = .D // D
			case 40..<50: self = .E // E
			case 50..<60: self = .Fs // F#
			case 60..<70: self = .Gs // G#
			case 70..<80: self = .AA // A
			default: 	  self = .A
			}
		}
	}

	override func viewDidLoad() {

		super.viewDidLoad()

		// Initialize CBPMDelegate
		bluetoothManager = CBCentralManager(delegate: self as CBCentralManagerDelegate, queue: DispatchQueue.main)

		// Get that motion on
		monitorMotion()


		// --- SOUND ---

		let mixer = AKMixer(blueOsc, accOsc)
		AudioKit.output = mixer

		// Configure default amp and freq
		// (These are set later in didRangeBeacons())
		blueOsc.amplitude = 0.5
		blueOsc.frequency = 440

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

		// Start your engines
		blueOsc.start()
		accOsc.start()


	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		switch central.state {
			case .poweredOn: bluetoothManager?.scanForPeripherals(withServices: nil, options: nil)
			default: print("oh noes")
		}
	}

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		// Don't bother scanning if not ze macbook
		guard peripheral.name == "Peter’s MacBook Pro" else {
			return
		}

//		os_log("MacBook RSSI: %@", RSSI)

		// Scale RSSI to something reasonable
		let currentRSSI = (abs(RSSI.intValue) - 40) * (2)

		// Kalman stuff
		rssiMeasurements.append(RSSI.doubleValue)

		for val in rssiMeasurements {
			let prediction = filter.predict(stateTransitionModel: 1.0,
											controlInputModel: 0,
											controlVector: 0,
											covarianceOfProcessNoise: 10)

			let update = prediction.update(measurement: val, observationModel: 1, covarienceOfObservationNoise: 0.1)
			self.filter = update
		}

//		print(advertisementData.keys)


//		let roundRSSI = Int(log(abs(filter.stateEstimatePrior)))
		let roundRSSI = Int(abs(filter.stateEstimatePrior + 45))

		// Map adjusted value to Amaj scale
		let currentNote = Note(rssi: roundRSSI)

//		os_log("%f", filter.stateEstimatePrior)
//		os_log("%i", roundRSSI)

		// Throw up on screen
		frequencyLabel.text = currentNote.rawValue.description
		noteLabel.text = String(describing: currentNote)

		// And of course, set the frequency of our oscillator
		blueOsc.frequency = currentNote.rawValue

	}

	func monitorMotion() {

		// Parameter control with Euler angles
		if motionManager.isDeviceMotionAvailable {

			motionManager.showsDeviceMovementDisplay = true
			motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

			var pitchIndex = 0
			var pitches: [Note] = [.A, .B, .Cs, .D, .E, .Fs, .Gs, .AA]

			motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue.main) { (data, error) in

				guard let data = data else {
					return
				}

//				let rollFreq = Double(abs(100 * data.attitude.roll) + 300)
//				self.accOsc.amplitude = 0.5
//				self.accOsc.frequency = rollFreq


//				let linearAcc = sqrt(pow(data.userAcceleration.x, 2) + pow(data.userAcceleration.y, 2) + pow(data.userAcceleration.z, 2))
				let linearAcc = data.userAcceleration.y
				os_log("%f", linearAcc)

				if linearAcc >= 1.0 {
					if (pitchIndex == pitches.count - 1) {
						pitchIndex = 0
					} else {
						pitchIndex += 1
					}
				} else {
					if (pitchIndex != 0) {
						pitchIndex -= 1
					}
				}

				self.accOsc.amplitude = 0.5
				self.accOsc.frequency = pitches[pitchIndex].rawValue






			}

		}

	}

}

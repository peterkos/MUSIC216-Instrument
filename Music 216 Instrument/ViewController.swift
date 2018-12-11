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
import SwiftOSC
import os.log

class ViewController: UIViewController, CBCentralManagerDelegate {

	@IBOutlet weak var blueFrequencyLabel: UILabel!
	@IBOutlet weak var blueNoteLabel: UILabel!
	@IBOutlet weak var accFrequencyLabel: UILabel!
	@IBOutlet weak var accNoteLabel: UILabel!

	@IBAction func accOscSwitch(_ sender: UISwitch) {

		if sender.isOn && !accOsc.isPlaying {
			accOsc.start()
			os_log("starting accOsc...")
		} else {
			accOsc.stop()
			os_log("stopping accOsc...")
		}

	}

	@IBAction func blueOscSwitch(_ sender: UISwitch) {
		if sender.isOn && !blueOsc.isPlaying {
			blueOsc.start()
			os_log("starting blueOsc...")
		} else {
			blueOsc.stop()
			os_log("stopping blueOsc...")
		}
	}

	// Managers
	let motionManager = CMMotionManager()
	var bluetoothManager: CBCentralManager? = nil

	// Oscillators
	let blueOsc = AKOscillator()
	let accOsc = AKOscillator()
//	var mixer = AKMixer()
	var reverb = AKReverb()

	// Kalman filter stuff for relatively-consistent RSSI values
	var rssiMeasurements = [Double]()
	var filter = KalmanFilter<Double>(stateEstimatePrior: 0.0, errorCovariancePrior: 10.0)


	// SwiftOSC garbage
	let client = OSCClient(address: "10.19.207.86", port: 8080)
//	let message = OSCMessage(OSCAddressPattern("/"), "Hello World")

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

//		mixer = AKMixer(blueOsc, accOsc)
//		AudioKit.output = mixer
		AudioKit.output = accOsc

		// Configure default amp and freq
		// (These are set later in didRangeBeacons())
		blueOsc.amplitude = 0.5
		blueOsc.frequency = 440

		// Default values for accosc
		// (These are set later in monitorMotion()
		accOsc.amplitude = 0.5
		accOsc.frequency = 220

		// Reverb
		reverb = AKReverb(accOsc, dryWetMix: 1.0)
		reverb.loadFactoryPreset(.cathedral)

		let envelope = AKAmplitudeEnvelope(reverb, attackDuration: 0.01, decayDuration: 0.1, sustainLevel: 1.0, releaseDuration: 0.5)
		AudioKit.output = envelope

		accOsc.rampDuration = 0.10



		// Output sound
		do {
			try AudioKit.start()
		} catch {
			print("oh no")
		}

		// Start your engines
		blueOsc.start()
		accOsc.start()

		do {
			if #available(iOS 10.0, *) {
				try AKSettings.setSession(category: .playback, with: [.defaultToSpeaker, .allowAirPlay])
			}
		} catch {
			print("Unable to set AudioKit playback settings")
		}


	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		switch central.state {
			case .poweredOn: bluetoothManager?.scanForPeripherals(withServices: nil, options: nil)
			default: print("oh noes")
		}
	}

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		// Don't bother scanning if not ze macbook

		os_log("%@", peripheral.name ?? "nil")
		guard peripheral.name == "Peter’s MacBook Pro" else {
			return
		}

//		os_log("MacBook RSSI: %@", RSSI)

		// Scale RSSI to something reasonable
//		let currentRSSI = (abs(RSSI.intValue) - 40) * (2)

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


		let address = OSCAddressPattern("/")
		self.client.send(OSCMessage(address, roundRSSI, "rssi"))
		os_log("%i", roundRSSI)


//		let bitCrush = AKBitCrusher(accOsc, bitDepth: 16, sampleRate: 40000)


		// Map adjusted value to Amaj scale
		let currentNote = Note(rssi: roundRSSI)

//		os_log("%f", filter.stateEstimatePrior)
//		os_log("%i", roundRSSI)

		// Throw up on screen
		blueFrequencyLabel.text = currentNote.rawValue.description
		blueNoteLabel.text = String(describing: currentNote)

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

			var accData = [Double]()

			motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue.main) { (data, error) in

				guard let data = data else {
					return
				}

//				let rollFreq = Double(abs(100 * data.attitude.roll) + 300)
//				self.accOsc.amplitude = 0.5
//				self.accOsc.frequency = rollFreq


//				let linearAcc = sqrt(pow(data.userAcceleration.x, 2) + pow(data.userAcceleration.y, 2) + pow(data.userAcceleration.z, 2))
				let linearAcc = data.userAcceleration.x

				// Dump cache
				if (accData.count >= (60 / 2)) {


					if accData.max()! >= 1.5 {
						if (pitchIndex == pitches.count - 1) {
							pitchIndex = 0
						} else {
							pitchIndex += 1
						}

						os_log("max: %f", accData.max()!)

					} else if (accData.min()! <= -1.5){
						if (pitchIndex != 0) {
							pitchIndex -= 1
						}

						os_log("min: %f", accData.min()!)
					}

					accData.removeAll()
					return
				}

				accData.append(linearAcc)

				self.accOsc.amplitude = 0.5
				self.accOsc.frequency = pitches[pitchIndex].rawValue

				let address = OSCAddressPattern("/")
				self.client.send(OSCMessage(address, pitches[pitchIndex].rawValue))

				DispatchQueue.main.async {
					self.accFrequencyLabel.text = String(self.accOsc.frequency)
					self.accNoteLabel.text = String(describing: pitches[pitchIndex])
				}




			}

		}

	}

}

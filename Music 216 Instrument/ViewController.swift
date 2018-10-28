//
//  ViewController.swift
//  Music 216 Instrument
//
//  Created by Peter Kos on 10/25/18.
//  Copyright © 2018 UW. All rights reserved.
//

import UIKit
import CoreMotion
import AudioKit


class ViewController: UIViewController {



	@IBOutlet var accelerometerLabelX: UILabel!
	@IBOutlet var accelerometerLabelY: UILabel!
	@IBOutlet var accelerometerLabelZ: UILabel!

	@IBOutlet var gyroscopeLabelX: UILabel!
	@IBOutlet var gyroscopeLabelY: UILabel!
	@IBOutlet var gyroscopeLabelZ: UILabel!


	let motionManager = CMMotionManager()
	var currentPitch = 0.0
	var currentRoll = 0.0
	var currentYaw = 0.0

	let osc = AKOscillator()


	override func viewDidLoad() {
		super.viewDidLoad()


		let bitcrusher = AKBitCrusher(osc, bitDepth: 16, sampleRate: 40000)
		AudioKit.output = bitcrusher



		if motionManager.isDeviceMotionAvailable {

			motionManager.showsDeviceMovementDisplay = true
			motionManager.deviceMotionUpdateInterval = 1.0 / 100.0

			motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue.main) { (data, error) in


				if let data = data {

					// Assign data for AudioKit to use
					self.currentPitch = data.attitude.pitch
					self.currentRoll = data.attitude.roll
					self.currentYaw = data.attitude.yaw

					// Show on screen for Debug reasons
					self.accelerometerLabelX.text = "Pitch: " + self.currentPitch.description
					self.accelerometerLabelY.text = "Roll: " + self.currentRoll.description
					self.accelerometerLabelZ.text = "Yaw: " + self.currentYaw.description

					self.osc.amplitude = 0.5
					self.osc.frequency = abs(1000 * self.currentRoll)
					print(self.osc.frequency)

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


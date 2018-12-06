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

	let osc = AKOscillator()



	func calcVal(diff: CFTimeInterval, accBuffer: inout [Double], grav: CMAcceleration) {
		accBuffer = accBuffer.map { ($0 - grav.y) * 0.5 * (Double(diff) * Double(diff)) }
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		let reverb = AKReverb(osc, dryWetMix: 0.2)
		AudioKit.output = reverb



		if motionManager.isDeviceMotionAvailable {

			motionManager.showsDeviceMovementDisplay = true
			motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

			var accBuffer = [Double]()
			var timeStart = CFAbsoluteTime()
			var timeEnd = CFAbsoluteTime()

			motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue.main) { (data, error) in


				if let data = data {

					// Assign data for AudioKit to use
					self.currentPitch = data.attitude.pitch
					self.currentRoll = data.attitude.roll
					self.currentYaw = data.attitude.yaw


//					let firstVec = vector3(data.userAcceleration.x, data.userAcceleration.y, data.userAcceleration.z)
//					let gravVec = vector3(data.gravity.x, data.gravity.y, data.gravity.z)
//					let value = (1/2) * (firstVec - gravVec)
//					print("VALUE: \(value * 3600)")

					if (accBuffer.isEmpty) {
						timeStart = CFAbsoluteTimeGetCurrent()
						print("timestart: \(timeStart)")
					}

					accBuffer.append(data.userAcceleration.y)

					// Only fill to 2 seconds of data
					// Erase all when limit hit
					if (accBuffer.count >= (2 * 60)) {

						let sum = accBuffer.reduce(0, { x, y in x + y})
						print(sum)

						accBuffer.removeAll()
						timeEnd = CFAbsoluteTimeGetCurrent()

						let diff = timeEnd - timeStart
						self.calcVal(diff: diff, accBuffer: &accBuffer, grav: data.gravity)
						print("\tERASED for duration \(diff)")
						timeStart = 0
					}


//					gravityBuffer.append(rateAlongGravity)

//					let avg = sum / gravityBuffer.count


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


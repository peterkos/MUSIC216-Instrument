//
//  ViewController.swift
//  Music 216 Instrument
//
//  Created by Peter Kos on 10/25/18.
//  Copyright © 2018 UW. All rights reserved.
//

import UIKit
import CoreMotion


class ViewController: UIViewController {

	let motion = CMMotionManager()

	@IBOutlet var accelerometerLabelX: UILabel!
	@IBOutlet var accelerometerLabelY: UILabel!
	@IBOutlet var accelerometerLabelZ: UILabel!

	@IBOutlet var gyroscopeLabelX: UILabel!
	@IBOutlet var gyroscopeLabelY: UILabel!
	@IBOutlet var gyroscopeLabelZ: UILabel!



	override func viewDidLoad() {
		super.viewDidLoad()

		printAccelerometerEvents()
		printGyroscopeEvents()

	}

	func printAccelerometerEvents() {

		print("print here we go")

		guard motion.isAccelerometerAvailable else {
			fatalError("Error: Accelerometer not available")
		}

		motion.accelerometerUpdateInterval = 1.0 / 5.0

		motion.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in

			OperationQueue.main.addOperation {

				let xData = data!.acceleration.x
				let yData = data!.acceleration.y
				let zData = data!.acceleration.z

				self.accelerometerLabelX.text = String(format: "%.5f", xData)
				self.accelerometerLabelY.text = String(format: "%.5f", yData)
				self.accelerometerLabelZ.text = String(format: "%.5f", zData)
			}

		}
	}


	func printGyroscopeEvents() {

		print("print here we go")

		guard motion.isGyroAvailable else {
			fatalError("Error: Gyro not available")
		}

		motion.gyroUpdateInterval = 1.0 / 5.0

		motion.startGyroUpdates(to: OperationQueue.main) { (data, error) in

			OperationQueue.main.addOperation {

				let xData = data!.rotationRate.x
				let yData = data!.rotationRate.y
				let zData = data!.rotationRate.z

				self.gyroscopeLabelX.text = String(format: "%.5f", xData)
				self.gyroscopeLabelY.text = String(format: "%.5f", yData)
				self.gyroscopeLabelZ.text = String(format: "%.5f", zData)
			}

		}
	}




}


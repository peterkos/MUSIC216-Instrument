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



	@IBOutlet var accelerometerLabelX: UILabel!
	@IBOutlet var accelerometerLabelY: UILabel!
	@IBOutlet var accelerometerLabelZ: UILabel!

	@IBOutlet var gyroscopeLabelX: UILabel!
	@IBOutlet var gyroscopeLabelY: UILabel!
	@IBOutlet var gyroscopeLabelZ: UILabel!


	let motionManager = CMMotionManager()


	override func viewDidLoad() {
		super.viewDidLoad()

		if motionManager.isDeviceMotionAvailable {

			motionManager.showsDeviceMovementDisplay = true
			motionManager.deviceMotionUpdateInterval = 1.0 / 50.0

			motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue.main) { (data, error) in


				if let data = data {
					self.accelerometerLabelX.text = "Pitch: " + data.attitude.pitch.description
					self.accelerometerLabelY.text = "Roll: " + data.attitude.roll.description
					self.accelerometerLabelZ.text = "Yaw: " + data.attitude.yaw.description
				}

			}

		}
	}



}


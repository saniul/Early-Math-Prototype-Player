//
//  PlayerViewController.swift
//  Prototope
//
//  Created by Jason Brennan on 2015-06-22.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

import UIKit
import Prototope
import PrototopeJSBridge


/** This view controller hosts and plays Prototypes. */
class PlayerViewController: UIViewController {
	var context: Context!
	let jsPath: NSURL
	
	init(path: NSURL) {
		self.jsPath = path
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor.whiteColor()
		
		
		let prototypeDirectoryURL = self.jsPath.URLByDeletingLastPathComponent!
		
		let imageProvider = { 
			(name: String) -> UIImage? in
			let scale = UIScreen.mainScreen().scale
			let filenameWithScale = (name.stringByAppendingString("@\(Int(scale))x") as NSString).stringByAppendingPathExtension("png")!
			let filename = (name as NSString).stringByAppendingPathExtension("png")!
			
			let scalePath = prototypeDirectoryURL.URLByAppendingPathComponent(filenameWithScale)
			let noScalePath = prototypeDirectoryURL.URLByAppendingPathComponent(filename)
			
			let loadImage: (String) -> UIImage? = { path in
				let image = UIImage(contentsOfFile: path)
				return image
			}
			
			return loadImage(scalePath.path!) ?? loadImage(noScalePath.path!)
		}
		
		let soundProvider = { 
			(name: String) -> NSData? in
			let fileManager = NSFileManager.defaultManager()
			for fileExtension in Sound.supportedExtensions {
				let URL = prototypeDirectoryURL.URLByAppendingPathComponent(name).URLByAppendingPathExtension(fileExtension)
				if fileManager.fileExistsAtPath(URL.path!) {
					return try? NSData(contentsOfURL: URL, options: [])
				}
			}
			return nil
		}
		
		
		let defaultEnvironment = Environment.defaultEnvironmentWithRootView(self.view)
		Environment.currentEnvironment = Environment(
			rootView: view, 
			imageProvider: imageProvider, 
			soundProvider: soundProvider, 
			fontProvider: defaultEnvironment.fontProvider, 
			exceptionHandler: defaultEnvironment.exceptionHandler
		)

		runJSPrototope()
	}

	override func viewWillAppear(animated: Bool) {
		if !InstructionsViewController.userHasSeenInstructions {
			self.presentViewController(InstructionsViewController(), animated: true, completion: nil)
		}
	}

	
	func runJSPrototope() {
		
		context = Context()
		context.exceptionHandler = { value in
			let lineNumber = value.objectForKeyedSubscript("line")
			print("Exception on line \(lineNumber): \(value)")
		}
		context.consoleLogHandler = { message in
			print(message)
		}
		
		let script = try! NSString(contentsOfURL: self.jsPath, encoding: NSUTF8StringEncoding)
		context.evaluateScript(script as String)
	}
	
	
	func handleKeyCommand(command: UIKeyCommand!) {
		switch command.input {
		case UIKeyInputEscape:
			self.navigationController?.popToRootViewControllerAnimated(true)
		default:
			return
		}
	}
	
	// needed to let vc handle keypresses
	override func canBecomeFirstResponder() -> Bool {
		return true
	}
	
	override var keyCommands: [UIKeyCommand]? {
		get {
			let escape = UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(self.handleKeyCommand(_:)))
			return [escape]
		}
	}

}
//
//  ViewController.swift
//  ARTEXT
//
//  Created by Mark Zhong on 8/28/17.
//  Copyright © 2017 Mark Zhong. All rights reserved.
//

import UIKit
//import NextGrowingTextView
import SceneKit
import ARKit

class ViewController: UIViewController,ARSCNViewDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var inputContainerViewBottom: NSLayoutConstraint!
    @IBOutlet weak var growingTextView: NextGrowingTextView!
    
    
    @IBOutlet weak var settingsButton: UIButton!
    
    let defaults = UserDefaults.standard
    
    let session = ARSession()
    
    var textNode:SCNNode?
    var textSize:CGFloat = 5
    var textDistance:Float = 15
    
    //メモ部分定義
    lazy var memoSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    let defaultConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        } else {
            // Fallback on earlier versions
        }
        return configuration
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //setup sceneView
        
        setupScene()
        SettingsViewController.registerDefaults()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.growingTextView.layer.cornerRadius = 4
        self.growingTextView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        self.growingTextView.textView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        self.growingTextView.placeholderAttributedText = NSAttributedString(string: "Placeholder text",
                                                                            attributes: [NSAttributedStringKey.font: self.growingTextView.textView.font!,
                                                                                         NSAttributedStringKey.foregroundColor: UIColor.gray
            ]
        )
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupScene() {
        // set up sceneView
        sceneView.delegate = self
        sceneView.session = session
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = false
        
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = 1.3
        //sceneView.showsStatistics = true
        
        enableEnvironmentMapWithIntensity(25.0)
        
        DispatchQueue.main.async {
            //self.screenCenter = self.sceneView.bounds.mid
        }
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            //camera.wantsExposureAdaptation = true
            //camera.exposureOffset = -1
            //camera.minimumExposure = -1
        }
        
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    //関数作成
    private func showOKDialog(title: String, message: String? = nil, ok: String = "OK", completion: (() -> Void)? = nil){
        DispatchQueue.main.async {
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: ok, style: .default, handler: { _ in
                completion?()
            })
            alert.addAction(defaultAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //保存するボタン
    @IBAction func SaveButtonTapped(_ sender: Any) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else {
                return
            }
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.memoSaveURL, options: [.atomic])
                self.showOKDialog(title: "Saved")
            } catch {
                self.showOKDialog(title: error.localizedDescription)
            }
        }
        
        
    }
    
    //ロードするボタン
    @IBAction func LoadButtonTapped(_ sender: Any) {
        guard let data = try? Data(contentsOf: memoSaveURL),
            let worldMap: ARWorldMap? = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) else {
                return
        }
        let configuration = self.defaultConfiguration
        configuration.initialWorldMap = worldMap
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.showOKDialog(title: "Loaded")
    }
    
    
    @IBAction func handleSendButton(_ sender: AnyObject) {
        if let text = growingTextView.textView.text {
            self.showText(text: text)
        }else{
            print("empty string")
        }
        //print(growingTextView.textView.text)
        self.growingTextView.textView.text = ""
        self.view.endEditing(true)
    }
    
    
    @objc func keyboardWillHide(_ sender: Notification) {
        if let userInfo = (sender as NSNotification).userInfo {
            if let _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                //key point 0,
                self.inputContainerViewBottom.constant =  0
                //textViewBottomConstraint.constant = keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in self.view.layoutIfNeeded() })
            }
        }
    }
    @objc func keyboardWillShow(_ sender: Notification) {
        if let userInfo = (sender as NSNotification).userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                self.inputContainerViewBottom.constant = keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    
    @IBAction func showSettings(_ button: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let settingsViewController = storyboard.instantiateViewController(withIdentifier: "settingsViewController") as? SettingsViewController else {
            return
        }
        
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        settingsViewController.navigationItem.rightBarButtonItem = barButtonItem
        settingsViewController.title = "Setting"
        
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.delegate = self
        navigationController.preferredContentSize = CGSize(width: sceneView.bounds.size.width - 20, height: sceneView.bounds.size.height - 100)
        self.present(navigationController, animated: true, completion: nil)
        
        navigationController.popoverPresentationController?.sourceView = settingsButton
        navigationController.popoverPresentationController?.sourceRect = settingsButton.bounds
    }
    
    @objc
    func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
        updateSettings()
        
    }
    
    private func updateSettings() {
        //let defaults = UserDefaults.standard
        
        
    }
    
    func showText(text:String) -> Void{
        /*
         if (defaults.object(forKey: "textDistance") != nil){
         print("distance is:", defaults.object(forKey: "textDistance") ?? "nothing")
         }else{
         print("no distance: ", defaults.object(forKey: "textDistance") ?? "nothing")
         
         }
         
         
         let textScn = ARText(text: text, font: UIFont.systemFont(ofSize: 200), color:defaults.colorForKey(key: "textColor")!, depth: 40)
         let textNode = TextNode(distance: defaults.float(forKey: "textDistance"), scntext: textScn, sceneView: self.sceneView, scale: 1/100.0)
         self.sceneView.scene.rootNode.addChildNode(textNode)
         */
        
        
        /*
         let textScn = ARText(text: text, font: UIFont.systemFont(ofSize: 25), color: UIColor .white, depth: 5)
         let textNode = TextNode(distance: 1, scntext: textScn, sceneView: self.sceneView, scale: 1/100.0)
         self.sceneView.scene.rootNode.addChildNode(textNode)
         */
        
        let fontSize = CGFloat(defaults.float(forKey: "textFont"))
        let textDistance = defaults.float(forKey: "textDistance")
        let textColor = defaults.colorForKey(key: "textColor")
        
        let textScn = ARText(text: text, font: UIFont .systemFont(ofSize: fontSize), color: textColor!, depth: fontSize/10)
        let textNode = TextNode(distance: textDistance/10, scntext: textScn, sceneView: self.sceneView, scale: 1/100.0)
        self.sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    
    
    @IBAction func restartButton(_ sender: UIButton) {
        
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
        
    }
    
    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if sceneView.scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
                sceneView.scene.lightingEnvironment.contents = environmentMap
            }
        }
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
}


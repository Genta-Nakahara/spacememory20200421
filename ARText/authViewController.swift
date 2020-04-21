//
//  authViewController.swift
//  ARText
//
//  Created by hdymacuser on 2020/04/19.
//  Copyright © 2020 Mark Zhong. All rights reserved.
//

import UIKit
import FirebaseAuth

class authViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func tapSignupButton(_ sender: Any) {
        
        guard let email = emailTextField.text,
            let password = passwordTextField.text else { return }
        if email.isEmpty {
            showErrorAlert(text: "メールアドレスを入力して下さい")
            return
        }
        if password.isEmpty {
            showErrorAlert(text: "パスワードを入力して下さい")
            return
        }
        emailSignUp(email: email, password: password)
    }
    
    
    @IBAction func tapLoginButton(_ sender: Any) {
        
        guard let email = emailTextField.text,
            let password = passwordTextField.text else { return }
        if email.isEmpty { showErrorAlert(text: "メールアドレスを入力して下さい")
            return
        }
        if password.isEmpty {
            showErrorAlert(text: "パスワードを入力して下さい")
            return
        }
        emailLogIn(email: email, password: password)
    }
    
    func emailSignUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                self.signUpErrorAlert(error)
                print ("登録失敗:\(error.localizedDescription)")
            } else {
                self.presentTaskListPage()
                print ("登録成功")
                
            }
        }
    }
    
    func emailLogIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                self.logInErrorAlert(error)
                print ("ログイン失敗")
            } else {
                self.presentTaskListPage()
                print ("ログイン成功")
            }
        }
    }
    
    func signUpErrorAlert(_ error: Error){
        if let errCode = AuthErrorCode(rawValue: error._code) {
            var message = ""
            switch errCode {
            case .invalidEmail:
                message = "有効なメールアドレスを入力してください"
            case .emailAlreadyInUse:
                message = "既に登録されているメールアドレスです"
            case .weakPassword:
                message = "パスワードは６文字以上で入力してください"
            default:
                message = "エラー: \(error.localizedDescription)"
            }
            showErrorAlert(text: message)
        }
    }
    
    func logInErrorAlert(_ error: Error){
        if let errCode = AuthErrorCode(rawValue: error._code) {
            var message = ""
            switch errCode {
            case .userNotFound:
                message = "アカウントが見つかりませんでした"
            case .wrongPassword:
                message = "パスワードを確認してください"
            case .userDisabled:
                message = "アカウントが無効になっています"
            case .invalidEmail:
                message = "Eメールが無効な形式です"
            default: message = "エラー: \(error.localizedDescription)"
            }
            showErrorAlert(text: message)
        }
    }
    
    func presentTaskListPage() {
        // xib で作るよりも長くなる...
        // 開発現場では 1Storyboard1VC が基本
        //        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //        guard let vc = storyboard.instantiateInitialViewController() else {
        //            print("viewControllerがない。")
        //            return
        //        }
        //        vc.modalPresentationStyle = .fullScreen
        //        present(vc, animated: true)
        
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "MainView")
        present(nextView, animated: true, completion: nil)

    }
    
}

//
//  EditViewController.swift
//  Imanani
//
//  Created by 落合遼梧 on 2023/03/07.
//

import UIKit
import Firebase

class EditViewController: UIViewController {
    
    @IBOutlet var profileImage: UIButton!
    @IBOutlet var userNameTextField: UITextField!
    
    var saveData: UserDefaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        userNameTextField.text = saveData.object(forKey: "userName") as? String
        
    }
    
    @IBAction func save() {
        
        if let user = Auth.auth().currentUser {
            let userNameIsEmpty = userNameTextField.text?.isEmpty ?? true
            if userNameIsEmpty {
                let dialog = UIAlertController(title: "更新失敗", message: "Usernameを入力してください", preferredStyle: .alert)
                dialog.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(dialog, animated: true, completion: nil)
            } else {
                Firestore.firestore().collection("users").document("\(user.uid)").setData([
                    "userName": userNameTextField.text ?? "\(String(describing: saveData.object(forKey: "userName") as? String))"
                ], merge: true, completion: { [self] error in
                    if let error = error {
                        print("更新失敗" + error.localizedDescription)
                        let dialog = UIAlertController(title: "更新失敗", message: error.localizedDescription, preferredStyle: .alert)
                        dialog.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(dialog, animated: true, completion: nil)
                    } else {
                        print("更新成功")
                        saveData.set(userNameTextField.text ?? "\(String(describing: saveData.object(forKey: "userName") as? String))", forKey: "userName")
                        let storyboard: UIStoryboard = self.storyboard!
                        let tabBarController = storyboard.instantiateViewController(withIdentifier: "tabBar") as! UITabBarController
                        tabBarController.selectedIndex = 2
                        let nav = UINavigationController(rootViewController: tabBarController)
                        nav.modalPresentationStyle = .fullScreen
                        nav.modalTransitionStyle = .crossDissolve
                        self.present(nav, animated: true, completion: nil)
                    }
                })
            }
        }
        
    }

}

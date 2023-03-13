//
//  EditViewController.swift
//  Imanani
//
//  Created by 落合遼梧 on 2023/03/07.
//

import UIKit
import Firebase
import FirebaseStorage

class EditViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet var profileImageButton: UIButton!
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var saveButton: UIButton!
    
    let signUpModel = SignUpModel()
    var saveData: UserDefaults = UserDefaults.standard
    var downloadURL: URL?
    var userImage: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        userNameTextField.text = saveData.object(forKey: "userName") as? String
        userImage = (saveData.object(forKey: "profileImage") as? String)!
        let storageref = Storage.storage().reference(forURL: "gs://imanani-7ee50.appspot.com/profile_image").child(userImage)
        storageref.downloadURL { url, error in
            if let url = url {
                self.downloadURL = url
                print(url)
                do {
                    let data = try Data(contentsOf: url)
                    return self.profileImageButton.setImage(UIImage(data: data), for: .normal)
                } catch let imageerror {
                    print("Error : \(imageerror.localizedDescription)")
                }
            }
        }
        profileImageButton.layer.masksToBounds = true
        profileImageButton.layer.cornerRadius = 66.5
        
        saveButton.layer.cornerRadius = 10
        
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
                        editImageToFirestorage()
                        let storyboard: UIStoryboard = self.storyboard!
                        let tabBarController = storyboard.instantiateViewController(withIdentifier: "tabBar") as! UITabBarController
                        tabBarController.selectedIndex = 3
                        let nav = UINavigationController(rootViewController: tabBarController)
                        nav.modalPresentationStyle = .fullScreen
                        nav.modalTransitionStyle = .crossDissolve
                        self.present(nav, animated: true, completion: nil)
                    }
                })
            }
        }
        
    }
    
    @IBAction func profileImageButtonAction(_ sender: Any) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    func editImageToFirestorage() {
        
        if let image = self.profileImageButton.imageView?.image {
            let uploadImage = image.jpegData(compressionQuality: 0.5)
            let fileName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_image").child(fileName)
            storageRef.putData(uploadImage!, metadata: nil) { (metadata, err) in
                if let err = err {
                    print("Firestorageへの保存に失敗しました。\(err)")
                    return
                }
                print("Firestorageへの保存に成功しました")
                if let user = Auth.auth().currentUser {
                    Firestore.firestore().collection("users").document("\(user.uid)").setData([
                        "profileImageName": fileName
                    ], merge: true, completion: { [self] error in
                        if let error = error {
                            print("更新失敗" + error.localizedDescription)
                        } else {
                            print("更新成功")
                            saveData.set(fileName, forKey: "profileImage")
                        }
                    })
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for:  .normal)
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        dismiss(animated: true, completion: nil)
    }

}

//
//  SignUpViewController.swift
//  Imanani
//
//  Created by 落合遼梧 on 2023/03/01.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseStorage

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    
    let signUpModel = SignUpModel()
    var saveData: UserDefaults = UserDefaults.standard
    var saveDataUserName: String = ""
    var saveDataUid: String = ""
    var locationManager: CLLocationManager!
    // 緯度
    var latitudeNow: String = ""
    // 経度
    var longitudeNow: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        userNameTextField.delegate = self
        signUpModel.delegate = self
        
        profileImageButton.layer.masksToBounds = true
        
        setupLocationManager()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            if saveData.object(forKey: "uid") as? String != nil {
                completedRegisterUserInfoAction()
                
            }
        }
            
    }
    
    @IBAction func profileImageButtonAction(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    // 新規登録処理
    @IBAction func signUpButtonAction(_ sender: Any) {

        guard let email = emailTextField.text,
              let password = passwordTextField.text
        else { return }

        // FirebaseAuthへ保存
        signUpModel.createUser(email: email, password: password)
    }
    
    // プロフィール画像をFirebaseStorageへ保存する処理
    private func createImageToFirestorage() {
        // プロフィール画像が設定されている場合の処理
        if let image = self.profileImageButton.imageView?.image {
            let uploadImage = image.jpegData(compressionQuality: 0.5)
            let fileName = NSUUID().uuidString
            // FirebaseStorageへ保存
            signUpModel.creatrImage(fileName: fileName, uploadImage: uploadImage!)
        } else {
            print("プロフィール画像が設定されていないため、デフォルト画像になります。")
            // User情報をFirebaseFirestoreへ保存
            self.createUserToFirestore(profileImageName: nil)
        }
    }
    
    // User情報をFirebaseFirestoreへ保存する処理
    private func createUserToFirestore(profileImageName: String?) {

        guard let email = Auth.auth().currentUser?.email,
              let uid = Auth.auth().currentUser?.uid,
              let userName = self.userNameTextField.text
        else { return }

        // 保存内容を定義する（辞書型）
        let docData = ["email": email,
                       "userName": userName,
                       "profileImageName": profileImageName,
                       "createdAt": Timestamp(),
                       "latitude": self.latitudeNow,
                       "longitude": self.longitudeNow] as [String : Any?]

        // FirebaseFirestoreへ保存
        signUpModel.createUserInfo(uid: uid, docDate: docData as [String : Any])
        
        saveData.set(userName, forKey: "userName")
        saveData.set(uid, forKey: "uid")
        saveData.set(profileImageName, forKey: "profileImage")
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        
        guard let locationManager = locationManager else { return }
        locationManager.requestWhenInUseAuthorization()
        
        // マネージャの設定
        let status = CLLocationManager().authorizationStatus
        // ステータスごとの処理
        if status == .authorizedWhenInUse {
            locationManager.delegate = self
            // 位置情報取得を開始
            locationManager.startUpdatingLocation()
        }
    }
    
    /// アラートを表示する
    func showAlert() {
        let alertTitle = "位置情報取得が許可されていません。"
        let alertMessage = "設定アプリの「プライバシー > 位置情報サービス」から変更してください。"
        let alert: UIAlertController = UIAlertController(
            title: alertTitle,
            message: alertMessage,
            preferredStyle:  UIAlertController.Style.alert
        )
        // OKボタン
        let defaultAction: UIAlertAction = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: nil
        )
        // UIAlertController に Action を追加
        alert.addAction(defaultAction)
        // Alertを表示
        present(alert, animated: true, completion: nil)
    }
    
}

extension SignUpViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    // 写真が選択された時に呼ばれるメソッド
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        dismiss(animated: true, completion: nil)
    }

}

extension SignUpViewController: UITextFieldDelegate {
    // textFieldでテキスト選択が変更された時に呼ばれるメソッド
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // textFieldが空かどうかの判別するための変数(Bool型)で定義
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        let userNameIsEmpty = userNameTextField.text?.isEmpty ?? true
        // 全てのtextFieldが記入済みの場合の処理
        if emailIsEmpty || passwordIsEmpty || userNameIsEmpty {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = UIColor.systemGray2
        } else {
            signUpButton.isEnabled = true
            signUpButton.backgroundColor = UIColor(named: "lineGreen")
        }
    }

    // textField以外の部分を押したときキーボードが閉じる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension SignUpViewController: SignUpModelDelegate {
    
    // FirebaseAuthへ保存完了 -> FirebaseStorageへ保存処理
    func createImageToFirestorageAction() {
        print("FirebaseAuthへの保存に成功しました。")
        self.createImageToFirestorage()
    }
    
    // FirebaseStorageへ保存完了 -> FirebaseFirestoreへ保存処理
    func createUserToFirestoreAction(fileName: String?) {
        print("Firestorageへの保存に成功しました。")
        self.createUserToFirestore(profileImageName: fileName)
    }
    
    // ユーザー情報の登録が完了した時の処理
    func completedRegisterUserInfoAction() {
        // ChatListViewControllerへ画面遷移
        let storyboard: UIStoryboard = self.storyboard!
//        let contentVC = storyboard.instantiateViewController(withIdentifier: "ContentVC") as! ContentViewController
//        let nav = UINavigationController(rootViewController: contentVC)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "tabBar") as! UITabBarController
        tabBarController.selectedIndex = 0
        let nav = UINavigationController(rootViewController: tabBarController)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        self.present(nav, animated: true, completion: nil)
        
    }

}

extension SignUpViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        let latitude = location?.coordinate.latitude
        let longitude = location?.coordinate.longitude
        // 位置情報を格納する
        self.latitudeNow = String(latitude!)
        self.longitudeNow = String(longitude!)
    }
    
}

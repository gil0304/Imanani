//
//  ContentViewController.swift
//  Imanani
//
//  Created by 落合遼梧 on 2023/03/01.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseStorage

class ContentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var userIdArray: [String] = []
    var userContentArray: [String] = []
    var userAddressArray: [String] = []
    var userName: String = ""
    var saveData: UserDefaults = UserDefaults.standard
    
    @IBOutlet weak var contentTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var locationManager: CLLocationManager!
    // 緯度
    var latitudeNow: String = ""
    // 経度
    var longitudeNow: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ContentTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.rowHeight = 87
        tableView.reloadData()
        
        
        setupLocationManager()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let user = Auth.auth().currentUser {
            Firestore.firestore().collection("users").document(user.uid).getDocument(completion: {(snapshot,error) in
                if let snap = snapshot {
                    if let data = snap.data() {
                        self.userName = data["userName"] as! String
                    }
                }
            })
            Firestore.firestore().collection("users/\(user.uid)/contents").order(by: "createdAt").addSnapshotListener({ (querySnapshot, error) in
                if let querySnapshot = querySnapshot {
                    var idArray: [String] = []
                    var contentArray: [String] = []
                    var addressArray: [String] = []
                    for doc in querySnapshot.documents {
                        let data = doc.data()
                        idArray.append(doc.documentID)
                        contentArray.append(data["content"] as! String)
                        addressArray.append(data["address"] as! String)
                    }
                    self.userIdArray = idArray
                    self.userContentArray = contentArray
                    self.userAddressArray = addressArray
                    self.tableView.reloadData()
                } else if let error = error {
                    print("取得失敗:" + error.localizedDescription)
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userContentArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContentTableViewCell
        let storageref = Storage.storage().reference(forURL: "gs://imanani-7ee50.appspot.com").child("profile_image").child("\(saveData.object(forKey: "profileImage") as? String)")
        print(type(of: storageref))
        cell.setCell(profileImage: storageref, userName: userName, content: userContentArray[indexPath.row], address: userAddressArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 87
    }
    
    @IBAction func sendContent() {
        let status = CLLocationManager().authorizationStatus
        if status == .denied {
            showAlert()
        } else if status == .authorizedWhenInUse {
            let location = CLLocation(latitude: Double(latitudeNow)!, longitude: Double(longitudeNow)!)
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                guard let placemark = placemarks?.first, error == nil,
                let administrativeArea = placemark.administrativeArea, // 都道府県
                let locality = placemark.locality, // 市区町村
                let subLocality = placemark.subLocality // 地名
                else {
                    return
                }
                let address: String = "\(administrativeArea)\(locality)\(subLocality)"
                if let content = self.contentTextField.text {
                    if let user = Auth.auth().currentUser {
                        let createdTime = FieldValue.serverTimestamp()
                        Firestore.firestore().collection("users/\(user.uid)/contents").document().setData(
                            [
                                "content": content,
                                "address": address,
                                "createdAt": createdTime,
                                "updatedAt": createdTime
                            ],merge: true
                            ,completion: { [self] error in
                                if let error = error {
                                    print("作成失敗" + error.localizedDescription)
                                    let dialog = UIAlertController(title: "作成失敗", message: error.localizedDescription, preferredStyle: .alert)
                                    dialog.addAction(UIAlertAction(title: "OK", style: .default))
                                    self.present(dialog, animated: true, completion: nil)
                                } else {
                                    print("作成成功")
                                    contentTextField.text = ""
                                }
                            }
                        )
                        Firestore.firestore().collection("users").document("\(user.uid)").setData(
                            [
                                "latitude": self.latitudeNow,
                                "longitude": self.longitudeNow
                            ],merge: true
                            ,completion: { [self] error in
                                if let error = error {
                                    print("作成失敗" + error.localizedDescription)
                                    let dialog = UIAlertController(title: "作成失敗", message: error.localizedDescription, preferredStyle: .alert)
                                    dialog.addAction(UIAlertAction(title: "OK", style: .default))
                                    self.present(dialog, animated: true, completion: nil)
                                } else {
                                    print("作成成功")
                                }
                            }
                        )
                    }
                }
            }
        }
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

extension ContentViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        let latitude = location?.coordinate.latitude
        let longitude = location?.coordinate.longitude
        // 位置情報を格納する
        self.latitudeNow = String(latitude!)
        self.longitudeNow = String(longitude!)
    }
    
}

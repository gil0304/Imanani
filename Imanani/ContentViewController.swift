//
//  ContentViewController.swift
//  Imanani
//
//  Created by 落合遼梧 on 2023/03/01.
//

import UIKit
import CoreLocation
import Firebase

class ContentViewController: UIViewController {
    
    @IBOutlet weak var contentTextField: UITextField!
    
    var locationManager: CLLocationManager!
    // 緯度
    var latitudeNow: String = ""
    // 経度
    var longitudeNow: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocationManager()

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
                let thoroughfare = placemark.thoroughfare, // 地名(丁目)
                let subThoroughfare = placemark.subThoroughfare // 番地
                else {
                    return
                }
                let adress: String = "\(administrativeArea)\(locality)\(thoroughfare)\(subThoroughfare)"
                if let content = self.contentTextField.text {
                    if let user = Auth.auth().currentUser {
                        let createdTime = FieldValue.serverTimestamp()
                        Firestore.firestore().collection("users/\(user.uid)/contents").document().setData(
                            [
                                "content": content,
                                "adress": adress,
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

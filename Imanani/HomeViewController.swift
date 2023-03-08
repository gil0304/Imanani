//
//  HomeViewController.swift
//  Imanani
//
//  Created by 落合遼梧 on 2023/03/07.
//

import UIKit
import Firebase
import FirebaseStorage

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var saveData: UserDefaults = UserDefaults.standard
    var userIdArray: [String] = []
    var userNameArray: [String] = []
    var userContentArray: [String] = []
    var userAddressArray: [String] = []
    var userName: String = ""
    var userImage: String = ""
    var downloadURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameLabel.text = saveData.object(forKey: "userName") as? String
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ContentTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.rowHeight = 87
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let user = Auth.auth().currentUser {
            
            Firestore.firestore().collection("users").document(user.uid).getDocument(completion: {(snapshot,error) in
                if let snap = snapshot {
                    if let data = snap.data() {
                        self.userName = data["userName"] as! String
                        self.userImage = data["profileImageName"] as! String
                        print(type(of: self.userImage))
                        print(self.userImage)
                    }
                }
            })
            
            Firestore.firestore().collection("contents").order(by: "createdAt").addSnapshotListener({(querySnapshot, error) in
                if let querySnapshot = querySnapshot {
                    var idArray: [String] = []
                    var nameArray: [String] = []
                    var contentArray: [String] = []
                    var addressArray: [String] = []
                    for doc in querySnapshot.documents {
                        let data = doc.data()
                        idArray.append(doc.documentID)
                        nameArray.append(data["user"] as! String)
                        contentArray.append(data["content"] as! String)
                        addressArray.append(data["address"] as! String)
                    }
                    self.userIdArray = idArray
                    self.userNameArray = nameArray
                    self.userContentArray = contentArray
                    self.userAddressArray = addressArray
                    self.tableView.reloadData()
                } else if let error = error {
                    print("取得失敗" + error.localizedDescription)
                }
            })
            
//            let imageUrl:URL = URL(string: userImage)!
//            let imageData:Data = try! Data(contentsOf: imageUrl)
//            profileImage.image = UIImage(data: imageData)!
        }
        let storageref = Storage.storage().reference(forURL: "gs://imanani-7ee50.appspot.com/profile_image").child(self.userImage)
        storageref.downloadURL { url, error in
            if let url = url {
                self.downloadURL = url
                print(url)
                do {
                    let data = try Data(contentsOf: url)
                    return self.profileImage.image = UIImage(data: data)
                } catch let imageerror {
                    print("Error : \(imageerror.localizedDescription)")
                }
            }
        }
        print(self.downloadURL)
        print(storageref)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userContentArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContentTableViewCell
        let storageref = Storage.storage().reference(forURL: "gs://imanani-7ee50.appspot.com/profile_image").child(userImage)
        cell.setCell(profileImage: storageref, userName: userNameArray[indexPath.row], content: userContentArray[indexPath.row], address: userAddressArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 87
    }
    
    @IBAction func toEdit() {
        let storyboard: UIStoryboard = self.storyboard!
        let editVC = storyboard.instantiateViewController(withIdentifier: "EditVC") as! EditViewController
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        self.present(nav, animated: true, completion: nil)
    }

}

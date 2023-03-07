//
//  HomeViewController.swift
//  Imanani
//
//  Created by 落合遼梧 on 2023/03/07.
//

import UIKit
import Firebase

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var saveData: UserDefaults = UserDefaults.standard
    var userIdArray: [String] = []
    var userContentArray: [String] = []
    var userAddressArray: [String] = []
    var userName: String = ""
    
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
                    }
                }
            })
            
            Firestore.firestore().collection("users/\(user.uid)/contents").order(by: "createdAt").addSnapshotListener({(querySnapshot, error) in
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
                    print("取得失敗" + error.localizedDescription)
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userContentArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContentTableViewCell
        cell.setCell(userName: userName, content: userContentArray[indexPath.row], address: userAddressArray[indexPath.row])
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

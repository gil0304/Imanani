//
//  ContentTableViewCell.swift
//  Imanani
//
//  Created by 落合遼梧 on 2023/03/02.
//

import UIKit
import Firebase
import FirebaseStorage

class ContentTableViewCell: UITableViewCell {
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    
    var downloadURL: URL?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCell(profileImage: StorageReference, userName: String, content: String, address: String) {
        userNameLabel.text = userName
        contentLabel.text = content
        addressLabel.text = address
        profileImage.downloadURL { url, error in
            if let url = url {
                self.downloadURL = url
                print(url)
                do {
                    let data = try Data(contentsOf: url)
                    return self.profileImageView.image = UIImage(data: data)
                } catch let imageerror {
                    print("Error : \(imageerror.localizedDescription)")
                }
            }
        }
    }
    
}

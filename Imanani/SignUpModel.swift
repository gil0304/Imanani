import Foundation
import Firebase
import FirebaseStorage

//delegateはweak参照したいため、classを継承する
protocol SignUpModelDelegate: class {
    func createImageToFirestorageAction()
    func createUserToFirestoreAction(fileName: String?)
    func completedRegisterUserInfoAction()
}

class SignUpModel {

    // delegateはメモリリークを回避するためweak参照する
    weak var delegate: SignUpModelDelegate?

    func createUser(email: String, password: String) {
        // FirebaseAuthへ保存
        Auth.auth().createUser(withEmail: email, password: password) { (res, err) in
            if let err = err {
                print("FirebaseAuthへの保存に失敗しました。\(err)")
                // ユーザー情報の登録が失敗した時の処理
                return
            }
            print("FirebaseAuthへの保存に成功しました。")
            // FirebaseAuthへ保存完了 -> FirebaseStorageへ保存処理
            self.delegate?.createImageToFirestorageAction()
        }
    }

    func creatrImage(fileName: String, uploadImage: Data) {
        // FirebaseStorageへ保存
        let storageRef = Storage.storage().reference().child("profile_image").child(fileName)
        storageRef.putData(uploadImage, metadata: nil) { (metadate, err) in
            if let err = err {
                print("Firestorageへの保存に失敗しました。\(err)")
                // ユーザー情報の登録が失敗した時の処理
                return
            }
            print("Firestorageへの保存に成功しました。")
            // FirebaseStorageへ保存完了 -> FirebaseFirestoreへ保存処理
            self.delegate?.createUserToFirestoreAction(fileName: fileName)
        }
    }

    func createUserInfo(uid: String, docDate: [String : Any]) {
        // FirebaseFirestoreへ保存
        Firestore.firestore().collection("users").document(uid).setData(docDate as [String : Any]) { (err) in
            if let err = err {
                print("Firestoreへの保存に失敗しました。\(err)")
                // ユーザー情報の登録が失敗した時の処理
                return
            }
            print("Firestoreへの保存に成功しました。")
            // ユーザー情報の登録が完了した時の処理
            self.delegate?.completedRegisterUserInfoAction()
        }
    }

}

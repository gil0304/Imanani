//
//  MapViewController.swift
//  Imanani
//
//  Created by 落合遼梧 on 2023/03/06.
//

import UIKit
import MapKit
import Firebase

class MapViewController: UIViewController {
    
    var latitude: String = ""
    var longitude: String = ""
    var userName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        if let user = Auth.auth().currentUser {
            Firestore.firestore().collection("users").document(user.uid).getDocument(completion: { (snapshot,error) in
                if let snap = snapshot {
                    if let data = snap.data() {
                        self.latitude = data["latitude"] as! String
                        self.longitude = data["longitude"] as! String
                        var doubleLat: Double = Double(self.latitude)!
                        var doubleLon: Double = Double(self.longitude)!
                        self.userName = data["userName"] as! String
                        
                        var myMapView: MKMapView = MKMapView()
                        myMapView.frame = self.view.frame

                        let myLatitude: CLLocationDegrees = doubleLat
                        let myLongitude: CLLocationDegrees = doubleLon

                        let center: CLLocationCoordinate2D = CLLocationCoordinate2DMake(myLatitude, myLongitude)

                        myMapView.setCenter(center, animated: true)

                        let mySpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        let myRegion: MKCoordinateRegion = MKCoordinateRegion(center: center, span: mySpan)

                        myMapView.region = myRegion

                        self.view.addSubview(myMapView)

                        var myPin: MKPointAnnotation = MKPointAnnotation()

                        myPin.coordinate = center

                        myPin.title = self.userName

                        myMapView.addAnnotation(myPin)
                            
                    }
                }
            })

           
            
        }

            
    }

}

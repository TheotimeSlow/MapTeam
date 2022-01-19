//
//  MapViewController.swift
//  MapTeam
//
//  Created by etudiant on 18/01/2022.
//
import MapKit
import UIKit
import CoreLocation
import Alamofire

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var nomVille: UILabel!
    @IBOutlet weak var regionVille: UILabel!
    @IBOutlet weak var departementVille: UILabel!
    @IBOutlet weak var populationVille: UILabel!
    var locationManager:CLLocationManager!
    var currentLocationStr = "Current location"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        let gestureRecognizer = UITapGestureRecognizer(
                                      target: self, action:#selector(handleTap))
            gestureRecognizer.delegate = self
            map.addGestureRecognizer(gestureRecognizer)
    }
    override func viewDidAppear(_ animated: Bool){
        determineCurrentLocation()
    }

    func locationManager(_ manager:CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let mUserLocation:CLLocation = locations[0] as CLLocation
        
        let center = CLLocationCoordinate2D(latitude:mUserLocation.coordinate.latitude, longitude: mUserLocation.coordinate.longitude)
        print(center)
        let mRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        map.setRegion(mRegion, animated: true)
        
        let mkAnnotation:MKPointAnnotation = MKPointAnnotation()
        mkAnnotation.coordinate = CLLocationCoordinate2DMake(mUserLocation.coordinate.latitude, mUserLocation.coordinate.longitude)
        mkAnnotation.title = self.setUsersClosestLocation(mLatitude: mUserLocation.coordinate.latitude, mLongitude: mUserLocation.coordinate.longitude)
        map.addAnnotation(mkAnnotation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        print("Error - locationManager: \(error.localizedDescription)")
    }
    
    func determineCurrentLocation(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.startUpdatingLocation()
        }
    }
 
    func setUsersClosestLocation(mLatitude: CLLocationDegrees, mLongitude: CLLocationDegrees) -> String{
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: mLatitude, longitude: mLongitude)
        
        geoCoder.reverseGeocodeLocation(location){
            (placemarks, error)->Void in
            
            if let mPlacemark = placemarks{
                if let dict = mPlacemark[0].addressDictionary as? [String: Any]{
                    if let Name = dict["Name"] as? String{
                        if let City = dict["City"] as? String{
                            self.currentLocationStr = Name + ", " + City
                        }
                    }
                }
            }
        }
        return currentLocationStr
    }


    @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        
        let location = gestureRecognizer.location(in: map)
        let coordinate = map.convert(location, toCoordinateFrom: map)
        print(coordinate)
        var apiResponse2: [ApiResponse] = []
        AF.request("https://geo.api.gouv.fr/communes?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&fields=nom,code,codeDepartement,codeRegion,population,departement,region&format=json&geometry=centre", method: .get).validate(statusCode: [200]).responseDecodable(of: [ApiResponse].self) {[weak self] resp in
            
            switch resp.result {
            case .success(let apiResponse):
                
                print("---------API RESPONSE---------")
                print(apiResponse)
                print(apiResponse[0].nom)
                print(apiResponse[0].departement.nom)
                print(apiResponse[0].region.nom)
                print("------------------------------")
                apiResponse2 = apiResponse
                changeLabel()
                
            case .failure(let aferror):
                print(String(describing: aferror))
            }
        }
        // Add annotation:
        func changeLabel() {
            
           
            let annotation = CCMPointAnnotation()
            annotation.apiResponse = apiResponse2.first
            annotation.coordinate = coordinate
            annotation.title = String(apiResponse2[0].nom + ", " + apiResponse2[0].departement.nom)
            //let annotationView = MKAnnotationView()
            
            map.addAnnotation(annotation)
            mapView(map, didSelect: MKAnnotationView())
            
        }
        func mapView(_: MKMapView, didSelect view: MKAnnotationView){
            print("Détail \(apiResponse2.first!.population)")
            self.nomVille.text = "Nom : \(apiResponse2.first!.nom)"
            self.regionVille.text = "Région : \(apiResponse2.first!.region.nom)"
            self.departementVille.text = "Departement : \(apiResponse2.first!.departement.nom)"
            self.populationVille.text = "Population : \(apiResponse2.first!.population)"
 
        }
    }
    
class CCMPointAnnotation: MKPointAnnotation{
    var apiResponse: ApiResponse?
}
    
}

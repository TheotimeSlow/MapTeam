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
import SQLite

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var nomVille: UILabel!
    @IBOutlet weak var regionVille: UILabel!
    @IBOutlet weak var departementVille: UILabel!
    @IBOutlet weak var populationVille: UILabel!
    @IBOutlet weak var latitudeVille: UILabel!
    @IBOutlet weak var longitudeVille: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    var locationManager:CLLocationManager!
    var currentLocationStr = "Current location"
    var db : Connection?
    let coordinates = Table("coordinates")
    let id = Expression<Int64>("id")
    let nomCol = Expression<String?>("nomCol")
    let departementCol = Expression<String?>("departementCol")
    let latitudeCol = Expression<String?>("latitudeCol")
    let longitudeCol = Expression<String?>("longitudeCol")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        do{
            self.db = try Connection("\(path)/db.sqlite3")
        } catch {
            print("Unable to create connection: \(error)")
        }
        
        
        
        do{
            try self.db?.run(coordinates.create(ifNotExists:true){ t in
            t.column(id, primaryKey: .autoincrement)
            t.column(nomCol)
            t.column(departementCol)
            t.column(latitudeCol)
            t.column(longitudeCol)
        })
        }catch{
            print("Table error create: \(error)")
        }
        
        map.delegate = self
        let gestureRecognizer = UITapGestureRecognizer(
                                      target: self, action:#selector(handleTap))
            gestureRecognizer.delegate = self
            map.addGestureRecognizer(gestureRecognizer)

        saveButton.layer.cornerRadius = 21
        saveButton.layer.masksToBounds = true
        
    }
    override func viewDidAppear(_ animated: Bool){
        determineCurrentLocation()
        do{
           
            for coordinate in try self.db!.prepare(coordinates) {
                print("id: \(coordinate[id]), nom \(coordinate[nomCol]), departement \(coordinate[departementCol]), latitude \(coordinate[latitudeCol]), longitude \(coordinate[longitudeCol])")
                if let lati = Double(coordinate[latitudeCol]!), let longi = Double(coordinate[longitudeCol]!){
                    let dbAnnotation:MKPointAnnotation = MKPointAnnotation()
                    dbAnnotation.coordinate = CLLocationCoordinate2DMake(lati, longi)
                    
                    
                    dbAnnotation.title = "\(coordinate[nomCol] ?? ""), \(coordinate[departementCol] ?? "")"
                    map.addAnnotation(dbAnnotation)
                }

            }
        }catch{
            print("Print error table : \(error)")
        }
        
    }

    func locationManager(_ manager:CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let mUserLocation:CLLocation = locations[0] as CLLocation
        
        let center = CLLocationCoordinate2D(latitude:mUserLocation.coordinate.latitude, longitude: mUserLocation.coordinate.longitude)
        
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
            
            self.nomVille.text = "\(apiResponse2.first!.nom)"
            self.regionVille.text = "\(apiResponse2.first!.region.nom)"
            self.departementVille.text = "\(apiResponse2.first!.departement.nom)"
            self.populationVille.text = " \(apiResponse2.first!.population) habitants"
            self.latitudeVille.text = String(coordinate.latitude)
            self.longitudeVille.text = String(coordinate.longitude)
 
        }
    }
    
class CCMPointAnnotation: MKPointAnnotation{
    var apiResponse: ApiResponse?
}
 
    
    @IBAction func onClickFav(_ sender: Any) {
        print(self.latitudeVille.text)
        print(self.longitudeVille.text)
       
        do{
            
            try self.db?.run(self.coordinates.insert(self.nomCol <- self.nomVille.text, self.departementCol <- self.departementVille.text, self.latitudeCol <- self.latitudeVille.text, self.longitudeCol <- self.longitudeVille.text))
            
        }catch{
            print("insert error : \(error)")
        }
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            toastLabel.textColor = UIColor.white
            
            toastLabel.textAlignment = .center;
            toastLabel.text = "Point sauvegardé"
            toastLabel.alpha = 1.0
            toastLabel.layer.cornerRadius = 10;
            toastLabel.clipsToBounds  =  true
            self.view.addSubview(toastLabel)
            UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
                 toastLabel.alpha = 0.0
            }, completion: {(isCompleted) in
                toastLabel.removeFromSuperview()
            })

    }
   
    
    @IBAction func githubButton(_ sender: Any) {
        if let url = URL(string: "https://github.com/TheotimeSlow/MapTeam") {
        UIApplication.shared.open(url)
        }
    }
}

//
//  ViewController.swift
//  MapTeam
//
//  Created by etudiant on 18/01/2022.
//
import MapKit
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
    
    }

    @IBAction func goToMapAction(_ sender: Any) {
    
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MapID")
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    

}


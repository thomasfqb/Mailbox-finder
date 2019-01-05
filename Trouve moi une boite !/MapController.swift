//
//  ViewController.swift
//  Trouve moi une boite !
//
//  Created by Thomas Fauquemberg on 11/05/2018.
//  Copyright © 2018 Thomas Fauquemberg. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import ScalingCarousel
import SwiftMessages

class MapController : UIViewController, CLLocationManagerDelegate {
    
    let cellId = "cellId"
    let emptyCellId = "emptyCellId"
    
    var userLocation: CLLocation?
    var distance:Float = 1000
    
    var mailBoxes = [MailBox]()
    
    var selectedAnnotation: MKPointAnnotation?
    var mapAnnontations = [MKPointAnnotation : MailBox]()
    
    let locationManager = CLLocationManager()
    
    let mapView: MKMapView = {
       let v = MKMapView()
        return v
    }()
    
    lazy var mailboxCollectionView = ScalingCarouselView(withFrame: view.frame, andInset: 40)
    
    
    let slider: UISlider = {
       let s = UISlider()
        s.minimumValue = 1
        s.maximumValue = 10
        s.thumbTintColor = UIColor.rgb(red: 254, green: 203, blue: 0)
        s.minimumTrackTintColor = UIColor.rgb(red: 61, green: 61, blue: 61)
        s.backgroundColor = .clear //UIColor.rgb(red: 235, green: 235, blue: 235)
        s.clipsToBounds = true
        s.layer.cornerRadius = 10
        s.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        s.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        return s
    }()
    
    
    @objc func handleSliderChange() {
        distance = slider.value * 1000
        let stringDistance = String(format: "Rechercher à %2.f km ", distance/1000)
        let attributedString = NSAttributedString(string: stringDistance, attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 24), .foregroundColor: UIColor.rgb(red: 61, green: 61, blue: 61)])
        findButton.setAttributedTitle(attributedString, for: .normal)
        
    }
    
    let findButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = UIColor.rgb(red: 254, green: 203, blue: 0)
        btn.sizeToFit()
        let attributedString = NSAttributedString(string: "Rechercher", attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 24), .foregroundColor: UIColor.rgb(red: 61, green: 61, blue: 61)])
        btn.setAttributedTitle(attributedString, for: .normal)
        
        btn.layer.cornerRadius = 10
        btn.clipsToBounds = true
        btn.addTarget(self, action: #selector(fetchMailBox), for: .touchUpInside)
        return btn
    }()
    
    let closeButton: UIButton = {
       let btn = UIButton()
        let image = UIImage(named: "close")?.withRenderingMode(.alwaysTemplate)
        btn.setImage(image, for: .normal)
        btn.tintColor = UIColor.rgb(red: 254, green: 203, blue: 0)
        btn.addTarget(self, action: #selector(hideMailBoxCollectionView), for: .touchUpInside)
        return btn
    }()
    
    
    @objc func fetchMailBox() {
        print("fetching mailbox...")

        
        if Reachability.isConnectedToNetwork() {
            print("Internet Connection Available!")
        }else{
            print("Internet Connection not Available!")
            showUserNoInternetConection()
            return
        }
        
        checkLocationAutorization()
        
        guard let userLocation = userLocation else { return }
        
        
        centerMap(on: userLocation, with: 0.05)
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude

        let urlString = "https://datanova.laposte.fr/api/records/1.0/search/?dataset=laposte_boiterue&rows=20&facet=lb_voie_ext&facet=lb_com&facet=co_insee_com&facet=co_postal&facet=lb_type_geo&facet=syst_proj_ini&geofilter.distance=\(latitude)%2C\(longitude)%2C\(distance)"
        
        guard let url = URL(string: urlString) else { return }
        
        let urlRequest = URLRequest(url: url)
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            
            if let error = error {
                print("failed to fetch mailboxes ", error )
            }
            
            guard let data = data, let _ = response else { return }
            
            do {
                let dictionnaries = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                
                guard let mailBoxesDictionnary = dictionnaries["records"] as? [AnyObject] else { return }
            
                mailBoxesDictionnary.forEach({ (mailBoxDictionnary) in
                    let mailBoxDictionnary = mailBoxDictionnary["fields"] as! [String: Any]
                    
                    let city = mailBoxDictionnary["lb_com"] as! String
                    let distanceFromUserString = mailBoxDictionnary["dist"] as! String
                    let zipCodeString = mailBoxDictionnary["co_postal"] as! String
                    let streetNumber = mailBoxDictionnary["va_no_voie"] as! String
                    let streetName = mailBoxDictionnary["lb_voie_ext"] as! String
                    let coordinate = mailBoxDictionnary["latlong"] as! [Double]
                    let latitude = coordinate[0]
                    let longitude = coordinate[1]
                    
                    
                    let zipCode = Int(zipCodeString)
                    let distanceFromUser = Int(distanceFromUserString)
                    
                    let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = location
                    
                    
                    DispatchQueue.main.async {
                        self.mapView.addAnnotation(annotation)
                    }
                    
                    
                    let mailBox = MailBox(latitude: latitude, longitude: longitude, distanceFromUser: distanceFromUser, streetNumber: streetNumber, streetName: streetName, city: city, zipCode: zipCode, annotation: annotation)
                
                    self.mapAnnontations[annotation] = mailBox
                    self.mailBoxes.append(mailBox)
                    
                    
                })
                
                self.mailBoxes.sort(by: { (mailbox1, mailbox2) -> Bool in
                    
                    guard let dist1 = mailbox1.distanceFromUser, let dist2 = mailbox2.distanceFromUser else { return false }
                    return dist1 < dist2
                })
                
                if self.mailBoxes.count == 20 {
                    self.showWarningAboutIgnoredResults()
                }
                
                
                self.presentMailBoxCollectionView()
                
               
                
            } catch {
                print("error converting data to JSon")
            }
        }
        task.resume()
        
    }

    func showWarningAboutIgnoredResults() {
        DispatchQueue.main.async {
            let warning = MessageView.viewFromNib(layout: .tabView)
            warning.configureTheme(.warning)
            warning.configureContent(title: "Information", body: "Les résultats les plus éloignés ont été ignorés")
            warning.button?.removeFromSuperview()
            SwiftMessages.show(view: warning)
        }
    }
    
    
    
    func clearData() {
        mailBoxes.removeAll()
        var annotationToRemove = [MKPointAnnotation]()
        mapAnnontations.forEach { (annotation) in
            annotationToRemove.append(annotation.key)
        }
        mapView.removeAnnotations(annotationToRemove)
        mapAnnontations.removeAll()
    }
    
    
    fileprivate func showUserNoInternetConection() {
        let error = MessageView.viewFromNib(layout: .tabView)
        error.configureTheme(.error)
        error.configureContent(title: "Erreur", body: "Aucune connexion internet!")
        error.button?.removeFromSuperview()
        SwiftMessages.show(view: error)
    }
    
    func checkLocationAutorization() {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                showUserEnableLocationService()
                print("No access")
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
            }
        } else {
            showUserEnableLocationService()
        }
    }
    
    fileprivate func showUserEnableLocationService() {
        let error = MessageView.viewFromNib(layout: .tabView)
        error.configureTheme(.error)
        error.configureContent(title: "Erreur", body: "Activez votre service de localisation")
        error.button?.removeFromSuperview()
        SwiftMessages.show(view: error)
    }
    
    
    
    func presentMailBoxCollectionView() {
        print("presenting collection View to user")
        
        DispatchQueue.main.async {
            self.mailboxCollectionView.reloadData()
            
            self.mailBoxCollectionViewBottomPadding?.constant = -20
            self.sliderRightPadding?.constant = 200
            
            UIView.animate(withDuration: 0.4, animations: {
                self.view.layoutIfNeeded()
                self.findButton.alpha = 0
            }, completion: { (bool) in
                self.mailboxCollectionView.didScroll()
            })
        }
    }
    
    @objc func hideMailBoxCollectionView() {
        print("hiding collection View to user")
        
        clearData()
        if let userLocation = userLocation {
            centerMap(on: userLocation, with: 0.05)
        }
        
        
        DispatchQueue.main.async {
            self.mailboxCollectionView.reloadData()
            
            self.mailBoxCollectionViewBottomPadding?.constant = 350
            self.sliderRightPadding?.constant = 100
            
            UIView.animate(withDuration: 0.4, animations: {
                self.view.layoutIfNeeded()
                self.findButton.alpha = 1
            }, completion: { (bool) in
                self.mailboxCollectionView.didScroll()
            })
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        mapView.delegate = self
        
        setupLocationManager()
        setupCarouselView()
        setupViews()
        
        guard let userLocation = userLocation else { return }
        centerMap(on: userLocation, with: 0.005)
    }
    
    fileprivate func setupCarouselView() {
        mailboxCollectionView.backgroundColor = .clear
        mailboxCollectionView.register(MailBoxCell.self, forCellWithReuseIdentifier: cellId)
        mailboxCollectionView.register(NoResultCell.self, forCellWithReuseIdentifier: emptyCellId)
        mailboxCollectionView.delegate = self
        mailboxCollectionView.dataSource = self
    }
    
    fileprivate func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    fileprivate func setupViews() {
        view.addSubview(mapView)
        mapView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(findButton)
        findButton.anchor(top: nil, left: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 15, paddingRight: 0, width: 250, height: 50)
        findButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(slider)
        slider.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 250, height: 50)
        slider.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        sliderRightPadding = slider.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 100)
        sliderRightPadding?.isActive = true
        
        view.addSubview(mailboxCollectionView)
        mailboxCollectionView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)
        
        mailBoxCollectionViewBottomPadding = mailboxCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 350)
        mailBoxCollectionViewBottomPadding?.isActive = true
        
        view.addSubview(closeButton)
        closeButton.anchor(top: nil, left: nil, bottom: mailboxCollectionView.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 8, paddingRight: 14, width: 0, height: 0)
    }
    
    var mailBoxCollectionViewBottomPadding: NSLayoutConstraint?
    var sliderRightPadding: NSLayoutConstraint?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0]
        mapView.showsUserLocation = true
    }
    
    
    func centerMap(on location: CLLocation, with delta: CLLocationDegrees) {
        let center = location.coordinate
        let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
}



extension MapController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if mailBoxes.isEmpty {
            return 1
        }
        return mailBoxes.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if mailBoxes.isEmpty {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emptyCellId, for: indexPath) as! NoResultCell
            return setupEmptyCollectionCell(for: cell)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MailBoxCell
        cell.mailBox = mailBoxes[indexPath.item]
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        return cell
    }
    
    
    fileprivate func setupEmptyCollectionCell(for cell: NoResultCell) -> NoResultCell {
        let attributedString = NSMutableAttributedString(string: "Aucun resultat à moins de \(Int(distance/1000)) km\n", attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 24)])
        attributedString.append(NSMutableAttributedString(string: "Elargissez la zone de recherche", attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 18)]))
        cell.textLabel.attributedText = attributedString
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        return cell
    }
    
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mailboxCollectionView.didScroll()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        
        visibleRect.origin = mailboxCollectionView.contentOffset
        visibleRect.size = mailboxCollectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        guard let indexPath = mailboxCollectionView.indexPathForItem(at: visiblePoint) else { return }
        
        let mailbox = mailBoxes[indexPath.item]
        
        guard let annontation = mailbox.annotation else { return }
        mapView.selectAnnotation(annontation, animated: true)
        mapView.setCenter(annontation.coordinate, animated: true)
 
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if mailBoxes.isEmpty {
            return
        }
        let mailbox = mailBoxes[indexPath.item]
        openMap(for: mailbox)
    }
    
    
    func openMap(for mailbox: MailBox) {
        
        guard let latitude = mailbox.latitude, let longitude = mailbox.longitude else { return }
        
        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Boite au lettre"
        mapItem.openInMaps(launchOptions: options)
    }
    
    
    
}


extension MapController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        selectedAnnotation = view.annotation as? MKPointAnnotation
        guard let selectedAnnotation = selectedAnnotation else { return }
        guard let mailBox = mapAnnontations[selectedAnnotation] else { return }
        
        guard let index = mailBoxes.index(where: { $0.latitude == mailBox.latitude && $0.longitude == mailBox.longitude}) else { return }
    
        let latitude = selectedAnnotation.coordinate.latitude
        let longitude = selectedAnnotation.coordinate.longitude
        
        centerMap(on: CLLocation(latitude: latitude, longitude: longitude), with: 0.005)
        
        let indexPath = IndexPath(item: index, section: 0)
        
        mailboxCollectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: true)
        
    }
    
   

}








//
//  mailBox.swift
//  Trouve moi une boite !
//
//  Created by Thomas Fauquemberg on 11/05/2018.
//  Copyright © 2018 Thomas Fauquemberg. All rights reserved.
//

import Foundation
import MapKit

struct MailBox {

    let latitude: Double?
    let longitude: Double?
    let distanceFromUser: Int?
    let streetNumber: String?
    let streetName: String?
    let city: String?
    let zipCode: Int?
    var annotation: MKPointAnnotation?
}



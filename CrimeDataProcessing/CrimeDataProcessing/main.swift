//
//  main.swift
//  CrimeDataProcessing
//
//  Created by 张国晔 on 2016/10/9.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import Foundation
import SQLite

struct Crime: CustomStringConvertible {
    let date: Date
    let address: String
    let location: (latitude: Double, longitude: Double)
    let linkId: Int
    let type: String
    
    var description: String {
        return "\(date) \(location) \(linkId) \(type)"
    }
}

do {
    let db = try Connection("server.db")
    let crimes = Table("crimes")
    let dateCol = Expression<Int>("date")
    let addressCol = Expression<String>("address")
    let latitudeCol = Expression<Double>("latitude")
    let longitudeCol = Expression<Double>("longitude")
    let linkIdCol = Expression<Int>("linkId")
    let typeCol = Expression<String>("type")
    try db.run(crimes.create(ifNotExists: true) { t in
        t.column(dateCol)
        t.column(addressCol)
        t.column(latitudeCol)
        t.column(longitudeCol)
        t.column(linkIdCol)
        t.column(typeCol)
    } )
    
    let data = try Data(contentsOf: URL(fileURLWithPath: "crime.json"))
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: [[Any]]] else { fatalError() }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss"
    let numberFormatter = NumberFormatter()
    var urlComponents = URLComponents()
    urlComponents.scheme = "http"
    urlComponents.host = "www.mapquestapi.com"
    urlComponents.path = "/directions/v2/findlinkid"
    
    for entry in json["data"] ?? [] {
        guard let dateString = entry[10] as? String,
                let date = dateFormatter.date(from: dateString),
                let address = entry[14] as? String,
                let latitudeString = entry[20] as? String,
                let latitude = numberFormatter.number(from: latitudeString)?.doubleValue,
                let longitudeString = entry[21] as? String,
                let longitude = numberFormatter.number(from: longitudeString)?.doubleValue,
                let type = entry[27] as? String else {
            continue
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: "afbtgu28aAJW4kgGbc8yarMCZ3LdWWbh"),
            URLQueryItem(name: "lat", value: latitudeString),
            URLQueryItem(name: "lng", value: longitudeString)
        ]
        guard let url = urlComponents.url else { continue }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data else {
                print(error)
                return
            }
            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return }
            guard let linkId = json["linkId"] as? Int else { return }
            
            _ = try? db.run(crimes.insert(dateCol <- Int(date.timeIntervalSince1970), addressCol <- address, latitudeCol <- latitude, longitudeCol <- longitude, linkIdCol <- linkId, typeCol <- type))
            
            print(Crime(date: date, address: address, location: (latitude, longitude), linkId: linkId, type: type))
        }.resume()
    }
} catch {
    print(error)
}

RunLoop.current.run()

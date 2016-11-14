//
//  main.swift
//  CrimeDataProcessing
//
//  Created by 张国晔 on 2016/10/9.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import Cocoa
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
    urlComponents.host = "open.mapquestapi.com"
    urlComponents.path = "/directions/v2/findlinkid"
    
    var linkIds = [Int: [Int: Int]]()
    var c = 0
    
    func writeDatabase() {
        for entry in json["data"] ?? [] {
            guard let dateString = entry[8] as? String,
                let date = dateFormatter.date(from: dateString),
                let address = entry[11] as? String,
                let type = entry[12] as? String,
                let locationType = entry[13] as? String, locationType.hasPrefix("O"),
                let coordinate = entry[18] as? [Any],
                let latitudeString = coordinate[1] as? String,
                let latitude = numberFormatter.number(from: latitudeString)?.doubleValue,
                let longitudeString = coordinate[2] as? String,
                let longitude = numberFormatter.number(from: longitudeString)?.doubleValue else {
                    continue
            }
            let latitudeDegree = latitude * .pi / 180
            let dx = (longitude + 180) / 360 * 262144
            let dy = (1 - (log(tan(latitudeDegree) + 1 / cos(latitudeDegree)) / .pi)) / 2 * 262144
            let x = Int(dx), y = Int(dy)
            
            if let linkId = linkIds[x]?[y], linkId != -1 {
                _ = try? db.run(crimes.insert(dateCol <- Int(date.timeIntervalSince1970), addressCol <- address, latitudeCol <- latitude, longitudeCol <- longitude, linkIdCol <- linkId, typeCol <- type))
            }
        }
    }
    
    for entry in json["data"] ?? [] {
        guard let dateString = entry[8] as? String,
            let date = dateFormatter.date(from: dateString),
            let address = entry[11] as? String,
            let type = entry[12] as? String,
            let locationType = entry[13] as? String, locationType.hasPrefix("O"),
            let coordinate = entry[18] as? [Any],
            let latitudeString = coordinate[1] as? String,
            let latitude = numberFormatter.number(from: latitudeString)?.doubleValue,
            let longitudeString = coordinate[2] as? String,
            let longitude = numberFormatter.number(from: longitudeString)?.doubleValue else {
                continue
        }
        let latitudeDegree = latitude * .pi / 180
        let dx = (longitude + 180) / 360 * 262144
        let dy = (1 - (log(tan(latitudeDegree) + 1 / cos(latitudeDegree)) / .pi)) / 2 * 262144
        let x = Int(dx), y = Int(dy)
        
        guard linkIds[x]?[y] == nil else {
            continue
        }
        c += 1
        var xLinkIds = linkIds[x] ?? [:]
        xLinkIds[y] = -1
        linkIds[x] = xLinkIds
        
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: "afbtgu28aAJW4kgGbc8yarMCZ3LdWWbh"),
            URLQueryItem(name: "lat", value: latitudeString),
            URLQueryItem(name: "lng", value: longitudeString)
        ]
        guard let url = urlComponents.url else { continue }
        usleep(500000)
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                c -= 1
            }
            guard let data = data else {
                print("Failed")
                return
            }
            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return }
            guard let linkId = json["linkId"] as? Int else { return }
            
            var xLinkIds = linkIds[x] ?? [:]
            xLinkIds[y] = linkId
            linkIds[x] = xLinkIds
            
            print("add(\(x), \(y), \(linkId))")
            
            DispatchQueue.main.async {
                if c == 0 {
                    writeDatabase()
                    exit(0)
                }
            }
        }.resume()
    }
    
    RunLoop.current.run()
    
//    for level in 0...12 {
//        var tiles = [Int: [Int: [Int]]]()
//        
//        var maxN = 0
//        let resolution = 256
//        let radius = 3
//        let variance = 0.5
//        
//        let numTiles = Double(1 << level)
//        let lineWidth = resolution + radius * 2
//        
//        func inc(x: Int, y: Int, index: Int) {
//            var tile = tiles[x]?[y] ?? [Int](repeating: 0, count: lineWidth * lineWidth)
//            tile[index] += 1
//            var tilesX = tiles[x] ?? [Int: [Int]]()
//            tilesX[y] = tile
//            tiles[x] = tilesX
//            maxN = max(tile[index], maxN)
//        }
//        
//        for entry in json["data"] ?? [] {
//            guard let dateString = entry[8] as? String,
//                    let date = dateFormatter.date(from: dateString),
//                    let address = entry[11] as? String,
//                    let type = entry[12] as? String,
//                    let locationType = entry[13] as? String, locationType.hasPrefix("O"),
//                    let coordinate = entry[18] as? [Any],
//                    let latitudeString = coordinate[1] as? String,
//                    let latitude = numberFormatter.number(from: latitudeString)?.doubleValue,
//                    let longitudeString = coordinate[2] as? String,
//                    let longitude = numberFormatter.number(from: longitudeString)?.doubleValue else {
//                continue
//            }
//            if latitude == 0 || longitude == 0 {
//                continue
//            }
//            let latitudeDegree = latitude * .pi / 180
//            let dx = (longitude + 180) / 360 * numTiles
//            let dy = (1 - (log(tan(latitudeDegree) + 1 / cos(latitudeDegree)) / .pi)) / 2 * numTiles
//            let x = Int(dx), y = Int(dy)
//            let itx = Int(dx.truncatingRemainder(dividingBy: 1) * Double(resolution))
//            let ity = Int(dy.truncatingRemainder(dividingBy: 1) * Double(resolution))
//            inc(x: x, y: y, index: (itx + radius) * lineWidth + ity + radius)
//            if itx < radius {
//                inc(x: x - 1, y: y, index: (itx + resolution + radius) * lineWidth + ity + radius)
//            }
//            if itx >= resolution - radius {
//                inc(x: x + 1, y: y, index: (itx - resolution + radius) * lineWidth + ity + radius)
//            }
//            if ity < radius {
//                inc(x: x, y: y - 1, index: (itx + radius) * lineWidth + ity + resolution + radius)
//            }
//            if ity >= resolution - radius {
//                inc(x: x, y: y + 1, index: (itx + radius) * lineWidth + ity - resolution + radius)
//            }
//        }
//        print(level, maxN)
//        for (x, tilesX) in tiles {
//            for (y, tile) in tilesX {
//                let image = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: resolution, pixelsHigh: resolution, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: 0, bitsPerPixel: 0)!
//                for i in radius..<resolution + radius {
//                    for j in radius..<resolution + radius {
//                        var count = 0.0
//                        var t = 0.0
//                        for k in i - radius..<i + radius {
//                            for l in j - radius..<j + radius {
//                                let g = exp(Double(-((k-i)*(k-i)+(l-j)*(l-j))))/variance
//                                count += Double(tile[k * lineWidth + l]) * g
//                                t += g
//                            }
//                        }
//                        count = Double(count) / t
//                        if count > 0 {
//                            let color = -1 / (CGFloat(count) / 5 + 0.1) + 1
//                            image.setColor(NSColor(calibratedRed: 1, green: 0, blue: 0, alpha: color), atX: i - radius, y: j - radius)
//                        }
//                    }
//                }
//                try! image.representation(using: .PNG, properties: [:])!.write(to: URL(fileURLWithPath: "\(x)-\(y)-\(level).png"))
//            }
//        }
//    }
} catch {
    print(error)
}

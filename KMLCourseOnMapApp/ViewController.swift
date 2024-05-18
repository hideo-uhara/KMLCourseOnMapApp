//
// ViewController.swift
//

import MapKit
import Cocoa

class ViewController: NSViewController {

	@IBOutlet var mapView: MKMapView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let xmlReader: XMLReader = XMLReader(url: Bundle.main.url(forResource: "ejio park", withExtension: "kml")!)
		
		do {
			let root: [String: Any] = try xmlReader.load()
			
			if let kml: [String: Any] = root["kml"] as? [String: Any],
			   let document: [String: Any] = kml["Document"] as? [String: Any] {
				
				var placemarks: [[String: Any]] = []
				
				if let placemark: [[String: Any]] = document["Placemark"] as? [[String: Any]] { // Placemarkが複数
					placemarks = placemark
				} else if let placemark: [String: Any] = document["Placemark"] as? [String: Any] { // Placemarkがひとつ
					placemarks = [placemark]
				}
				
				for placemark: [String: Any] in placemarks {
					if let point: [String: Any] = placemark["Point"] as? [String: Any],
					   let coordinates: [String: Any] = point["coordinates"] as? [String: Any],
					   var text: String = coordinates[XMLReader.textNodeKey] as? String {
						
						text = text.trimmingCharacters(in: .whitespacesAndNewlines)
						
						let line: [String] = text.components(separatedBy: ",")
						
						if let lon: Double = Double(line[0]),
						   let lat: Double = Double(line[1]) {
							
							let pin: MKPointAnnotation = MKPointAnnotation()
							
							pin.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
							
							if let name: [String: Any] = placemark["name"] as? [String: Any],
							   let text: String = name[XMLReader.textNodeKey] as? String {
								
								pin.title = text.trimmingCharacters(in: .whitespacesAndNewlines)
							}
							
							self.mapView.addAnnotation(pin)
						}
					}
					
					if let lineString: [String: Any] = placemark["LineString"] as? [String: Any],
					   let coordinates: [String: Any] = lineString["coordinates"] as? [String: Any],
					   var text: String = coordinates[XMLReader.textNodeKey] as? String {
						
						text = text.trimmingCharacters(in: .whitespacesAndNewlines)
						
						var list: [[String]] = []
						
						text.enumerateLines(invoking: { (line, stop) in
							list.append(line.trimmingCharacters(in: .whitespaces).components(separatedBy: ","))
						})
						
						var locList: [CLLocationCoordinate2D] = []
						
						for line: [String] in list {
							if let lon: Double = Double(line[0]),
							   let lat: Double = Double(line[1]) {
								
								locList.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
							}
						}
						
						let polyline: MKPolyline = MKPolyline(coordinates: locList, count: locList.count)
						
						self.mapView.addOverlay(polyline)
						self.mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: NSEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0), animated: true)
					}
				}
				
			}
			
		} catch let error as NSError {
			print(error.localizedDescription)
		}
		
	}

	override var representedObject: Any? {
		didSet {
		}
	}

}

extension ViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		
		if #available(macOS 11.0, *) {
			let pinId: String = "locationPin"
			
			var annotationView: MKMarkerAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: pinId) as? MKMarkerAnnotationView
			
			if annotationView == nil {
				annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: pinId)
			} else {
				annotationView!.annotation = annotation
			}
			
			//annotationView!.displayPriority = .required // 全てのピンを常に表示
			
			return annotationView
			
		} else {
			return nil
		}
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if let polyline: MKPolyline = overlay as? MKPolyline {
			let polylineRenderer: MKPolylineRenderer = MKPolylineRenderer(polyline: polyline)
			
			polylineRenderer.strokeColor = .blue
			polylineRenderer.lineWidth = 2.0
			
			return polylineRenderer
		}
		
		return MKOverlayRenderer()
	}

}

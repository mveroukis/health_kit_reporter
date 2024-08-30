//
//  AnchoredObjectQueryStreamHandler.swift
//  health_kit_reporter
//
//  Created by Victor Kachalov on 09.12.20.
//

import Foundation
import HealthKit

public final class AnchoredObjectQueryStreamHandler: NSObject {
    public let reporter: HealthKitReporter
    public var activeQueries = Set<Query>()
    public var plannedQueries = Set<Query>()
    
    init(reporter: HealthKitReporter) {
        self.reporter = reporter
    }
}

extension HKQueryAnchor {
    func toBytes() throws -> [UInt8] {
        let rawData = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
        let bytes = [UInt8](rawData)

        return bytes
    }
}

extension [UInt8] {
    func toHKQueryAnchor() -> HKQueryAnchor {
        let data = Data(self)
        let decodedAnchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
        
        return decodedAnchor!
    }
}

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

// MARK: - StreamHandlerProtocol
extension AnchoredObjectQueryStreamHandler: StreamHandlerProtocol {
    public func setQueries(arguments: [String: Any], events: @escaping FlutterEventSink) throws {
        guard
            let anchoredIdentifiers = arguments["identifiers"] as? [String : FlutterStandardTypedData?],
            let startTimestamp = arguments["startTimestamp"] as? Double,
            let endTimestamp = arguments["endTimestamp"] as? Double
        else {
            return
        }

        let predicate = NSPredicate.samplesPredicate(
            startDate: Date.make(from: startTimestamp),
            endDate: Date.make(from: endTimestamp)
        )

        for anchoredIdentifier in anchoredIdentifiers {
            guard let type = anchoredIdentifier.key.objectType as? SampleType else {
                return
            }

            let anchorData = anchoredIdentifier.value?.data
            let anchorBytes = anchorData?.bytes
            let query = try reporter.reader.anchoredObjectQuery(
                type: type,
                predicate: predicate,
                anchor: anchorBytes?.toHKQueryAnchor(),
                monitorUpdates: true
            ) { (query, samples, deletedObjects, anchor, error) in
                guard error == nil else {
                    return
                }
                var jsonDictionary: [String: Any] = [:]
                var samplesArray: [String] = []

                for sample in samples {
                    do {
                        let encoded = try sample.encoded()
                        samplesArray.append(encoded)
                    } catch {
                        continue
                    }
                }
                var deletedObjectsArray: [String] = []
                for deletedObject in deletedObjects {
                    do {
                        let encoded = try deletedObject.encoded()
                        deletedObjectsArray.append(encoded)
                    } catch {
                        continue
                    }
                }

                jsonDictionary["samples"] = samplesArray
                jsonDictionary["deletedObjects"] = deletedObjectsArray
                jsonDictionary["anchor"] = try? anchor?.toBytes() ?? [UInt8()]

                events(jsonDictionary)
            }

            plannedQueries.insert(query)
        }
    }
    
    public static func make(with reporter: HealthKitReporter) -> AnchoredObjectQueryStreamHandler {
        AnchoredObjectQueryStreamHandler(reporter: reporter)
    }
}

// MARK: - FlutterStreamHandler
extension AnchoredObjectQueryStreamHandler: FlutterStreamHandler {
    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        handleOnListen(withArguments: arguments, eventSink: events)
    }
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        handleOnCancel(withArguments: arguments)
    }
}

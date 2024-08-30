//
//  Extensions+NSPredicate.swift
//  HealthKitReporter
//
//  Created by Victor on 14.09.20.
//

import HealthKit

public extension NSPredicate {
    static var allSamples: NSPredicate {
        return HKQuery.predicateForSamples(
            withStart: .distantPast,
            end: .distantFuture,
            options: []
        )
    }
    static func samplesPredicate(
        startDate: Date,
        endDate: Date?,
        excludeManual: Bool = false,
        options: HKQueryOptions = [.strictStartDate, .strictEndDate]
    ) -> NSPredicate {
        let predicateForSamples = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: options
        )
        
        if excludeManual {
            let predicateExcludeManual = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)

            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                predicateExcludeManual,
                predicateForSamples
                //HKQuery.predicateForSamples(withStart: startDate, end: nil)
            ])
        }
        else {
            return predicateForSamples
        }
        
//        return HKQuery.predicateForSamples(
//            withStart: startDate,
//            end: endDate,
//            options: options
//        )
    }
    @available(iOS 9.3, *)
    static func activitySummaryPredicate(
        dateComponents: DateComponents
    ) -> NSPredicate {
        return HKQuery.predicateForActivitySummary(with: dateComponents)
    }
    @available(iOS 9.3, *)
    static func activitySummaryPredicateBetween(
        start: DateComponents,
        end: DateComponents
    ) -> NSPredicate {
        return HKQuery.predicate(forActivitySummariesBetweenStart: start, end: end)
    }
}

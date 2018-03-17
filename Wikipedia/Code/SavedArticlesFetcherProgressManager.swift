/*
 TODO:
 
 - rename this to not use "Progress" or maybe switch it to be an NSProgress subclass altogether???
 - document purpose of this class is to bridge between SavedArticlesFetcher and vc's which want to display its progress (while being minimally invasive to SavedArticlesFetcher).
    something like:
        swift singleton which observes SavedArticlesFetcher's 'fetchesInProcessCount'
        that way we can access the progress singleton from anywhere w/o having to change SavedArticlesFetcher's public interface beyond exposing 'fetchesInProcessCount'
 
 - per carolyn, progress bar should show on both tabs of Saved. it should strive to maintain position between tabs and not reset to 0.
 */

@objcMembers class SavedArticlesFetcherProgressManager: NSObject, ProgressReporting {

    public static let fetchingSavedArticlesStartedNotification = NSNotification.Name(rawValue:"WMFFetchingSavedArticlesStartedNotification")
    public static let fetchingSavedArticlesCompletedNotification = NSNotification.Name(rawValue:"WMFFetchingSavedArticlesCompletedNotification")
//    public static let fetchingSavedArticlesProgressResetNotification = NSNotification.Name(rawValue:"WMFFetchingSavedArticlesProgressResetNotification")

    static let shared = SavedArticlesFetcherProgressManager()
    
    private var observation: NSKeyValueObservation?
    
    dynamic private(set) var progress: Progress = Progress.discreteProgress(totalUnitCount: -1)
// should this obj be sending notifications when "progress" changes or should external interested classes just observe "progress"?

    
private func reset() {
    // Per https://developer.apple.com/videos/play/wwdc2015/232/ by way of https://stinkykitten.com/index.php/2017/08/13/nsprogress/:
    // "NSProgress objects cannot be reused. Once they’re done, they’re done. Once they’re cancelled, they’re cancelled. If you need to reuse an NSProgress, instead make a new instance and provide a mechanism so the client of your progress knows that the object has been replaced, like a notification."
    progress = Progress.discreteProgress(totalUnitCount: -1)
//    NotificationCenter.default.post(name: SavedArticlesFetcherProgressManager.fetchingSavedArticlesProgressResetNotification, object: nil, userInfo: nil)
    
    //                                                                                                                                  ^ pass the new progress in one of these?
}
    
    
    var fetcher: SavedArticlesFetcher? {
        didSet {
            observation?.invalidate()
            if let fetcher = fetcher {
                observation = fetcher.observe(\SavedArticlesFetcher.fetchesInProcessCount, options: [.new, .old]) { [weak self] (fetcher, change) in
                    if
                        let newValue = change.newValue?.int64Value,
                        let oldValue = change.oldValue?.int64Value,
                        let progress = self?.progress
                    {
                        // Advance totalUnitCount if new units were added
                        let deltaValue = newValue - oldValue
                        let wereNewUnitsAdded = deltaValue > 0
                        if wereNewUnitsAdded {
                            progress.totalUnitCount = progress.totalUnitCount + deltaValue
                        }
                        
                        // Update completedUnitCount
                        let unitsRemaining = progress.totalUnitCount - newValue
                        progress.completedUnitCount = unitsRemaining
                        
                        // Start notification
                        let wasFirstUnitCompleted = newValue > 0 && oldValue == 0
                        if wasFirstUnitCompleted {
                            NotificationCenter.default.post(name: SavedArticlesFetcherProgressManager.fetchingSavedArticlesStartedNotification, object: nil, userInfo: nil)
                        }

                        // Finish notification
                        let wereAllUnitsCompleted = newValue == 0 && oldValue > 0
                        if wereAllUnitsCompleted {
                            NotificationCenter.default.post(name: SavedArticlesFetcherProgressManager.fetchingSavedArticlesCompletedNotification, object: nil, userInfo: nil)
                            self?.reset()
                        }
                    }
                }
            } else {
                observation?.invalidate()
            }
        }
    }
}

/*
fileprivate extension NSKeyValueObservedChange where Value == NSNumber {
    func wasFirstUnitCompleted() -> Bool {
        guard let newValue = newValue?.int64Value, let oldValue = oldValue?.int64Value else {
            return false
        }
        return newValue > 0 && oldValue == 0
    }
}
*/

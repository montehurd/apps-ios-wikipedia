/*
 TODO:
 
 - rename this to not use "Progress" or maybe switch it to be an NSProgress subclass altogether???
 - document purpose of this class is to bridge between SavedArticlesFetcher and vc's which want to display its progress (while being minimally invasive to SavedArticlesFetcher).
    something like:
        swift singleton which observes SavedArticlesFetcher's 'fetchesInProcessCount'
        that way we can access the progress singleton from anywhere w/o having to change SavedArticlesFetcher's public interface beyond exposing 'fetchesInProcessCount'
 
 - figure out how to have it reset after completing (some sort of reset method to set totalUnitCount to -1?)
 - per carolyn, progress bar should show on both tabs of Saved. it should strive to maintain position between tabs and not reset to 0.

 
 https://stinkykitten.com/index.php/2017/08/13/nsprogress/
    The clue is in the WWDC session (https://developer.apple.com/videos/play/wwdc2015/232/) where towards the end he states:
 
    "NSProgress objects cannot be reused. Once they’re done, they’re done. Once they’re cancelled, they’re cancelled. If you need to reuse an NSProgress, instead make a new instance and provide a mechanism so the client of your progress knows that the object has been replaced, like a notification."
 
    ^ so need to make this obj set a new Progress in reset, then need some way to have the objects watching this have their ProgressView observe this one
        and use it as their observedProgress whenever it changes
    (may also need to ensure the "self?.progress" references in the "fetcher.observe" block below are then still pointing to the new instance of progress - unsure if swift captures their scope a.t.m. ...)
 */

@objcMembers class SavedArticlesFetcherProgressManager: NSObject, ProgressReporting {

    public static let fetchingSavedArticlesStartedNotification = NSNotification.Name(rawValue:"WMFFetchingSavedArticlesStartedNotification")
    public static let fetchingSavedArticlesCompletedNotification = NSNotification.Name(rawValue:"WMFFetchingSavedArticlesCompletedNotification")
    public static let fetchingSavedArticlesProgressResetNotification = NSNotification.Name(rawValue:"WMFFetchingSavedArticlesProgressResetNotification")

    static let shared = SavedArticlesFetcherProgressManager()
    
    private var observation: NSKeyValueObservation?
    
    private(set) var progress: Progress = Progress.discreteProgress(totalUnitCount: -1)

    
private func reset() {
    // Per https://developer.apple.com/videos/play/wwdc2015/232/ :
    // "NSProgress objects cannot be reused. Once they’re done, they’re done. Once they’re cancelled, they’re cancelled. If you need to reuse an NSProgress, instead make a new instance and provide a mechanism so the client of your progress knows that the object has been replaced, like a notification."
    progress = Progress.discreteProgress(totalUnitCount: -1)
    NotificationCenter.default.post(name: SavedArticlesFetcherProgressManager.fetchingSavedArticlesProgressResetNotification, object: nil, userInfo: nil)
    
//    progress.totalUnitCount = -1
//    progress.completedUnitCount = 0
}
    
    
    var fetcher: SavedArticlesFetcher? {
        didSet {
            observation?.invalidate()
            if let fetcher = fetcher {
                observation = fetcher.observe(\SavedArticlesFetcher.fetchesInProcessCount, options: [.new, .old]) { [weak self] (fetcher, change) in
                    if
                        let newValueInt64 = change.newValue?.int64Value,
                        let oldValueInt64 = change.oldValue?.int64Value
                    {
                        // Advance totalUnitCount if new units were added
                        let valueDelta = newValueInt64 - oldValueInt64
                        let newUnitsWereAdded = valueDelta > 0
                        if newUnitsWereAdded {
                            if let existingTotalUnitCount = self?.progress.totalUnitCount {
                                self?.progress.totalUnitCount = existingTotalUnitCount + valueDelta
                            }
                        }
                        
                        
                        if let progress = self?.progress {
                            let unitsRemaining = progress.totalUnitCount - newValueInt64
                            progress.completedUnitCount = unitsRemaining
                        }

print("\n\nTHE observed count is \(fetcher.fetchesInProcessCount) new value is \(newValueInt64) old value was \(oldValueInt64) isFinished = \(self?.progress.isFinished)\n\n")

                        if (newValueInt64 == 0 && oldValueInt64 > 0) {
                            NotificationCenter.default.post(name: SavedArticlesFetcherProgressManager.fetchingSavedArticlesCompletedNotification, object: nil, userInfo: nil)
                            self?.reset()
                            //DONE
                        } else if (newValueInt64 > 0 && oldValueInt64 == 0) {
                            //STARTED
                            NotificationCenter.default.post(name: SavedArticlesFetcherProgressManager.fetchingSavedArticlesStartedNotification, object: nil, userInfo: nil)
                        } else {
                            print("WOT")
                        }

                        
                    }
                }
            } else {
                observation?.invalidate()
            }
        }
    }
}

//
//  TTAdUtil.swift
//  Pods-Runner
//
//  Created by Jerry on 2020/7/19.
//

import BUAdSDK
import Flutter

public final class PangleAdManager: NSObject {
    public static let shared = PangleAdManager()

    private var expressAdCollection: [String: BUNativeExpressAdView] = [:]

    private var rewardedVideoAdData: [String: [Any]] = [:]

    private var fullscreenVideoAdData: [String: [Any]] = [:]

    private var taskList: [FLTTaskProtocol] = []

    fileprivate func execTask(_ task: FLTTaskProtocol, _ loadingType: LoadingType? = nil) -> (@escaping (Any) -> Void) -> Void {
        self.taskList.append(task)
        return { result in
            if loadingType == nil {
                task.execute()({ [weak self] task, data in
                    self?.taskList.removeAll(where: { $0 === task })
                    result(data)
                })
            } else {
                task.execute(loadingType!)({ [weak self] task, data in
                    self?.taskList.removeAll(where: { $0 === task })
                    result(data)
                })
            }
        }
    }

    public func initialize(_ args: [String: Any?], _ result: @escaping FlutterResult) {
        let appId: String = args["appId"] as! String
        let logLevel: Int? = args["logLevel"] as? Int
        let idfa: String? = args["idfa"] as? String
        
        let config = BUAdSDKConfiguration.init()
        config.appID = appId
        if logLevel != nil {
            config.debugLog = logLevel == 0 ? 0 : 1
        }
        
        if idfa != nil {
            config.customIdfa = idfa!
        }
        
        config.appLogoImage = UIImage(named: "AppIcon")
        
        BUAdSDKManager.start(asyncCompletionHandler: { success, error in
            DispatchQueue.main.async {
                result(["code": 0, "message": ""] as [String: Any])
            }
        })
        
    }

    public func loadSplashAd(_ args: [String: Any?], result: @escaping FlutterResult) {
        let task = FLTSplashAdTask(args)
        self.execTask(task)({ object in
            result(object)
        })
    }

    public func loadRewardVideoAd(_ args: [String: Any?], result: @escaping FlutterResult) {
        let loadingTypeIndex: Int = args["loadingType"] as! Int
        let loadingType = LoadingType(rawValue: loadingTypeIndex)!

        if loadingType == .preload || loadingType == .normal {
            let success = showRewardedVideoAd(args)({ [unowned self] object in
                if loadingType == .preload {
                    loadRewardVideoAdOnly(args, loadingType: .preload_only)
                }
                result(object)
            })
            if !success {
                loadRewardVideoAdOnly(args, loadingType: .normal, result: result)
            }
        } else {
            loadRewardVideoAdOnly(args, loadingType: .preload_only, result: result)
        }

    }

    private func loadRewardVideoAdOnly(_ args: [String: Any?], loadingType: LoadingType, result: FlutterResult? = nil) {
        let task = FLTRewardedVideoExpressAdTask(args)
        execTask(task, loadingType)({ data in
            if loadingType == .normal || loadingType == .preload_only {
                result?(data)
            }
        })
    }

    public func loadFeedAd(_ args: [String: Any?], result: @escaping FlutterResult) {
        let task = FLTNativeExpressAdTask(args)
        execTask(task)({ data in
            result(data)
        })
    }

    public func loadInterstitialAd(_ args: [String: Any?], result: @escaping FlutterResult) {

//        let task = FLTInterstitialExpressAdTask(args)
//        execTask(task)({ data in
//            result(data)
//        })
        result(FlutterMethodNotImplemented)
    }

    public func loadFullscreenVideoAd(_ args: [String: Any?], result: @escaping FlutterResult) {
        let loadingTypeIndex: Int = args["loadingType"] as! Int
        let loadingType = LoadingType(rawValue: loadingTypeIndex)!

        if loadingType == .preload || loadingType == .normal {
            let success = showFullScreenVideoAd(args)({ [unowned self] object in
                if loadingType == .preload {
                    loadFullscreenVideoAdOnly(args, loadingType: .preload_only)
                }
                result(object)
            })
            if !success {
                loadFullscreenVideoAdOnly(args, loadingType: .normal, result: result)
            }
        } else {
            loadFullscreenVideoAdOnly(args, loadingType: .preload_only, result: result)
        }


    }

    private func loadFullscreenVideoAdOnly(_ args: [String: Any?], loadingType: LoadingType, result: FlutterResult? = nil) {
        let task = FLTFullscreenVideoExpressAdTask(args)
        execTask(task, loadingType)({ data in
            if loadingType == .normal || loadingType == .preload_only {
                result?(data)
            }
        })
    }
}

enum LoadingType: Int {
    case normal
    case preload
    case preload_only
}

extension PangleAdManager {

    public func setExpressAd(_ nativeExpressAdViews: [BUNativeExpressAdView]?) {
        guard let nativeAds = nativeExpressAdViews else {
            return
        }
        var expressAds: [String: BUNativeExpressAdView] = [:]
        for nativeAd in nativeAds {
            expressAds[String(nativeAd.hash)] = nativeAd
        }
        expressAdCollection.merge(expressAds, uniquingKeysWith: { _, last in last })
    }

    public func getExpressAd(_ key: String) -> BUNativeExpressAdView? {
        expressAdCollection[key]
    }

    public func removeExpressAd(_ key: String?) -> Bool {
        if key != nil {
            let value = expressAdCollection.removeValue(forKey: key!)
            return value != nil
        }
        return false
    }

    public func setRewardedVideoAd(_ slotId: String, _ ad: NSObject?) {
        if ad != nil {
            var data = rewardedVideoAdData[slotId] ?? []
            data.append(ad!)
            rewardedVideoAdData[slotId] = data
        }
    }

    public func showRewardedVideoAd(_ args: [String: Any?]) -> (@escaping (Any) -> Void) -> Bool {
        { result in
            let slotId: String = args["slotId"] as! String
            var data = self.rewardedVideoAdData[slotId] ?? []
            if data.count > 0 {
                let obj = data[0]
                if obj is BUNativeExpressRewardedVideoAd {
                    let ad = obj as! BUNativeExpressRewardedVideoAd
                    ad.didReceiveSuccess = { verify in
                        data.removeFirst()
                        self.rewardedVideoAdData[slotId] = data
                        result(["code": 0, "verify": verify] as [String:Any])
                    }
                    ad.didReceiveFail = { error in
                        data.removeFirst()
                        self.rewardedVideoAdData[slotId] = data
                        let e = error as NSError?
                        result(["code": e?.code ?? -1, "message": e?.localizedDescription ?? ""] as [String:Any])
                    }
                    let vc = AppUtil.getVC()
                    ad.show(fromRootViewController: vc)
                    return true
                }
            }

            return false
        }
    }

    public func setFullScreenVideoAd(_ slotId: String, _ ad: NSObject?) {
        if ad != nil {
            var data = fullscreenVideoAdData[slotId] ?? []
            data.append(ad!)
            fullscreenVideoAdData[slotId] = data
        }
    }

    public func showFullScreenVideoAd(_ args: [String: Any?]) -> (@escaping (Any) -> Void) -> Bool {
        { result in
            let slotId: String = args["slotId"] as! String
            var data = self.fullscreenVideoAdData[slotId] ?? []
            if data.count > 0 {
                let obj = data[0]

                if obj is BUNativeExpressFullscreenVideoAd {
                    let ad = obj as! BUNativeExpressFullscreenVideoAd
                    ad.didReceiveSuccess = {
                        data.removeFirst()
                        self.fullscreenVideoAdData[slotId] = data
                        result(["code": 0])
                    }
                    ad.didReceiveFail = { error in
                        data.removeFirst()
                        self.fullscreenVideoAdData[slotId] = data
                        let e = error as NSError?
                        result(["code": e?.code ?? -1, "message": e?.localizedDescription ?? ""] as [String:Any])
                    }
                    let vc = AppUtil.getVC()
                    ad.show(fromRootViewController: vc)
                    return true
                }
            }

            return false
        }
    }
    
}

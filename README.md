# ``CinemagharPlayerSDK``

import CinemagharPlayerSDK

let configuration = VideoPlayerConfiguration()
configuration.authToken = "userAuthToken"
configuration.contentTitle = "contentTitle"
configuration.userUniqueId = "userUniqueId"
configuration.contentId = 12 // contentId

let videoPlayerSDK = VideoPlayerSDK(configuration: configuration)
videoPlayerSDK.delegate = self
videoPlayerSDK.present(from: self, animated: true)

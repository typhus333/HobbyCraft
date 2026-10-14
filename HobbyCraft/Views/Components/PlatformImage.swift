import SwiftUI

#if canImport(UIKit)
import UIKit
public typealias UniversalImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias UniversalImage = NSImage
#endif

public struct PlatformImageView: View {
    public let data: Data?

    public init(data: Data?) {
        self.data = data
    }

    public var body: some View {
        Group {
            #if canImport(UIKit)
            if let data = data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
            #elseif canImport(AppKit)
            if let data = data, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
            #else
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
            #endif
        }
    }
}

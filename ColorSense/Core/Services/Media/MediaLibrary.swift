//
//  MediaLibrary.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import Foundation
import Photos
import UIKit

/// An object that writes photos and movies to the user's Photos library.
actor MediaLibrary {

    // Errors that media library can throw.
    enum Error: Swift.Error {
        case unauthorized
        case saveFailed
    }

    /// An asynchronous stream of thumbnail images the app generates after capturing media.
    let thumbnails: AsyncStream<CGImage?>
    private let continuation: AsyncStream<CGImage?>.Continuation?

    /// Creates a new media library object.
    init() {
        let (thumbnails, continuation) = AsyncStream.makeStream(of: CGImage?.self)
        self.thumbnails = thumbnails
        self.continuation = continuation
    }

    // MARK: - Authorization

    private var isAuthorized: Bool {
        get async {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            /// Determine whether the user has previously authorized `PHPhotoLibrary` access.
            var isAuthorized = status == .authorized
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                // Request authorization to add media to the library.
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                isAuthorized = status == .authorized
            }
            return isAuthorized
        }
    }

    // MARK: - Saving media

    /// Saves a photo to the Photos library.
    func save(photo: Photo) async throws {
        print("MediaLibrary: Saving photo (\(photo.data.count) bytes)")

        try await performChange {
            let creationRequest = PHAssetCreationRequest.forAsset()

            // Save primary photo.
            let options = PHAssetResourceCreationOptions()

            // Verify the photo data is valid
            if let image = UIImage(data: photo.data) {
                print("MediaLibrary: Photo data is valid, dimensions: \(image.size.width) x \(image.size.height)")
            } else {
                print("WARNING: MediaLibrary received invalid photo data!")
            }

            // Specify the appropriate resource type for the photo.
            creationRequest.addResource(with: photo.isProxy ? .photoProxy : .photo, data: photo.data, options: options)

            // Save Live Photo data.
            if let url = photo.livePhotoMovieURL {
                let livePhotoOptions = PHAssetResourceCreationOptions()
                livePhotoOptions.shouldMoveFile = true
                creationRequest.addResource(with: .pairedVideo, fileURL: url, options: livePhotoOptions)
            }

            return creationRequest.placeholderForCreatedAsset
        }

        print("MediaLibrary: Save completed")
    }

    /// Saves a movie to the Photos library.
    func save(movie: Movie) async throws {
        try await performChange {
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .video, fileURL: movie.url, options: options)
            return creationRequest.placeholderForCreatedAsset
        }
    }

    // A template method for writing a change to the user's photo library.
    private func performChange(_ change: @Sendable @escaping () -> PHObjectPlaceholder?) async throws {
        guard await isAuthorized else {
            print("MediaLibrary: Not authorized to save to Photos")
            throw Error.unauthorized
        }

        do {
            var placeholder: PHObjectPlaceholder?
            try await PHPhotoLibrary.shared().performChanges {
                // Execute the change closure.
                print("MediaLibrary: Executing PHAssetCreationRequest")
                placeholder = change()
            }

            print("MediaLibrary: PHPhotoLibrary changes completed")

            if let placeholder {
                /// Retrieve the newly created `PHAsset` instance.
                print("MediaLibrary: Got placeholder, creating thumbnail")
                guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier],
                                                      options: nil).firstObject else {
                    print("MediaLibrary: Failed to fetch asset for thumbnail")
                    return
                }
                await createThumbnail(for: asset)
            } else {
                print("MediaLibrary: No placeholder returned from change closure")
            }
        } catch {
            print("MediaLibrary: Save failed with error: \(error.localizedDescription)")
            throw Error.saveFailed
        }
    }

    func saveFilteredImage(_ image: UIImage) async throws {
        print("MediaLibrary: Saving filtered image directly")

        guard await isAuthorized else {
            print("MediaLibrary: Not authorized to save to Photos")
            throw Error.unauthorized
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                // Create a simple asset creation request
                let request = PHAssetCreationRequest.forAsset()

                // Try to get JPEG data with high quality
                if let imageData = image.jpegData(compressionQuality: 0.95) {
                    let options = PHAssetResourceCreationOptions()
                    options.uniformTypeIdentifier = UTType.jpeg.identifier
                    request.addResource(with: .photo, data: imageData, options: options)
                } else {
                    print("MediaLibrary: Failed to convert image to JPEG data")
                }
            }

            print("MediaLibrary: Direct image save completed")
        } catch {
            print("MediaLibrary: Direct save failed: \(error.localizedDescription)")
            throw Error.saveFailed
        }
    }

    // MARK: - Thumbnail handling

    private func loadInitialThumbnail() async {
        // Only load an initial thumbnail if the user has already authorized the app to write to the Photos library.
        // Deferring this call prevents the app from prompting for Photos authorization when the app starts.
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized else { return }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        if let asset = PHAsset.fetchAssets(with: options).lastObject {
            await createThumbnail(for: asset)
        }
    }

    private func createThumbnail(for asset: PHAsset) async {
        // Request the generation of a 256x256 thumbnail image.
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: .init(width: 256, height: 256),
                                              contentMode: .default,
                                              options: nil) { [weak self] image, _ in
            // Set the latest thumbnail image.
            guard let self, let image = image else { return }
            continuation?.yield(image.cgImage)
        }
    }
}

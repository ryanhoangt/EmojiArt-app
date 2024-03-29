//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by hoang on 27/04/2023.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            scheduleAutosave()
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary();
            }
        }
    }
    
    private var autosaveTimer: Timer?
    
    private func scheduleAutosave() {
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: AutosaveConstants.coalescingInterval, repeats: false) {_ in
            self.autoSave()
        }
    }
    
    private struct AutosaveConstants {
        static let filename = "Autosaved.emojiart"
        static var url: URL? {
            let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDir?.appendingPathComponent(filename)
        }
        static let coalescingInterval = 5.0
    }
    
    private func autoSave() {
        if let url = AutosaveConstants.url {
            save(to: url)
        }
    }
    
    private func save(to url: URL) {
        let thisFunc = "\(String(describing: self)).\(#function)"
        do {
            let data: Data = try emojiArt.json()
            print("\(thisFunc) json = \(String(data: data, encoding: .utf8) ?? "nil")")
            try data.write(to: url)
            print("\(thisFunc) success!")
        } catch let encodingErr where encodingErr is EncodingError {
            print("\(thisFunc) couldn't encode EmojiArt as JSON because \(encodingErr.localizedDescription)")
        } catch {
            print("\(thisFunc) error = \(error)")
        }
    }
    
    init() {
        if let url = AutosaveConstants.url, let autosavedEmojiArt = try? EmojiArtModel(fileUrl: url) {
            emojiArt = autosavedEmojiArt
            fetchBackgroundImageDataIfNecessary()
        } else {
            emojiArt = EmojiArtModel()
            emojiArt.addEmoji("🥰", at: (-200, -100), size: 80)
            emojiArt.addEmoji("🫣", at: (50, 100), size: 40)
            //        emojiArt.addEmoji("", at: (-200, -100), size: 80)
            //        emojiArt.addEmoji("", at: (-200, -100), size: 80)
        }
    }
    
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }
    
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus {
        case idle
        case fetching
    }
    
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch emojiArt.background {
        case .url(let url):
            // Fetch the URL
            backgroundImageFetchStatus = .fetching
            DispatchQueue.global(qos: .userInitiated).async {
                let imageData = try? Data(contentsOf: url)
                DispatchQueue.main.async {[weak self] in
                    // Check the downloaded image is still the one user currently wants
                    if self?.emojiArt.background == EmojiArtModel.Background.url(url) {
                        self?.backgroundImageFetchStatus = .idle
                        if imageData != nil {
                            self?.backgroundImage = UIImage(data: imageData!)
                        }
                    }
                }
            }
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    // MARK: - Intents Functions
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
        print("Background set to \(background)")
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        
    }
    
}


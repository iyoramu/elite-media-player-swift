import SwiftUI
import AVKit
import Combine

// MARK: - Elite Media Player
// Designed to win the world-class media player competition
// Features: Modern UI, Advanced UX, Premium Functionality, Optimal Performance

@main
struct EliteMediaPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Main Player View
struct ContentView: View {
    @StateObject private var playerVM = PlayerViewModel()
    @State private var showPlaylist = false
    @State private var showSettings = false
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    
    private let animationDuration = 0.3
    
    var body: some View {
        ZStack {
            // Background with album art blur
            backgroundView
            
            // Main player interface
            VStack(spacing: 0) {
                // Navigation and info bar
                headerView
                
                // Album art with gestures
                albumArtView
                    .padding(.vertical, 20)
                
                // Track info
                trackInfoView
                    .padding(.bottom, 25)
                
                // Progress bar
                progressView
                    .padding(.bottom, 25)
                
                // Controls
                controlsView
                    .padding(.bottom, 30)
                
                // Bottom bar
                bottomBarView
            }
            .padding(.horizontal, 25)
            .blur(radius: showPlaylist || showSettings ? 10 : 0)
            .disabled(showPlaylist || showSettings)
            
            // Playlist view
            if showPlaylist {
                PlaylistView(playerVM: playerVM, isPresented: $showPlaylist)
                    .transition(.move(edge: .trailing))
            }
            
            // Settings view
            if showSettings {
                SettingsView(isPresented: $showSettings)
                    .transition(.move(edge: .leading))
            }
        }
        .statusBar(hidden: true)
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDragGesture(value: value)
                }
                .onEnded { value in
                    handleDragEnd(value: value)
                }
        )
    }
    
    // MARK: - Subviews
    private var backgroundView: some View {
        Group {
            if let image = playerVM.currentTrack?.artwork {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width)
                    .blur(radius: 50)
                    .opacity(0.7)
                    .animation(.easeInOut(duration: animationDuration), value: playerVM.currentTrack)
            } else {
                LinearGradient(gradient: Gradient(colors: [.black, .purple]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { withAnimation { showSettings.toggle() } }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(playerVM.currentTrack?.artist ?? "Unknown Artist")
                    .font(.system(size: 16, weight: .medium))
                Text(playerVM.playbackSource.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.7)
            }
            
            Spacer()
            
            Button(action: { withAnimation { showPlaylist.toggle() } }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 22))
            }
        }
        .foregroundColor(.white)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    private var albumArtView: some View {
        ZStack {
            if let image = playerVM.currentTrack?.artwork {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                    .rotation3DEffect(
                        .degrees(isDragging ? Double(dragOffset.width) / 10 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .scaleEffect(isDragging ? 0.95 : 1)
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            }
        }
        .frame(height: UIScreen.main.bounds.width * 0.8)
    }
    
    private var trackInfoView: some View {
        VStack(spacing: 8) {
            Text(playerVM.currentTrack?.title ?? "No Track Selected")
                .font(.system(size: 24, weight: .bold))
                .lineLimit(1)
            
            HStack(spacing: 15) {
                Image(systemName: "heart.fill")
                    .foregroundColor(playerVM.isCurrentTrackLiked ? .pink : .white.opacity(0.3))
                    .onTapGesture {
                        playerVM.toggleLike()
                    }
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.white)
                    .onTapGesture {
                        playerVM.addToFavorites()
                    }
                
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.white)
                    .onTapGesture {
                        playerVM.downloadCurrentTrack()
                    }
            }
            .font(.system(size: 22))
        }
        .foregroundColor(.white)
    }
    
    private var progressView: some View {
        VStack(spacing: 5) {
            Slider(value: $playerVM.currentTime, in: 0...playerVM.duration, onEditingChanged: { editing in
                playerVM.isScrubbing = editing
                if !editing {
                    playerVM.seekToCurrentTime()
                }
            })
            .accentColor(.white)
            .disabled(playerVM.currentTrack == nil)
            
            HStack {
                Text(playerVM.formattedTime(playerVM.currentTime))
                    .font(.caption)
                    .monospacedDigit()
                
                Spacer()
                
                Text(playerVM.formattedTime(playerVM.duration))
                    .font(.caption)
                    .monospacedDigit()
            }
            .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var controlsView: some View {
        HStack(spacing: 30) {
            // Previous track
            Button(action: { playerVM.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
            }
            .disabled(playerVM.currentTrackIndex == 0)
            
            // Play/Pause
            Button(action: { playerVM.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.white)
                    
                    Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            
            // Next track
            Button(action: { playerVM.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
            }
            .disabled(playerVM.currentTrackIndex == playerVM.tracks.count - 1)
        }
        .foregroundColor(.white)
    }
    
    private var bottomBarView: some View {
        HStack {
            // AirPlay button
            Button(action: { playerVM.showAirPlayPicker() }) {
                Image(systemName: "airplayaudio")
                    .font(.system(size: 22))
            }
            
            Spacer()
            
            // Playback mode
            Button(action: { playerVM.cyclePlaybackMode() }) {
                Image(systemName: playerVM.playbackMode.systemImage)
                    .font(.system(size: 22))
            }
            
            Spacer()
            
            // EQ
            Button(action: { playerVM.showEqualizer() }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 22))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 30)
    }
    
    // MARK: - Gesture Handlers
    private func handleDragGesture(value: DragGesture.Value) {
        let dragThreshold: CGFloat = 50
        
        if !isDragging && abs(value.translation.width) > dragThreshold {
            isDragging = true
        }
        
        if isDragging {
            dragOffset = value.translation
            
            // Limit drag offset to prevent over-rotation
            let maxOffset: CGFloat = 100
            dragOffset.width = min(max(dragOffset.width, -maxOffset), maxOffset)
        }
    }
    
    private func handleDragEnd(value: DragGesture.Value) {
        let swipeThreshold: CGFloat = 100
        let velocityThreshold: CGFloat = 500
        
        // Calculate velocity (points per second)
        let velocity = value.predictedEndTranslation.width - value.translation.width
        
        if value.translation.width > swipeThreshold || velocity > velocityThreshold {
            playerVM.previousTrack()
        } else if value.translation.width < -swipeThreshold || velocity < -velocityThreshold {
            playerVM.nextTrack()
        }
        
        withAnimation(.spring()) {
            isDragging = false
            dragOffset = .zero
        }
    }
}

// MARK: - ViewModel
class PlayerViewModel: ObservableObject {
    enum PlaybackSource: String {
        case local = "Local Library"
        case streaming = "Premium Streaming"
        case radio = "Internet Radio"
    }
    
    enum PlaybackMode: CaseIterable {
        case normal, repeatOne, shuffle
        
        var systemImage: String {
            switch self {
            case .normal: return "repeat"
            case .repeatOne: return "repeat.1"
            case .shuffle: return "shuffle"
            }
        }
    }
    
    // Player properties
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties
    @Published var tracks: [Track] = []
    @Published var currentTrack: Track?
    @Published var currentTrackIndex = 0
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isScrubbing = false
    @Published var playbackMode: PlaybackMode = .normal
    @Published var playbackSource: PlaybackSource = .streaming
    @Published var isCurrentTrackLiked = false
    
    init() {
        setupMockData()
        setupPlayer()
        setupObservers()
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }
    
    // MARK: - Setup
    private func setupMockData() {
        // In a real app, this would load from a service
        tracks = [
            Track(id: "1", title: "Blinding Lights", artist: "The Weeknd", duration: 203, artwork: UIImage(named: "weeknd") ?? UIImage(), url: URL(string: "https://example.com/track1.mp3")!),
            Track(id: "2", title: "Save Your Tears", artist: "The Weeknd", duration: 215, artwork: UIImage(named: "weeknd") ?? UIImage(), url: URL(string: "https://example.com/track2.mp3")!),
            Track(id: "3", title: "Starboy", artist: "The Weeknd ft. Daft Punk", duration: 230, artwork: UIImage(named: "weeknd") ?? UIImage(), url: URL(string: "https://example.com/track3.mp3")!),
            Track(id: "4", title: "Levitating", artist: "Dua Lipa", duration: 220, artwork: UIImage(named: "dualipa") ?? UIImage(), url: URL(string: "https://example.com/track4.mp3")!),
            Track(id: "5", title: "Don't Start Now", artist: "Dua Lipa", duration: 183, artwork: UIImage(named: "dualipa") ?? UIImage(), url: URL(string: "https://example.com/track5.mp3")!)
        ]
        
        currentTrack = tracks.first
    }
    
    private func setupPlayer() {
        player = AVPlayer()
        player?.automaticallyWaitsToMinimizeStalling = false
        
        // Audio session configuration
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupObservers() {
        // Periodic time observer
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self, !self.isScrubbing else { return }
            self.currentTime = time.seconds
        }
        
        // Track completion observer
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                self?.handleTrackCompletion()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Player Controls
    func togglePlayPause() {
        guard let player = player else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    func playTrack(_ track: Track) {
        guard let index = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        
        currentTrackIndex = index
        currentTrack = track
        isCurrentTrackLiked = false // Reset like state for new track
        
        let playerItem = AVPlayerItem(url: track.url)
        player?.replaceCurrentItem(with: playerItem)
        
        // Observe duration
        playerItem.publisher(for: \.status)
            .filter { $0 == .readyToPlay }
            .sink { [weak self] _ in
                self?.duration = playerItem.asset.duration.seconds
                self?.player?.play()
                self?.isPlaying = true
            }
            .store(in: &cancellables)
    }
    
    func nextTrack() {
        guard !tracks.isEmpty else { return }
        
        switch playbackMode {
        case .normal, .repeatOne:
            let nextIndex = (currentTrackIndex + 1) % tracks.count
            playTrack(tracks[nextIndex])
        case .shuffle:
            let randomIndex = Int.random(in: 0..<tracks.count)
            playTrack(tracks[randomIndex])
        }
    }
    
    func previousTrack() {
        guard !tracks.isEmpty else { return }
        
        if currentTime > 3 {
            // Restart current track if more than 3 seconds in
            seek(to: 0)
        } else {
            switch playbackMode {
            case .normal, .repeatOne:
                let prevIndex = (currentTrackIndex - 1 + tracks.count) % tracks.count
                playTrack(tracks[prevIndex])
            case .shuffle:
                let randomIndex = Int.random(in: 0..<tracks.count)
                playTrack(tracks[randomIndex])
            }
        }
    }
    
    func seekToCurrentTime() {
        seek(to: currentTime)
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func cyclePlaybackMode() {
        let allModes = PlaybackMode.allCases
        guard let currentIndex = allModes.firstIndex(of: playbackMode) else { return }
        let nextIndex = (currentIndex + 1) % allModes.count
        playbackMode = allModes[nextIndex]
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Track Management
    func toggleLike() {
        isCurrentTrackLiked.toggle()
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func addToFavorites() {
        // In a real app, this would save to a favorites list
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func downloadCurrentTrack() {
        // In a real app, this would initiate a download
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Utility
    func formattedTime(_ time: Double) -> String {
        guard !time.isNaN else { return "0:00" }
        
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - System Integration
    func showAirPlayPicker() {
        let rect = CGRect(x: -100, y: 0, width: 0, height: 0)
        let airPlayView = AVRoutePickerView(frame: rect)
        airPlayView.tintColor = .white
        
        if let window = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({ $0 })
            .first?.windows
            .filter({ $0.isKeyWindow }).first {
            
            window.addSubview(airPlayView)
            
            for view in airPlayView.subviews {
                if let button = view as? UIButton {
                    button.sendActions(for: .touchUpInside)
                    DispatchQueue.main.async {
                        airPlayView.removeFromSuperview()
                    }
                    break
                }
            }
        }
    }
    
    func showEqualizer() {
        // In a real app, this would show an equalizer interface
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: - Private Helpers
    private func handleTrackCompletion() {
        switch playbackMode {
        case .normal:
            nextTrack()
        case .repeatOne:
            seek(to: 0)
            player?.play()
        case .shuffle:
            let randomIndex = Int.random(in: 0..<tracks.count)
            playTrack(tracks[randomIndex])
        }
    }
}

// MARK: - Models
struct Track: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let duration: Double // in seconds
    let artwork: UIImage
    let url: URL
}

// MARK: - Playlist View
struct PlaylistView: View {
    @ObservedObject var playerVM: PlayerViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text("Playlist")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { withAnimation { isPresented = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding()
            
            List {
                ForEach(playerVM.tracks) { track in
                    PlaylistRow(track: track, isCurrent: track.id == playerVM.currentTrack?.id)
                        .onTapGesture {
                            playerVM.playTrack(track)
                        }
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .ignoresSafeArea()
        )
    }
}

struct PlaylistRow: View {
    let track: Track
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(uiImage: track.artwork)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: isCurrent ? .bold : .medium))
                    .foregroundColor(isCurrent ? .white : .white.opacity(0.9))
                
                Text(track.artist)
                    .font(.system(size: 14))
                    .foregroundColor(isCurrent ? .white.opacity(0.9) : .white.opacity(0.7))
            }
            
            Spacer()
            
            Text(playerVM.formattedTime(track.duration))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(isCurrent ? Color.white.opacity(0.2) : Color.clear)
        .cornerRadius(10)
    }
    
    private var playerVM: PlayerViewModel {
        // This is a simplified access - in a real app you'd pass the ViewModel or use EnvironmentObject
        PlayerViewModel()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var isPresented: Bool
    
    @State private var volume: Double = 0.8
    @State private var playbackQuality = 1
    @State private var enableLossless = false
    @State private var enableCrossfade = false
    @State private var crossfadeDuration: Double = 5
    @State private var enableSleepTimer = false
    @State private var sleepTimerDuration: Double = 30
    
    let qualityOptions = ["Low", "Normal", "High", "Very High"]
    
    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { withAnimation { isPresented = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding()
            
            Form {
                Section(header: Text("PLAYBACK").foregroundColor(.white.opacity(0.7))) {
                    HStack {
                        Text("Volume")
                        Slider(value: $volume, in: 0...1)
                            .accentColor(.white)
                    }
                    
                    Picker("Quality", selection: $playbackQuality) {
                        ForEach(0..<qualityOptions.count, id: \.self) { index in
                            Text(qualityOptions[index]).tag(index)
                        }
                    }
                    
                    Toggle("Lossless Audio", isOn: $enableLossless)
                    Toggle("Crossfade", isOn: $enableCrossfade)
                    
                    if enableCrossfade {
                        HStack {
                            Text("Duration")
                            Slider(value: $crossfadeDuration, in: 1...10, step: 1)
                                .accentColor(.white)
                            Text("\(Int(crossfadeDuration))s")
                                .frame(width: 30)
                        }
                    }
                }
                
                Section(header: Text("TIMER").foregroundColor(.white.opacity(0.7))) {
                    Toggle("Sleep Timer", isOn: $enableSleepTimer)
                    
                    if enableSleepTimer {
                        Picker("Duration", selection: $sleepTimerDuration) {
                            Text("15 min").tag(15.0)
                            Text("30 min").tag(30.0)
                            Text("45 min").tag(45.0)
                            Text("60 min").tag(60.0)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section {
                    Button(action: {}) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .ignoresSafeArea()
        )
    }
}

// MARK: - Visual Effect View (for Blur)
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}

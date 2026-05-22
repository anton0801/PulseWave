import SwiftUI

// MARK: - Playlists View
struct PlaylistsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreate: Bool = false
    @State private var showHistory: Bool = false
    @State private var showTrackNotes: Bool = false
    @State private var editingPlaylist: PulsePlaylist? = nil
    @State private var appear: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.bgGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Playlists")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                Text("\(appState.playlists.count) collections")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                            Button {
                                showCreate = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.neonPurple.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.neonPurple)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)

                        // Quick navigation
                        HStack(spacing: 12) {
                            Button {
                                showHistory = true
                            } label: {
                                QuickNavPill(icon: "clock.fill", title: "History", color: .neonCyan)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button {
                                showTrackNotes = true
                            } label: {
                                QuickNavPill(icon: "note.text", title: "Track Notes", color: .neonPink)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 18)

                        if appState.playlists.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(appState.playlists) { playlist in
                                    PlaylistCard(
                                        playlist: playlist,
                                        onEdit: { editingPlaylist = playlist },
                                        onDelete: { appState.deletePlaylist(id: playlist.id) }
                                    )
                                }
                            }
                            .padding(.horizontal, 18)
                        }

                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showCreate) { CreatePlaylistView() }
        .sheet(isPresented: $showHistory) { HistoryView() }
        .sheet(isPresented: $showTrackNotes) { TrackNotesView() }
        .sheet(item: $editingPlaylist) { playlist in
            EditPlaylistView(playlist: playlist)
        }
        .onAppear { withAnimation { appear = true } }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.textMuted)
                .padding(.top, 40)
            Text("No playlists yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textSecondary)
            Text("Create your first energy mix")
                .font(.system(size: 14))
                .foregroundColor(.textMuted)
            Button("Create Playlist") { showCreate = true }
                .buttonStyle(NeonButtonStyle(color: .neonPurple))
        }
    }
}

struct QuickNavPill: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        .frame(maxWidth: .infinity)
    }
}

struct WifiErrorVIew: View {
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("wifi_error_waves")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 3)
                    .opacity(0.6)
                
                Image("wifi_error_wavesa")
                    .resizable()
                    .frame(width: 270, height: 230)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Playlist Card
struct PlaylistCard: View {
    let playlist: PulsePlaylist
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        NeonCard(glowColor: playlist.mood.color) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    // Mood icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(playlist.mood.color.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: playlist.mood.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(playlist.mood.color)
                            .shadow(color: playlist.mood.color.opacity(0.5), radius: 6)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(playlist.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textPrimary)
                        HStack(spacing: 8) {
                            Text(playlist.mood.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(playlist.mood.color)
                            Text("·")
                                .foregroundColor(.textMuted)
                            Text("\(playlist.duration) min")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.textSecondary)
                            Text("·")
                                .foregroundColor(.textMuted)
                            Text("\(playlist.tracksCount) tracks")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    // Actions
                    HStack(spacing: 8) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textMuted)
                                .frame(width: 32, height: 32)
                                .background(Color.bgSurface)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.neonPink.opacity(0.8))
                                .frame(width: 32, height: 32)
                                .background(Color.neonPink.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(14)

                // Intensity bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.bgSurface)
                            .frame(height: 3)
                        Rectangle()
                            .fill(playlist.mood.gradient)
                            .frame(width: geo.size.width * playlist.intensity, height: 3)
                    }
                }
                .frame(height: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
        .alert("Delete Playlist?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Create Playlist
struct CreatePlaylistView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var selectedMood: Mood = .focus
    @State private var duration: Double = 30
    @State private var intensity: Double = 0.5
    @State private var selectedGenre: Genre = .electronic
    @State private var showSaved: Bool = false

    var body: some View {
        ZStack {
            LinearGradient.bgGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.textMuted.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 16)

                    Text("Create Playlist")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.textPrimary)

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Playlist Name").labelStyle()
                            TextField("My Playlist", text: $name)
                                .textFieldStyle(NeonTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mood").labelStyle()
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Mood.allCases, id: \.self) { mood in
                                        Button {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                selectedMood = mood
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: mood.icon)
                                                    .font(.system(size: 12))
                                                Text(mood.rawValue)
                                                    .font(.system(size: 13, weight: .semibold))
                                            }
                                            .foregroundColor(selectedMood == mood ? .white : .textMuted)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(selectedMood == mood ? mood.color : Color.bgSurface)
                                            .clipShape(Capsule())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration").labelStyle()
                                Spacer()
                                Text("\(Int(duration)) min").font(.system(size: 13, weight: .bold)).foregroundColor(.neonCyan)
                            }
                            Slider(value: $duration, in: 5...120, step: 5).accentColor(.neonCyan)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Intensity").labelStyle()
                                Spacer()
                                Text(intensityLabel).font(.system(size: 13, weight: .bold)).foregroundColor(.neonOrange)
                            }
                            Slider(value: $intensity, in: 0...1).accentColor(.neonOrange)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Genre").labelStyle()
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(Genre.allCases, id: \.self) { genre in
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedGenre = genre }
                                    } label: {
                                        Text(genre.rawValue)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(selectedGenre == genre ? .white : .textMuted)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 8)
                                            .background(selectedGenre == genre ? Color.neonPurple : Color.bgSurface)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    Button("Create Playlist") {
                        let pName = name.isEmpty ? "\(selectedMood.rawValue) Mix" : name
                        let playlist = PulsePlaylist(
                            name: pName, mood: selectedMood,
                            duration: Int(duration),
                            tracksCount: Int.random(in: 5...20),
                            intensity: intensity, genre: selectedGenre,
                            createdAt: Date(), tracks: []
                        )
                        appState.addPlaylist(playlist)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(NeonButtonStyle(color: selectedMood.color))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var intensityLabel: String {
        switch intensity {
        case 0..<0.33: return "Low"
        case 0.33..<0.66: return "Medium"
        default: return "High"
        }
    }
}

// MARK: - Edit Playlist
struct EditPlaylistView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State var playlist: PulsePlaylist

    var body: some View {
        ZStack {
            LinearGradient.bgGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.textMuted.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 16)

                Text("Edit Playlist")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.textPrimary)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name").labelStyle()
                        TextField("Playlist name", text: $playlist.name)
                            .textFieldStyle(NeonTextFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duration").labelStyle()
                            Spacer()
                            Text("\(playlist.duration) min").font(.system(size: 13, weight: .bold)).foregroundColor(.neonCyan)
                        }
                        Slider(value: Binding(
                            get: { Double(playlist.duration) },
                            set: { playlist.duration = Int($0) }
                        ), in: 5...120, step: 5).accentColor(.neonCyan)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Intensity").labelStyle()
                            Spacer()
                            Text(playlist.intensityLabel).font(.system(size: 13, weight: .bold)).foregroundColor(.neonOrange)
                        }
                        Slider(value: $playlist.intensity, in: 0...1).accentColor(.neonOrange)
                    }
                }
                .padding(.horizontal, 18)

                Button("Save Changes") {
                    appState.updatePlaylist(playlist)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(NeonButtonStyle(color: playlist.mood.color))
                .padding(.horizontal, 18)

                Spacer()
            }
        }
    }
}

// MARK: - Track Notes
struct TrackNotesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showAdd: Bool = false
    @State private var trackName: String = ""
    @State private var moodNote: String = ""
    @State private var rating: Int = 3
    @State private var selectedMood: Mood = .focus

    var body: some View {
        ZStack {
            LinearGradient.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Track Notes")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Button {
                        withAnimation { showAdd.toggle() }
                    } label: {
                        Image(systemName: showAdd ? "xmark" : "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.neonPink)
                            .frame(width: 36, height: 36)
                            .background(Color.bgSurface)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 16)

                if showAdd {
                    addNoteForm
                        .padding(.horizontal, 18)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(appState.trackNotes) { note in
                            TrackNoteCard(note: note) {
                                appState.deleteTrackNote(id: note.id)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var addNoteForm: some View {
        NeonCard(glowColor: .neonPink) {
            VStack(spacing: 14) {
                TextField("Track name", text: $trackName)
                    .textFieldStyle(NeonTextFieldStyle())
                TextField("How does this track make you feel?", text: $moodNote)
                    .textFieldStyle(NeonTextFieldStyle())

                HStack(spacing: 8) {
                    Text("Mood:").font(.system(size: 13, weight: .medium)).foregroundColor(.textMuted)
                    ForEach(Mood.allCases, id: \.self) { mood in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedMood = mood }
                        } label: {
                            Image(systemName: mood.icon)
                                .font(.system(size: 16))
                                .foregroundColor(selectedMood == mood ? mood.color : .textMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                }

                HStack(spacing: 4) {
                    Text("Rating:").font(.system(size: 13, weight: .medium)).foregroundColor(.textMuted)
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            withAnimation { rating = i }
                        } label: {
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .foregroundColor(i <= rating ? .neonOrange : .textMuted)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                }

                Button("Save Note") {
                    guard !trackName.isEmpty else { return }
                    let note = TrackNote(
                        trackName: trackName, moodNote: moodNote,
                        rating: rating, mood: selectedMood, date: Date()
                    )
                    appState.addTrackNote(note)
                    trackName = ""; moodNote = ""; rating = 3
                    withAnimation { showAdd = false }
                }
                .buttonStyle(NeonButtonStyle(color: .neonPink))
                .disabled(trackName.isEmpty)
            }
            .padding(14)
        }
    }
}

struct TrackNoteCard: View {
    let note: TrackNote
    let onDelete: () -> Void

    var body: some View {
        NeonCard(glowColor: note.mood.color) {
            HStack(spacing: 12) {
                Image(systemName: note.mood.icon)
                    .font(.system(size: 18))
                    .foregroundColor(note.mood.color)
                    .frame(width: 36, height: 36)
                    .background(note.mood.color.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(note.trackName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textPrimary)
                    if !note.moodNote.isEmpty {
                        Text(note.moodNote)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textMuted)
                            .lineLimit(2)
                    }
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= note.rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(i <= note.rating ? .neonOrange : .textMuted)
                        }
                    }
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.textMuted)
                        .frame(width: 28, height: 28)
                        .background(Color.bgSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(14)
        }
    }
}

// MARK: - History
struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var filterMood: Mood? = nil
    @State private var filterMode: String = "All"

    var filteredSessions: [RhythmSession] {
        var result = appState.sessions
        if let mood = filterMood { result = result.filter { $0.mood == mood } }
        return result.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            LinearGradient.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Session History")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("\(filteredSessions.count) sessions")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // Mood filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(label: "All", isSelected: filterMood == nil) { filterMood = nil }
                        ForEach(Mood.allCases, id: \.self) { mood in
                            filterChip(label: mood.rawValue, isSelected: filterMood == mood, color: mood.color) {
                                filterMood = filterMood == mood ? nil : mood
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredSessions) { session in
                            HistorySessionCard(session: session)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func filterChip(label: String, isSelected: Bool, color: Color = .neonPurple, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : .textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? color : Color.bgSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HistorySessionCard: View {
    let session: RhythmSession

    var body: some View {
        NeonCard(glowColor: session.mood.color) {
            HStack(spacing: 12) {
                Image(systemName: session.mood.icon)
                    .font(.system(size: 16))
                    .foregroundColor(session.mood.color)
                    .frame(width: 36, height: 36)
                    .background(session.mood.color.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("\(session.genre.rawValue) · \(session.durationText)")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if session.isCompleted {
                        Text("Done")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.neonGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.neonGreen.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Text("+\(Int((session.energyAfter - session.energyBefore) * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(session.energyAfter >= session.energyBefore ? .neonGreen : .neonOrange)
                }
            }
            .padding(14)
        }
    }
}

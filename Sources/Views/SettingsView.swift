import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var repositoryOwner: String = ""
    @State private var repositoryName: String = ""
    @State private var personalAccessToken: String = ""
    @State private var showingTokenField = false
    @State private var isValidating = false
    @State private var validationMessage: String = ""
    @State private var validationSuccess = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                // Repository Configuration
                Group {
                    Text("GitHub Repository")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        TextField("Owner", text: $repositoryOwner)
                            .textFieldStyle(.roundedBorder)
                        Text("/")
                            .foregroundColor(.secondary)
                        TextField("Repository", text: $repositoryName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    if !repositoryOwner.isEmpty && !repositoryName.isEmpty {
                        Text("https://github.com/\(repositoryOwner)/\(repositoryName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Personal Access Token
                Group {
                    HStack {
                        Text("Personal Access Token")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(showingTokenField ? "Hide" : "Show") {
                            showingTokenField.toggle()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    
                    if showingTokenField {
                        SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $personalAccessToken)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        HStack {
                            Text(personalAccessToken.isEmpty ? "Not configured" : "••••••••••••••••••••")
                                .foregroundColor(personalAccessToken.isEmpty ? .red : .green)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    
                    Text("Required scopes: repo, read:discussion, write:discussion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Validation Status
                if !validationMessage.isEmpty {
                    HStack {
                        Image(systemName: validationSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(validationSuccess ? .green : .orange)
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundColor(validationSuccess ? .green : .orange)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 8) {
                Button(action: validateAndSave) {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isValidating ? "Validating..." : "Save Settings")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isValidating || repositoryOwner.isEmpty || repositoryName.isEmpty || personalAccessToken.isEmpty)
                
                Button("Cancel") {
                    loadCurrentSettings()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private func loadCurrentSettings() {
        let settings = settingsManager.settings
        repositoryOwner = settings.repositoryOwner
        repositoryName = settings.repositoryName
        personalAccessToken = settings.personalAccessToken
    }
    
    private func validateAndSave() {
        isValidating = true
        validationMessage = ""
        
        // Create temporary settings for validation
        var newSettings = settingsManager.settings
        newSettings.repositoryOwner = repositoryOwner
        newSettings.repositoryName = repositoryName
        newSettings.personalAccessToken = personalAccessToken
        
        // Save settings immediately
        settingsManager.updateSettings(newSettings)
        
        // Validate with GitHub API
        Task {
            let authService = AuthenticationService(settingsManager: settingsManager)
            await authService.validateToken()
            
            await MainActor.run {
                switch authService.authenticationState {
                case .valid:
                    validationMessage = "Settings saved and validated successfully!"
                    validationSuccess = true
                case .invalid(let error):
                    validationMessage = "Settings saved, but validation failed: \(error.localizedDescription)"
                    validationSuccess = false
                case .notConfigured:
                    validationMessage = "Please fill in all required fields"
                    validationSuccess = false
                default:
                    validationMessage = "Settings saved, but validation is still in progress"
                    validationSuccess = false
                }
                
                isValidating = false
                
                // Clear validation message after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    validationMessage = ""
                }
            }
        }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
}
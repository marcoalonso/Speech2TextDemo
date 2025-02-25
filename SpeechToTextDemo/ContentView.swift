//
//  ContentView.swift
//  SpeechToTextDemo
//
//  Created by Marco Alonso Rodriguez on 25/02/25.
//

import SwiftUI
import Speech
import AVFoundation

// MARK: - Gestor de Reconocimiento de Voz
class SpeechManager: ObservableObject {
    @Published var recognizedText: String = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error al configurar la sesión de audio: \(error.localizedDescription)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("No se pudo crear el recognitionRequest")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("No se pudo iniciar el audioEngine: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }
}

// MARK: - Vista Principal
struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @State private var isRecording = false
    @State private var showSnackbar: Bool = false
    @State private var snackbarMessage: String = ""
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Imagen representativa (se asume que la imagen "micro" está en Assets)
                Image("micro")
                    .resizable()
                    .frame(width: 150, height: 150)
                
                // Área para mostrar el texto reconocido con ScrollView
                ScrollView {
                    Text(speechManager.recognizedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(height: 500)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Botones: uno para grabar/detener y otro para copiar el texto
                HStack(spacing: 16) {
                    Button(action: {
                        isRecording.toggle()
                        if isRecording {
                            speechManager.startRecording()
                        } else {
                            speechManager.stopRecording()
                        }
                    }) {
                        HStack {
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            Text(isRecording ? "Detener" : "Grabar")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(isRecording ? Color.red : Color.green)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Copiar el contenido del texto al portapapeles
                        UIPasteboard.general.string = speechManager.recognizedText
                        showBottomNotification(message: "Texto copiado al portapapeles")
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copiar")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .onAppear {
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    switch authStatus {
                    case .authorized:
                        print("Autorización concedida")
                    case .denied:
                        print("Autorización denegada")
                    case .restricted:
                        print("El reconocimiento de voz está restringido en este dispositivo")
                    case .notDetermined:
                        print("La autorización no se ha determinado")
                    @unknown default:
                        print("Estado desconocido")
                    }
                }
            }
            
            // Vista de notificación (Snackbar) en la parte inferior
            if showSnackbar {
                VStack {
                    Spacer()
                    SnackbarView(message: snackbarMessage)
                        .transition(.move(edge: .bottom))
                        .padding(.bottom, 20)
                }
                .animation(.easeInOut, value: showSnackbar)
            }
        }
    }
    
    // Función para mostrar la notificación tipo Snackbar
    func showBottomNotification(message: String) {
        snackbarMessage = message
        withAnimation {
            showSnackbar = true
        }
        // Ocultar la notificación después de 3 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showSnackbar = false
            }
        }
    }
}

// MARK: - Snackbar View
struct SnackbarView: View {
    var message: String
    
    var body: some View {
        Text(message)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal, 16)
    }
}

#Preview {
    ContentView()
}

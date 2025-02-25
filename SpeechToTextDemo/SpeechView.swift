//
//  SpeechView.swift
//  SpeechToTextDemo
//
//  Created by Marco Alonso Rodriguez on 25/02/25.
//

import SwiftUI
import Speech
import AVFoundation

struct SpeechView: View {
    @State private var isRecording = false
    @State private var recognizedText = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES")) // Cambia el locale según tu idioma
    private let audioEngine = AVAudioEngine()
    
    var body: some View {
        VStack {
            TextField("Texto reconocido", text: $recognizedText)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                if self.isRecording {
                    self.stopRecording()
                } else {
                    self.startRecording()
                }
            }) {
                Text(isRecording ? "Detener grabación" : "Comenzar grabación")
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            self.requestPermissions()
        }
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Permiso de reconocimiento de voz concedido")
            case .denied:
                print("Permiso de reconocimiento de voz denegado")
            case .restricted:
                print("Permiso de reconocimiento de voz restringido")
            case .notDetermined:
                print("Permiso de reconocimiento de voz no determinado")
            @unknown default:
                fatalError("Estado de autorización desconocido")
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Permiso de micrófono concedido")
            } else {
                print("Permiso de micrófono denegado")
            }
        }
    }
    
    private func startRecording() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("El reconocimiento de voz no está disponible")
            return
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        request.shouldReportPartialResults = true
        
        let recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
            } else if let error = error {
                print("Error en el reconocimiento: \(error.localizedDescription)")
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Error al iniciar el motor de audio: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
    }
}



#Preview {
    SpeechView()
}

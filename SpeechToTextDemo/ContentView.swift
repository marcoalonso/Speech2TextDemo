//
//  ContentView.swift
//  SpeechToTextDemo
//
//  Created by Marco Alonso Rodriguez on 25/02/25.
//

import SwiftUI
import Speech
import AVFoundation

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @State private var isRecording = false
    @State private var showSnackbar: Bool = false
    @State private var snackbarMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = "" // Estado para el mensaje de la alerta
    @State private var snackbarOffset: CGFloat = 80
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Imagen representativa
                Image("micro")
                    .resizable()
                    .frame(width: 150, height: 150)
                
                // Área para mostrar el texto reconocido
                ScrollView {
                    Text(speechManager.recognizedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(height: 500)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Botones: grabar/detener y copiar texto
                HStack(spacing: 8) {
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
                    
                    HStack {
                        Button(action: {
                            if speechManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                showAlertWithMessage("Debe grabar para convertir el audio a texto y poder copiarlo al portapapeles.")
                            } else {
                                UIPasteboard.general.string = speechManager.recognizedText
                                Task { await showBottomNotification(message: "Texto copiado al portapapeles") }
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            if speechManager.recognizedText.isEmpty {
                                return
                            } else {
                                speechManager.recognizedText = ""
                                Task { await showBottomNotification(message: "Contenido borrado") }
                            }
                            
                        }) {
                            Image(systemName: "trash")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .onAppear {
                // Solicita autorización para usar el reconocimiento de voz
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    switch authStatus {
                    case .authorized:
                        print("Autorización concedida")
                    case .denied:
                        print("Autorización denegada")
                        showAlertWithMessage("Autorización denegada para usar el reconocimiento de voz. Ajusta las configuraciones de privacidad en tu dispositivo.")
                    case .restricted:
                        print("El reconocimiento de voz está restringido en este dispositivo")
                        showAlertWithMessage("El reconocimiento de voz está restringido en este dispositivo.")
                    case .notDetermined:
                        print("La autorización no se ha determinado")
                    @unknown default:
                        print("Estado desconocido")
                    }
                }
            }
            .alert("Aviso", isPresented: $showAlert) { // Título de la alerta
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage) // Mensaje dinámico de la alerta
            }
            
            // Snackbar animado
            if showSnackbar {
                VStack {
                    Spacer()
                    SnackbarView(message: snackbarMessage)
                        .padding(.bottom, 40)
                        .offset(y: snackbarOffset)
                }
            }
        }
    }
    
    // Función para mostrar la alerta con un mensaje específico
    func showAlertWithMessage(_ message: String) {
        alertMessage = message // Configura el mensaje
        showAlert = true // Muestra la alerta
    }
    
    // Función para mostrar el Snackbar
    @MainActor // Asegura que toda la función se ejecute en el hilo principal
    func showBottomNotification(message: String) async {
        snackbarMessage = message
        snackbarOffset = 80
        showSnackbar = true
        
        // Animación para mostrar el Snackbar
        withAnimation(.easeInOut(duration: 0.5)) {
            snackbarOffset = 0
        }
        
        // Espera 1 segundo antes de ocultar el Snackbar
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
        
        // Animación para ocultar el Snackbar
        withAnimation(.easeInOut(duration: 0.5)) {
            snackbarOffset = 80
        }
        
        // Espera 0.5 segundos antes de desactivar el Snackbar
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
        
        showSnackbar = false
    }
}


#Preview {
    ContentView()
}

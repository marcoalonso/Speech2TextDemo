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
    
    // Instancias de UIImpactFeedbackGenerator para diferentes estilos de vibración
    private let recordHaptic = UIImpactFeedbackGenerator(style: .medium) // Para grabar/detener
    private let copyHaptic = UIImpactFeedbackGenerator(style: .light)    // Para copiar
    private let deleteHaptic = UIImpactFeedbackGenerator(style: .heavy)  // Para borrar
    
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
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
                .frame(height: 400)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Botones: grabar/detener y copiar texto
                HStack(spacing: 8) {
                    CustomButton(
                        iconName: isRecording ? "stop.fill" : "mic.fill",
                        text: isRecording ? "Detener" : "Grabar",
                        backgroundColor: isRecording ? .red : .green,
                        action: {
                            recordHaptic.impactOccurred()
                            isRecording.toggle()
                            if isRecording {
                                speechManager.startRecording()
                            } else {
                                speechManager.stopRecording()
                            }
                        }
                    )
                    
                    HStack {
                        // Botón de copiar
                        CustomButton(
                            iconName: "doc.on.doc",
                            text: nil, // Solo ícono
                            backgroundColor: .blue,
                            action: {
                                if speechManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    showAlertWithMessage("Debe grabar para convertir el audio a texto y poder copiarlo al portapapeles.")
                                    copyHaptic.impactOccurred()
                                } else {
                                    UIPasteboard.general.string = speechManager.recognizedText
                                    Task { await showBottomNotification(message: "Texto copiado al portapapeles") }
                                }
                            }
                        )
                        
                        // Botón de borrar
                        CustomButton(
                            iconName: "trash",
                            text: nil, // Solo ícono
                            backgroundColor: .red,
                            action: {
                                if !speechManager.recognizedText.isEmpty {
                                    speechManager.recognizedText = ""
                                    Task { await showBottomNotification(message: "Contenido borrado") }
                                } else {
                                    showAlertWithMessage("No hay nada que borrar.")
                                    deleteHaptic.impactOccurred()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .onAppear {
                // Solicita autorización para usar el reconocimiento de voz
                requestPermissionSpeech()
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
    
    private func requestPermissionSpeech() {
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

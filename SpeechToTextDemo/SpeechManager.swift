//
//  SpeechManager.swift
//  SpeechToTextDemo
//
//  Created by Marco Alonso Rodriguez on 25/02/25.
//

import Foundation
import Speech
import AVFoundation
// Define una clase `SpeechManager` que maneja el reconocimiento de voz y es observable para actualizar la UI
class SpeechManager: ObservableObject {
    // Publica una propiedad `recognizedText` que almacena el texto reconocido
    @Published var recognizedText: String = ""
    
    // Crea un reconocedor de voz para el idioma español
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))!
    
    // Almacena la solicitud de reconocimiento de voz
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // Almacena la tarea de reconocimiento de voz
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Crea un motor de audio para manejar la grabación
    private let audioEngine = AVAudioEngine()
    
    // Función para iniciar la grabación de voz
    func startRecording() {
        // Si ya hay una tarea de reconocimiento en curso, la cancela
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Obtiene la instancia compartida de la sesión de audio
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Configura la sesión de audio para grabación
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            // Activa la sesión de audio
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Imprime un error si la configuración falla
            print("Error al configurar la sesión de audio: \(error.localizedDescription)")
            return
        }
        
        // Crea una nueva solicitud de reconocimiento de voz
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        // Verifica que la solicitud se haya creado correctamente
        guard let recognitionRequest = recognitionRequest else {
            fatalError("No se pudo crear el recognitionRequest")
        }
        // Configura la solicitud para reportar resultados parciales
        recognitionRequest.shouldReportPartialResults = true
        
        // Obtiene el nodo de entrada del motor de audio
        let inputNode = audioEngine.inputNode
        // Crea una tarea de reconocimiento de voz con la solicitud
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            // Si hay un resultado, actualiza el texto reconocido en el hilo principal
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            // Si hay un error o el resultado es final, detiene la grabación y limpia los recursos
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // Obtiene el formato de grabación del nodo de entrada
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        // Instala un tap en el nodo de entrada para capturar el audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Prepara el motor de audio para la grabación
        audioEngine.prepare()
        do {
            // Inicia el motor de audio
            try audioEngine.start()
        } catch {
            // Imprime un error si no se puede iniciar el motor de audio
            print("No se pudo iniciar el audioEngine: \(error.localizedDescription)")
        }
    }
    
    // Función para detener la grabación de voz
    func stopRecording() {
        // Detiene el motor de audio
        audioEngine.stop()
        // Finaliza la grabación de audio
        recognitionRequest?.endAudio()
    }
}

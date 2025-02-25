//
//  SnackbarView.swift
//  SpeechToTextDemo
//
//  Created by Marco Alonso Rodriguez on 25/02/25.
//

import SwiftUI

struct SnackbarView: View {
    // Mensaje que se mostrará en el Snackbar
    var message: String
    
    // Define el cuerpo de la vista
    var body: some View {
        // Muestra el mensaje en un texto con estilo
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
    SnackbarView(message: "Text copied to clipboard!")
}

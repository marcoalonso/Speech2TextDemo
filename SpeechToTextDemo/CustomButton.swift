//
//  CustomButton.swift
//  SpeechToTextDemo
//
//  Created by Marco Alonso Rodriguez on 25/02/25.
//

import SwiftUI

struct CustomButton: View {
    var iconName: String // Nombre del ícono SF Symbols
    var text: String? // Texto opcional
    var backgroundColor: Color // Color de fondo del botón
    var action: () -> Void // Acción al presionar el botón
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName) // Ícono
                if let text = text { // Texto opcional
                    Text(text)
                }
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(backgroundColor)
            .cornerRadius(10)
        }
    }
}

#Preview {
    CustomButton(iconName: "trash", backgroundColor: Color.red, action: {
        
    })
}

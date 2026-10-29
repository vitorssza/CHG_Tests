//
//  ContentView.swift
//  Nearby_Network
//
//  Created by Vitor Silva Souza on 29/10/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var mode: AppMode = .menu
    
    enum AppMode { case menu, hosting, joining }
    
    var body: some View {
        VStack {
            if viewModel.wordToShow != nil {
                roleRevealView
            } else {
                switch mode {
                case .menu:
                    menuView
                case .hosting:
                    hostView
                case .joining:
                    clientView
                }
            }
        }
        .padding()
        .animation(.easeInOut, value: mode)
        .animation(.easeInOut, value: viewModel.wordToShow)
    }
    
    private var menuView: some View {
        VStack(spacing: 20) {
            
            Button("Criar Partida") {
                mode = .hosting
                viewModel.createRoom()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Entrar em uma partida") {
                mode = .joining
                viewModel.joinRoom()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
        }
    }
    
    private var hostView: some View {
        VStack(spacing: 20) {
            Text("Total de jogadores: \(viewModel.playersInRoom)")
                .font(.title2)
            
            if viewModel.playersInRoom > 0 {
                Button("Começar Partida") {
                    viewModel.startGame()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.large)
            }
                        
            Button("Cancelar") {
                resetGame()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding(.bottom, 10)
        }
    }
    
    private var clientView: some View {
        VStack(spacing: 20) {
                        
            Text("Esperando partida começar")
                .font(.title2)
                .multilineTextAlignment(.center)
                        
            Button("Sair") {
                resetGame()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding(.bottom, 10)
        }
    }
    
    private var roleRevealView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if viewModel.isImpostor {
                Text("VOCÊ É O IMPOSTOR")
                    .font(.largeTitle).bold()
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                Text("A palavra secreta é:")
                    .font(.title2)
                
                Text(viewModel.wordToShow ?? "")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button("Sair da Partida") {
                resetGame()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding(.bottom, 10)
        }
    }
    
    private func resetGame() {
        
        //derruba a rede ativa para não bugar a próxima partida
        viewModel.disconnect()
        
        //cria um modelo limpo
        viewModel = GameViewModel()
        
        mode = .menu
    }
}

#Preview {
    ContentView()
}

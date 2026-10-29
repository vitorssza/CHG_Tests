//
//  Untitled.swift
//  Nearby_Network
//
//  Created by Vitor Silva Souza on 29/10/26.
//

import SwiftUI
import Observation
import Network

@Observable
class GameViewModel {
    private var networkService = GameNetworkService()
    
    var isHost: Bool = false
    var isConnectedAsGuest: Bool = false
    var playersInRoom: Int = 0
    
    var wordToShow: String? = nil
    var isImpostor: Bool = false
    
    private let wordsPool = [
        // Objetos e Tecnologia
        "Celular", "Bicicleta", "Fliperama", "Relógio", "Telescópio",
        "Mochila", "Micro-ondas", "Televisão", "Drone", "Fone de Ouvido",
        "Notebook", "Projetor", "Controle Remoto", "Câmera", "Lanterna",
        "Impressora", "Caixa de Som", "Pen Drive", "Calculadora", "Console",
        "Kindle", "Aspirador Robô", "Bateria Portátil", "Walkie-Talkie", "Óculos VR",

        // Comidas e Bebidas
        "Pizza", "Brigadeiro", "Sushi", "Café", "Pipoca",
        "Churrasco", "Hambúrguer", "Sorvete", "Açaí", "Pastel",
        "Lasanha", "Cerveja", "Vinho", "Pão de Queijo", "Coxinha",
        "Chocolate", "Tacos", "Macarronada", "Salada", "Panqueca",
        "Waffle", "Suco de Laranja", "Milho Cozido", "Croissant", "Cookie",

        // Lugares e Ambientes
        "Cinema", "Aeroporto", "Hospital", "Praia", "Biblioteca",
        "Museu", "Padaria", "Academia", "Cemitério", "Parque de Diversões",
        "Supermercado", "Estádio", "Zoológico", "Hotel", "Castelo",
        "Ilha Deserta", "Cassino", "Boate", "Escola", "Banco",
        "Estação de Trem", "Teatro", "Igreja", "Shopping", "Prisão",

        // Animais
        "Pinguim", "Golfinho", "Tubarão", "Leão", "Coruja",
        "Girafa", "Camaleão", "Bicho-Preguiça", "Dinossauro", "Gato",
        "Cachorro", "Elefante", "Urso Polar", "Canguru", "Polvo",
        "Águia", "Morcego", "Hipopótamo", "Zebra", "Lobo",
        "Cobra", "Flamingo", "Jacaré", "Pavão", "Macaco",

        // Personagens e Cultura Pop
        "Batman", "Harry Potter", "Pikachu", "Shrek", "Darth Vader",
        "Mickey Mouse", "Homem-Aranha", "Coringa", "Mario", "Bob Esponja",
        "Barbie", "Yoda", "Sonic", "Gandalf", "Elsa",
        "Sherlock Holmes", "Goku", "Wolverine", "Capitão América", "Scooby-Doo",
        "Minion", "Buzz Lightyear", "Jack Sparrow", "Wednesday Addams", "Naruto",

        // Profissões e Ocupações
        "Astronauta", "Bombeiro", "Detetive", "Cirurgião", "Piloto",
        "Policial", "Professor", "Mágico", "Juiz", "Arqueólogo",
        "Cozinheiro", "Fotógrafo", "Pintor", "Jardineiro", "Veterinário",
        "Cientista", "Espião", "Mergulhador", "Guarda-Costas", "Barman",

        // Esportes, Hobbies e Lazer
        "Videogame", "Fórmula 1", "Acampamento", "Paraquedismo", "Karaokê",
        "Futebol", "Basquete", "Surfe", "Xadrez", "Skate",
        "Boliche", "Natação", "Tênis", "Escalada", "Paintball",
        "Poker", "Pesca", "Boxe", "Dança de Salão", "Yoga",

        // Meios de Transporte 
        "Submarino", "Helicóptero", "Balão de Ar Quente", "Navio", "Trem",
        "Foguete", "Moto", "Carro de Polícia", "Ambulância", "Caminhão",
        "Trator", "Teleférico", "Patinete", "Carruagem", "Iate",

        // Casa e Itens do Cotidiano
        "Geladeira", "Sofá", "Espelho", "Vassoura", "Guarda-Chuva",
        "Travesseiro", "Chuveiro", "Tapete", "Ferro de Passar", "Abajur",
        "Escova de Dentes", "Chave", "Panela de Pressão", "Tesoura", "Mala",

        // Roupas e Acessórios
        "Tênis", "Chapéu", "Óculos de Sol", "Cachecol", "Gravata",
        "Luvas", "Capa de Chuva", "Bota", "Vestido", "Anel de Noivado",

        // Natureza e Fenômenos
        "Vulcão", "Tornado", "Arco-Íris", "Neve", "Aurora Boreal",
        "Cachoeira", "Caverna", "Deserto", "Tsunami", "Meteoro"
    ]
    
    init() {
        setupNetworkCallbacks()
    }
    
    private func setupNetworkCallbacks() {
        networkService.onClientsUpdated = { [weak self] count in
            self?.playersInRoom = count
            self?.isConnectedAsGuest = true
        }
        
        networkService.onPayloadReceived = { [weak self] payload in
            self?.wordToShow = payload.word
            self?.isImpostor = payload.isImpostor
        }
    }
    
    func createRoom() {
        isHost = true
        networkService.startHosting()
    }
    
    func joinRoom() {
        isHost = false
        networkService.startBrowsing()
    }
    
    func startGame() {
            guard let randomWord = wordsPool.randomElement() else { return }
            
            let clients = networkService.connectedClients
            let totalPlayers = clients.count + 1
            
            let impostorIndex = Int.random(in: 0..<totalPlayers)
            
            self.isImpostor = (impostorIndex == 0)
            self.wordToShow = self.isImpostor ? "Você é o Impostor!" : randomWord
            
            for (index, clientConnection) in clients.enumerated() {
                let isThisClientImpostor = ((index + 1) == impostorIndex)
                let wordToSend = isThisClientImpostor ? "Você é o Impostor!" : randomWord
                let gamePayload = GamePayload(word: wordToSend, isImpostor: isThisClientImpostor)
                
                let message = NetworkMessage(tokenData: nil, gamePayload: gamePayload)
                networkService.sendMessage(message, to: clientConnection)
            }
        }
    
    //encerra o jogo atual
    func disconnect() {
        networkService.stopAll()
    }
}

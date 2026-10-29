//
//  Untitled.swift
//  Nearby_Network
//
//  Created by Vitor Silva Souza on 29/10/26.
//

//import Foundation
//import Network
//import NearbyInteraction
//
//class GameNetworkService: NSObject, NISessionDelegate {
//    private let serviceType = "_undercover._tcp"
//    private let serviceDomain = "local."
//    private let queue = DispatchQueue(label: "com.game.networkQueue")
//    
//    private var listener: NWListener?
//    private(set) var connectedClients: [NWConnection] = []
//    
//    // Gerenciadores do NearbyInteraction
//    private var activeSessions: [NISession: NWConnection] = [:]
//    private var guestSession: NISession?
//    
//    private var browser: NWBrowser?
//    private var hostConnection: NWConnection?
//    
//    var onClientsUpdated: ((Int) -> Void)?
//    var onPayloadReceived: ((GamePayload) -> Void)?
//    var onConnectionRejected: (() -> Void)? // Novo aviso para expulsão
//    
//    func startHosting() {
//        do {
//            listener = try NWListener(using: .tcp)
//            listener?.service = NWListener.Service(name: "Sala Undercover", type: serviceType)
//            listener?.newConnectionHandler = { [weak self] newConnection in
//                self?.handleNewClientConnection(newConnection)
//            }
//            listener?.start(queue: queue)
//        } catch {
//            print("Erro ao iniciar o Host: \(error)")
//        }
//    }
//    
//    private func handleNewClientConnection(_ connection: NWConnection) {
//        connection.stateUpdateHandler = { [weak self] state in
//            guard let self = self else { return }
//            switch state {
//            case .ready:
//                self.receiveData(on: connection)
//                self.startNearbyHandshake(for: connection)
//            case .failed, .cancelled:
//                self.removeConnection(connection)
//            default:
//                break
//            }
//        }
//        connection.start(queue: queue)
//    }
//    
//    func startBrowsing() {
//        browser = NWBrowser(for: .bonjour(type: serviceType, domain: serviceDomain), using: .tcp)
//        browser?.browseResultsChangedHandler = { [weak self] results, _ in
//            guard let self = self, let result = results.first else { return }
//            self.connectToHost(endpoint: result.endpoint)
//            self.browser?.cancel()
//        }
//        browser?.start(queue: queue)
//    }
//    
//    private func connectToHost(endpoint: NWEndpoint) {
//        let connection = NWConnection(to: endpoint, using: .tcp)
//        connection.stateUpdateHandler = { [weak self] state in
//            guard let self = self else { return }
//            if case .ready = state {
//                self.hostConnection = connection
//                self.receiveData(on: connection)
//                
//                // Guest inicia a sua sessão para o Host
//                self.guestSession = NISession()
//                self.guestSession?.delegate = self
//                self.guestSession?.delegateQueue = self.queue
//                
//                self.sendLocalToken(from: self.guestSession, to: connection)
//            }
//        }
//        connection.start(queue: queue)
//    }
//    
//    //logica do Nearby Interaction
//    private func startNearbyHandshake(for connection: NWConnection) {
//        let session = NISession()
//        session.delegate = self
//        session.delegateQueue = queue
//        activeSessions[session] = connection
//        
//        sendLocalToken(from: session, to: connection)
//    }
//    
//    private func sendLocalToken(from session: NISession?, to connection: NWConnection) {
//        guard let token = session?.discoveryToken,
//              let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else { return }
//        
//        let message = NetworkMessage(tokenData: tokenData, gamePayload: nil)
//        sendMessage(message, to: connection)
//    }
//    
//    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
//        guard let peer = nearbyObjects.first, let distance = peer.distance else { return }
//        
//        let connection = activeSessions[session] ?? hostConnection
//        
//        if distance <= 5.0 {
//            if let conn = connection, conn !== hostConnection {
//                //
//                if !connectedClients.contains(where: { $0 === conn }) {
//                    connectedClients.append(conn)
//                    notifyClientsUpdate()
//                }
//            } else if connection === hostConnection {
//                //validando proximidade
//                DispatchQueue.main.async { self.onClientsUpdated?(0) }
//            }
//        } else {
//            //derruba a conexão imediatamente se estiver longe de 5 metros
//            connection?.cancel()
//            session.invalidate()
//            
//            if let conn = connection {
//                removeConnection(conn)
//            }
//            
//            DispatchQueue.main.async {
//                self.onConnectionRejected?()
//            }
//        }
//    }
//        
//    func sendMessage(_ message: NetworkMessage, to connection: NWConnection) {
//        do {
//            let data = try JSONEncoder().encode(message)
//            connection.send(content: data, completion: .contentProcessed({ error in
//                if let error = error { print("Erro ao enviar: \(error)") }
//            }))
//        } catch {
//            print("Erro ao codificar mensagem: \(error)")
//        }
//    }
//    
//    private func receiveData(on connection: NWConnection) {
//        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
//            if let data = data, !data.isEmpty {
//                if let message = try? JSONDecoder().decode(NetworkMessage.self, from: data) {
//                    self?.processMessage(message, from: connection)
//                }
//            }
//            if error == nil && !isComplete {
//                self?.receiveData(on: connection)
//            }
//        }
//    }
//    
//    private func processMessage(_ message: NetworkMessage, from connection: NWConnection) {
//        if let tokenData = message.tokenData {
//            if let peerToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: tokenData) {
//                let config = NINearbyPeerConfiguration(peerToken: peerToken)
//                
//                if let session = activeSessions.first(where: { $0.value === connection })?.key {
//                    session.run(config) //Dono rodando
//                } else if let guestSession = guestSession, connection === hostConnection {
//                    guestSession.run(config) //Convidado rodando
//                }
//            }
//        }
//        
//        //se recebeu a palavra
//        if let gamePayload = message.gamePayload {
//            DispatchQueue.main.async {
//                self.onPayloadReceived?(gamePayload)
//            }
//        }
//    }
//    
//    private func removeConnection(_ connection: NWConnection) {
//        connectedClients.removeAll(where: { $0 === connection })
//        if let session = activeSessions.first(where: { $0.value === connection })?.key {
//            session.invalidate()
//            activeSessions.removeValue(forKey: session)
//        }
//        notifyClientsUpdate()
//    }
//    
//    private func notifyClientsUpdate() {
//        DispatchQueue.main.async {
//            self.onClientsUpdated?(self.connectedClients.count)
//        }
//    }
//    
//    func stopAll() {
//        listener?.cancel()
//        listener = nil
//        browser?.cancel()
//        browser = nil
//        hostConnection?.cancel()
//        hostConnection = nil
//        
//        guestSession?.invalidate()
//        guestSession = nil
//        
//        for session in activeSessions.keys { session.invalidate() }
//        activeSessions.removeAll()
//        
//        for client in connectedClients { client.cancel() }
//        connectedClients.removeAll()
//    }
//}



import Foundation
import Network
import NearbyInteraction

class GameNetworkService: NSObject, NISessionDelegate {
    private let serviceType = "_undercover._tcp"
    private let serviceDomain = "local."
    private let queue = DispatchQueue(label: "com.game.networkQueue")
    
    private var listener: NWListener?
    private(set) var connectedClients: [NWConnection] = []
    
    private var activeSessions: [NISession: NWConnection] = [:]
    private var guestSession: NISession?
    
    private var browser: NWBrowser?
    private var hostConnection: NWConnection?
    
    var onClientsUpdated: ((Int) -> Void)?
    var onPayloadReceived: ((GamePayload) -> Void)?
    var onConnectionRejected: (() -> Void)?
    
    private func createP2PParameters() -> NWParameters {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        return parameters
    }
    
    func startHosting() {
        do {
            listener = try NWListener(using: createP2PParameters())
            listener?.service = NWListener.Service(name: "Sala Undercover", type: serviceType)
            listener?.newConnectionHandler = { [weak self] newConnection in
                self?.handleNewClientConnection(newConnection)
            }
            listener?.start(queue: queue)
        } catch {
            print("Erro ao iniciar o Host: \(error)")
        }
    }
    
    private func handleNewClientConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.receiveData(on: connection)
                self.startNearbyHandshake(for: connection)
            case .failed, .cancelled:
                self.removeConnection(connection)
            default:
                break
            }
        }
        connection.start(queue: queue)
    }
    
    func startBrowsing() {
        browser = NWBrowser(for: .bonjour(type: serviceType, domain: serviceDomain), using: createP2PParameters())
        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self = self, let result = results.first else { return }
            self.connectToHost(endpoint: result.endpoint)
            self.browser?.cancel()
        }
        browser?.start(queue: queue)
    }
    
    private func connectToHost(endpoint: NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: createP2PParameters())
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            if case .ready = state {
                self.hostConnection = connection
                self.receiveData(on: connection)
                
                self.guestSession = NISession()
                self.guestSession?.delegate = self
                self.guestSession?.delegateQueue = self.queue
                
                self.sendLocalToken(from: self.guestSession, to: connection)
            }
        }
        connection.start(queue: queue)
    }
    
    
    private func startNearbyHandshake(for connection: NWConnection) {
        let session = NISession()
        session.delegate = self
        session.delegateQueue = queue
        activeSessions[session] = connection
        
        sendLocalToken(from: session, to: connection)
    }
    
    private func sendLocalToken(from session: NISession?, to connection: NWConnection) {
        guard let token = session?.discoveryToken,
              let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else { return }
        
        let message = NetworkMessage(tokenData: tokenData, gamePayload: nil)
        sendMessage(message, to: connection)
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peer = nearbyObjects.first, let distance = peer.distance else { return }
        
        let connection = activeSessions[session] ?? hostConnection
        
        if distance <= 5.0 {
            if let conn = connection, conn !== hostConnection {
                if !connectedClients.contains(where: { $0 === conn }) {
                    connectedClients.append(conn)
                    notifyClientsUpdate()
                }
            } else if connection === hostConnection {
                DispatchQueue.main.async { self.onClientsUpdated?(0) }
            }
        } else {
            connection?.cancel()
            session.invalidate()
            
            if let conn = connection {
                removeConnection(conn)
            }
            
            DispatchQueue.main.async {
                self.onConnectionRejected?()
            }
        }
    }
    
    
    func sendMessage(_ message: NetworkMessage, to connection: NWConnection) {
        do {
            let data = try JSONEncoder().encode(message)
            connection.send(content: data, completion: .contentProcessed({ error in
                if let error = error { print("Erro ao enviar: \(error)") }
            }))
        } catch {
            print("Erro ao codificar mensagem: \(error)")
        }
    }
    
    private func receiveData(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                if let message = try? JSONDecoder().decode(NetworkMessage.self, from: data) {
                    self?.processMessage(message, from: connection)
                }
            }
            if error == nil && !isComplete {
                self?.receiveData(on: connection)
            }
        }
    }
    
    private func processMessage(_ message: NetworkMessage, from connection: NWConnection) {
        if let tokenData = message.tokenData {
            if let peerToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: tokenData) {
                let config = NINearbyPeerConfiguration(peerToken: peerToken)
                
                if let session = activeSessions.first(where: { $0.value === connection })?.key {
                    session.run(config)
                } else if let guestSession = guestSession, connection === hostConnection {
                    guestSession.run(config)
                }
            }
        }
        
        if let gamePayload = message.gamePayload {
            DispatchQueue.main.async {
                self.onPayloadReceived?(gamePayload)
            }
        }
    }
    
    private func removeConnection(_ connection: NWConnection) {
        connectedClients.removeAll(where: { $0 === connection })
        if let session = activeSessions.first(where: { $0.value === connection })?.key {
            session.invalidate()
            activeSessions.removeValue(forKey: session)
        }
        notifyClientsUpdate()
    }
    
    private func notifyClientsUpdate() {
        DispatchQueue.main.async {
            self.onClientsUpdated?(self.connectedClients.count)
        }
    }
    
    func stopAll() {
        listener?.cancel()
        listener = nil
        browser?.cancel()
        browser = nil
        hostConnection?.cancel()
        hostConnection = nil
        
        guestSession?.invalidate()
        guestSession = nil
        
        for session in activeSessions.keys { session.invalidate() }
        activeSessions.removeAll()
        
        for client in connectedClients { client.cancel() }
        connectedClients.removeAll()
    }
}

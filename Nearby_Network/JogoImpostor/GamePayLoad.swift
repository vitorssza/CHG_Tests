//
//  GamePayLoad.swift
//  Nearby_Network
//
//  Created by Vitor Silva Souza on 29/10/26.
//

import Foundation

struct GamePayload: Codable {
    let word: String
    let isImpostor: Bool
}

struct NetworkMessage: Codable {
    var tokenData: Data?
    var gamePayload: GamePayload?
}

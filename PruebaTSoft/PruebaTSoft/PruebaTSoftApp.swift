//
//  PruebaTSoftApp.swift
//  PruebaTSoft
//
//  Created by IRAN CARRILLO GUZMAN on 14/07/26.
//

import SwiftUI

@main
struct PruebaTSoftApp: App {
    private let container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PokemonListView(
                    viewModel: container.makePokemonListViewModel(),
                    imageLoader: container.imageLoader,
                    fetchPokemonDetailUseCase: container.fetchPokemonDetailUseCase
                )
            }
        }
    }
}

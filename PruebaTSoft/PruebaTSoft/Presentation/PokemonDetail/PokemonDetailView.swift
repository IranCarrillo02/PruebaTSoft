import SwiftUI

struct PokemonDetailView: View {
    @State private var viewModel: PokemonDetailViewModel
    private let imageLoader: ImageLoading

    init(viewModel: PokemonDetailViewModel, imageLoader: ImageLoading) {
        _viewModel = State(initialValue: viewModel)
        self.imageLoader = imageLoader
    }

    var body: some View {
        content
            .navigationTitle(viewModel.pokemon.name)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadIfNeeded()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .error(error):
            ErrorStateView(message: error.errorDescription ?? "") {
                Task { await viewModel.retry() }
            }
        case let .loaded(detail):
            PokemonDetailContentView(detail: detail, imageLoader: imageLoader)
        }
    }
}

private struct PokemonDetailContentView: View {
    let detail: PokemonDetail
    let imageLoader: ImageLoading

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AsyncCachedImage(url: detail.imageURL, imageLoader: imageLoader)
                    .frame(width: 180, height: 180)
                    .accessibilityLabel(detail.name)

                if !detail.types.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(detail.types, id: \.self) { type in
                            TypeBadgeView(type: type)
                        }
                    }
                }

                measurements

                if !detail.abilities.isEmpty {
                    section(title: "Habilidades") {
                        ForEach(detail.abilities, id: \.name) { ability in
                            Text(ability.isHidden ? "\(ability.name) (oculta)" : ability.name)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !detail.stats.isEmpty {
                    section(title: "Estadísticas") {
                        VStack(spacing: 12) {
                            ForEach(detail.stats, id: \.name) { stat in
                                StatBarView(stat: stat)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var measurements: some View {
        HStack(spacing: 32) {
            measurementView(title: "Altura", value: String(format: "%.1f m", detail.heightInMeters))
            measurementView(title: "Peso", value: String(format: "%.1f kg", detail.weightInKilograms))
            if let baseExperience = detail.baseExperience {
                measurementView(title: "Exp. base", value: "\(baseExperience)")
            }
        }
    }

    private func measurementView(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

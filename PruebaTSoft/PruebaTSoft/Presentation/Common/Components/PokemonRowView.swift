import SwiftUI

struct PokemonRowView: View {
    let pokemon: Pokemon
    let imageLoader: ImageLoading

    var body: some View {
        HStack(spacing: 12) {
            AsyncCachedImage(url: pokemon.imageURL, imageLoader: imageLoader)
                .frame(width: 56, height: 56)
                .accessibilityHidden(true)
            Text(pokemon.name)
                .font(.body)
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pokemon.name)
        .accessibilityAddTraits(.isButton)
    }
}

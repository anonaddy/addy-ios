
import SwiftUI

struct AliasNatoView: View {
    let alias: String
    @Binding var isPresented: Bool

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        let isLandscape = verticalSizeClass == .compact || horizontalSizeClass == .regular
        let natoList = alias.map { NatoAlphabet.getWord($0) }

        if isLandscape {
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                        ForEach(0..<natoList.count) { index in
                            let item = natoList[index]
                            VStack {
                                Text(String(item.character))
                                    .font(.system(size: 80, weight: .bold))
                                Text(item.word)
                                    .font(.title)
                            }
                            .frame(width: 200, height: 200)
                            .background(index % 2 == 0 ? Color.gray.opacity(0.2) : Color.clear)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemBackground))
                .ignoresSafeArea()

                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .padding()
                }
            }
        } else {
            NavigationView {
                List {
                    ForEach(0..<natoList.count) { index in
                        let item = natoList[index]
                        HStack {
                            Text(String(item.character))
                                .font(.headline)
                                .frame(width: 48)
                            Text(item.word)
                                .font(.body)
                        }
                    }
                }
                .navigationBarTitle(Text("Phonetic Alphabet"), displayMode: .inline)
                .navigationBarItems(trailing: Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                })
            }
        }
    }
}

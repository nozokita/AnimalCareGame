import SwiftUI

struct AnimalCreationView: View {
    @ObservedObject var viewModel: AnimalCareViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var animalName = ""
    @State private var selectedType: AnimalType = .dog
    
    var body: some View {
        NavigationView {
            Form {
                // 名前入力
                Section(header: Text("名前")) {
                    TextField("動物の名前を入力", text: $animalName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // 動物の種類選択
                Section(header: Text("種類")) {
                    Picker("動物の種類", selection: $selectedType) {
                        ForEach(AnimalType.allCases) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(.accentColor)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                // プレビュー
                Section(header: Text("プレビュー")) {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Image(systemName: selectedType.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.accentColor)
                            
                            Text(animalName.isEmpty ? "名前なし" : animalName)
                                .font(.headline)
                            
                            Text(selectedType.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                // 作成ボタン
                Section {
                    Button(action: createAnimal) {
                        Text("作成する")
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .disabled(animalName.isEmpty)
                }
            }
            .navigationTitle("新しい動物")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    dismiss()
                }
            )
        }
    }
    
    // 動物を作成
    private func createAnimal() {
        guard !animalName.isEmpty else { return }
        
        viewModel.createAnimal(name: animalName, type: selectedType)
        dismiss()
    }
} 
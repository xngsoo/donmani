import Core
import SwiftUI
import UI

public struct RecordEditView: View {
    @State private var viewModel: RecordEditViewModel
    @State private var isConfirmingDelete = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAmountFocused: Bool
    private let onSaved: () -> Void

    public init(viewModel: RecordEditViewModel, onSaved: @escaping () -> Void = {}) {
        _viewModel = State(wrappedValue: viewModel)
        self.onSaved = onSaved
    }

    public var body: some View {
        Form {
            Section("금액") {
                HStack {
                    TextField("0", text: $viewModel.amountText)
                        .keyboardType(.numberPad)
                        .focused($isAmountFocused)
                        .font(DMFont.amount)
                        .monospacedDigit()
                    Text("원")
                        .font(DMFont.headline)
                        .foregroundStyle(DMColor.secondaryText)
                }
            }

            Section("카테고리") {
                Picker("카테고리", selection: $viewModel.category) {
                    ForEach(RecordCategory.allCases, id: \.self) { category in
                        Label {
                            Text(category.displayName)
                        } icon: {
                            Image(systemName: CategoryStyle.symbol(for: category))
                                .foregroundStyle(CategoryStyle.color(for: category))
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("시간") {
                DatePicker("지출 시각", selection: $viewModel.spentAt)
                    .datePickerStyle(.compact)
            }

            Section("메모") {
                TextField("메모 (선택)", text: $viewModel.memo, axis: .vertical)
                    .lineLimit(1 ... 3)
            }

            if let message = viewModel.errorMessage {
                Section {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(DMFont.caption)
                        .foregroundStyle(DMColor.danger)
                }
            }

            if viewModel.isEditing {
                Section {
                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("이 기록 삭제", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    guard viewModel.save() else { return }
                    onSaved()
                    dismiss()
                }
                .disabled(!viewModel.canSave)
            }
        }
        .confirmationDialog("이 기록을 삭제할까요?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                guard viewModel.delete() else { return }
                onSaved()
                dismiss()
            }
            Button("취소", role: .cancel) {}
        }
        .onAppear { isAmountFocused = !viewModel.isEditing }
    }
}

#Preview("추가") {
    NavigationStack {
        RecordEditView(
            viewModel: RecordEditViewModel(
                repository: PreviewFactory.repository(seeded: false),
                mode: .create(on: .now)
            )
        )
    }
}

#Preview("수정") {
    let repository = PreviewFactory.repository(seeded: true)
    let existing = try? repository.fetchAll().first

    return NavigationStack {
        if let existing {
            RecordEditView(
                viewModel: RecordEditViewModel(repository: repository, mode: .edit(existing.persistentModelID))
            )
        } else {
            Text("프리뷰 데이터를 만들지 못했어요.")
        }
    }
}

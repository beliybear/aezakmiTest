//
//  HistoryView.swift
//  testAezakmi
//
//  Created by BeliyBear on 02/02/2026.
//

import SwiftUI

struct HistoryView: View {

    @ObservedObject var services: ServicesHolder
    @StateObject private var viewModel: HistoryViewModel

    init(services: ServicesHolder) {
        self.services = services
        _viewModel = StateObject(wrappedValue: HistoryViewModel(services: services))
    }

    private static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        f.locale = Locale(identifier: "ru_RU")
        return f
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    filterBar

                    if viewModel.sessions.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 44))
                                .foregroundStyle(.tertiary)
                            Text("Нет сеансов сканирования")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Запустите сканирование на вкладке «Сканирование»")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(viewModel.sessions) { session in
                                NavigationLink(destination: SessionDetailView(sessionId: session.id, viewModel: viewModel)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(Self.dateFormatter.string(from: session.date))
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text("Устройств: \(session.deviceCount)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if session.id != viewModel.sessions.last?.id {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.load() }
        }
        .navigationViewStyle(.stack)
    }

    private var filterBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.body)
                TextField("Имя устройства", text: $viewModel.nameFilter)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemFill)))
                    .autocapitalization(.none)
                    .onSubmit { viewModel.load() }
                    .overlay(alignment: .trailing) {
                        if !viewModel.nameFilter.isEmpty {
                            Button(action: {
                                viewModel.nameFilter = ""
                                viewModel.load()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.trailing, 12)
                        }
                    }
            }
            HStack(spacing: 16) {
                DatePicker("С", selection: Binding(
                    get: { viewModel.dateFrom ?? Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() },
                    set: { viewModel.dateFrom = $0; viewModel.load() }
                ), displayedComponents: .date)
                .labelsHidden()
                Text("–")
                    .foregroundStyle(.secondary)
                DatePicker("По", selection: Binding(
                    get: { viewModel.dateTo ?? Date() },
                    set: { viewModel.dateTo = $0; viewModel.load() }
                ), displayedComponents: .date)
                .labelsHidden()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

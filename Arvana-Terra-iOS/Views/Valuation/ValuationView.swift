import SwiftUI
import Charts

struct ValuationView: View {
    @StateObject private var vm = ValuationViewModel()
    @State private var showCalculate = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("評価履歴").tag(0)
                Text("シミュレーション").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(12)
            .background(Color.surfaceWhite)

            if selectedTab == 0 {
                valuationHistoryView
            } else {
                valuationCalculatorView
            }
        }
        .navigationTitle("資産評価")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.fetchValuations() }
    }

    private var valuationHistoryView: some View {
        Group {
            if vm.isLoading && vm.valuations.isEmpty {
                LoadingView()
            } else if vm.valuations.isEmpty {
                EmptyStateView(
                    title: "評価履歴なし",
                    message: "シミュレーションで評価額を計算してください",
                    systemImage: "chart.bar.fill",
                    actionTitle: "シミュレーション開始",
                    action: { selectedTab = 1 }
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Chart
                        if vm.valuations.count > 1 {
                            ValuationChart(valuations: vm.valuations)
                        }

                        // List
                        ForEach(vm.valuations) { val in
                            ValuationCard(valuation: val, vm: vm)
                        }
                    }
                    .padding(16)
                }
                .background(Color.backgroundGray)
            }
        }
    }

    private var valuationCalculatorView: some View {
        ValuationCalculatorView(vm: vm)
    }
}

struct ValuationChart: View {
    let valuations: [AssetValuation]

    var chartData: [(Date, Double)] {
        let fmt = ISO8601DateFormatter()
        return valuations.compactMap { val in
            guard let date = fmt.date(from: val.valuationDate) else { return nil }
            return (date, val.estimatedValue)
        }.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("評価額推移")
                .font(.headline).foregroundColor(.textDark)

            Chart {
                ForEach(chartData, id: \.0) { item in
                    LineMark(
                        x: .value("日付", item.0),
                        y: .value("評価額", item.1)
                    )
                    .foregroundStyle(Color.primaryNavy)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("日付", item.0),
                        y: .value("評価額", item.1)
                    )
                    .foregroundStyle(Color.primaryNavy.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text(formatChartValue(amount))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func formatChartValue(_ value: Double) -> String {
        if value >= 100_000_000 { return String(format: "%.0f億", value / 100_000_000) }
        if value >= 10_000 { return String(format: "%.0f万", value / 10_000) }
        return "\(Int(value))"
    }
}

struct ValuationCard: View {
    let valuation: AssetValuation
    @ObservedObject var vm: ValuationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("評価額").font(.caption).foregroundColor(.textGray)
                    Text(vm.formatCurrency(valuation.estimatedValue))
                        .font(.title2).fontWeight(.bold).foregroundColor(.primaryNavy)
                }
                Spacer()
                Text(formatDate(valuation.valuationDate))
                    .font(.caption).foregroundColor(.textGray)
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                if let market = valuation.marketValue {
                    ValuationMetric(label: "市場価格", value: vm.formatCurrency(market))
                }
                if let income = valuation.incomeApproach {
                    ValuationMetric(label: "収益還元", value: vm.formatCurrency(income))
                }
                if let cost = valuation.costApproach {
                    ValuationMetric(label: "原価法", value: vm.formatCurrency(cost))
                }
            }

            if let appraiser = valuation.appraiserName {
                Label("鑑定人: \(appraiser)", systemImage: "person.fill")
                    .font(.caption).foregroundColor(.textGray)
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func formatDate(_ dateString: String) -> String {
        let fmt = ISO8601DateFormatter()
        guard let date = fmt.date(from: dateString) else { return dateString }
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }
}

struct ValuationMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.textGray)
            Text(value).font(.caption).fontWeight(.semibold).foregroundColor(.textDark)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundGray)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct ValuationCalculatorView: View {
    @ObservedObject var vm: ValuationViewModel

    @State private var area = ""
    @State private var location = ""
    @State private var buildingType = "apartment"
    @State private var yearBuilt = ""
    @State private var condition = "good"

    let buildingTypes = [("apartment","マンション"), ("house","一戸建て"), ("office","オフィス"), ("land","土地")]
    let conditions = [("excellent","優"), ("good","良"), ("fair","普通"), ("poor","劣")]

    var isValid: Bool { !area.isEmpty && !location.isEmpty && Double(area) != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input form
                VStack(alignment: .leading, spacing: 16) {
                    Text("評価条件を入力")
                        .font(.headline).foregroundColor(.textDark)

                    VStack(spacing: 12) {
                        InputField(label: "面積 (㎡)", text: $area, keyboardType: .decimalPad)
                        InputField(label: "所在地", text: $location, keyboardType: .default)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("建物種別").font(.caption).fontWeight(.semibold).foregroundColor(.textGray)
                            Picker("建物種別", selection: $buildingType) {
                                ForEach(buildingTypes, id: \.0) { Text($0.1).tag($0.0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        InputField(label: "築年数 (任意)", text: $yearBuilt, keyboardType: .numberPad)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("状態").font(.caption).fontWeight(.semibold).foregroundColor(.textGray)
                            Picker("状態", selection: $condition) {
                                ForEach(conditions, id: \.0) { Text($0.1).tag($0.0) }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: {
                    Task {
                        await vm.calculateValuation(
                            propertyId: nil, landId: nil,
                            area: Double(area) ?? 0,
                            location: location,
                            buildingType: buildingType,
                            yearBuilt: Int(yearBuilt),
                            condition: condition
                        )
                    }
                }) {
                    HStack {
                        if vm.isCalculating {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("計算中...").foregroundColor(.white)
                        } else {
                            Label("評価額を計算", systemImage: "chart.bar.fill")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValid ? Color.primaryNavy : Color.textGray.opacity(0.4))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isValid || vm.isCalculating)

                // Result
                if let result = vm.calculationResult {
                    ValuationResultView(result: result, vm: vm)
                }
            }
            .padding(16)
        }
        .background(Color.backgroundGray)
    }
}

struct InputField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).fontWeight(.semibold).foregroundColor(.textGray)
            TextField(label, text: $text)
                .keyboardType(keyboardType)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Color.backgroundGray)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ValuationResultView: View {
    let result: CalculateValuationResponse
    @ObservedObject var vm: ValuationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("評価結果")
                    .font(.headline).foregroundColor(.textDark)
                Spacer()
                Text(vm.confidenceLabel(result.confidence))
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(vm.confidenceColor(result.confidence))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(vm.confidenceColor(result.confidence).opacity(0.12))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("推定評価額").font(.subheadline).foregroundColor(.textGray)
                Text(vm.formatCurrency(result.estimatedValue))
                    .font(.system(size: 36, weight: .bold)).foregroundColor(.primaryNavy)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primaryNavy.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ValuationMetric(label: "市場価格", value: vm.formatCurrency(result.marketValue))
                if let income = result.incomeApproach {
                    ValuationMetric(label: "収益還元", value: vm.formatCurrency(income))
                }
                if let cost = result.costApproach {
                    ValuationMetric(label: "原価法", value: vm.formatCurrency(cost))
                }
            }

            if !result.factors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("価格影響要因").font(.subheadline).fontWeight(.semibold).foregroundColor(.textGray)
                    ForEach(Array(result.factors.keys.sorted()), id: \.self) { key in
                        if let value = result.factors[key] {
                            HStack {
                                Text(key).font(.caption).foregroundColor(.textDark)
                                Spacer()
                                Text(String(format: "%+.1f%%", value))
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundColor(value >= 0 ? .successGreen : .errorRed)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

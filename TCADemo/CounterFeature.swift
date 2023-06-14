//
//  CounterFeature.swift
//  TCADemo
//
//  Created by 이원빈 on 2023/06/13.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Feature

struct CounterFeature: ReducerProtocol {
    struct State {
        var count = 0
        var fact: String?
        var isLoading = false
        var isTimerRunning = false
    }
    
    enum Action {
        case decrementButtonTapped
        case incrementButtonTapped
        case factButtonTapped
        case factResponse(String)
        case toggleTimerButtonTapped
        case timerTick
    }
    
    enum CancelID { case timer }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.numberFact) var numberFact
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .decrementButtonTapped:
            state.count -= 1
            state.fact = nil
            return .none
            
        case .factButtonTapped:
            state.fact = nil
            state.isLoading = true
            
            return .run { [count = state.count] send in
                try await send(.factResponse(self.numberFact.fetch(count)))
//                do {
////                    let (data, _) = try await URLSession.shared
////                        .data(from: URL(string: "http://numbersapi.com/\(count)")!)
////                    let fact = String(decoding: data, as: UTF8.self)
////                    try await Task.sleep(for: .seconds(2))
//                    try await clock.sleep(for: .seconds(2))
//                    await send(.factResponse("네트워킹 한 척"))
//                } catch {
//                    let fact = "네트워킹 실패"
//                    await send(.factResponse(fact))
//                }
            } catch: { error, action in
                print(error.localizedDescription)
            }
            
        case .factResponse(let fact):
            state.fact = fact
            state.isLoading = false
            return .none
            
        case .incrementButtonTapped:
            state.count += 1
            state.fact = nil
            return .none
            
        case .toggleTimerButtonTapped:
            state.isTimerRunning.toggle()
            if state.isTimerRunning {
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
//                    while true {
//                        try await Task.sleep(for: .seconds(1))
//                        await send(.timerTick)
//                    }
                }
                .cancellable(id: CancelID.timer)
            } else {
                return .cancel(id: CancelID.timer)
            }
        case .timerTick:
            state.count += 1
            state.fact = nil
            return .none
        }
    }
}

extension CounterFeature.State: Equatable {}
extension CounterFeature.Action: Equatable {}

// MARK: - View

struct ContentView: View {
    let store: StoreOf<CounterFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                Text("\(viewStore.count)")
                    .font(.largeTitle)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(3)
                HStack {
                    Button("-") {
                        viewStore.send(.decrementButtonTapped)
                    }
                    .font(.largeTitle)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(3)
                    
                    Button("+") {
                        viewStore.send(.incrementButtonTapped)
                    }
                    .font(.largeTitle)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(3)
                }
                Button(viewStore.isTimerRunning ? "Stop timer" : "Start timer") {
                    viewStore.send(.toggleTimerButtonTapped)
                }
                .font(.largeTitle)
                .padding()
                .cornerRadius(10)
                
                Button("Fact") {
                    viewStore.send(.factButtonTapped)
                }
                .font(.largeTitle)
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
                
                if viewStore.isLoading {
                    ProgressView()
                } else if let fact = viewStore.fact {
                    Text(fact)
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(initialState: CounterFeature.State()) {
                CounterFeature()
            }
        )
    }
}

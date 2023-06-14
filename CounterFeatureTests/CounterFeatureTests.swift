//
//  CounterFeatureTests.swift
//  CounterFeatureTests
//
//  Created by 이원빈 on 2023/06/13.
//

@testable import TCADemo
import ComposableArchitecture
import XCTest

@MainActor
final class CounterFeatureTests: XCTestCase {

    func testCounter() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }
        
        await store.send(.incrementButtonTapped) {
            // TODO: Action 이 보내지기 전에 count 를 변경하여 state 를 같도록 만들어 주면 통과
            // $0.count += 1 [relative](👎)    $0.count = 1 [absolute](✅)
            $0.count = 1
        }
        await store.send(.decrementButtonTapped) {
            $0.count = 0
        }
    }
    
    func testTimer() async {
        let clock = TestClock()
        
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerRunning = true
        }
        
        // TestStore 은 effects를 포함하여 전체 feature가 시간을 넘어서 진행되는 것에 가정하도록 강제하기 때문에 오류가 발생하는 것이다.
        // 이럴 땐 테스트가 끝나기 전에 모든 이펙트를 끝내도록 강제한다. 그래서 $0.isTimerRunning = false 인 상태가 결과로 나올 것이다.
        
//        await store.receive(.timerTick, timeout: 200000000) { // 2초
//            $0.count = 1
//        }
        // 위처럼 테스트를 진행하면 시간이 오래 걸리게 되서 좋지않다. -> Clock 을 이용해보자.
        
        // 시계를 조정해서 1초가 지나가게 마음대로 만든다. 실제로 1초를 기다리지 않아도 된다.
        await clock.advance(by: .seconds(1))
        
        await store.receive(.timerTick) {
            $0.count = 1
        }
        
        
        
        // 사용자가 버튼을 두번 눌렀다고 가정하고 테스트를 하면 정상적으로 통과할 것이다.
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerRunning = false
        }
    }
    
    func testNumberFact() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.numberFact.fetch = { "\($0) is a good number." }
        }
        
        await store.send(.factButtonTapped) {
            $0.isLoading = true
        }
        
        await store.receive(.factResponse("0 is a good number."), timeout: .seconds(1)) { // timeout 으로 기다려줄 필요도 없다.
            $0.isLoading = false
            $0.fact = "0 is a good number."
        }
    }
}

extension UInt64 {
    static func seconds(_ number: UInt64) -> Self {
        return number * UInt64(1000000000)
    }
}

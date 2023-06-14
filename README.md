# TCADemo
The Composable Architecture 학습 저장소 입니다. 

> 아래 글은 링크한 학습자료를 보고 정리한 내용입니다. 

## ▼ Your first feature

### ReducerProtocol

가장 먼저 기본이 되는 유닛인 `ReducerProtocol` 이 소개됩니다. `ReducerProtocol` 에는 액션이 시스템으로 보내졌을 때, 현재 상태를 다음 상태로 어떻게 진행 시키는지를 포함하고 있습니다. 또한, 가장 중요한 것은 기능의 코어 로직과 행위가 SwiftUI view로부터 완전히 독립적으로 설계될 수 있고 재사용, 테스트에 용이하다는 것입니다. 

ReducerProtocol 을 채택한 CounterFeature 구조체에 대해 설명합니다. 내부에는 상태를 나타내는 (보통 구조체로 구현) State , 행위를 나타내는 (보통 enum 구현) Action 이 존재합니다. Action 내의 case 네이밍은 사용자가 UI에서 하는 행동을 묘사하는 네이밍이 좋습니다. 
ex) decrementButtonTapped(O) / decrementCount(X)

ReducerProtocol을 채택한 객체는 항상 `reduce(into:, action:)` 메서드 내부를 구현해주어야 합니다. 
reduce 메서드는 `EffectTask<Action>` 타입을 반환하는데, 이는 바깥에서 실행되어야 하는 이펙트를 나타냅니다. 예시와 같이 아무것도 실행해줄 필요가 없을 땐 `.none` 을 반환해줍니다. 

### Integrating with SwiftUI

이제 우리는 reducer 로써 설계된 기본적인 기능을 가졌고, 어떻게 이 기능을 SwifUI 에 공급하는지 알아낼겁니다. 
- Store : 기능의 런타임을 나타냅니다. 
- ViewStore : 런타임 구독을 나타냅니다. 

ContentView 를 만듭니다. 이제 이 안에 store 상수를 생성합니다. Store 는 기능의 런타입을 나타냅니다. 즉, 상태를 업데이트 하기위해 액션을 수행할 수 있고, effects를 실행할 수 있고 이 effect로 인한 데이터를 다시 시스템에 제공할 수 있는 객체입니다.

뷰 뼈대를 가지고 이제 실제로 Store 에서 상태를 구독할 수 있습니다. 이는 ViewStore를 만들어서 구현할 수 있고, SwiftUI에서는 ViewStore를 간단하게 만들 수 있습니다. `WithViewStore` 를 호출해서 간단한 문법으로 View Store 를 구성할 수 있습니다.

View Store 는 State 가 Equatable 하기를 요구합니다. 이제 WithViewStore 문법으로 viewStore 를 생성하고 해당 클로저 내에서 viewStore 프로퍼티를 이용해 `.send()` 를 통해 action 을 수행해줄 수도 있고, 내부 State 값으로 접근할 수도 있습니다. 

### Integrating into the app

Entry point를 변경함으로써 완전한 앱에서 기능을 어떻게 실행하는지 알아낼 필요가 있습니다. 

기본적으로, 앱의 진입지점은 아마도 땡땡땡App.swift 파일에 존재할 것입니다. 여기에 아까 만들어 주었던 ContentView 를 생성해주면 됩니다. 
중요한 점 ) Store 객체는 한번만 생성되어야 합니다. 보통 WindowGroup 안의 root 에서 직접 생성합니다.  또한 static let 으로 생성해서 제공하기도 합니다. 

```swift
import SwiftUI
import ComposableArchitecture

@main
struct TCADemoApp: App {
    static let store = Store(initialState: CounterFeature.State()) {
        CounterFeature()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: TCADemoApp.store)
        }
    }
}

```

## ▼ Adding side effects

### 사이드이펙트란 무엇인가?

effects는 외부요인에 영향받을 가능성이 큽니다. 예를들면 네트워크 연결상태, 디스크 접근권한, 등등이 있죠. 이펙트를 실행할 때마다 다른 답이 돌아올 것입니다. 

액션에 비동기 처리가 필요한 네트워킹 요청을 보내볼겁니다. 

### Performing a network request

EffectTask 타입에서 `run(priority:operation:catch:fileID:line:)` static 메서드로 비동기 작업을 만들어줄 수 있습니다. 


## ▼ Testing your feature
> 만든 feature 를 테스트하는 방법에 대해 알아봅시다.

### Testing state changes

TCA 에서 테스트가 필요한 기능은 오직 reducer 입니다. 

테스트 해볼 항목 2가지
- Action 이 send 되었을 때 상태가 어떻게 변하는지에 대해 (비교적 쉽다.)
- Effect 가 어떻게 실행되는지, 그들의 data 가 어떻게 다시 reducer 로 들어가는지

TestStore 를 이용해서 쉽게 테스트 할 수 있습니다. 

### Testing effects

이전까지 Action 으로 인해 State 가 변하는 것을 테스트 해봤습니다. 이젠 두번째 단계인 Effect에 대한 테스트를 진행 해보겠습니다. 

Task.sleep 을 이용하는 것은 좋지 않습니다. 대신 continuousClock 을 이용할 수 있습니다. 

TestCase 에서는 TestClock 을 생성해서 reducer에 의존성주입을 해주어 사용 가능합니다. 

### Testing network requests

> 네트워크 요청은 아마 앱에서 가장 흔한 사이드 이펙트일 것입니다. 네트워크 요청기능에 대한 테스트는 느릴 수 있고, 네트워크 연결상태나 서버에 의존할 것입니다. 그리고 서버로부터 받아오는 데이터가 어떤 종류인지 예측할 방법이 없습니다.

타이머와 마찬가지로 테스트함수가 끝나는 시점에 해당 액션이 끝나지 않아 예측한 isLoading = true 와 실제 상태가 맞지 않게 됩니다. 즉, Assert 가 실패합니다. 네트워킹 시간을 기다려준다고 하더라도. 요청마다 응답이 다를 수 있고, 인터넷 연결 때문에 시간이 오래 걸릴 것입니다. 

### Controlling dependencies

> 우리의 코드상 제어 불가능한 의존성을 사용하는 데에 문제가 있습니다. 이것은 우리의 코드를 테스트하기 힘들게 만들고, 시간이 오래걸리게 만들 수 있습니다. 이러한 이유로, 외부 시스템에서 의존성을 제어하는 것이 강력히 권장됩니다. TCA 는 의존성을 제어, 전파할 수 있도록 완벽한 세트의 툴을 제공합니다. 

추상화 방법에 protocol 만 있는 것이 아닙니다. 우린 structure 와 mutable properties 로 인터페이스를 나타내고, struct의 값을 구성함으로 채택을 표현할 것입니다. (struct style 이라고 부르네요 ㅎㅎ 자세한 내용은 https://www.pointfree.co/collections/dependencies 여기를 참고해주세요)

TestStore 생성부에 후행 클로져로 withDependencies: 를 붙여주어 가짜 Dependency 를 주입해줄 수 있습니다. 이는 Protocol 을 이용한 의존성역전원칙과 마찬가지로 추상화가 되어 이제 테스터블한 코드가 완성되었습니다. 


> 예제코드에서 보여준 네트워킹에 대한 테스트는 그저 Call Count 를 세기 위한 테스트와도 같은 것이라 판단된다. 의도한 마지막 메서드가 실행되는지에 대한 테스트인 것이다. 결국엔 TCA 에서도 실제 네트워킹에 대한 테스트는 원하지 않는 것이다. 



### References
- [공식 깃허브 문서](https://pointfreeco.github.io/swift-composable-architecture/main/tutorials/composablearchitecture/01-01-yourfirstfeature)

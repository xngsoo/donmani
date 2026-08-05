# CLAUDE.md

이 파일은 **Claude Code(Claude Opus 5)** 가 이 저장소에서 작업할 때 따르는 프로젝트 가이드입니다.
Opus 5 동작 특성에 맞춰 작성됐으며, 예전 모델용 지시(중복 검증·재확인 요청 등)는 의도적으로 제외했습니다 — 이유는 문서 하단 참고.

---

## 프로젝트 개요

- **앱 표시 이름**: 돈마니
- **프로젝트 / 앱 타깃 / 스킴 이름**: `Donmani`  (저장소명: `donmani`)
- **번들 ID**: `com.xngsoo.donmani`
- **지원 기기**: iPhone 전용 (iPad 미지원)
- **화면 방향**: 세로(Portrait) 전용 — 가로모드 미지원
- **최소 iOS 버전**: iOS 17.0 (SwiftData 요구 최소 버전)
- **툴체인**: Xcode `26.6`, Swift `6.3` (언어 모드 6.0), Tuist `4.202.6` (`mise.toml`로 고정)

방향 제약은 `Info.plist`의 `UISupportedInterfaceOrientations`를 Portrait 하나로 제한해 강제한다(코드에서 회전 허용 재정의 금지). iPad를 지원하지 않으므로 `~ipad` 키는 두지 않는다.

---

## 기술 스택

기본으로 아래를 사용한다. **그 외 라이브러리는 필요한 경우 자체 판단으로 추가**하되, 추가 시 (1) 사유를 커밋 메시지에 남기고, (2) 최소한만 도입하며, (3) Apple 1st-party로 해결 가능하면 그쪽을 우선한다.

- **UI**: SwiftUI (필요한 경우에 한해 UIKit interop)
- **비동기**: Swift Concurrency (async/await, actor)
- **영속화**: SwiftData
- **프로젝트 생성/관리**: Tuist (멀티모듈)
- **테스트**: Swift Testing
- **배포 자동화**: Fastlane
- **CI/CD**: Jenkins

---

## 명령어 (Commands)

이 프로젝트는 **Tuist로 Xcode 프로젝트를 생성**한다. `.xcodeproj` / `.xcworkspace`는 생성물이므로 커밋하지 않는다(`.gitignore`). 항상 매니페스트(`Project.swift` / `Workspace.swift`)를 수정하고 재생성한다.

```bash
# 최초 셋업 / 의존성 변경 시
mise install          # Tuist 등 툴 버전 설치 (mise 사용 시)
tuist install         # 외부 SPM 의존성 해결 (Tuist/Package.swift 기준)
tuist generate        # 매니페스트로부터 Xcode 프로젝트/워크스페이스 생성

# 빌드 / 테스트 (결과 검증은 반드시 이걸로)
tuist build
tuist test            # 변경 대상만 선택 테스트하려면 tuist test Donmani

# (선택) 생성된 워크스페이스로 직접 xcodebuild
xcodebuild -workspace Donmani.xcworkspace -scheme Donmani \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

규칙:

- 매니페스트를 수정한 뒤에는 반드시 `tuist generate`를 다시 실행한다.
- 의존성을 추가/변경하면 `Tuist/Package.swift`에 SPM으로 추가 → `tuist install` → `tuist generate`.
- 코드를 수정하면 관련 모듈 빌드 1회, 로직 변경 시 `tuist test`로 확인한 뒤 완료로 간주한다.
- (선택) `xcodebuild ... | xcbeautify`로 오류 출력을 정리하면 읽기 쉽다.

---

## 프로젝트 구조 (Tuist 멀티모듈)

Feature별로 모듈을 분리한다. 워크스페이스는 `Workspace.swift`로 묶고, 각 모듈은 자체 `Project.swift`를 가진다.

```
donmani/
├── Workspace.swift              # 전체 프로젝트 묶기
├── Tuist/
│   ├── Package.swift            # 외부 SPM 의존성
│   └── ProjectDescriptionHelpers/  # 모듈 생성 팩토리(공통 설정 표준화)
├── Projects/
│   ├── App/                     # 앱 진입점 + DI 조립 (target: Donmani)
│   ├── Features/
│   │   ├── FeatureHome/
│   │   └── FeatureXXX/          # 화면/기능 단위 모듈
│   ├── Core/                    # 도메인 모델(@Model) + SwiftData + 리포지토리
│   └── UI/                      # 디자인 시스템 · 공용 SwiftUI 컴포넌트
└── (*.xcodeproj / *.xcworkspace)  # 생성물, .gitignore
```

**의존성 방향(단방향, 순환 금지):**

- `App` → `Features/*` → (`Core`, `UI`)
- `Feature`끼리는 서로 import 하지 않는다. 공유가 필요하면 `Core`/`UI`로 내린다.
- `Core`, `UI`는 다른 모듈에 의존하지 않는 최하위 계층.
- 새 모듈은 `ProjectDescriptionHelpers`의 팩토리를 통해 만들어 빌드 설정·번들 ID 접두사·배포 타깃을 일관되게 유지한다.

앱 타깃 매니페스트 예:

```swift
.target(
    name: "Donmani",
    destinations: [.iPhone],
    product: .app,
    bundleId: "com.xngsoo.donmani",
    deploymentTargets: .iOS("17.0"),
    infoPlist: .extendingDefault(with: [
        "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"]
    ]),
    sources: ["Sources/**"],
    resources: ["Resources/**"],
    dependencies: [ /* .project(target: "FeatureHome", path: ...) 등 */ ]
)
```

---

## 아키텍처

- 패턴: MVVM. View는 상태 표시·입력만, 비즈니스 로직/영속화는 View 밖으로.
- ViewModel: `@Observable` + `@MainActor` 격리.
- SwiftData: `@Model` 타입과 `ModelContext` 접근은 `Core`의 리포지토리/서비스로 감싼다. Feature의 View가 컨텍스트를 직접 광범위하게 만지지 않게 한다.
- 의존성 주입: 이니셜라이저 주입 우선, 전역 싱글턴 지양. 조립은 `App` 모듈에서.

---

## 코딩 규칙 (Swift / SwiftUI)

- **최신 API·모범 사례 우선.** deprecated API를 새로 쓰지 않는다. 콜백/`DispatchQueue` 대신 async/await, `ObservableObject` 대신 `@Observable`.
- **동시성 안전.** Swift 6 strict concurrency 기준으로 데이터 레이스 없이 작성한다. UI 갱신은 `@MainActor`, 공유 가변 상태는 actor 또는 `Sendable`로 보호한다.
- **에러 처리 필수.** 실패 가능한 경로(네트워크, 디코딩, SwiftData 저장/조회, 파일 I/O, 옵셔널 언래핑)는 `throws`/`Result`/`do-catch`로 명시적으로 처리한다. `try!`, 강제 언래핑(`!`), 빈 `catch`는 금지(테스트 코드 예외).
- **주석 최소화.** 자명한 코드에 주석을 달지 않는다. 주석은 "왜"를 설명할 때만. 이름으로 의도를 드러낸다.
- **SwiftUI View는 항상 `#Preview` 포함.** 새로 만들거나 수정하는 모든 `View`에 목(mock) 데이터로 채운 `#Preview`를 함께 제공한다. 로딩/에러/빈 상태 분기가 있으면 대표 케이스별 프리뷰를 추가한다. SwiftData 프리뷰는 `.modelContainer(for:inMemory: true)`로 인메모리 컨테이너를 쓴다.
- **불완전 산출물 금지.** 스텁·`// TODO: implement`·플레이스홀더로 남기지 않는다. 요청한 기능을 끝까지 구현한다. 정말 결정이 필요한 지점만 한 문장으로 질문한다.
- **설명 후 코드.** 코드를 제시하기 전에 동작 방식을 한 문단으로 간략히 설명한다.

---

## 테스트

- 프레임워크: **Swift Testing** (`@Test`, `#expect`, `#require`).
- 비즈니스 로직·ViewModel·리포지토리를 단위 테스트로 커버. 순수 함수는 경계값 포함. 테스트는 해당 모듈에 함께 둔다.
- SwiftData 의존 코드는 인메모리 `ModelContainer`로 테스트한다.
- 외부 의존성(네트워크 등)은 프로토콜로 추상화하고 목으로 대체한다.

---

## CI/CD & Fastlane (Jenkins)

빌드·서명·배포는 **Fastlane 레인**으로 감싸고, **Jenkins**가 macOS 에이전트에서 그 레인을 호출한다. 서명 인증서/API 키/비밀번호는 저장소에 넣지 않고 Jenkins Credentials로 주입한다.

- Fastlane 레인(예시):
  - `fastlane test` — `tuist generate` 후 `scan`
  - `fastlane beta` — `gym` 아카이브 → `pilot`로 TestFlight 업로드
  - `fastlane release` — App Store 제출
- `gym`/`scan`은 생성된 `Donmani.xcworkspace` / `Donmani` 스킴 사용.
- Jenkins Pipeline 단계(권장):
  1. Checkout
  2. Tooling: `mise install` → `tuist install` → `tuist generate`
  3. Test: `fastlane test`
  4. Archive: `fastlane beta` (또는 태그 push 시 `release`)
- Jenkins 에이전트 요건: macOS + 지정 Xcode 버전, mise/tuist, fastlane. 생성물(`.xcworkspace` 등)은 파이프라인에서 매번 새로 생성한다(캐시 사용 시 `tuist cache` 고려).

---

## Git · GitHub · 브랜치 전략

원격은 **GitHub**. 브랜치 모델은 1인 개발 + Jenkins CI에 맞춘 **GitHub Flow + 릴리스 태그**를 사용한다.

### 브랜치 규칙

- `main` — 항상 **릴리스 가능한** 상태. 직접 커밋 금지, **PR로만 병합**. App Store 릴리스는 여기서 `vX.Y.Z` 태그로 끊는다.
- 작업 브랜치는 `main`에서 분기해 **짧게** 유지하고 PR로 되돌린다:
  - `feature/<설명>` — 기능
  - `fix/<설명>` — 버그 수정
  - `hotfix/<설명>` — 출시본 긴급 수정(필요 시 릴리스 태그에서 분기)
  - `refactor/` · `chore/` · `docs/` · `ci/` — 보조 작업
- PR은 작게, 하나의 목적. 머지 전 **CI(테스트) 통과 필수**. 히스토리 선형을 위해 **Squash merge** 권장.

### 커밋 메시지 — Conventional Commits

`feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `ci:`, `docs:` 접두사를 쓴다. 제목은 72자 이내, 본문에는 "왜"를 적는다. 이슈가 있으면 `(#123)`로 참조한다.

### 브랜치 → Jenkins 트리거 매핑

- PR 열림/갱신 → `fastlane test` (머지 게이트)
- `main` 병합 → `fastlane beta` (TestFlight 자동 배포)
- `v*` 태그 push → `fastlane release` (App Store 제출)

> **미정 — Jenkins ↔ GitHub 연동 방식.** PR·브랜치·태그 이벤트를 Jenkins가 어떻게 받을지 아직 정하지 않았다(후보: multibranch pipeline + GitHub webhook / GitHub Branch Source 플러그인 / SCM 폴링 등). 연동을 실제로 구성하는 단계(`Jenkinsfile`, webhook, 자격증명 설정)에 오면, **진행하기 전에 어떤 방식을 쓸지 사용자에게 먼저 질문한다.** 확정 전에는 위 트리거 매핑을 목표 동작으로만 참고한다.

### GitHub 연결 (최초 1회)

```bash
git init
git branch -M main
git remote add origin git@github.com:<계정>/donmani.git
git add .
git commit -m "chore: initial Tuist project scaffold"
git push -u origin main
```

- GitHub → Settings → Branches에서 `main` 보호 규칙 설정: **PR 필수 + 상태 체크(Jenkins) 통과 필수**, force-push·삭제 금지.

### .gitignore 필수 항목 (Tuist / Xcode / Fastlane)

```gitignore
# macOS / Xcode
.DS_Store
xcuserdata/
*.xcuserstate
DerivedData/

# Tuist 생성물 (프로젝트/워크스페이스는 생성물이므로 커밋하지 않음)
*.xcodeproj
*.xcworkspace
Derived/
.tuist-cache/

# SPM
.build/
.swiftpm/

# Fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/test_output/

# Claude Code — 개인/로컬 파일만 무시 (공유 파일은 커밋)
.claude/settings.local.json
.claude/*.local.json
CLAUDE.local.md
```

- **`Tuist/Package.resolved`는 커밋한다** — 의존성 버전을 고정해 재현 가능한 빌드를 보장한다.
- **Claude 관련 파일**: 공유용 `CLAUDE.md`·`.claude/settings.json`·`.claude/commands/`·`.mcp.json`은 **커밋**하고, 개인용 `.claude/settings.local.json`·`CLAUDE.local.md`만 **무시**한다. Claude Code의 세션·todo·히스토리 등 진행 중 산출물은 저장소가 아니라 사용자 홈(`~/.claude/`)에 저장되므로 저장소 `.gitignore` 대상이 아니다.
- 서명 인증서·provisioning profile·API 키·`.env` 등 **비밀정보는 절대 커밋하지 않는다**(Jenkins Credentials로 주입).

### 에이전트(Claude Code) git 규칙

- 작업 시작 시 `main`을 최신화하고 새 작업 브랜치를 만든다. **`main`에 직접 커밋/푸시하지 않는다.**
- 커밋은 논리 단위로 나누고 Conventional Commits 형식을 지킨다.
- **커밋 메시지·PR 본문에 Claude가 작성했다는 표시를 남기지 않는다.** `Co-Authored-By: Claude ...`, `🤖 Generated with Claude Code` 같은 서명·푸터를 붙이지 않는다.
- **원격에 영향을 주거나 되돌리기 어려운 작업은 실행 전 사용자에게 확인받는다**: `git push`, PR 생성/머지, `git push --force`, 브랜치/태그 삭제, 태그 push, 공유 브랜치의 히스토리 재작성(`rebase`/`reset --hard`). 로컬 브랜치·커밋 생성은 확인 없이 진행 가능.
- 비밀정보가 커밋에 포함되지 않는지 매 커밋 전에 확인한다.

---

## Opus 5 작업 방식 (에이전트 동작)

Opus 5는 기본적으로 응답이 길고, 나레이션이 많고, 스스로 검증·정정하며, 서브에이전트에 잘 위임한다. 이 저장소에서는 아래로 조정한다.

### 응답 간결성
채팅 응답은 핵심에 집중해 간결하게. 단서·주의문은 짧게 하고 본론에 지면을 쓴다. 설명 요청이 아니면 고수준 요약으로 답한다.

### 작업 스코프
요청받은 것을 요청받은 범위로 전달한다. 통상적 판단은 스스로 내리되, 해석에 따라 결과물이 크게 달라지는 경우에만 확인한다. 요청이 잘못됐거나 더 나은 방법이 있으면 한 문장으로 짚고 요청대로 진행한다. 범위를 임의로 넓히거나 좁히지 않는다.

### 서브에이전트
독립적이고 규모가 큰 병렬 작업(예: 여러 모듈에 걸친 광범위한 조사)에만 위임한다. 몇 번의 툴 호출로 끝낼 일은 직접 하고, 자기 검증·재확인 목적으로 서브에이전트를 쓰지 않는다. 필요 최소 개수만 띄운다.

### 진행 나레이션
첫 툴 호출 전 한 문장으로 무엇을 할지 말한다. 작업 중에는 중요한 발견이나 방향 전환이 있을 때만 짧게 알린다. 마무리에서는 결과부터 말한다.

### 정정 나레이션
이전 발언의 오류는 그것이 코드·결론·판단을 바꿀 때만 간단히 정정하고 이어간다. 영향 없는 사소한 수정은 조용히 고치고 넘어간다.

### 코드 리뷰
리뷰 시 "고심각도만 보고"처럼 제한하지 않는다. 발견한 이슈를 모두 보고하고, 취사선택은 사람이 별도 단계에서 한다.

### effort
기본 `high`. 루틴 작업은 `low`/`medium`을 적극 활용해 비용·지연을 줄이고, 어려운 리팩터·복잡한 기능은 `xhigh`로 올린다.

---

## 의도적으로 넣지 않은 것 (재추가 금지)

Opus 5 프롬프팅 가이드에 따라 아래는 **일부러 뺐다**. 다시 넣으면 과잉 검증으로 토큰만 늘고 품질 이득이 없다.

- "답을 두 번 확인하라 / 응답 전 재검증하라 / 최종 검증 단계를 넣어라" 류의 재확인 지시
- 자기 작업을 검증하기 위한 별도 서브에이전트 지시
- "생각/추론하지 말라" 류의 지시 (내부 태그 누출 유발)
- 예전 모델에서 가져온 effort 기본값 (본인 eval로 다시 스윕할 것)

Useful utils for [gist.cafe](https://gist.cafe) Swift Apps.

## Install

```swift
dependencies: [
    .package(name: "gistcafe", url: "https://github.com/ServiceStack/gistcafe-swift.git", from: "1.0.0"),
],
```

## Usage

Simple usage example:

```swift
import Foundation
import FoundationNetworking
import gistcafe

struct GitHubRepo : Codable {
  let name: String
  let description: String?
  let language: String?
  let watchers: Int
  let forks: Int
}

let orgName = "apple"

if let url = URL(string: "https://api.github.com/orgs/\(orgName)/repos") {
    let sem = DispatchSemaphore.init(value: 0)

    URLSession.shared.dataTask(with: url) { data, response, error in
        defer { sem.signal() }
        if let data = data {
            do {
                let orgRepos = try JSONDecoder().decode([GitHubRepo].self, from: data)
                    .sorted { $0.watchers > $1.watchers }

                print("Top 3 \(orgName) GitHub Repos:")
                Inspect.printDump(Array(orgRepos.prefix(3)))

                print("\nTop 10 \(orgName) GitHub Repos:")
                Inspect.printDumpTable(Array(orgRepos.prefix(10)), 
                    columns:["name","language","watchers","forks"])

                Inspect.vars(["orgRepos":orgRepos])
            } catch let error {
                print(error)
            }
        }
    }.resume()

  sem.wait()
}
```

Which outputs:

```
Top 3 apple GitHub Repos:
[
  {
    name : swift,
    forks : 8774,
    watchers : 54710,
    description : The Swift Programming Language,
    language : C++
  },
  {
    name : swift-evolution,
    forks : 1900,
    watchers : 11744,
    language : Markdown,
    description : This maintains proposals for changes to the Swift Programming Language.
  },
  {
    name : swift-package-manager,
    language : Swift,
    watchers : 8114,
    forks : 1023,
    description : The Package Manager for the Swift Programming Language
  }
]

Top 10 apple GitHub Repos:
+------------------------------------------------------------+
|            name            |  language  | watchers | forks |
+------------------------------------------------------------+
| swift                      | C++        |    54710 |  8774 |
| swift-evolution            | Markdown   |    11744 |  1900 |
| swift-package-manager      | Swift      |     8114 |  1023 |
| swift-corelibs-foundation  | Swift      |     4093 |   959 |
| swift-corelibs-libdispatch | C          |     1955 |   363 |
| cups                       | C          |     1174 |   359 |
| swift-docker               | Dockerfile |     1117 |   138 |
| swift-corelibs-xctest      | Swift      |      871 |   236 |
| swift-llbuild              | C++        |      819 |   169 |
| swift-llvm                 | LLVM       |      802 |   196 |
+------------------------------------------------------------+
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/ServiceStack/gistcafe-swift/issues).